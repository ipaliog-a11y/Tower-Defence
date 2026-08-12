# Paper Play Kit — Spine District (Map A)

**Purpose:** Test whether *routing power + surviving Saboteurs* is fun **before** any engine work.  
**Time:** 25–40 minutes for a full short campaign; 10 minutes for a smoke test (waves 0–3 only).  
**Players:** 1 (solo designer) or 1 player + 1 “enemy operator.”  
**Map:** Spine District (simplified 8×8) from the design doc.

**Success signal:** You disagree with yourself about north rail vs south rail vs split feed, and Saboteur cuts feel dramatic—not random or unreadable.

---

## 1. What You Need

### Physical tokens (use whatever you have)

| Token | Stand-ins |
|-------|-----------|
| **Core (C)** | Coin, large bead, “C” on paper |
| **Base (B)** | Different coin / “B” |
| **Conduit tile** | Matchsticks, dry spaghetti, paper strips, pen lines |
| **Standard / Reinforced / HV** | Three colors or marks: plain / double line / “HV” |
| **Towers** | 4 types of scraps (see §3) — bottle caps, colored paper, Lego |
| **Enemies** | Dice, beans, pennies — mark type with letter |
| **Saboteur** | Distinct token (red bead, “S”) |
| **Scrap tracker** | Paper + pen, or phone notes |
| **Load / Integrity / Heat** | Three numbers on a sticky note |
| **Optional RNG** | One d6 or d10 |

### Print or redraw the board

Copy this grid large enough to place tokens (phone screenshot of this file works if you play on a tablet with digital tokens).

```
    0 1 2 3 4 5 6 7
0   # . . . . . . #
1   # C . . . . . #
2   # . . . . . . #
3   P > > > > > > B
4   # . . . . . . #
5   # . . . . . . #
6   # . # # # . . #
7   # . . . . . . #
```

**Legend**

- `#` = blocked (no build, no path)  
- `.` = buildable  
- `P` → `B` along row 3 = enemy lane (cells `(3,0)…(3,7)`). **Do not place towers on path cells.** Conduits also **cannot** occupy path cells in this paper ruleset (keeps adjudication simple).  
- `C` at `(1,1)` fixed. `B` at `(3,7)` fixed.

**Buildable cells (count them once):** all `.` and the Core cell does not accept a tower (Core is not a tower). Path and `#` are illegal.

---

## 2. Simplified Paper Rules

These are **lighter than the full design doc** so a human can resolve turns without a spreadsheet. If paper-fun survives, full numbers can return in greybox.

### 2.1 Tracked resources

| Resource | Start | Notes |
|----------|-------|--------|
| **Scrap** | 120 | Only spend currency |
| **Max Power** | 100 | Softened; wear is repairable |
| **Heat** | 0 | 0–20 scale on paper |
| **Base Integrity** | 12 | Lower than doc’s 20 so paper campaigns end faster |
| **Tower cap** | 8 | Slightly under digital MVP 10 for less clutter |

### 2.2 Power budget (coarse)

Do **not** simulate per-tile loss every second. Use this coarse model:

1. **Cable length** = number of conduit tiles in the shortest path from Core to that tower (orthogonal only: N/S/E/W).  
2. **Power draw** of a tower = **Idle** if it didn’t shoot this enemy step, else **Fire** (paper: assume Fire if any enemy was in range during the wave segment).  
3. **Network load** each wave = sum of all powered towers’ draws + **cable tax**.

**Cable tax (paper):**

| Total conduit tiles on board | Tax |
|------------------------------|-----|
| 1–4 | +0 |
| 5–8 | +5 |
| 9–12 | +10 |
| 13+ | +15 |

**Load %** ≈ `(sum of tower draws + cable tax) / Max Power × 100`  
(If >100%, you are in hard overload.)

**Unpowered tower:** If no orthogonal conduit path from Core → tower (through conduit tiles only), tower is **dark** (no attack, no draw).

**Branch rule:** A tower is powered if there is *any* conduit path from Core to its cell’s conduit connection. Paper simplification: **tower sits on a buildable cell; it must be orthogonally adjacent to at least one conduit tile that connects to the Core, OR sit on a cell that you declare as “tower + junction”** (place tower token *on* the last conduit tile).  

**Recommended paper convention (pick one and stick to it):**

- **Convention A (cleaner):** Conduits occupy cells. Towers occupy cells. Tower must share an edge with a conduit cell that traces to Core.  
- **Convention B (faster):** Towers sit on conduit endpoints (same cell). That cell counts as conduit for connectivity.

**Use Convention A** unless the board gets too crowded.

### 2.3 Build costs (Scrap)

