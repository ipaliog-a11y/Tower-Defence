extends Control
## Main shell: board + HUD + legend + tools.

const SfxPlayerScript = preload("res://scripts/sfx_player.gd")

var state: GameState
var board: BoardView
var sfx: Node

@onready var board_host: CenterContainer = %BoardHost
@onready var scrap_label: Label = %ScrapLabel
@onready var load_label: Label = %LoadLabel
@onready var heat_label: Label = %HeatLabel
@onready var hp_label: Label = %HpLabel
@onready var wave_label: Label = %WaveLabel
@onready var hp_bar: ProgressBar = %HpBar
@onready var wave_preview: Label = %WavePreview
@onready var action_status: Label = %ActionStatus
@onready var log_box: RichTextLabel = %LogBox
@onready var toast_label: Label = %ToastLabel
@onready var tower_legend: VBoxContainer = %TowerLegend
@onready var board_legend: RichTextLabel = %BoardLegend
@onready var tool_box: HFlowContainer = %ToolBox
@onready var overlay: ColorRect = %Overlay
@onready var overlay_title: Label = %OverlayTitle
@onready var overlay_body: Label = %OverlayBody

var toast_tween: Tween
var _prev_integrity: int = GameData.MAX_INTEGRITY
var _prev_scrap: int = 0
var _hp_punch: float = 0.0
var _scrap_punch: float = 0.0


func _ready() -> void:
	state = GameState.new()
	state.log_line.connect(_on_log)
	state.toast.connect(_on_toast)
	state.state_changed.connect(_refresh_hud)
	state.match_over.connect(_on_match_over)
	state.juice.connect(_on_juice)

	sfx = SfxPlayerScript.new()
	sfx.name = "SfxPlayer"
	add_child(sfx)

	board = BoardView.new()
	board.name = "BoardView"
	board.setup(state)
	board.cell_clicked.connect(_on_cell_clicked)
	board_host.add_child(board)

	_build_tools()
	_build_tower_legend()
	_build_board_legend()
	state.reset(true)
	_prev_integrity = state.integrity
	_prev_scrap = state.scrap
	_show_overlay(
		"Grid & Decay — Godot slice",
		"10×10 winding path. Powerlines attach to towers. Wireless bridges path gaps. Pick a preset or build free.",
		true
	)
	_refresh_hud()


func _process(delta: float) -> void:
	if state:
		state.tick(delta, board.cell_size)
	# HUD punches decay
	if _hp_punch > 0.0:
		_hp_punch = maxf(0.0, _hp_punch - delta * 2.5)
		hp_label.scale = Vector2.ONE * (1.0 + 0.12 * _hp_punch)
		hp_label.modulate = Color(1, 1, 1).lerp(Color("e06c75"), _hp_punch)
	else:
		hp_label.scale = Vector2.ONE
		hp_label.modulate = Color("e0b3f0")
	if _scrap_punch > 0.0:
		_scrap_punch = maxf(0.0, _scrap_punch - delta * 3.0)
		scrap_label.scale = Vector2.ONE * (1.0 + 0.1 * _scrap_punch)
	else:
		scrap_label.scale = Vector2.ONE


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_wave"):
		state.start_wave()
	elif event.is_action_pressed("tool_1"):
		_set_tool("link")
	elif event.is_action_pressed("tool_2"):
		_set_tool("wireless")
	elif event.is_action_pressed("tool_3"):
		_set_tool("capacitor")
	elif event.is_action_pressed("tool_4"):
		_set_tool("transformer")
	elif event.is_action_pressed("tool_5"):
		_set_tool("regulator")
	elif event.is_action_pressed("tool_6"):
		_set_tool("drainer")
	elif event.is_action_pressed("burst"):
		state.do_burst(board.cell_size)
	elif event.is_action_pressed("spike"):
		state.toggle_spike()
	elif event.is_action_pressed("fortify"):
		state.arm_fortify()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		state.sell_mode = false
		state.fortify_armed = false
		state.link_from = ""
		state.state_changed.emit()


func _set_tool(id: String) -> void:
	state.tool = id
	state.sell_mode = false
	state.fortify_armed = false
	if id != "link" and id != "wireless":
		state.link_from = ""
	if sfx:
		sfx.play_event("ui")
	state.state_changed.emit()
	_highlight_tools()


