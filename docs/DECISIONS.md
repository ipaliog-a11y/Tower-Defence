# Design decisions

Update this when a rule is locked, reversed, or left explicitly open.

## Locked for the current slice

| Decision | Choice | Why |
|----------|--------|-----|
| Engine | Godot 4 (GDScript, standard build) | Solo, custom systems, PC then mobile |
| Repo | https://github.com/ipaliog-a11y/Tower-Defence (`main`) | Multi-model handoff |
| Board | 10×10 | 8×8 was too tight for scenery + routing |
| Path | Long winding path around factory/rocks (~27 cells) | More geometry than a straight spine |
| Power presentation | **Links on Core/towers**, no cable tiles | Frees cells for towers/scenery |
| Cross-gap tool | Wireless link (range 4, +load, max 4) | Bridge path/scenery; **not** saboteur armor |
| Land links | Range 2 and same landmass (BFS around path) | Path/scenery can force wireless |
| Lose condition | Base Integrity → 0 | Clear, mobile-friendly |
| Economy | Single currency: Scrap | Build + links + repair |
| Wear | Repairable (click Core); permanent loss later/hard only | Early runs must not soft-lock |
| Start power | Underpowered towers; buffed enemies | 2 Caps must not 0-damage full clear |
| Meta progression | **Deferred** | Balance combat first |
| 2.5D / final art | **Deferred** | Rules may still change radically |
| Juice | Procedural SFX + drawn FX | No asset pack yet |

## Open / expected to change

- Exact tower stats, wave lists, link ranges/costs
- Whether wireless should resist saboteurs (currently **no**)
- Map count and board size mix
- In-run upgrades vs meta shop
- Camera: 3D ortho diorama vs 2D isometric sprites
- Additional sabotage (EMP, Grid Worms)

## Superseded (do not re-implement unless asked)

- 8×8 as the only board
- Physical conduit tiles occupying cells
- Cables under the road
- Wireless transmitters mounted on roadside cable nodes
- Dual currency (Scrap + “build points”)
- Permanent max-power loss in default mode

See also the exploration draft `Grid_and_Decay_Design_Document.md` — historical, partially obsolete.
