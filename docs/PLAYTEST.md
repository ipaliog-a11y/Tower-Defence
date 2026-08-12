# Playtest log

Append dated notes. Newest first. Other models: do not delete history.

## Template

```
### YYYY-MM-DD — <who/model>
Preset / custom:
Waves reached / win-lose:
HP / Scrap leftover:
Keep:
Change:
Cut:
```

## 2026-08-13 — owner, on `feat/saboteur-rework-and-hacker` (PR #2)

Build: per-tower fire rate + Fortify immunity + slowed Saboteur + new Hacker.

**Verdict: keep. "Overall good play."**

- **Hacker lands.** Reads as a genuine advanced unit — challenging without feeling unfair.
  The windup telegraph → temporary disable shape is working. Do not nerf it.
- **Hacker + Saboteur in the same wave is noticeably harder**, and the owner rated that as
  good difficulty rather than a problem. Treat the overlap as a deliberate late-game spike:
  if more waves pair them, escalate on purpose, don't scatter it.
  *(Correction: an earlier note in this file claimed they overlapped only in wave 8. At the
  time of this playtest the Hacker was in waves 5, 7 and 8, and **both 7 and 8 paired it
  with a Saboteur** — so the combined pressure the owner felt may have been wave 7. The wave
  list has since been changed per owner request, below.)*
- Fortify-as-immunity plus the visible HUNTING crawl resolved the earlier complaint (a cut
  root link darkening every tower while broke). No repeat of that report this session.

**Owner decisions taken from this session:**

- **Hacker moves later.** Was waves 5/7/8. Now debuts **alone in wave 7** so the pulse can be
  learned in isolation, then pairs with Saboteurs in **wave 8** as the finale. Wave 5 is back
  to a Saboteur.
- **`hack_resist` becomes a mid/high-tier tower upgrade addon**, level 1 = 50%, level 2 =
  100%. Tiers declared in `GameData.HACK_RESIST_TIERS`. Measured: outage per pulse goes
  2.51s → 1.26s → 0s.
- Required a mechanic change to be worth buying: **a wireless link now inherits the best
  `hack_resist` of its tower endpoints.** Without it, a fully-upgraded board was still
  blacked out — towers immune but unpowered, because the Hacker suppressed the Core's
  wireless root link. Verified: at 100%, 0 of 4 towers go dark; previously 4 of 4.

**Still open, not raised as pain this session:**

- A Hacker pulse blacks out 4/4 towers, because the Core's only exit is wireless. Survivable
  at 2.5s, but the same shape as a cut. See `DECISIONS.md` → Core is an island.
- The economy half of the original complaint: a cut link while broke is still unrecoverable.
- Zero-input auto-play stalls at wave 3, pre-existing (baseline stalls at 3–4).

## 2026-08-12 — historical (from earlier mockup, before Godot)

- North preset was the only affordable opener until presets became free layouts + leftover scrap.
- 2 Capacitors full-cleared with 0 HP loss → towers weakened, enemies buffed.
- Load often read as ~4% in the web mockup (accounting bug / unused fire flag). Godot recomputes from fired flags + link tax.
- Saboteurs often magnetized to one feeder (`1,2` on 8×8). Now they target nearby **links**.
- South feed was impossible without path cables; then under-road cables; then wireless Tx on cable nodes; **current: tower-to-tower wireless**.
- Owner: wireless is **higher cost to bridge**, not a saboteur counter.
- Owner: may bring radical gameplay later; stay flexible; delay 2.5D assets.
- Owner: juice while they keep playtesting.
- Godot slice runs (4.7.1).
