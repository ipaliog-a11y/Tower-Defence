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
  good difficulty rather than a problem. They currently overlap only in **wave 8**, the last
  wave, which is the right place for it. Treat that overlap as a deliberate late-game spike:
  if more waves pair them, escalate on purpose, don't scatter it.
- Fortify-as-immunity plus the visible HUNTING crawl resolved the earlier complaint (a cut
  root link darkening every tower while broke). No repeat of that report this session.

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