| Item | Cost |
|------|------|
| Standard conduit / tile | 8 |
| Reinforced / tile | 15 |
| High-Voltage / tile | 22 |
| Capacitor | 35 |
| Transformer | 28 |
| Regulator | 32 |
| Drainer | 40 |
| Sell tower | refund 70% Scrap (round down) between waves; 50% if you allow mid-wave sells |
| Repair 1 Max Power of wear | 3 Scrap (between waves) |

**HV / Reinforced paper effects:**

- **HV:** cable tax counts HV tiles as **0.5** each (round tax down at end). Saboteurs **prefer** HV if multiple targets.  
- **Reinforced:** Saboteur cut takes **2 segments** instead of 1 (see combat).  
- **Standard:** normal.

### 2.4 Tower combat (coarse)

Range is in **orthogonal + diagonal Chebyshev distance** (king-move in chess) from tower cell to enemy cell—simple on a grid.

| Tower | Draw (idle/fire) | Range | Damage per wave segment* | Special (paper) |
|-------|------------------|-------|---------------------------|-----------------|
| Capacitor | 3 / 6 | 3 | 18 | Once per wave: **Burst** → 40 dmg to one target in range (costs: treat draw as 6 extra this wave) |
| Transformer | 4 / 4 | 3 | 12 | **Valve:** mark one conduit edge “closed” (downstream dark). **Sever:** once per wave, destroy one conduit tile you own (eject setup for later Worms; vs Saboteur free scrap only if you sever under them—optional) |
| Regulator | 5 / 5 | 2 | 9 | **2 charges / wave:** (1) Fortify one conduit tile (Saboteur fails first cut on it), or (2) Instant rebuild one Standard conduit tile for free if you have the Scrap for materials waived—paper: **free one tile Standard rebuild** |
| Drainer | 8 / 8 or 18 spike | 4 | 22 / **40 spike** | **Spike:** once per wave, +18 draw for that wave, Saboteurs prefer Drainer’s feed branch |

\*“Per wave segment” = once when enemies are processed in that tower’s range; see turn structure.

**Armor (Brute):** damage from each tower hit reduced by 5 (min 1 per hit).  
**No complex RoF:** each powered tower in range deals its damage **once per enemy per row-step** when that enemy enters or remains in range (see §4). If that is too slow, use **once per full wave** AoE sum—see Fast Mode (§8).

### 2.5 Integrity leaks

When an enemy reaches **B**, Integrity loss:

| Enemy | Integrity |
|-------|-----------|
| Grunt | 1 |
| Swarm Mite (pack) | 1 per pack token |
| Brute | 2 |
| Runner | 1 |
| Saboteur | 2 |

At **0 Integrity** → defeat.

---

## 3. Token Legend (print strip)

```
C  Core
B  Base
=  Standard conduit
R  Reinforced conduit
H  HV conduit
K  Capacitor (thinK bank)
T  Transformer
G  ReGulator
D  Drainer
g  Grunt
m  Mite pack
b  Brute
r  Runner
S  Saboteur
```

---

## 4. Turn Structure (one wave)

### Phase 0 — Between waves (before wave 1, and after each wave)

1. **Repair wear** (optional): pay Scrap, restore Max Power.  
2. **Buy upgrades** if using the mini upgrade list (§6).  
3. **Build / sell / rewire** freely (orthogonal conduits only).  
4. Confirm all towers you want powered are connected.  
5. Write down: Scrap, Max Power, Heat, Integrity, load estimate.

### Phase 1 — Threat spawn

Place enemies on **P `(3,0)`** per wave script (§5). If multiple, they form a queue: only first stands on P; others wait “off-map” and enter when the cell frees **or** stack as a line going west off the board and advance together (simpler: **process one enemy at a time** fully—solo friendly).

**Solo recommendation:** Resolve **one enemy fully** (walk to death or base), then the next. Saboteurs interrupt (below).

### Phase 2 — Enemy steps

For each enemy token:

1. Move **one path cell** toward B along row 3:  
   `(3,0)→(3,1)→(3,2)→(3,3)→(3,4)→(3,5)→(3,6)→(3,7)=B`  
2. After each step, every **powered** tower in range deals its damage once to that enemy (apply armor).  
3. If HP ≤ 0, remove enemy; gain Scrap kill reward.  
4. If enemy is **Saboteur**, after any step it may **attempt a cut** (see §4.1) instead of only walking—use Saboteur AI.  
5. If it enters B with HP > 0, apply Integrity loss.

**Enemy HP (paper):**

| Enemy | HP | Scrap on kill |
|-------|-----|---------------|
| Grunt | 40 | 4 |
| Mite pack | 25 | 3 |
| Brute | 70 | 7 |
| Runner | 28 | 5 |
| Saboteur | 55 | 10 |

