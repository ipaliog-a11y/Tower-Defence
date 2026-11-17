class_name GameState
extends RefCounted
## Runtime match state: towers, power links, enemies, economy.

signal log_line(text: String, kind: String)
signal toast(text: String)
signal state_changed
signal match_over(won: bool, message: String)
## kind: place|link|wireless|wave|hit|kill|burst|spike_on|spike_off|cut|fortify|channel|channel_break|leak|win|lose|ui|error
signal juice(kind: String, payload: Dictionary)

enum Phase { BUILD, COMBAT, WON, LOST }

var scrap: int = GameData.START_SCRAP
var max_power: int = 100
var heat: int = 0
var integrity: int = GameData.MAX_INTEGRITY
var wave_index: int = 0
var phase: Phase = Phase.BUILD

## cell_key -> { type, fired_this_wave, fired_recently }
var towers: Dictionary = {}
## link_id -> { a, b, wireless, fortified }
var links: Dictionary = {}

var tool: String = "capacitor"
var link_from: String = ""
var sell_mode: bool = false
var fortify_armed: bool = false
var fortify_charges: int = 2
var burst_used: bool = false
var spike_on: bool = false
var sim_speed: float = 1.0
var wave_leak: int = 0

var enemies: Array = []
var spawn_queue: Array = []
var spawn_timer: float = 0.0

var path_lookup: Dictionary = {}
var blocked_lookup: Dictionary = {}

# visual FX: { kind, life, max, ... }
var fx: Array = []


func _init() -> void:
	path_lookup = GameData.path_set()
	blocked_lookup = GameData.blocked_set()


func reset(clear_log: bool = true) -> void:
	scrap = GameData.START_SCRAP
	max_power = 100
	heat = 0
	integrity = GameData.MAX_INTEGRITY
	wave_index = 0
	phase = Phase.BUILD
	towers.clear()
	links.clear()
	enemies.clear()
	spawn_queue.clear()
	spawn_timer = 0.0
	tool = "capacitor"
	link_from = ""
	sell_mode = false
	fortify_armed = false
	fortify_charges = 2
	burst_used = false
	spike_on = false
	wave_leak = 0
	fx.clear()
	if clear_log:
		emit_log("—— New run —— Godot vertical slice", "good")
	state_changed.emit()


func emit_log(text: String, kind: String = "") -> void:
	log_line.emit(text, kind)


func emit_toast(text: String) -> void:
	toast.emit(text)


func emit_juice(kind: String, payload: Dictionary = {}) -> void:
	juice.emit(kind, payload)
	# Always spawn a few visual FX for juice kinds that need them
	match kind:
		"place":
			if payload.has("cell"):
				_fx_ring(payload.cell, Color("5ec8c0"), 0.35)
				_fx_flash_cell(payload.cell, Color("5ec8c0"), 0.25)
		"link", "wireless":
			if payload.has("a") and payload.has("b"):
				_fx_link_pulse(str(payload.a), str(payload.b), kind == "wireless")
		"cut":
			if payload.has("a") and payload.has("b"):
				_fx_link_pulse(str(payload.a), str(payload.b), true, Color("e06c75"), 0.45)
				_fx_sparks_mid(str(payload.a), str(payload.b), Color("ff8a7a"))
		"kill":
			if payload.has("pos"):
				_fx_ring_world(payload.pos, Color("98c379"), 0.4)
				_fx_sparks_world(payload.pos, Color("e5c07b"))
			elif payload.has("cell"):
				_fx_ring(payload.cell, Color("98c379"), 0.4)
				_fx_flash_cell(payload.cell, Color("e5c07b"), 0.3)
		"burst":
			if payload.has("pos"):
				_fx_ring_world(payload.pos, Color("61afef"), 0.5)
				_fx_sparks_world(payload.pos, Color("61afef"), 14)
		"leak":
			_fx_screen_tint(Color("e06c75"), 0.35)
		"wave":
			_fx_screen_tint(Color("5ec8c0"), 0.2)
		"fortify":
			if payload.has("a") and payload.has("b"):
				_fx_link_pulse(str(payload.a), str(payload.b), false, Color("61afef"), 0.5)
		"channel":
			if payload.has("pos"):
				_fx_ring_world(payload.pos, Color("ff6b4a"), 0.55)
		"channel_break":
			if payload.has("pos"):
				_fx_sparks_world(payload.pos, Color.WHITE, 10)
		"win":
			_fx_screen_tint(Color("98c379"), 0.5)
		"lose":
			_fx_screen_tint(Color("be5046"), 0.6)


