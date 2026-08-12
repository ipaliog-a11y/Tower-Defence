class_name GameData
extends RefCounted
## Static balance + Spine map data (ported from browser mockup).

const SIZE := 10
const CORE := Vector2i(0, 2)
const MAX_INTEGRITY := 10
const START_SCRAP := 140
const PRESET_LEFTOVER := 75
const TOWER_CAP := 12

const ENEMY_MOVE_SPEED := 0.62
const SPAWN_INTERVAL := 0.55

const LINK_RANGE := 2
const WIRELESS_RANGE := 4
const WIRELESS_MAX := 4
const LINK_COST := 10
const WIRELESS_COST := 22
const LINK_DRAW := 1
const WIRELESS_DRAW := 3

## Winding path around central factory + rocks (~27 steps).
const PATH: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3),
	Vector2i(1, 4), Vector2i(1, 5), Vector2i(1, 6), Vector2i(1, 7),
	Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7), Vector2i(6, 7),
	Vector2i(6, 6), Vector2i(6, 5), Vector2i(6, 4), Vector2i(6, 3), Vector2i(6, 2),
	Vector2i(7, 2), Vector2i(8, 2), Vector2i(8, 3), Vector2i(8, 4),
	Vector2i(8, 5), Vector2i(8, 6), Vector2i(8, 7), Vector2i(8, 8), Vector2i(8, 9),
]

const BLOCKED: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(0, 9), Vector2i(9, 0), Vector2i(9, 9),
	Vector2i(3, 3), Vector2i(3, 4), Vector2i(3, 5),
	Vector2i(4, 3), Vector2i(4, 4), Vector2i(4, 5),
	Vector2i(5, 3), Vector2i(5, 4), Vector2i(5, 5),
	Vector2i(7, 0), Vector2i(7, 1),
	Vector2i(8, 0), Vector2i(8, 1),
	Vector2i(9, 1), Vector2i(9, 2),
	Vector2i(0, 6), Vector2i(0, 7), Vector2i(0, 8),
	Vector2i(2, 8), Vector2i(2, 9),
]

# Colors as RGB so this stays friendly across Godot 4.2–4.3
static var TOWER_DEFS: Dictionary = {
	"capacitor": {
		"name": "Capacitor", "short": "Ca", "cost": 35,
		"draw_idle": 3, "draw_fire": 6, "range": 2, "dmg": 8, "burst": 22,
		"color": Color(0.38, 0.686, 0.937),
		"role": "Baseline single-target. Burst (B) once/wave.",
	},
	"transformer": {
		"name": "Transformer", "short": "Tf", "cost": 28,
		"draw_idle": 4, "draw_fire": 4, "range": 2, "dmg": 5,
		"color": Color(0.776, 0.471, 0.867),
		"role": "Low damage; network control later.",
	},
	"regulator": {
		"name": "Regulator", "short": "Rg", "cost": 32,
		"draw_idle": 5, "draw_fire": 5, "range": 2, "dmg": 4,
		"color": Color(0.596, 0.765, 0.475),
		"role": "Enables Fortify (F) on power links.",
	},
	"drainer": {
		"name": "Drainer", "short": "Dr", "cost": 40,
		"draw_idle": 8, "draw_fire": 10, "range": 3, "dmg": 11,
		"spike_dmg": 20, "spike_draw": 18,
		"color": Color(0.878, 0.424, 0.459),
		"role": "Highest DPS. Spike (V) = more dmg + load.",
	},
}

static var ENEMY_DEFS: Dictionary = {
	"grunt": {"name": "Grunt", "hp": 72, "speed": 1.0, "leak": 1, "scrap": 4, "color": Color(0.898, 0.753, 0.482), "r": 9.0},
	"mite": {"name": "Mite", "hp": 38, "speed": 1.1, "leak": 1, "scrap": 3, "color": Color(0.596, 0.765, 0.475), "r": 7.0},
	"brute": {"name": "Brute", "hp": 130, "speed": 0.85, "leak": 2, "scrap": 7, "color": Color(0.745, 0.314, 0.275), "r": 12.0, "armor": 5},
	"runner": {"name": "Runner", "hp": 48, "speed": 2.15, "leak": 1, "scrap": 5, "color": Color(0.337, 0.714, 0.761), "r": 8.0},
	"saboteur": {"name": "Saboteur", "hp": 95, "speed": 1.0, "leak": 2, "scrap": 10, "color": Color(1.0, 0.42, 0.29), "r": 10.0, "saboteur": true},
}

const WAVES: Array = [
	["grunt", "grunt", "grunt"],
	["grunt", "grunt", "grunt", "mite", "grunt"],
	["grunt", "grunt", "saboteur", "grunt", "grunt", "mite"],
	["brute", "grunt", "grunt", "brute", "mite", "grunt"],
	["grunt", "runner", "saboteur", "runner", "grunt", "grunt", "mite"],
	["mite", "brute", "saboteur", "brute", "grunt", "mite"],
	["runner", "runner", "runner", "grunt", "saboteur", "runner", "grunt"],
	["brute", "brute", "runner", "grunt", "brute", "runner", "grunt"],
	["saboteur", "grunt", "brute", "saboteur", "runner", "brute", "grunt", "runner", "mite"],
]


static func path_set() -> Dictionary:
	var s := {}
	for p in PATH:
		s[p] = true
	return s


static func blocked_set() -> Dictionary:
	var s := {}
	for p in BLOCKED:
		s[p] = true
	return s


static func cell_key(v: Vector2i) -> String:
	return "%d,%d" % [v.x, v.y]


static func parse_key(k: String) -> Vector2i:
	var parts := k.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


static func chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


static func neighbors4(v: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var n: Vector2i = v + d
		if n.x >= 0 and n.x < SIZE and n.y >= 0 and n.y < SIZE:
			out.append(n)
	return out