**Runner:** moves **two** path cells per step resolution (still only one damage volley per step resolution—so fewer volleys; they are dangerous).

### 4.1 Saboteur AI (paper)

After each move, if Saboteur is alive:

1. Look at all conduit tiles within **Chebyshev range 2** of its current cell (path cell).  
2. Prefer: **HV > tile feeding most towers > Standard > Reinforced**.  
3. If none in range, keep walking toward B.  
4. If target found: spend this step **channeling** (does not move). Place a “channel” marker.  
5. Next Saboteur action: **cut succeeds** unless:  
   - tile was **Fortified** by Regulator this wave (consume fortify; cut fails; Saboteur skips ahead one path cell), or  
   - tile is **Reinforced** and this is the first cut attempt on it (Reinforced needs **two** successful cut actions), or  
   - you spend focus fire: any single tower volley that deals **≥20 damage during channel** cancels channel (Saboteur stuns: skips one action).  
6. On successful cut: remove that conduit tile. All towers that relied only on that bridge go dark until rewired. Saboteur has **40%** chance (roll d10 ≤ 4) to target a second cut later; else walks to B.

### Phase 3 — End of wave

1. Sum **Load** using fire draws for any tower that shot at least once + cable tax.  
2. **Heat:**  
   - load < 60% → Heat −2 (min 0)  
   - 60–79% → Heat +1  
   - 80–99% → Heat +3  
   - 100%+ → Heat +5  
3. If Heat ≥ 10 at wave end: **Wear** = half of Heat (round down); Max Power − Wear; Heat − 4 (residual). Write “repair debt.”  
4. Wave clear bonus: **+15 Scrap** if Integrity loss this wave was 0; else **+8**.  
5. Rebuild freely (Phase 0).

---

## 5. Wave Script — Spine Short Campaign

**Goal:** 8 waves. Defeat if Integrity hits 0. Win if wave 8 cleared.

| Wave | Enemies (resolve in order) | Intent |
|------|----------------------------|--------|
| 0 | 3× Grunt | Teach cable + shoot |
| 1 | 4× Grunt, 1× Mite pack | Multiple towers, load |
| 2 | 3× Grunt, **1× Saboteur**, 2× Grunt | First cut drama |
| 3 | 2× Brute, 2× Grunt, 1× Mite | Armor + heat |
| 4 | 2× Grunt, **1× Saboteur**, 1× Runner, 2× Grunt | Speed + sabotage |
| 5 | 2× Mite, 1× Brute, **1× Saboteur**, 1× Brute | Pressure combo |
| 6 | 3× Runner, 2× Grunt, **1× Saboteur** | Gaps punish dark towers |
| 7 | 2× Brute, 2× Runner, 2× Grunt | DPS check |
| 8 | 2× Grunt, **2× Saboteur**, 1× Brute, 1× Runner, 2× Grunt | Boss-ish finale |

**Smoke test:** Waves **0–3** only (~10–15 min). If wave 2–3 aren’t fun, stop and note why.

---

## 6. Mini Upgrades (optional, between waves)

Only if Scrap ≥ cost. Max one purchase per between-wave phase for paper pace.

| Upgrade | Cost | Effect |
|---------|------|--------|
| Regulator +1 charge | 45 | 3 charges / wave |
| Failover notes | 65 | When a cut happens, you may place **1 free Standard** conduit on an empty buildable cell adjacent to Core or existing conduit (instant patch) |
| Predator (Drainer) | 50 | Drainer non-spike damage 22→28 |
| Load masking | 70 | Soft overload heat band starts at 85% (80–84% counts as 60–79%) |

---

## 7. Opening Build Recipes (try each on a separate run)

Do **three short runs** (smoke test waves 0–3) with different openers. Do not optimize mid-run toward the same graph.

### Recipe N — North Rail

- Conduit: Core `(1,1)` → north/east toward row 2.  
- Towers primarily on **row 2** covering the lane.  
- Minimal south investment.

**Watch for:** long east feed; Saboteur on the single feeder.

### Recipe S — South Rail

- Feed down around blockers on row 6 (`# # #` at 6,2–6,4).  
- Towers on **row 4–5**.

**Watch for:** longer cable tax; safer from early Saboteur range if S stays mid-path.

### Recipe X — Split Feed

- Junction near Core; one branch north, one south.  
- Transformer at junction; 1 Regulator.  
- Higher cable tax; better failover story.

**Watch for:** low Scrap early; weaker peak DPS.

**After each run, fill §9 log.** If one recipe always wins and the others always die, note whether that’s map, costs, or Saboteur rules.