func _fx_ring(cell: Vector2i, color: Color, life: float) -> void:
	fx.append({"kind": "ring", "cell": cell, "color": color, "life": life, "max": life})


func _fx_ring_world(pos: Vector2, color: Color, life: float) -> void:
	fx.append({"kind": "ring_world", "pos": pos, "color": color, "life": life, "max": life})


func _fx_flash_cell(cell: Vector2i, color: Color, life: float) -> void:
	fx.append({"kind": "flash_cell", "cell": cell, "color": color, "life": life, "max": life})


func _fx_link_pulse(a: String, b: String, wireless: bool, color: Color = Color.WHITE, life: float = 0.35) -> void:
	fx.append({
		"kind": "link_pulse", "a": a, "b": b, "wireless": wireless,
		"color": color if color != Color.WHITE else (Color("50dcff") if wireless else Color("d19a66")),
		"life": life, "max": life,
	})


func _fx_sparks_mid(a: String, b: String, color: Color) -> void:
	var pa := node_pos(a)
	var pb := node_pos(b)
	# world positions filled at draw time via cells; store cells
	fx.append({
		"kind": "sparks",
		"cell_a": pa,
		"cell_b": pb,
		"color": color,
		"life": 0.4,
		"max": 0.4,
		"count": 12,
	})


func _fx_sparks_world(pos: Vector2, color: Color, count: int = 10) -> void:
	fx.append({
		"kind": "sparks_world",
		"pos": pos,
		"color": color,
		"life": 0.35,
		"max": 0.35,
		"count": count,
	})


func _fx_screen_tint(color: Color, life: float) -> void:
	fx.append({"kind": "screen_tint", "color": color, "life": life, "max": life})


