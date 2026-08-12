# Grid & Decay — Playable Mockup

**10×10** board · **powerlines attach to towers/Core** (no cable tiles) · wireless bridges the road.

## Run

Open `index.html` or:

```powershell
cd C:\Users\WiNdOS\Tower-Defence\mockup
npx --yes serve -p 5173
```

→ http://localhost:5173

## Power model

| Piece | Role |
|--------|------|
| **Tower cell** | Only structures that occupy a tile |
| **Powerline** | Edge Core↔tower or tower↔tower · range 2 · same side of road · 10 scrap |
| **Wireless** | Edge that **crosses the road** · range 4 · max 4 · 22 scrap · higher load |
| **Auto-link** | New towers try to connect to nearest powered node |

Saboteurs cut **links**, not floor tiles. Fortify protects a link.

## Keys

1 Powerline · 2 Wireless · 3–6 towers · Space wave · B burst · V spike · F fortify
