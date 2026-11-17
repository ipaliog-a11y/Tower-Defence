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
