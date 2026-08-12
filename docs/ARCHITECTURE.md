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

## Combat (coarse)

- Enemies walk `GameData.PATH` (Vector2i row, col).
- On each path-cell step, every powered tower in Chebyshev range deals damage once.
- Armor reduces per hit (min 1).
- Saboteur: if a link midpoint is near, channel then cut (or Fortify consumes).
- Leak: enemy finishes path → Base Integrity damage.

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
