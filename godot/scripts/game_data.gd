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

## Saboteur cut behaviour.
## The saboteur must commit: it crawls while hunting and stands still while cutting, which
## is the player's tell. Long channel + slow approach = plenty of warning, but it also means
## far more time under fire, so SABOTEUR hp is tuned against this (see ENEMY_DEFS).
const SABOTEUR_CHANNEL_TIME := 3.5
## Damage on a channeling saboteur needed to break the cut.
const SABOTEUR_INTERRUPT_DAMAGE := 32.0
## hack_resist tiers the upgrade system will sell, as mid- and high-tier tower addons.
## Index = purchased level: 0 none, 1 halves a Hacker's disable, 2 makes it immune.
## Nothing sets these yet — every tower ships at 0.0 until the upgrade tree exists.
const HACK_RESIST_TIERS: Array[float] = [0.0, 0.5, 1.0]

## Speed multiplier applied while a saboteur is hunting a link to cut.
const SABOTEUR_HUNT_SLOWDOWN := 0.35
## The saboteur NOTICES a link from further away than it can cut it. The gap between these
## two radii is the approach phase — the visible crawl that warns the player. If they were
## equal the saboteur would commit the instant it saw a target and there would be no tell.
const SABOTEUR_HUNT_RADIUS := 4
const SABOTEUR_CUT_RADIUS := 2

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

## Numeric tower stats that the (future) upgrade system is allowed to modify.
## Anything not in this list is identity/presentation and must not be scaled.
## See GameState.tower_stats() — that is the single hook progression plugs into.
const TOWER_STAT_KEYS: Array[String] = [
	"damage", "fire_rate", "range", "armor_pierce",
	"draw_idle", "draw_fire", "burst_damage", "spike_damage", "spike_draw",
	"hack_resist",
]

# Colors as RGB so this stays friendly across Godot 4.x
#
# Stat block, per tower:
#   damage       — per shot, before enemy armor
#   fire_rate    — shots per second (cooldown = 1.0 / fire_rate)
#   range        — Chebyshev cells
#   armor_pierce — subtracted from the target's armor before it reduces damage
#   draw_idle    — power drawn while powered but not firing
#   draw_fire    — power drawn while actively engaging
#   hack_resist  — 0..1, fraction of a Hacker's disable duration ignored. 0 on every tower
#                  today; this is the hook the upgrade system sells "countermeasures" against.
#
# DPS is damage * fire_rate. Because enemies are only in range for a fixed time,
# effective damage also scales with range (more covered path cells) and inversely
# with enemy speed. See docs/ARCHITECTURE.md#combat.
static var TOWER_DEFS: Dictionary = {
	"capacitor": {
		"name": "Capacitor", "short": "Ca", "cost": 35,
		"damage": 6, "fire_rate": 0.85, "range": 2, "armor_pierce": 2,
		"draw_idle": 3, "draw_fire": 6, "hack_resist": 0.0,
		"burst_damage": 22,
		"color": Color(0.38, 0.686, 0.937),
		"role": "Baseline single-target. Burst (B) once/wave.",
	},
	"transformer": {
		"name": "Transformer", "short": "Tf", "cost": 28,
		"damage": 4, "fire_rate": 0.8, "range": 2, "armor_pierce": 1,
		"draw_idle": 4, "draw_fire": 4, "hack_resist": 0.0,
		"color": Color(0.776, 0.471, 0.867),
		"role": "Low damage; network control later.",
	},
	"regulator": {
		"name": "Regulator", "short": "Rg", "cost": 32,
		"damage": 3, "fire_rate": 0.85, "range": 2, "armor_pierce": 0,
		"draw_idle": 5, "draw_fire": 5, "hack_resist": 0.0,
		"color": Color(0.596, 0.765, 0.475),
		"role": "Enables Fortify (F) on power links.",
	},
	"drainer": {
		"name": "Drainer", "short": "Dr", "cost": 40,
		"damage": 9, "fire_rate": 0.75, "range": 3, "armor_pierce": 5,
		"draw_idle": 8, "draw_fire": 10, "hack_resist": 0.0,
		"spike_damage": 17, "spike_draw": 18,
		"color": Color(0.878, 0.424, 0.459),
		"role": "Highest DPS, best vs armor. Spike (V) = more dmg + load.",
	},
}

static var ENEMY_DEFS: Dictionary = {
	"grunt": {"name": "Grunt", "hp": 72, "speed": 1.0, "leak": 1, "scrap": 4, "color": Color(0.898, 0.753, 0.482), "r": 9.0},
	"mite": {"name": "Mite", "hp": 38, "speed": 1.1, "leak": 1, "scrap": 3, "color": Color(0.596, 0.765, 0.475), "r": 7.0},
	"brute": {"name": "Brute", "hp": 130, "speed": 0.85, "leak": 2, "scrap": 7, "color": Color(0.745, 0.314, 0.275), "r": 12.0, "armor": 5},
	"runner": {"name": "Runner", "hp": 48, "speed": 2.15, "leak": 1, "scrap": 5, "color": Color(0.337, 0.714, 0.761), "r": 8.0},
	# Saboteur crawls (0.55) and crawls harder while hunting, so it is easy to spot and eats a
	# lot of fire. HP is raised to match: under the fire-rate model, time in range IS damage.
	"saboteur": {"name": "Saboteur", "hp": 120, "speed": 0.55, "leak": 2, "scrap": 14, "color": Color(1.0, 0.42, 0.29), "r": 10.0, "saboteur": true},
	# Hacker does not cut. It pulses, temporarily disabling wireless links and towers in
	# radius. Nothing it does is permanent — the grid comes back on its own.
	"hacker": {
		"name": "Hacker", "hp": 150, "speed": 0.8, "leak": 2, "scrap": 16,
		"color": Color(0.65, 0.42, 0.95), "r": 11.0, "hacker": true,
		"hack_radius": 2, "hack_duration": 2.5, "hack_interval": 6.0, "hack_windup": 1.4,
	},
}

## Hacker is a late-campaign unit: it debuts ALONE in wave 7 so the pulse mechanic can be
## learned in isolation, then pairs with Saboteurs in wave 8 as the finale spike. Waves 0-6
## teach lane pressure and sabotage only.
const WAVES: Array = [
	["grunt", "grunt", "grunt"],
	["grunt", "grunt", "grunt", "mite", "grunt"],
	["grunt", "grunt", "saboteur", "grunt", "grunt", "mite"],
	["brute", "grunt", "grunt", "brute", "mite", "grunt"],
	["grunt", "runner", "saboteur", "runner", "grunt", "grunt", "mite"],
	["mite", "brute", "saboteur", "brute", "grunt", "mite"],
	["runner", "runner", "runner", "grunt", "saboteur", "runner", "grunt"],
	["brute", "hacker", "runner", "grunt", "brute", "grunt"],
	["saboteur", "grunt", "hacker", "saboteur", "runner", "brute", "grunt", "runner", "mite"],
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