func _build_tools() -> void:
	var tools := [
		{"id": "link", "label": "Powerline", "cost": GameData.LINK_COST, "key": "1"},
		{"id": "wireless", "label": "Wireless", "cost": GameData.WIRELESS_COST, "key": "2"},
		{"id": "capacitor", "label": "Capacitor", "cost": 35, "key": "3"},
		{"id": "transformer", "label": "Transformer", "cost": 28, "key": "4"},
		{"id": "regulator", "label": "Regulator", "cost": 32, "key": "5"},
		{"id": "drainer", "label": "Drainer", "cost": 40, "key": "6"},
	]
	for t in tools:
		var btn := Button.new()
		btn.text = "%s\n%d scrap · %s" % [t.label, t.cost, t.key]
		btn.custom_minimum_size = Vector2(110, 48)
		btn.toggle_mode = true
		btn.set_meta("tool_id", t.id)
		btn.pressed.connect(_set_tool.bind(t.id))
		tool_box.add_child(btn)
	_highlight_tools()


func _highlight_tools() -> void:
	for child in tool_box.get_children():
		if child is Button:
			child.button_pressed = child.get_meta("tool_id") == state.tool and not state.sell_mode


func _build_tower_legend() -> void:
	for child in tower_legend.get_children():
		child.queue_free()
	for type in GameData.TOWER_DEFS:
		var def: Dictionary = GameData.TOWER_DEFS[type]
		var panel := PanelContainer.new()
		var vb := VBoxContainer.new()
		var title := Label.new()
		title.text = "%s %s  —  %d scrap" % [def.short, def.name, def.cost]
		title.add_theme_color_override("font_color", def.color)
		var stats := Label.new()
		var extra := ""
		if def.has("burst_damage"):
			extra += " · Burst %d" % def.burst_damage
		if def.has("spike_damage"):
			extra += " · Spike %d (draw %d)" % [def.spike_damage, def.spike_draw]
		stats.text = "DMG %d · %.2f/s = %.1f DPS%s\nRange %d · Pierce %d · Draw idle %d / fire %d" % [
			def.damage, def.fire_rate, float(def.damage) * float(def.fire_rate), extra,
			def.range, def.armor_pierce, def.draw_idle, def.draw_fire
		]
		stats.add_theme_font_size_override("font_size", 12)
		stats.add_theme_color_override("font_color", Color("9aa3b5"))
		var role := Label.new()
		role.text = def.role
		role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		role.add_theme_font_size_override("font_size", 12)
		vb.add_child(title)
		vb.add_child(stats)
		vb.add_child(role)
		panel.add_child(vb)
		tower_legend.add_child(panel)


func _build_board_legend() -> void:
	board_legend.clear()
	board_legend.append_text("[b]Path[/b]: %d cells (winding around scenery)\n" % GameData.PATH.size())
	board_legend.append_text("[color=#d19a66][b]Powerline[/b][/color]: range %d · %d scrap · +%d load · land only\n" % [
		GameData.LINK_RANGE, GameData.LINK_COST, GameData.LINK_DRAW
	])
	board_legend.append_text("[color=#50dcff][b]Wireless[/b][/color]: range %d · %d scrap · +%d load · max %d · bridges gaps\n" % [
		GameData.WIRELESS_RANGE, GameData.WIRELESS_COST, GameData.WIRELESS_DRAW, GameData.WIRELESS_MAX
	])
	board_legend.append_text("[b]Core C[/b]: power source · click to repair\n")
	board_legend.append_text("[b]P → B[/b]: enemy lane · no towers\n")
	board_legend.append_text("[b]# dark[/b]: scenery · path routes around\n")
	board_legend.append_text("[b]Saboteur[/b]: cuts links · Fortify (F) blocks one cut")


func _on_cell_clicked(cell: Vector2i) -> void:
	if state.fortify_armed:
		state.fortify_at(cell)
		return
	if state.sell_mode:
		state.sell_tower_at(cell)
		return
	if cell == GameData.CORE and state.tool != "link" and state.tool != "wireless":
		if state.phase == GameState.Phase.BUILD:
			state.repair_core_click()
		return
	if state.tool == "link" or state.tool == "wireless":
		state.handle_link_click(cell, state.tool == "wireless")
		return
	if state.phase != GameState.Phase.BUILD:
		state.emit_toast("Build between waves")
		return
	if GameData.TOWER_DEFS.has(state.tool):
		state.place_tower(cell, state.tool, false)
	_highlight_tools()


func _on_juice(kind: String, _payload: Dictionary) -> void:
	if sfx:
		sfx.play_event(kind)
	# Light board shake on heavy events
	if kind in ["cut", "leak", "burst", "lose"]:
		_shake_board(6.0 if kind != "lose" else 10.0)