---

## 8. Fast Mode (if full step combat is too slow)

Use when you only care about **routing + sabotage**, not DPS math.

1. Build network + towers.  
2. Each wave has a **Threat HP pool** = sum of enemy HP.  
3. Your **DPS score** = sum of powered towers’ damage values in range of **any path cell** (each tower counts once if it covers at least one path cell in range).  
4. If DPS score ≥ Threat HP → wave cleared (gain Scrap).  
5. If not, Integrity loss = `ceil((Threat − DPS) / 40)`.  
6. Resolve **Saboteurs separately**: for each Saboteur, force **one cut attempt** on highest-priority conduit in range of path cell `(3,3)` or `(3,4)` (mid-lane). Apply dark towers, then recompute DPS once.

Fast Mode is worse for combat feel, better for **topology** feel.

---

## 9. Playtest Log (copy per run)

```
Run #____   Date:________   Mode: Full / Fast   Recipe: N / S / X / Other
Waves reached: ____   Win? Y/N   Final Integrity: ____   Final Scrap: ____

Opening conduit tile count: ____   Opening tower list:
______________________________________________________________

When did first dark-tower event happen? Wave ____
Was the cause obvious? Y/N   Notes:
______________________________________________________________

Most interesting decision:
______________________________________________________________

Most frustrating moment:
______________________________________________________________

Did north vs south vs split feel meaningfully different? Y/N
Saboteur: Fun / Neutral / Annoying / Confusing
Load/Heat: Felt real / Invisible / Punitive
Would you play another run to try a different wiring? Y/N

Keep / Change / Cut (circle):
- Orthogonal only
- Cable tax table
- Integrity 12
- Saboteur channel cancel at 20 dmg
- Repairable wear
- Map blockers on row 6

Free notes:
______________________________________________________________
```

### Aggregate decision (after 3+ runs)

| Signal | Lean |
|--------|------|
| You keep wanting “one more run” to try another wire | **Concept strong → greybox** |
| Fun only when ignoring Saboteurs | Saboteur rules or feedback need work |
| Every win is the same spine | Map A too solved; nudge blockers/costs before Map B |
| Tracking load killed pacing | Use Fast Mode or coarser heat |
| Mobile-in-head: “I couldn’t do this on a phone” | Simplify mid-wave verbs further |

---

## 10. Facilitator Script (if two people)

**Player:** builds, upgrades, chooses valve/fortify/burst.  
**Operator:** moves enemies, runs Saboteur AI honestly, tracks Integrity/Scrap.  

Operator mantra: *Be the rules, not the opponent.* If a cut would be ambiguous, prefer the **more telegraphed** target (the fat feeder), not the spite cut.

---

## 11. After Paper Play — Feed Back Into Design

Bring answers into `Grid_and_Decay_Design_Document.md` only when stable:

1. Is Convention A (tower adjacent to cable) clear enough?  
2. Is cable tax a decent proxy for per-tile loss?  
3. Should path-adjacent conduit be allowed? (paper forbids it)  
4. Integrity 12 vs 20 for digital?  
5. Which opener is weak on purpose vs accidentally?

**Do not** jump to Map B/C until Spine smoke tests clear the fun bar in §16 of the main design doc.

---

## 12. Quick Reference Card

```
START: Scrap 120 | MaxP 100 | Heat 0 | Integrity 12 | Towers ≤ 8

BUILD: Std 8 | Reinf 15 | HV 22 | Cap 35 | Xfrm 28 | Reg 32 | Drain 40
DRAW:  Cap 3/6 | Xfrm 4 | Reg 5 | Drain 8 (18 spike)
DMG:   Cap 18 (burst 40) | Xfrm 12 | Reg 9 | Drain 22 (40 spike)
RANGE: Cap 3 | Xfrm 3 | Reg 2 | Drain 4

PATH: (3,0)→(3,1)→(3,2)→(3,3)→(3,4)→(3,5)→(3,6)→(3,7)=B
TAX:  1–4:+0 | 5–8:+5 | 9–12:+10 | 13+:+15  (HV tiles count 0.5)

SABOTEUR: range 2 from path → prefer HV → channel → cut
          Reinforced needs 2 cuts | Fortify blocks 1 | ≥20 dmg cancels channel

HEAT: <60:-2 | 60–79:+1 | 80–99:+3 | 100%:+5
WEAR: if Heat≥10 at wave end → MaxP -= floor(Heat/2); Heat -= 4
CLEAR: +15 Scrap if no leak else +8
```

---

*Paper play is the vertical slice without an engine. When runs feel good, greybox Map A next—not more rules.*