func is_yard(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= GameData.SIZE or cell.y < 0 or cell.y >= GameData.SIZE:
		return false
	if cell == GameData.CORE:
		return false
	if path_lookup.has(cell):
		return false
	if blocked_lookup.has(cell):
		return false
	return true


func is_land(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= GameData.SIZE or cell.y < 0 or cell.y >= GameData.SIZE:
		return false
	if path_lookup.has(cell):
		return false
	if blocked_lookup.has(cell):
		return false
	return true


func same_landmass(a: Vector2i, b: Vector2i) -> bool:
	if not is_land(a) or not is_land(b):
		return false
	if a == b:
		return true
	var seen: Dictionary = {}
	var q: Array[Vector2i] = [a]
	seen[a] = true
	while not q.is_empty():
		var cur: Vector2i = q.pop_front()
		if cur == b:
			return true
		for n in GameData.neighbors4(cur):
			if seen.has(n) or not is_land(n):
				continue
			seen[n] = true
			q.append(n)
	return false


func node_pos(node: String) -> Vector2i:
	if node == "core":
		return GameData.CORE
	return GameData.parse_key(node)


func link_id(a: String, b: String) -> String:
	if a < b:
		return a + "|" + b
	return b + "|" + a


func count_wireless() -> int:
	var n := 0
	for L in links.values():
		if L.wireless:
			n += 1
	return n


func is_node(node: String) -> bool:
	if node == "core":
		return true
	return towers.has(node)


func can_link(a: String, b: String, wireless: bool) -> Dictionary:
	if a == b:
		return {"ok": false, "reason": "Same node"}
	if not is_node(a) or not is_node(b):
		return {"ok": false, "reason": "Need Core or towers"}
	var pa := node_pos(a)
	var pb := node_pos(b)
	var dist := GameData.chebyshev(pa, pb)
	var range_max := GameData.WIRELESS_RANGE if wireless else GameData.LINK_RANGE
	if dist < 1:
		return {"ok": false, "reason": "Too close"}
	if dist > range_max:
		return {"ok": false, "reason": "Out of range (max %d)" % range_max}
	if not wireless and not same_landmass(pa, pb):
		return {"ok": false, "reason": "Path/scenery blocks land link — use Wireless"}
	if links.has(link_id(a, b)):
		return {"ok": false, "reason": "Already linked"}
	if wireless and count_wireless() >= GameData.WIRELESS_MAX:
		return {"ok": false, "reason": "Max %d wireless" % GameData.WIRELESS_MAX}
	return {"ok": true, "dist": dist}


func powered_nodes() -> Dictionary:
	var powered: Dictionary = {"core": true}
	var q: Array[String] = ["core"]
	while not q.is_empty():
		var cur: String = q.pop_front()
		for L in links.values():
			var other := ""
			if L.a == cur:
				other = L.b
			elif L.b == cur:
				other = L.a
			else:
				continue
			if powered.has(other) or not is_node(other):
				continue
			powered[other] = true
			q.append(other)
	return powered


func link_tax() -> int:
	var t := 0
	for L in links.values():
		t += GameData.WIRELESS_DRAW if L.wireless else GameData.LINK_DRAW
	return t


## Resolves one numeric tower stat. **This is the hook the progression / upgrade system
## plugs into** — apply purchased modifiers here and every combat path picks them up,
## because no combat code reads GameData.TOWER_DEFS numbers directly.
## `key` must be one of GameData.TOWER_STAT_KEYS.
func tower_stat(type: String, key: String) -> float:
	var base: float = float(GameData.TOWER_DEFS[type].get(key, 0.0))
	# Upgrades land here, e.g.:
	#   base += flat_bonus(type, key)
	#   base *= mult_bonus(type, key)
	return base


func compute_load(use_fire: bool) -> Dictionary:
	var powered := powered_nodes()
	var draw := 0
	var powered_towers := 0
	for k in towers:
		if not powered.has(k):
			continue
		powered_towers += 1
		var t: Dictionary = towers[k]
		if use_fire or t.fired_this_wave or (phase == Phase.COMBAT and t.fired_recently):
			if t.type == "drainer" and spike_on:
				draw += int(tower_stat(t.type, "spike_draw"))
			else:
				draw += int(tower_stat(t.type, "draw_fire"))
		else:
			draw += int(tower_stat(t.type, "draw_idle"))
	var tax := link_tax()
	draw += tax
	return {"draw": draw, "max": max_power, "powered_towers": powered_towers, "powered": powered, "tax": tax}


func add_link(a: String, b: String, wireless: bool, free: bool = false) -> bool:
	var check := can_link(a, b, wireless)
	if not check.ok:
		if not free:
			emit_toast(check.reason)
		return false
	var cost := 0 if free else (GameData.WIRELESS_COST if wireless else GameData.LINK_COST)
	if not free and scrap < cost:
		emit_toast("Not enough Scrap")
		return false
	if not free:
		scrap -= cost
	var id := link_id(a, b)
	links[id] = {"a": a, "b": b, "wireless": wireless, "fortified": false}
	if not free:
		emit_log(("%s %s ↔ %s" % ["Wireless" if wireless else "Powerline", a, b]), "good")
		emit_toast("Wireless bridge set" if wireless else "Powerline attached")
		emit_juice("wireless" if wireless else "link", {"a": a, "b": b})
	state_changed.emit()
	return true


func auto_link_tower(cell_key: String, free: bool = false) -> bool:
	var powered := powered_nodes()
	var best_std: Dictionary = {}
	var best_w: Dictionary = {}
	var candidates: Array[String] = ["core"]
	for k in towers.keys():
		if k != cell_key:
			candidates.append(k)
	for n in candidates:
		if n != "core" and not powered.has(n):
			continue
		var p_std := can_link(cell_key, n, false)
		if p_std.ok:
			if best_std.is_empty() or int(p_std.dist) < int(best_std.dist):
				best_std = {"n": n, "dist": p_std.dist}
		var p_w := can_link(cell_key, n, true)
		if p_w.ok:
			if best_w.is_empty() or int(p_w.dist) < int(best_w.dist):
				best_w = {"n": n, "dist": p_w.dist}
	if not best_std.is_empty():
		return add_link(cell_key, best_std.n, false, free)
	if not best_w.is_empty():
		return add_link(cell_key, best_w.n, true, free)
	return false


func place_tower(cell: Vector2i, type: String, free: bool = false) -> bool:
	if not is_yard(cell):
		if not free:
			emit_toast("Can't build here" if not path_lookup.has(cell) else "Not on the road")
		return false
	var k := GameData.cell_key(cell)
	if towers.has(k):
		if not free:
			emit_toast("Tower here already")
		return false
	if towers.size() >= GameData.TOWER_CAP:
		if not free:
			emit_toast("Tower cap (%d)" % GameData.TOWER_CAP)
		return false
	var cost := 0 if free else int(GameData.TOWER_DEFS[type].cost)
	if not free and scrap < cost:
		emit_toast("Not enough Scrap")
		return false
	if not free:
		scrap -= cost
	towers[k] = {
		"type": type, "fired_this_wave": false, "fired_recently": false,
		"cooldown": 0.0, "place_flash": 0.35,
	}
	if not free:
		emit_log("Built %s at %s" % [GameData.TOWER_DEFS[type].name, k])
		emit_juice("place", {"cell": cell, "type": type})
	var linked := auto_link_tower(k, free)
	if not linked and not free:
		emit_toast("Tower dark — link it (Powerline / Wireless)")
		emit_log("Tower at %s has no powerline yet" % k, "warn")
		emit_juice("error")
	state_changed.emit()
	return true


func sell_tower_at(cell: Vector2i) -> void:
	if phase != Phase.BUILD:
		emit_toast("Sell between waves")
		return
	var k := GameData.cell_key(cell)
	if not towers.has(k):
		emit_toast("Click a tower to sell")
		return
	var t: Dictionary = towers[k]
	var refund := int(GameData.TOWER_DEFS[t.type].cost)
	var remove: Array[String] = []
	for id in links:
		var L: Dictionary = links[id]
		if L.a == k or L.b == k:
			refund += GameData.WIRELESS_COST if L.wireless else GameData.LINK_COST
			remove.append(id)
	for id in remove:
		links.erase(id)
	towers.erase(k)
	refund = int(floor(refund * 0.7))
	scrap += refund
	emit_log("Sold tower + links for %d" % refund, "good")
	state_changed.emit()


func pick_node_at(cell: Vector2i) -> String:
	if cell == GameData.CORE:
		return "core"
	var k := GameData.cell_key(cell)
	if towers.has(k):
		return k
	return ""


func handle_link_click(cell: Vector2i, wireless: bool) -> void:
	var node := pick_node_at(cell)
	if node.is_empty():
		emit_toast("Click Core or a tower")
		return
	if link_from.is_empty():
		link_from = node
		emit_toast("Wireless: click other end" if wireless else "Powerline: click target")
		state_changed.emit()
		return
	if link_from == node:
		link_from = ""
		emit_toast("Cancelled")
		state_changed.emit()
		return
	add_link(link_from, node, wireless, false)
	link_from = ""
	state_changed.emit()


func fortify_at(cell: Vector2i) -> void:
	if fortify_charges <= 0:
		emit_toast("No fortify charges")
		return
	var node := pick_node_at(cell)
	var best := ""
	for id in links:
		var L: Dictionary = links[id]
		if L.fortified:
			continue
		if not node.is_empty() and (L.a == node or L.b == node):
			best = id
			break
	if best.is_empty():
		for id in links:
			if not links[id].fortified:
				best = id
				break
	if best.is_empty():
		emit_toast("No link to fortify")
		return
	var Lf: Dictionary = links[best]
	Lf.fortified = true
	fortify_charges -= 1
	fortify_armed = false
	emit_log("Fortified link %s (%d left)" % [best, fortify_charges], "good")
	emit_toast("Link fortified")
	emit_juice("fortify", {"a": Lf.a, "b": Lf.b})
	state_changed.emit()


func apply_preset(name: String) -> void:
	if phase != Phase.BUILD and phase != Phase.WON and phase != Phase.LOST:
		emit_toast("Only between waves")
		return
	reset(false)
	scrap = GameData.PRESET_LEFTOVER
	if name == "north":
		place_tower(Vector2i(2, 2), "capacitor", true)
		place_tower(Vector2i(2, 4), "transformer", true)
		place_tower(Vector2i(2, 6), "regulator", true)
		place_tower(Vector2i(3, 6), "drainer", true)
		add_link("core", "2,2", false, true)
		add_link("2,2", "2,4", false, true)
		add_link("2,4", "2,6", false, true)
		add_link("2,6", "3,6", false, true)
		emit_log("Preset: North rail", "good")
		emit_toast("North rail + 75 scrap")
	elif name == "south":
		place_tower(Vector2i(2, 3), "transformer", true)
		place_tower(Vector2i(2, 6), "capacitor", true)
		place_tower(Vector2i(4, 6), "drainer", true)
		place_tower(Vector2i(7, 6), "regulator", true)
		add_link("core", "2,3", false, true)
		add_link("2,3", "2,6", false, true)
		add_link("2,6", "4,6", false, true)
		add_link("4,6", "7,6", true, true)
		emit_log("Preset: South rail (wireless late)", "good")
		emit_toast("South rail + 75 scrap")
	elif name == "split":
		place_tower(Vector2i(2, 2), "capacitor", true)
		place_tower(Vector2i(2, 6), "transformer", true)
		place_tower(Vector2i(4, 6), "drainer", true)
		place_tower(Vector2i(7, 5), "regulator", true)
		add_link("core", "2,2", false, true)
		add_link("2,2", "2,6", false, true)
		add_link("2,6", "4,6", false, true)
		add_link("4,6", "7,5", true, true)
		emit_log("Preset: Split feed", "good")
		emit_toast("Split feed + 75 scrap")
	state_changed.emit()


func start_wave() -> void:
	if phase != Phase.BUILD:
		return
	if wave_index >= GameData.WAVES.size():
		emit_toast("Campaign complete")
		return
	var load := compute_load(false)
	if int(load.powered_towers) == 0:
		emit_toast("No powered towers — link them to the Core")
		return
	phase = Phase.COMBAT
	enemies.clear()
	spawn_queue = GameData.WAVES[wave_index].duplicate()
	spawn_timer = 0.25
	burst_used = false
	var regs := 0
	for t in towers.values():
		if t.type == "regulator":
			regs += 1
	fortify_charges = (2 + maxi(0, regs - 1)) if regs > 0 else 0
	fortify_armed = false
	wave_leak = 0
	link_from = ""
	for t in towers.values():
		t.fired_this_wave = false
		t.fired_recently = false
		t.cooldown = 0.0
	emit_log("Wave %d started (%d enemies)" % [wave_index, spawn_queue.size()])
	emit_toast("Wave %d · HP %d/%d" % [wave_index, integrity, GameData.MAX_INTEGRITY])
	emit_juice("wave", {"wave": wave_index})
	state_changed.emit()


func spawn_enemy(type: String) -> void:
	var def: Dictionary = GameData.ENEMY_DEFS[type]
	enemies.append({
		"type": type,
		"hp": float(def.hp),
		"max_hp": float(def.hp),
		"path_index": 0,
		"progress": 0.0,
		"alive": true,
		"channeling": false,
		"channel_time": 0.0,
		"channel_target": "",
		"wants_second_cut": false,
		"cuts_done": 0,
		"channel_dmg": 0.0,
	})


func enemy_cell(e: Dictionary) -> Vector2i:
	var idx: int = mini(int(e.path_index), GameData.PATH.size() - 1)
	return GameData.PATH[idx]


## "First" targeting: the enemy furthest along the path (nearest the base) within range.
func acquire_target(pos: Vector2i, range_cells: int) -> Dictionary:
	var best: Dictionary = {}
	var best_progress := -1.0
	for e in enemies:
		if not e.alive:
			continue
		if GameData.chebyshev(pos, enemy_cell(e)) > range_cells:
			continue
		var prog := float(e.path_index) + float(e.progress)
		if prog > best_progress:
			best_progress = prog
			best = e
	return best


## Every powered tower runs its own cooldown and fires independently. Enemy `speed` is a
## real defensive stat under this model: a faster enemy spends less time inside a tower's
## range and therefore eats fewer shots.
func fire_towers(dt: float, powered: Dictionary, cell_size: float) -> void:
	for k in towers:
		if not powered.has(k):
			continue
		var t: Dictionary = towers[k]
		t.cooldown = maxf(0.0, float(t.get("cooldown", 0.0)) - dt)
		var rate := tower_stat(t.type, "fire_rate")
		if rate <= 0.0:
			continue
		var pos := GameData.parse_key(k)
		var target := acquire_target(pos, int(tower_stat(t.type, "range")))
		if target.is_empty():
			t.fired_recently = false
			continue
		# Holding a target counts as engaged for load purposes, even between shots.
		t.fired_recently = true
		if t.cooldown > 0.0:
			continue
		t.cooldown = 1.0 / rate
		var def: Dictionary = GameData.TOWER_DEFS[t.type]
		var dmg := tower_stat(t.type, "damage")
		if t.type == "drainer" and spike_on:
			dmg = tower_stat(t.type, "spike_damage")
		var dealt := damage_enemy(target, dmg, {
			"pos": pos,
			"to_world": enemy_world_pos(target, cell_size),
			"color": def.color,
			"name": def.short,
			"tower": t,
			"pierce": tower_stat(t.type, "armor_pierce"),
		})
		# Return fire on a channeling saboteur builds toward interrupting the cut.
		if target.get("channeling", false):
			target.channel_dmg += dealt
		if target.hp <= 0.0:
			kill_enemy(target)


func spawn_hit_fx(from: Vector2i, to_world: Vector2, dmg: int, color: Color, _label: String) -> void:
	fx.append({
		"kind": "beam",
		"from": from,
		"to": to_world,
		"color": color,
		"life": 0.18,
		"max": 0.18,
	})
	# Impact spark at target
	fx.append({
		"kind": "impact",
		"pos": to_world,
		"color": color,
		"life": 0.2,
		"max": 0.2,
	})
	fx.append({
		"kind": "float",
		"pos": to_world + Vector2(randf_range(-6, 6), -10),
		"text": "-%d" % dmg,
		"color": color,
		"life": 0.7,
		"max": 0.7,
		"vy": -28.0,
	})
	# Tower muzzle flash
	fx.append({
		"kind": "flash_cell",
		"cell": from,
		"color": color,
		"life": 0.12,
		"max": 0.12,
	})


func damage_enemy(e: Dictionary, amount: float, meta: Dictionary = {}) -> float:
	var def: Dictionary = GameData.ENEMY_DEFS[e.type]
	var dmg := amount
	if def.has("armor"):
		# armor_pierce eats armor first; whatever is left still subtracts flat.
		var armor := maxf(0.0, float(def.armor) - float(meta.get("pierce", 0.0)))
		dmg = maxf(1.0, dmg - armor)
	e.hp -= dmg
	if not meta.is_empty():
		spawn_hit_fx(meta.pos, meta.to_world, int(dmg), meta.color, meta.name)
		meta.tower.fired_this_wave = true
		meta.tower.fired_recently = true
		meta.tower.muzzle = 0.12
		# Throttled hit juice (not every frame of multi-tower volleys)
		if randf() < 0.35:
			emit_juice("hit", {"pos": meta.to_world})
	return dmg


func kill_enemy(e: Dictionary) -> void:
	e.alive = false
	var def: Dictionary = GameData.ENEMY_DEFS[e.type]
	scrap += int(def.scrap)
	emit_log("Killed %s (+%d scrap)" % [def.name, def.scrap], "good")
	# pos filled by caller when possible via last known — use path cell
	var cell := enemy_cell(e)
	# approximate; board will interpret via sparks if world pos later
	emit_juice("kill", {"cell": cell})


func enemy_world_pos(e: Dictionary, cell_size: float) -> Vector2:
	var idx: int = int(e.path_index)
	if idx >= GameData.PATH.size() - 1:
		var a: Vector2i = GameData.PATH[GameData.PATH.size() - 1]
		return Vector2((a.y + 0.5) * cell_size, (a.x + 0.5) * cell_size)
	var a2: Vector2i = GameData.PATH[idx]
	var b2: Vector2i = GameData.PATH[mini(idx + 1, GameData.PATH.size() - 1)]
	var t: float = float(e.progress)
	var col := lerpf(float(a2.y), float(b2.y), t)
	var row := lerpf(float(a2.x), float(b2.x), t)
	return Vector2((col + 0.5) * cell_size, (row + 0.5) * cell_size)


func pick_saboteur_link(e: Dictionary) -> String:
	var cell := enemy_cell(e)
	var best_id := ""
	var best_score := -999.0
	for id in links:
		var L: Dictionary = links[id]
		var pa := node_pos(L.a)
		var pb := node_pos(L.b)
		var mid := Vector2i(int(round((pa.x + pb.x) / 2.0)), int(round((pa.y + pb.y) / 2.0)))
		var dist := GameData.chebyshev(cell, mid)
		if dist > 2:
			continue
		var score := 40.0 if L.wireless else 20.0
		score += randf() * 10.0
		if score > best_score:
			best_score = score
			best_id = id
	return best_id


func cut_link(id: String) -> bool:
	if not links.has(id):
		return false
	var L: Dictionary = links[id]
	if L.fortified:
		L.fortified = false
		emit_log("Fortify blocked cut on %s" % id, "warn")
		emit_toast("Fortify held!")
		emit_juice("fortify", {"a": L.a, "b": L.b})
		return false
	links.erase(id)
	emit_log("Saboteur severed %s %s" % ["wireless" if L.wireless else "powerline", id], "bad")
	emit_toast("Powerline cut!")
	emit_juice("cut", {"a": L.a, "b": L.b, "wireless": L.wireless})
	state_changed.emit()
	return true


func end_wave() -> void:
	var load := compute_load(true)
	var pct: float = (float(load.draw) / float(load.max)) * 100.0 if int(load.max) > 0 else 0.0
	if pct < 60.0:
		heat = maxi(0, heat - 2)
	elif pct < 80.0:
		heat += 1
	elif pct < 100.0:
		heat += 3
	else:
		heat += 5
	if heat >= 10:
		var wear := int(heat / 2.0)
		max_power = maxi(40, max_power - wear)
		heat = maxi(0, heat - 4)
		emit_log("Core stress: −%d max power (click Core to repair)" % wear, "warn")
	var bonus := 15 if wave_leak == 0 else 8
	scrap += bonus
	emit_log("Wave %d clear · +%d scrap · load %d%% · HP %d/%d" % [
		wave_index, bonus, int(round(pct)), integrity, GameData.MAX_INTEGRITY
	], "good")
	wave_index += 1
	phase = Phase.BUILD
	enemies.clear()
	spike_on = false
	for t in towers.values():
		t.fired_recently = false
	if wave_index >= GameData.WAVES.size():
		phase = Phase.WON
		emit_juice("win")
		match_over.emit(true, "Cleared all waves with %d/%d Base HP." % [integrity, GameData.MAX_INTEGRITY])
	else:
		emit_toast("Build · HP %d/%d" % [integrity, GameData.MAX_INTEGRITY])
	state_changed.emit()


func do_burst(cell_size: float) -> void:
	if phase != Phase.COMBAT:
		emit_toast("Burst during combat")
		return
	if burst_used:
		emit_toast("Burst used")
		return
	var powered := powered_nodes()
	var caps: Array = []
	for k in towers:
		var t: Dictionary = towers[k]
		if t.type == "capacitor" and powered.has(k):
			caps.append({"k": k, "pos": GameData.parse_key(k), "t": t})
	if caps.is_empty():
		emit_toast("Need powered Capacitor")
		return
	var best: Dictionary = {}
	var best_hp := INF
	for e in enemies:
		if not e.alive:
			continue
		var cell := enemy_cell(e)
		for cap in caps:
			if GameData.chebyshev(cap.pos, cell) <= int(tower_stat("capacitor", "range")):
				if e.hp < best_hp:
					best_hp = e.hp
					best = e
	if best.is_empty():
		emit_toast("No target in range")
		return
	burst_used = true
	var cap0: Dictionary = caps[0]
	var to_w := enemy_world_pos(best, cell_size)
	damage_enemy(best, tower_stat("capacitor", "burst_damage"), {
		"pos": cap0.pos,
		"to_world": to_w,
		"color": GameData.TOWER_DEFS.capacitor.color,
		"name": "Ca BURST",
		"tower": cap0.t,
		"pierce": tower_stat("capacitor", "armor_pierce"),
	})
	emit_log("Capacitor BURST!", "warn")
	emit_toast("BURST!")
	emit_juice("burst", {"pos": to_w, "from": cap0.pos})
	if best.hp <= 0.0:
		kill_enemy(best)
	state_changed.emit()


func toggle_spike() -> void:
	var has := false
	for t in towers.values():
		if t.type == "drainer":
			has = true
			break
	if not has:
		emit_toast("Need a Drainer")
		return
	spike_on = not spike_on
	emit_toast("SPIKE ON" if spike_on else "Spike off")
	emit_juice("spike_on" if spike_on else "spike_off")
	state_changed.emit()


func arm_fortify() -> void:
	var regs := 0
	for t in towers.values():
		if t.type == "regulator":
			regs += 1
	if regs == 0:
		emit_toast("Need a Regulator for Fortify")
		return
	if phase == Phase.BUILD:
		fortify_charges = maxi(fortify_charges, 2)
	if fortify_charges <= 0:
		emit_toast("No charges")
		return
	fortify_armed = not fortify_armed
	sell_mode = false
	link_from = ""
	emit_toast("Click a linked tower to fortify" if fortify_armed else "Fortify off")
	state_changed.emit()


func repair_core_click() -> void:
	if phase != Phase.BUILD:
		return
	if max_power >= 100:
		emit_toast("Core healthy")
		return
	if scrap < 3:
		emit_toast("Need scrap to repair")
		return
	var room := 100 - max_power
	var can := mini(room, mini(5, int(scrap / 3.0)))
	scrap -= can * 3
	max_power += can
	emit_log("Repaired +%d max power" % can, "good")
	emit_toast("Repaired +%d" % can)
	state_changed.emit()


func tick(delta: float, cell_size: float) -> void:
	# FX decay + tower flash decay
	var keep_fx: Array = []
	for f in fx:
		f.life -= delta
		if f.life > 0.0:
			keep_fx.append(f)
	fx = keep_fx
	for t in towers.values():
		if t.has("place_flash") and float(t.place_flash) > 0.0:
			t.place_flash = maxf(0.0, float(t.place_flash) - delta)
		if t.has("muzzle") and float(t.muzzle) > 0.0:
			t.muzzle = maxf(0.0, float(t.muzzle) - delta)

	if phase != Phase.COMBAT:
		return
	var dt := delta * sim_speed
	var powered := powered_nodes()

	if not spawn_queue.is_empty():
		spawn_timer -= dt
		if spawn_timer <= 0.0:
			spawn_enemy(str(spawn_queue.pop_front()))
			spawn_timer = GameData.SPAWN_INTERVAL

	for e in enemies:
		if not e.alive:
			continue
		var def: Dictionary = GameData.ENEMY_DEFS[e.type]
		var is_sab: bool = def.get("saboteur", false)

		if is_sab and e.channeling:
			e.channel_time -= dt
			if e.channel_dmg >= 20.0:
				e.channeling = false
				e.channel_target = ""
				e.channel_dmg = 0.0
				emit_log("Saboteur channel interrupted!", "good")
				emit_toast("Channel broken")
				emit_juice("channel_break", {"pos": enemy_world_pos(e, cell_size)})
			elif e.channel_time <= 0.0:
				cut_link(e.channel_target)
				e.channeling = false
				e.channel_target = ""
				e.channel_dmg = 0.0
				e.cuts_done += 1
				if e.cuts_done == 1 and randf() < 0.4:
					e.wants_second_cut = true
			continue

		e.progress += GameData.ENEMY_MOVE_SPEED * float(def.speed) * dt
		while e.progress >= 1.0 and e.alive:
			e.progress -= 1.0
			e.path_index += 1
			if e.path_index >= GameData.PATH.size():
				e.alive = false
				integrity -= int(def.leak)
				wave_leak += int(def.leak)
				emit_log("%s reached base (−%d) → %d/%d" % [
					def.name, def.leak, integrity, GameData.MAX_INTEGRITY
				], "bad")
				emit_toast("Base hit! %d/%d" % [integrity, GameData.MAX_INTEGRITY])
				emit_juice("leak", {"amount": def.leak})
				if integrity <= 0:
					integrity = 0
					phase = Phase.LOST
					emit_juice("lose")
					match_over.emit(false, "Base integrity collapsed.")
					state_changed.emit()
					return
				break
			if is_sab and e.path_index < GameData.PATH.size() - 1 and (e.cuts_done == 0 or e.wants_second_cut):
				var tgt := pick_saboteur_link(e)
				if not tgt.is_empty():
					e.channeling = true
					e.channel_time = 1.5
					e.channel_target = tgt
					e.channel_dmg = 0.0
					e.wants_second_cut = false
					emit_log("Saboteur channeling on link", "warn")
					emit_toast("Saboteur cutting a powerline!")
					emit_juice("channel", {"pos": enemy_world_pos(e, cell_size)})
					break

	# Towers fire on their own cooldowns, after movement so they shoot current positions.
	fire_towers(dt, powered, cell_size)

	enemies = enemies.filter(func(e): return e.alive)
	if spawn_queue.is_empty() and enemies.is_empty():
		end_wave()
	else:
		state_changed.emit()