func _shake_board(amount: float) -> void:
	if board == null:
		return
	var base := board.position
	var tw := create_tween()
	tw.tween_property(board, "position", base + Vector2(amount, -amount * 0.4), 0.03)
	tw.tween_property(board, "position", base + Vector2(-amount * 0.7, amount * 0.5), 0.04)
	tw.tween_property(board, "position", base, 0.05)


func _refresh_hud() -> void:
	if state == null:
		return
	var load: Dictionary = state.compute_load(state.phase == GameState.Phase.COMBAT)
	if state.integrity < _prev_integrity:
		_hp_punch = 1.0
	if state.scrap > _prev_scrap:
		_scrap_punch = 1.0
	_prev_integrity = state.integrity
	_prev_scrap = state.scrap

	scrap_label.text = str(state.scrap)
	load_label.text = "%d/%d" % [load.draw, load.max]
	heat_label.text = str(state.heat)
	hp_label.text = "%d / %d" % [state.integrity, GameData.MAX_INTEGRITY]
	hp_bar.max_value = GameData.MAX_INTEGRITY
	hp_bar.value = state.integrity
	# Load color feedback
	var pct: float = float(load.draw) / float(maxi(1, int(load.max)))
	if pct >= 1.0:
		load_label.modulate = Color("e06c75")
	elif pct >= 0.8:
		load_label.modulate = Color("e5c07b")
	else:
		load_label.modulate = Color.WHITE
	wave_label.text = str(mini(state.wave_index, GameData.WAVES.size() - 1))

	if state.wave_index >= GameData.WAVES.size():
		wave_preview.text = "Campaign complete"
	else:
		var wave: Array = GameData.WAVES[state.wave_index]
		var counts: Dictionary = {}
		for t in wave:
			counts[t] = int(counts.get(t, 0)) + 1
		var parts: PackedStringArray = []
		for t in counts:
			parts.append("%dx %s" % [counts[t], GameData.ENEMY_DEFS[t].name])
		wave_preview.text = "Next: " + ", ".join(parts)

	action_status.text = "Burst %s · Spike %s · Fortify %d%s" % [
		"used" if state.burst_used else "ready",
		"ON" if state.spike_on else "off",
		state.fortify_charges,
		" · linking from %s" % state.link_from if not state.link_from.is_empty() else "",
	]
	_highlight_tools()


func _on_log(text: String, kind: String) -> void:
	var color := "9aa3b5"
	if kind == "good":
		color = "98c379"
	elif kind == "bad":
		color = "e06c75"
	elif kind == "warn":
		color = "e5c07b"
	log_box.append_text("[color=#%s]%s[/color]\n" % [color, text])


func _on_toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	if toast_tween:
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(1.4)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)


func _on_match_over(won: bool, message: String) -> void:
	_show_overlay("District Held" if won else "Blackout", message, false)


func _show_overlay(title: String, body: String, _show_presets: bool) -> void:
	overlay.visible = true
	overlay_title.text = title
	overlay_body.text = body


func _hide_overlay() -> void:
	overlay.visible = false


func _on_start_wave_pressed() -> void:
	state.start_wave()


func _on_speed_pressed() -> void:
	if state.sim_speed < 1.5:
		state.sim_speed = 2.0
	elif state.sim_speed < 2.5:
		state.sim_speed = 3.0
	else:
		state.sim_speed = 1.0
	%SpeedBtn.text = "×%d" % int(state.sim_speed)


func _on_burst_pressed() -> void:
	state.do_burst(board.cell_size)


func _on_spike_pressed() -> void:
	state.toggle_spike()


func _on_fortify_pressed() -> void:
	state.arm_fortify()


func _on_sell_pressed() -> void:
	state.sell_mode = not state.sell_mode
	state.fortify_armed = false
	state.link_from = ""
	state.emit_toast("Sell: click tower" if state.sell_mode else "Sell off")
	state.state_changed.emit()


func _on_reset_pressed() -> void:
	state.reset(true)
	_hide_overlay()


func _on_north_pressed() -> void:
	state.apply_preset("north")
	_hide_overlay()


func _on_south_pressed() -> void:
	state.apply_preset("south")
	_hide_overlay()


func _on_split_pressed() -> void:
	state.apply_preset("split")
	_hide_overlay()


func _on_empty_pressed() -> void:
	state.reset(true)
	_hide_overlay()
