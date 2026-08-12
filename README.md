# Tower-Defence — Grid & Decay

Infrastructure tower defense: **powerlines attach to towers**, winding path, PC + mobile target.

**GitHub:** https://github.com/ipaliog-a11y/Tower-Defence  
**Engine:** Godot 4 (4.7 verified)

> **Other AIs / new sessions:** start at [`AGENTS.md`](AGENTS.md) then [`docs/STATUS.md`](docs/STATUS.md).

## Folders

| Path | What |
|------|------|
| `godot/` | **Playable game** — open `godot/project.godot` |
| `mockup/` | Browser prototype (reference only) |
| `docs/` | Status, decisions, architecture, roadmap, playtests |
| `CHANGELOG.md` | What changed (required for multi-model work) |
| `Grid_and_Decay_Design_Document.md` | Older design draft (partially superseded) |
| `Paper_Play_Spine_District.md` | Historical paper rules |

## Quick start

1. Install [Godot 4.3+](https://godotengine.org/download/windows/) (4.7 works)
2. Import `godot/project.godot`
3. Press **F5**

Controls and juice notes: [`godot/README.md`](godot/README.md)

## Current rules (short)

- 10×10, long path around scenery
- No cable tiles — **links** between Core and towers
- Wireless = expensive gap/path bridge, **not** saboteur immunity
- Weak towers / tough enemies on purpose
- No meta progression, no 2.5D art yet

## Engine

**Godot 4** — chosen for custom grid + graph systems and solo scope.
