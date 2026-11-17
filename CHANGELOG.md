# Changelog

Newest first. **Every model must add an entry** when they change behavior, structure, or plans.

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
