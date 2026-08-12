# Changelog

Newest first. **Every model must add an entry** when they change behavior, structure, or plans.

## 2026-08-13

### Saboteur rework + new Hacker enemy

From a playtest report: a cut root wireless link darkened every tower at once, and being low
on scrap made it unrecoverable. Diagnosed first — the Core is reachable by land from only
**4 of 48** buildable cells, so the root link must be wireless; saboteurs score wireless 40
vs powerline 20 and so always prefer it; and that link's midpoint sits on the enemy path.
Four choices compounding into a guaranteed loss.

Owner's chosen fix was counterplay rather than changing the map:

- **Fortify is now immunity.** `pick_saboteur_link()` skips fortified links entirely instead
  of the cut consuming the fortification. Fortifying the root link is now the answer.
- **Saboteur must commit.** Speed 1.0 → 0.55, plus ×0.35 while hunting; cut channel
  1.5s → 3.5s; interrupt threshold 20 → 32. Hunt radius (4) is deliberately wider than cut
  radius (2) so there is a visible approach phase — with both at 2 the tell never rendered.
- **Saboteur HP 95 → 120**, tuned against the fire-rate model where time in range *is*
  damage. At 210 it survived a full crossing at 69% HP; at 120 it dies ~22s in while still
  landing one cut.
- **New Hacker enemy** — temporarily disables wireless links and towers in radius via
  `disabled_until` against a new `elapsed` combat clock. Destroys nothing. 1.4s windup
  telegraph, 2.5s disable, radius 2. Added to waves 5, 7 and 8.
- **New `hack_resist` tower stat** (0.0 on every tower), in `TOWER_STAT_KEYS` — the hook the
  upgrade system will sell countermeasures against.
- Visuals and audio for all of it: HUNTING ring, PULSE windup ring, distinct "HACK" tower
  state separate from "OFF", suppressed-link rendering, and three new procedural SFX.

**Measured, not assumed** (headless, Godot 4.7.1): fortified links are never selected across
400 samples; the saboteur is killed at 22.5s after landing one cut; Hacker pulses destroy 0
links.

**Two things left open.** A Hacker pulse still blacks out 4/4 towers, because the root link
is wireless — same failure shape as a cut, just time-boxed to 2.5s. And zero-input auto-play
stalls at wave 3 on all presets; the previous build stalls at wave 3–4, so that wall is
pre-existing rather than a regression. Both recorded in `docs/STATUS.md`.

## 2026-08-12

### Combat — per-tower fire rate, full tower stat block

Owner decision: enemy `speed` should be a real stat, and towers should carry a full stat set
for the future progression/upgrade system.

- **Towers now fire on their own cooldowns** (`fire_rate`, shots/sec) instead of dealing
  damage once per enemy path step. New `GameState.fire_towers()` + `acquire_target()`
  ("first" targeting: furthest along the path within range). Removed `fire_volley()` and
  `towers_in_range()`.
- **Enemy `speed` is now a defensive stat** — a faster enemy spends less time in range and
  eats fewer shots. Previously speed had no effect on total damage taken.
- **Full tower stat block**: `damage`, `fire_rate`, `range`, `armor_pierce`, `draw_idle`,
  `draw_fire`, plus `burst_damage` / `spike_damage` / `spike_draw`. Modifiable set is
  declared in `GameData.TOWER_STAT_KEYS`. Renamed `dmg`→`damage`, `burst`→`burst_damage`,
  `spike_dmg`→`spike_damage`.
- **New stat `armor_pierce`** — eats enemy armor before it reduces damage flat. Gives the
  Drainer an anti-armor identity and stops low-damage towers being floored to 1 vs Brutes.
- **`GameState.tower_stat(type, key)` is the single stat-resolution hook.** No combat code
  reads `TOWER_DEFS` numbers directly, so the upgrade system can apply modifiers in one
  place and reach combat, load, burst and the HUD legend at once.
- Fixed as a side effect: the shared global `channel_tick` is gone, so two saboteurs
  channeling at once no longer split one damage tick between them.
- HUD legend now shows DPS, fire rate and pierce.

**Not playtested.** Starting numbers were derived to roughly preserve the old effective DPS
against a `speed 1.0` Grunt. Fast and armored enemies have moved: expect Runners harder,
Brutes softer. Godot was not installed on the authoring machine, so this change is reviewed
but **unrun** — first job for the next session is to launch it and play a wave.

### Docs — verified handoff docs against the Godot source

- Corrected the engine requirement everywhere from "4.3+" to **4.7**: `project.godot` is
  saved at `config/features = "4.7"` and the `.uid` files need 4.4+, so 4.3 would prompt to
  convert the project.
- Documented in `docs/ARCHITECTURE.md` that **there is no rate of fire** — `fire_volley()`
  runs per path step, so enemy `speed` does not change how much damage an enemy takes, and
  tower `range` is the real DPS stat. Flagged in `AGENTS.md` and `docs/STATUS.md` because
  the balance pass is next and this invalidates the old design doc's RoF numbers.
- Noted the shared global `channel_tick`: two saboteurs channeling at once each take about
  half the intended return fire.
- No gameplay code changed.

### Docs — multi-model handoff

- Added `AGENTS.md`, `docs/STATUS.md`, `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, `docs/PLAYTEST.md`.
- Root `README.md` now points at those files.

### Godot juice (in tree before this doc pass)

- `sfx_player.gd` procedural SFX.
- Extra FX: rings, sparks, flow dots, screen tint, board shake, HUD punch.
- `GameState.juice` signal.

### GitHub

- Repo: https://github.com/ipaliog-a11y/Tower-Defence
- Branch `main` tracks origin. Merged GitHub stub README.

## Earlier (same week, condensed)

- Design doc: Grid & Decay, then exploration revision (Scrap, Base HP, 8×8 maps).
- Paper play kit for Spine District.
- HTML mockup (`mockup/`) with iterations: presets, HP UI, damage beams, memo, weaker towers, under-road cables (reverted), wireless Tx on cables (superseded), 10×10 + tower-attached links, winding path, legends.
- Godot 4 vertical slice port of that last mockup.
- Engine choice: Godot (not Unity).
- 2.5D / meta progression deferred.
