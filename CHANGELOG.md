# Changelog

Newest first. **Every model must add an entry** when they change behavior, structure, or plans.

## 2026-08-12

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
