# Agent / AI handoff

This repo is developed by **multiple AI models**. Read this file first, then `docs/STATUS.md`.

## Product

**Working title:** Grid & Decay  
**Genre:** Infrastructure tower defense (2.5D later; currently 2D prototype art)  
**Engine:** Godot 4.3+ (verified **4.7.1**)  
**Platforms (intent):** PC first, mobile later  
**GitHub:** https://github.com/ipaliog-a11y/Tower-Defence  
**Default branch:** `main`

## Where to work

| Path | Role |
|------|------|
| `godot/` | **Source of truth for the playable game** |
| `mockup/` | Frozen-ish browser prototype (design reference only) |
| `docs/` | Status, roadmap, architecture, conventions |
| `CHANGELOG.md` | What changed, for the next model |
| `Grid_and_Decay_Design_Document.md` | Older design exploration (some rules superseded) |
| `Paper_Play_Spine_District.md` | Paper-play kit (historical) |

**Do not treat the HTML mockup or the first design doc as current rules.** Current rules live in `godot/scripts/game_data.gd` + `godot/scripts/game_state.gd`.

## How to run

1. Open `godot/project.godot` in Godot 4.3+ (4.7 works).
2. Press **F5**.
3. Pick North / South / Split or build empty.

## Before you change anything

1. Read `docs/STATUS.md` (now / next / do-not).
2. Read `docs/DECISIONS.md` (locked vs flexible).
3. Append `CHANGELOG.md` for every meaningful change.
4. Update `docs/STATUS.md` if you finish, pivot, or leave work half-done.

## After you change anything

- Keep `game_data.gd` as the balance/map source of truth.
- If you change rules, note it in CHANGELOG **and** STATUS.
- Prefer small, documented commits.
- Push `main` when the owner asked to publish (do not force-push).

## Code map (Godot)

| File | Responsibility |
|------|----------------|
| `godot/scripts/game_data.gd` | Map, costs, tower/enemy stats, waves (static) |
| `godot/scripts/game_state.gd` | Match: build, links, combat, juice events |
| `godot/scripts/board_view.gd` | Draw grid + FX, board clicks |
| `godot/scripts/main.gd` | HUD, tools, legend, SFX wiring |
| `godot/scripts/sfx_player.gd` | Procedural audio |
| `godot/scenes/main.tscn` | UI shell |

Coordinate system: `Vector2i.x = row`, `Vector2i.y = col`. Screen x = col, screen y = row.

## Flexibility

Radical gameplay changes are **expected**. Stay system-first. Do **not** start a full 2.5D art pipeline until rules stop thrashing. See `docs/DECISIONS.md`.
