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
| Firing model | **Per-tower cooldown** (`fire_rate` shots/sec), "first" targeting | Makes enemy `speed` a real stat; replaces per-path-step volleys |
| Fortify | **Full immunity** — a saboteur cannot target a fortified link at all | Was a one-shot absorb; now it is the deliberate answer to a fragile root link |
| Saboteur | Crawls (speed 0.55), crawls harder while hunting (×0.35), 3.5s cut channel | The slowdown IS the tell — the threat must be visible and killable, not a coin flip |
| Hacker | Temporarily disables wireless links + towers in radius; **destroys nothing** | A second infrastructure threat that cannot end a run outright |
| Countermeasures | `hack_resist` stat exists on every tower, 0.0 everywhere | Hook for the upgrade system to sell counterplay later |
| Tower stats | **Full explicit stat block** per tower, listed in `GameData.TOWER_STAT_KEYS` | Progression/upgrades need concrete stats to modify |
| Stat access | All combat reads go through `GameState.tower_stat()` | One hook for upgrades; nothing reads `TOWER_DEFS` numbers directly |
| Start power | Underpowered towers; buffed enemies | 2 Caps must not 0-damage full clear |
| Meta progression | **Deferred** | Balance combat first |
| 2.5D / final art | **Deferred** | Rules may still change radically |
| Juice | Procedural SFX + drawn FX | No asset pack yet |

## Known structural issue — Core is an island

Only **4 of 48** buildable cells are land-reachable from the Core: the enemy path (row 1)
plus the blocked cells at (0,6)–(0,8) wall it into a row-0 pocket. Consequences:

- Every build must leave the Core by **wireless**, so wireless is mandatory infrastructure
  rather than the "premium gap tool" this document says it is.
- All three presets have a single root wireless link whose loss darkens 3–4 of 4 towers.
- A Hacker pulse near that root link blacks out the **whole grid** for its duration.

Fortify immunity is the current mitigation, not a fix. The owner chose counterplay over
changing the map; if the collapse still feels bad, moving the Core onto the main landmass is
the option that removes the cause rather than softening it.

## Open / expected to change

- Exact tower stats, wave lists, link ranges/costs — **all current fire-rate/damage numbers
  are a first derivation and unplayed**
- Which stats the upgrade system actually sells (the stat block is deliberately wider than
  the likely first upgrade tree)
- Targeting mode — currently always "first"; per-tower selectable targeting is a candidate
  upgrade/QoL feature
- Enemy stat block: enemies still carry a thinner set (hp/speed/armor/leak/scrap) than
  towers do, and will likely need the same treatment
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
- Damage dealt once per enemy path step (replaced by per-tower fire rate)

See also the exploration draft `Grid_and_Decay_Design_Document.md` — historical, partially obsolete.
