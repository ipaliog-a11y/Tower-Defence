# Status (read this first)

**Last updated:** 2026-08-12  
**Playable?** Yes — Godot 4 vertical slice on `main`.  
**Art:** Programmer colors / rects + juice. Not 2.5D yet.  
**Progression:** In-run Scrap only. No meta unlocks.

## Now (current slice)

Working in Godot:

- 10×10 grid, winding ~27-cell path around scenery
- Towers occupy cells; **powerlines attach between Core/towers** (no cable tiles)
- **Powerline:** range 2, land-connected only, cheap
- **Wireless:** range 4, can bridge path/scenery gaps, costlier, max 4
- Towers auto-link on place when possible
- Saboteurs cut **links**, not floor tiles; Fortify blocks one cut
- 4 towers: Capacitor, Transformer, Regulator, Drainer (intentionally weak)
- Enemies: Grunt, Mite, Brute, Runner, Saboteur
- 9 waves; Base HP 10; Scrap economy; load/heat (repairable wear)
- Presets: North / South / Split
- Juice: procedural SFX + beams, sparks, flow dots, shake, HUD punch

## In progress / next

1. **Playtest + balance** (owner is playtesting; juice already added)
2. Document playtest notes in `docs/PLAYTEST.md` when they arrive
3. **Do not start 2.5D assets** until rules stabilize (owner may still make radical gameplay changes)
4. After rule freeze: 2.5D board kit (ortho/isometric diorama) + tiny first asset set
5. Later: second map as data, then meta progression (weak start, spend after failed runs)

## Do not (unless owner asks)

- Port back to the HTML mockup as source of truth
- Add EMP / Grid Worms / full 4-tier upgrade trees yet
- Commission / generate a full art bible
- Switch engines
- Force-push `main`

## Known issues / debt

- `GameData` / mockup can drift if someone edits only one
- Headless Godot may fail `class_name` until project is imported once (`.godot/` is gitignored)
- `main.gd` preloads `sfx_player.gd` to avoid first-scan class cache issues
- Combat load/heat still easy to ignore vs DPS/pathing
- Wireless is **not** saboteur immunity (premium bridge only)
- Design doc still describes older conduit-tile / 8×8 rules in places

## Owner intent

- Development may **split across multiple AI models**
- Gameplay may change **radically** later — keep architecture data-driven
- Document every meaningful change in `CHANGELOG.md`
