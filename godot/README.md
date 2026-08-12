# Grid & Decay — Godot 4

Vertical slice port of the browser mockup:

- 10×10 grid, winding path around scenery  
- Towers occupy cells; **powerlines / wireless** attach between Core and towers  
- Scrap, Base HP, load/heat, saboteurs cut links  
- Presets: North / South / Split  
- Tower legend beside the board  

## Install Godot

1. Download **Godot 4.3+** (standard, not .NET unless you prefer C#):  
   https://godotengine.org/download/windows/  
2. Unzip anywhere (portable). No installer required.  
3. Run `Godot_v4.x_win64.exe`.

## Open the project

1. Godot → **Import** → browse to:

   `C:\Users\WiNdOS\Tower-Defence\godot`

2. Select `project.godot` → **Import & Edit**.  
3. Press **F5** (or Play) to run.

If Godot asks to upgrade/fix settings, accept defaults for 4.2–4.3.

## Controls

| Input | Action |
|--------|--------|
| **1** | Powerline tool |
| **2** | Wireless tool |
| **3–6** | Cap / Tf / Rg / Dr |
| Click board | Place / link |
| **Space** | Start wave |
| **B** | Capacitor burst |
| **V** | Drainer spike |
| **F** | Fortify link |
| **Esc** | Cancel sell / fortify / link |

## Project layout

```
godot/
  project.godot
  scenes/main.tscn      # UI shell
  scripts/
    main.gd             # HUD wiring
    board_view.gd       # Grid draw + input
    game_state.gd       # Match rules
    game_data.gd        # Map, balance, waves
  icon.svg
```

## Relationship to mockup

`../mockup/` remains the web prototype.  
Balance and map data were copied into `game_data.gd` — keep them in sync when you change rules.

## Juice (current)

Procedural SFX + visual feedback (no asset pack):

- Hit beams, impact sparks, floating damage  
- Power flow dots on live links  
- Place / link / cut / fortify / burst rings  
- OFF tower flicker, path pulse in combat  
- Screen tint on leak / wave / win-lose  
- Light board shake on cut / leak / burst  
- HUD punch on scrap gain / HP loss  

## Next

1. Playtest + balance notes  
2. Replace colored rects with sprites / 2.5D  
3. Second map as a resource  
4. Meta progression (later)  
5. Export Windows build (Project → Export)

## Export (later)

Project → Export → Add **Windows Desktop**.  
Download export templates when prompted.
