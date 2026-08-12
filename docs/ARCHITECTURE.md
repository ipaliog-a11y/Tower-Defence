# Architecture

## Runtime flow

```
main.tscn (Control)
  main.gd          — tools, HUD, overlay, juice/SFX hooks
  BoardView        — draw + click → cell
  GameState        — rules
  GameData         — static tables
  SfxPlayer        — procedural WAV beeps
```

1. Player clicks a cell → `main.gd` interprets tool (tower / link / sell / fortify / core repair).
2. `GameState` mutates towers/links/enemies and emits `state_changed`, `toast`, `log_line`, `juice`.
3. `BoardView` redraws every frame from state + `fx` list.
4. Combat is ticked from `main._process` → `GameState.tick`.

## Power graph

- Nodes: `"core"` and tower keys `"row,col"`.
- Edges: `links[id] = { a, b, wireless, fortified }`.
- Powered set: BFS from core along links.
- A tower is ON iff its key is in the powered set.
- Standard link illegal if `chebyshev > LINK_RANGE` or not `same_landmass`.
- Wireless allowed across path if `chebyshev <= WIRELESS_RANGE` and under cap.

## Combat

- Enemies walk `GameData.PATH` (Vector2i row, col) at `ENEMY_MOVE_SPEED * def.speed`.
- **Towers fire on their own cooldowns**, not on enemy movement. `fire_towers()` runs once
  per tick: each powered tower ticks `cooldown` down, acquires a target, and fires when the
  cooldown reaches 0. Cooldown is `1.0 / fire_rate`.
- Targeting is **"first"** — `acquire_target()` picks the enemy furthest along the path
  (nearest the base) within Chebyshev `range`. One target per shot.
- `armor_pierce` is subtracted from the target's `armor`; whatever armor remains still
  reduces damage flat, floored at 1.
- Saboteur: if a link midpoint is near, channel then cut (or Fortify consumes the cut).
  Damage dealt to a channeling saboteur accumulates in `channel_dmg`; at 20 the cut breaks.
- Leak: enemy finishes path → Base Integrity damage.

Cooldowns are ticked with the sim-speed-scaled `dt`, so ×2/×3 speed scales firing too.

### What `speed` now means

Enemy `speed` is a genuine defensive stat: a faster enemy spends less wall-clock time inside
a tower's range and therefore eats fewer shots. This is a change from the original slice,
where damage was dealt once per path *step* and speed had no effect on total damage taken.
Consequences when tuning:

- Effective damage on a target ≈ `damage * fire_rate * (time in range)`, and time in range
  is `(covered path cells) / (ENEMY_MOVE_SPEED * speed)`.
- `range` is still a strong multiplier — it decides how many of the 27 path cells a tower
  covers — but it is no longer the *only* DPS lever.
- Runners are meaningfully harder than their HP suggests; Brutes are softer.

### Infrastructure threats

**Saboteur** — permanently cuts one link, and must commit to do it:

1. *Hunting.* Within `SABOTEUR_HUNT_RADIUS` (4) of a cuttable link it crawls at
   `SABOTEUR_HUNT_SLOWDOWN` (×0.35 on top of its already-low 0.55 speed). `e.hunting` drives
   the on-board "HUNTING" tell.
2. *Channelling.* Within `SABOTEUR_CUT_RADIUS` (2) it stops for `SABOTEUR_CHANNEL_TIME`
   (3.5s). Taking `SABOTEUR_INTERRUPT_DAMAGE` (32) during that window breaks the cut.

The two radii **must stay different**. If they are equal the saboteur commits the instant it
sees a target, the approach phase collapses to zero frames, and the tell never renders.

`pick_saboteur_link()` skips fortified links entirely, so Fortify is immunity rather than a
one-shot absorb.

**Hacker** — destroys nothing. On a `hack_interval` timer it stalls for `hack_windup`, then
`hacker_pulse()` sets `disabled_until` on wireless links and towers within `hack_radius`.
`powered_nodes()` skips disabled links and `fire_towers()` skips disabled towers, both
compared against the `elapsed` combat clock. Tower duration is scaled by `1.0 - hack_resist`.

Note that on the current map a pulse near the Core's root link darkens **everything**,
because the Core has no land route out. That is map geometry, not Hacker tuning.

**Links are shielded by their towers.** `link_hack_resist()` returns the best `hack_resist`
among a link's tower endpoints (the Core is not a tower and contributes nothing), and that
scales the link's disable duration exactly as it does a tower's. This is load-bearing, not a
nicety: without it, a board upgraded to 100% resist is *still* fully dark during a pulse —
every tower immune but unpowered, because the wireless root link was suppressed. Measured
outage per pulse across `HACK_RESIST_TIERS`: **2.51s → 1.26s → 0s**.

### Tower stats

Base numbers live in `GameData.TOWER_DEFS`; the modifiable set is `GameData.TOWER_STAT_KEYS`.
**No combat code reads those numbers directly** — everything goes through
`GameState.tower_stat(type, key)`. That single function is where the progression / upgrade
system applies purchased modifiers, so upgrades reach combat, load, burst, and the HUD legend
without touching any call site.

## Juice

`GameState.emit_juice(kind, payload)` both:

- queues visual `fx` entries, and
- signals `main.gd` → `SfxPlayer.play_event(kind)` + optional board shake.

## Adding content (preferred)

| Add | Where |
|-----|--------|
| Stats / waves / path | `game_data.gd` only |
| New tool behavior | `game_state.gd` + `main.gd` tool list |
| New draw | `board_view.gd` |
| New SFX kind | `sfx_player.gd` + juice kind string |

Keep presentation out of rule functions so 2.5D can replace `BoardView` later without rewriting combat.
