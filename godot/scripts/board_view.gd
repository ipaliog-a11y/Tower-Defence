class_name BoardView
extends Control
## Draws the 10×10 grid and handles board clicks.

signal cell_clicked(cell: Vector2i)

var state: GameState
var cell_size: float = 56.0
var hover: Vector2i = Vector2i(-1, -1)


func setup(game_state: GameState) -> void:
	state = game_state
	state.state_changed.connect(queue_redraw)
	custom_minimum_size = Vector2(GameData.SIZE * cell_size, GameData.SIZE * cell_size)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var c := _pos_to_cell(event.position)
		if c != hover:
			hover = c
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := _pos_to_cell(event.position)
		if _in_bounds(c):
			cell_clicked.emit(c)


func _pos_to_cell(pos: Vector2) -> Vector2i:
	# cell: x=row, y=col — screen x = col, screen y = row
	var col := int(pos.x / cell_size)
	var row := int(pos.y / cell_size)
	return Vector2i(row, col)


func _in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < GameData.SIZE and c.y >= 0 and c.y < GameData.SIZE


func cell_center(cell: Vector2i) -> Vector2:
	return Vector2((cell.y + 0.5) * cell_size, (cell.x + 0.5) * cell_size)


func _draw() -> void:
	if state == null:
		return
	var powered: Dictionary = state.powered_nodes()
	var s := cell_size
	var tsec := Time.get_ticks_msec() / 1000.0

	# Screen tint (under everything)
	for f in state.fx:
		if f.kind == "screen_tint":
			var a: float = (f.life / f.max) * 0.28
			draw_rect(Rect2(Vector2.ZERO, size), Color(f.color, a))

	for r in GameData.SIZE:
		for c in GameData.SIZE:
			var cell := Vector2i(r, c)
			var rect := Rect2(c * s + 1, r * s + 1, s - 2, s - 2)
			var fill := Color("2a303c")
			if state.blocked_lookup.has(cell):
				fill = Color("14161b")
			if state.path_lookup.has(cell):
				# subtle pulse on path during combat
				var pulse := 0.0
				if state.phase == GameState.Phase.COMBAT:
					pulse = 0.04 * (0.5 + 0.5 * sin(tsec * 3.0 + float(c) * 0.4))
				fill = Color(0.24 + pulse, 0.27 + pulse, 0.33 + pulse)
			if cell == GameData.CORE:
				fill = Color("1e3a4a")
			var last: Vector2i = GameData.PATH[GameData.PATH.size() - 1]
			if cell == last:
				fill = Color("4a3060")
			# cell flash FX
			for f in state.fx:
				if f.kind == "flash_cell" and f.cell == cell:
					var fa: float = f.life / f.max
					fill = fill.lerp(f.color, fa * 0.65)
			draw_rect(rect, fill)
			draw_rect(rect, Color(0, 0, 0, 0.3), false, 1.0)

	# Path labels
	for i in GameData.PATH.size():
		var p: Vector2i = GameData.PATH[i]
		var label := "·"
		if i == 0:
			label = "P"
		elif i == GameData.PATH.size() - 1:
			label = "B"
		else:
			var prev: Vector2i = GameData.PATH[i - 1]
			var dr := p.x - prev.x
			var dc := p.y - prev.y
			if dc == 1:
				label = ">"
			elif dc == -1:
				label = "<"
			elif dr == 1:
				label = "v"
			elif dr == -1:
				label = "^"
		var pos := cell_center(p)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-6, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.35))

	# Base HP under B
	var bcell: Vector2i = GameData.PATH[GameData.PATH.size() - 1]
	var bpos := cell_center(bcell)
	draw_string(
		ThemeDB.fallback_font,
		bpos + Vector2(-16, s * 0.28),
		"%d/%d" % [state.integrity, GameData.MAX_INTEGRITY],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("e0b3f0")
	)

	# Links + energy flow dots
	for L in state.links.values():
		var pa := state.node_pos(L.a)
		var pb := state.node_pos(L.b)
		var hacked: bool = state.link_disabled(L)
		var live: bool = powered.has(L.a) and powered.has(L.b) and not hacked
		var energized: bool = (powered.has(L.a) or powered.has(L.b)) and not hacked
		var col: Color
		if hacked:
			# Suppressed by a Hacker pulse — present but carrying nothing.
			col = Color("a06cf0", 0.35 + 0.25 * sin(tsec * 14.0))
		elif L.wireless:
			col = Color("50dcff", 0.9 if energized else 0.25)
		else:
			col = Color("d19a66", 0.95 if energized else 0.3)
		var from := cell_center(pa)
		var to := cell_center(pb)
		if L.wireless:
			_draw_dashed_line(from, to, col, 3.0)
		else:
			draw_line(from, to, col, 2.5, true)
		if L.fortified:
			_draw_dashed_line(from, to, Color("61afef"), 2.0)
		# flowing power packet
		if live:
			var u := fposmod(tsec * (1.4 if L.wireless else 1.0), 1.0)
			var pkt := from.lerp(to, u)
			draw_circle(pkt, 3.5 if L.wireless else 3.0, Color(col, 0.95))

	# Link pulse FX (cut / fortify / new link)
	for f in state.fx:
		if f.kind == "link_pulse":
			var a: float = f.life / f.max
			var fa := cell_center(state.node_pos(str(f.a)))
			var fb := cell_center(state.node_pos(str(f.b)))
			var w := 2.0 + 6.0 * a
			if f.get("wireless", false):
				_draw_dashed_line(fa, fb, Color(f.color, a), w)
			else:
				draw_line(fa, fb, Color(f.color, a), w, true)

	# Pending link ghost
	if not state.link_from.is_empty() and _in_bounds(hover):
		var from2 := cell_center(state.node_pos(state.link_from))
		var to2 := cell_center(hover)
		var gcol := Color("50dcff", 0.5) if state.tool == "wireless" else Color("d19a66", 0.5)
		_draw_dashed_line(from2, to2, gcol, 2.0)

	# Core (soft glow)
	var core_c := cell_center(GameData.CORE)
	var glow := 0.5 + 0.5 * sin(tsec * 2.5)
	draw_circle(core_c, s * 0.34, Color(0.38, 0.686, 0.937, 0.12 + 0.1 * glow))
	draw_circle(core_c, s * 0.28, Color("61afef"))
	draw_string(ThemeDB.fallback_font, core_c + Vector2(-5, 5), "C", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("0d1117"))

	# Towers
	for k in state.towers:
		var tdict: Dictionary = state.towers[k]
		var cell := GameData.parse_key(k)
		var center := cell_center(cell)
		var hacked: bool = state.tower_disabled(tdict)
		var on: bool = powered.has(k) and not hacked
		var def: Dictionary = GameData.TOWER_DEFS[tdict.type]
		var hs := s * 0.3
		var rect := Rect2(center.x - hs, center.y - hs, hs * 2, hs * 2)
		var col: Color = def.color
		if not on:
			# flicker when dark
			var flick := 0.28 + 0.08 * sin(tsec * 9.0 + float(cell.x))
			col = Color(col, flick)
		draw_rect(rect, col)
		# place pop
		if tdict.get("place_flash", 0.0) > 0.0:
			var pf: float = float(tdict.place_flash) / 0.35
			draw_rect(rect.grow(4.0 * pf), Color(1, 1, 1, 0.55 * pf), false, 2.0)
		# muzzle
		if tdict.get("muzzle", 0.0) > 0.0:
			var mf: float = float(tdict.muzzle) / 0.12
			draw_rect(rect.grow(2.0), Color(1, 1, 1, 0.7 * mf), false, 2.0 + 2.0 * mf)
		if state.link_from == k:
			draw_rect(rect.grow(3), Color("50dcff"), false, 2.0)
		if tdict.type == "drainer" and state.spike_on:
			var sp := 0.6 + 0.4 * sin(tsec * 8.0)
			draw_rect(rect, Color(1.0, 0.54, 0.48, sp), false, 2.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(-8, 4), def.short, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("0d1117"))
		var dmg_show: int = int(def.spike_damage) if (tdict.type == "drainer" and state.spike_on) else int(def.damage)
		draw_string(ThemeDB.fallback_font, center + Vector2(-8, hs + 10), str(dmg_show), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.7 if on else 0.35))
		if not on:
			draw_rect(rect, Color(0, 0, 0, 0.4))
			# Distinguish "no power" from "temporarily hacked" — different problems.
			if hacked:
				draw_string(ThemeDB.fallback_font, center + Vector2(-14, 4), "HACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("c39bff"))
				draw_rect(rect.grow(3), Color("a06cf0", 0.5 + 0.4 * sin(tsec * 12.0)), false, 2.0)
			else:
				draw_string(ThemeDB.fallback_font, center + Vector2(-10, 4), "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("e06c75"))

	# Enemies
	for e in state.enemies:
		if not e.alive:
			continue
		var def2: Dictionary = GameData.ENEMY_DEFS[e.type]
		var pos := state.enemy_world_pos(e, s)
		# soft shadow
		draw_circle(pos + Vector2(1, 2), float(def2.r) + 1.0, Color(0, 0, 0, 0.25))
		draw_circle(pos, float(def2.r), def2.color)
		if e.channeling:
			var ch: float = maxf(0.0, e.channel_time / GameData.SABOTEUR_CHANNEL_TIME)
			draw_arc(pos, float(def2.r) + 5.0, 0.0, TAU * ch, 28, Color(1, 1, 1, 0.9), 2.5)
			draw_arc(pos, float(def2.r) + 9.0, 0.0, TAU, 28, Color(1.0, 0.42, 0.29, 0.25 + 0.2 * sin(tsec * 12.0)), 1.5)
		elif e.get("hunting", false):
			# Crawling toward a link it wants to cut — this is the "shoot me now" tell.
			draw_arc(pos, float(def2.r) + 6.0, 0.0, TAU, 24, Color(1.0, 0.42, 0.29, 0.35 + 0.3 * sin(tsec * 6.0)), 2.0)
			draw_string(ThemeDB.fallback_font, pos + Vector2(-20, float(def2.r) + 16.0), "HUNTING", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("ff6b4a"))
		if float(e.get("hack_winding", 0.0)) > 0.0:
			var def_hw: float = float(GameData.ENEMY_DEFS[e.type].get("hack_windup", 1.4))
			var wu: float = 1.0 - clampf(float(e.hack_winding) / maxf(def_hw, 0.01), 0.0, 1.0)
			draw_arc(pos, float(def2.r) + 6.0 + 10.0 * wu, 0.0, TAU, 32, Color(0.65, 0.42, 0.95, 0.9 - 0.5 * wu), 2.5)
			draw_string(ThemeDB.fallback_font, pos + Vector2(-18, float(def2.r) + 16.0), "PULSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("c39bff"))
		draw_string(ThemeDB.fallback_font, pos + Vector2(-16, -float(def2.r) - 10), def2.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
		var bw := 26.0
		var bar_y := pos.y - float(def2.r) - 6.0
		draw_rect(Rect2(pos.x - bw / 2, bar_y, bw, 4), Color.BLACK)
		var ratio: float = clampf(e.hp / e.max_hp, 0.0, 1.0)
		draw_rect(Rect2(pos.x - bw / 2, bar_y, bw * ratio, 4), Color("98c379") if ratio > 0.4 else Color("e06c75"))

	# Combat / build FX overlay
	for f in state.fx:
		var life_a: float = f.life / f.max
		match f.kind:
			"beam":
				var from3 := cell_center(f.from)
				draw_line(from3, f.to, Color(f.color, life_a), 2.0 + 3.0 * life_a, true)
				draw_circle(from3, 3.0 * life_a + 1.0, Color(f.color, life_a))
			"impact":
				draw_circle(f.pos, 4.0 + 8.0 * (1.0 - life_a), Color(f.color, life_a * 0.7))
				draw_circle(f.pos, 2.0 + 3.0 * life_a, Color(1, 1, 1, life_a))
			"float":
				var lift: float = (1.0 - life_a) * (absf(float(f.get("vy", -28.0))) * 0.35)
				draw_string(
					ThemeDB.fallback_font,
					f.pos + Vector2(0, -lift),
					f.text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(f.color, life_a)
				)
			"ring":
				var rc := cell_center(f.cell)
				var rr := (0.2 + (1.0 - life_a) * 0.9) * s
				draw_arc(rc, rr, 0, TAU, 32, Color(f.color, life_a * 0.85), 2.0)
			"ring_world":
				var rr2 := 6.0 + (1.0 - life_a) * 28.0
				draw_arc(f.pos, rr2, 0, TAU, 32, Color(f.color, life_a * 0.85), 2.0)
			"sparks":
				var mid := cell_center(f.cell_a).lerp(cell_center(f.cell_b), 0.5)
				_draw_sparks(mid, f.color, life_a, int(f.get("count", 10)))
			"sparks_world":
				_draw_sparks(f.pos, f.color, life_a, int(f.get("count", 10)))

	# Hover
	if _in_bounds(hover):
		var hr := Rect2(hover.y * s + 2, hover.x * s + 2, s - 4, s - 4)
		draw_rect(hr, Color("5ec8c0", 0.8), false, 2.0)
		if state.phase == GameState.Phase.BUILD and GameData.TOWER_DEFS.has(state.tool):
			var st: Dictionary = GameData.TOWER_DEFS[state.tool]
			draw_arc(cell_center(hover), float(st.range) * s, 0, TAU, 48, Color("5ec8c0", 0.22), 1.5)

	var phase_name := "BUILD"
	match state.phase:
		GameState.Phase.COMBAT:
			phase_name = "COMBAT"
		GameState.Phase.WON:
			phase_name = "WON"
		GameState.Phase.LOST:
			phase_name = "LOST"
	draw_string(
		ThemeDB.fallback_font,
		Vector2(8, 14),
		"%dx%d · %s" % [GameData.SIZE, GameData.SIZE, phase_name],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.4)
	)


func _draw_sparks(origin: Vector2, color: Color, life_a: float, count: int) -> void:
	for i in count:
		var ang := float(i) / float(maxi(count, 1)) * TAU + life_a * 2.0
		var dist := (1.0 - life_a) * (10.0 + float(i % 4) * 3.0)
		var p := origin + Vector2(cos(ang), sin(ang)) * dist
		draw_circle(p, 1.5 + life_a, Color(color, life_a))


func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var delta := to - from
	var length := delta.length()
	if length < 1.0:
		return
	var dir := delta / length
	var dash := 7.0
	var gap := 5.0
	var t := 0.0
	while t < length:
		var a := from + dir * t
		var b := from + dir * minf(t + dash, length)
		draw_line(a, b, color, width, true)
		t += dash + gap
