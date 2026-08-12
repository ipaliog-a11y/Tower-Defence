# Grid & Decay — Design Document

**Working Title:** Grid & Decay  
**Genre:** 2.5D Infrastructure Tower Defense  
**Platforms:** PC & Mobile  
**Document Status:** Exploration Draft (pre-commit)  
**Last Updated:** August 2026  

**Positioning:** Not “another path-DPS TD.”  
**Elevator pitch:** *A power grid under siege — route energy, manage load, and defend the network itself.*

---

## 0. How to Read This Doc

This revision applies exploration recommendations **before** locking production scope:

| Topic | Decision for exploration |
|--------|---------------------------|
| Board size | **8×8 default**, depth via buildable masks + map constraints (not bigger grids first) |
| Conduits (v0) | **Orthogonal only** |
| First playable enemies | **Lane fillers + Saboteur only** (EMP / Worm post-slice) |
| Permanent capacity loss | **Softened for first ship** (repairable wear default; permanent = hard/endless) |
| Beam re-aim mid-wave | **Post-MVP** |
| Economy | **One spend currency: Scrap** |
| Primary lose condition | **Base Integrity** (Core crisis is a severe soft-fail / modifier) |
| Upgrades in MVP | **2 tiers per path** (4-tier trees stay as design target) |
| Active assists | Priority mark + rationing = **optional assists**, not required skill |

Nothing here is final art, final numbers, or a production commitment. Numbers are **tuning direction**.

---

## 1. Premise & Lore Hook

### 1.1 Fantasy

Instead of a traditional gold/mana economy, towers run on a shared **power grid** with finite, stressed energy. Players do not simply place towers — they **route power through conduits**, manage load, and protect infrastructure. Towers brown out, overload, or underperform based on grid state.

**Central fantasy:** Keep power flowing under active, intelligent pressure.

### 1.2 Short lore (marketing + tone, skippable in play)

The last district still has a living **Power Core**. Everything outside the grid is dark. You are the **Load Warden** — part engineer, part commander. Echoes of the blackout (saboteurs, scrap-beasts, later parasites) try to cut the veins of the city and reach the Core.

Tone: industrial melancholy, readable diorama, not pure grimdark and not toy-cute neon.

Lore stays optional codex + map intros. Systems lead.

---

## 2. Design Pillars

1. **Power is a living resource** — scarce, tangible, reactive.  
2. **Infrastructure is a battlefield** — defending the network is a primary skill.  
3. **Meaningful trade-offs** — every route and upgrade creates strength *and* vulnerability.  
4. **Readable under pressure** — clear on a small board and on mobile.  
5. **Depth without sprawl** — systemic recombination over large content pipelines.

---

## 3. Core Loop

1. **Power Core** supplies a limited energy pool (Max Power).  
2. **Conduits** (later Relays) route energy to towers.  
3. **Towers** draw power to function. Unpowered towers go **dark**.  
4. **Heat / Decay** stresses Max Power under sustained high load → forces adaptation.  
5. **Enemies** pressure the **base** and (when unlocked) the **grid**.  
6. Between waves: spend **Scrap** on rebuilds, repairs, and upgrades.

Protecting the network becomes as important as protecting the base — but the **clock that ends the run** is Base Integrity (see §5).

---

## 4. Economy (Locked for Exploration)

### 4.1 Single currency: Scrap

| Use | When | Notes |
|-----|------|--------|
| Build conduits | Build phase + limited mid-wave (see below) | Per-tile cost |
| Build / sell towers | Build phase; sell anytime with refund rules | |
| Between-wave upgrades | Between waves only | Linear tiers |
| Repair structural wear | Between waves | Default mode |

**No second “build points” pool.** Earlier “build points” language is retired.

### 4.2 Income (direction)

| Source | Scrap |
|--------|--------|
| Wave clear bonus | Primary reliable income |
| Enemy kills | Small per kill (saboteurs worth more) |
| Efficiency bonus | Optional: end wave under 70% average load → small bonus |
| Leak penalty | Enemies that reach the base reduce clear bonus |

**Starting Scrap (MVP maps):** 120  
**Sell refund:** 70% between waves; 50% during waves (discourages panic thrash without forbidding fixes).

### 4.3 Mid-wave building

| Action | Mid-wave? |
|--------|-----------|
| Place / upgrade towers | Yes (full cost) |
| Paint new conduits | Yes, but **slower paint** or **+25% cost** during waves (explore in prototype) |
| Sell / manual cut | Yes |
| Between-wave upgrades | No |
| Beam re-aim | Between waves only (MVP) |

---

## 5. Win / Lose Conditions

### 5.1 Primary lose condition — Base Integrity

- Base starts at **20 Integrity** (tunable).  
- Each enemy that completes the lane deals Integrity damage by type.  
- At **0** → defeat.

**Why primary:** Clear, classic, mobile-friendly. Players always know why they lost.

### 5.2 Core crisis (secondary, severe)

The Core is not a second HP bar that ends the run by default.

| Event | Effect (default exploration mode) |
|-------|-------------------------------------|
| Grid Worm reaches Core *(post-MVP enemy)* | Large **repairable** wear + temporary hard brownout |
| Hard overload for extended time | Accelerated heat → wear at wave end |
| Total grid blackout | Towers dark; base becomes fragile (enemies effectively freer) |

**Hard / Endless modifiers (later):** unrepaired wear becomes **permanent Max Power loss** (old structural wear rule).

### 5.3 Win

Survive the map’s wave list (MVP: short set, e.g. 8–12 waves) with Integrity > 0.

---

## 6. Power System

### 6.1 Power Core & load (tuning direction)

| Parameter | Value | Notes |
|-----------|-------|--------|
| Starting Max Power | 100 | |
| Soft Overload | 80% load | Heat rises faster; UI warns |
| Hard Overload | 100%+ load | Rapid heat; instability VFX/SFX |
| Heat while loaded | directionally ~0.4/s base | Multipliers when soft/hard |
| Heat recovery | when load < 60% | Between spikes / after rationing |
| Wave-end wear | portion of remaining heat → **Repairable Wear** | Shown as “Core stress: −X max until repaired” |
| Repair cost | Scrap proportional to wear | Between waves |
| Minimum Max Power floor | 40 | Even if player ignores repairs (softened) |
| Permanent loss | **Off in default**; on in Hard/Endless | Former 15% rule lives here |

**Design intent:** Overload should feel like *debt you must pay*, not a silent run-ruiner after one mistake.

### 6.2 Physical conduits (v0)

| Type | Scrap / tile | Loss / tile | HP | Special |
|------|--------------|------------|-----|---------|
| Standard | 8 | 2 | 40 | Default |
| Reinforced | 15 | 4 | 90 | Longer Saboteur cut |
| High-Voltage | 22 | 0.5 | 55 | Efficient; higher Saboteur priority |

**v0 rules:**

- **Orthogonal only** (N/S/E/W). Diagonal routing = post-MVP quality-of-life.  
- Severed conduit → downstream fade-out ≈ **1.2s**, then dark.  
- Parallel paths → automatic failover ≈ **0.4–0.8s**.  
- Conduits occupy buildable tiles (or a dedicated cable layer on path-adjacent cells — pick one in prototype; prefer **shared cell layer with tower-or-cable exclusivity** for clarity).

### 6.3 Wireless relays (post–first playable)

| Type | Scrap | HP | Range | Throughput | Loss | Notes |
|------|-------|-----|-------|------------|------|--------|
| Omni Relay | 26 | 50 | 3.8 r | 42 | 10% flat | Unlock mid tutorial or map 2 |
| Beam Relay | 32 | 55 | 6.0 beam | 60 | 6% flat | 16-way snap; **re-aim between waves only** in MVP |

**Rules:**

- Need power from physical link or another relay.  
- Max **2** wireless hops.  
- Caps: Omni ×4, Beam ×3 (per map).  
- Ignored by Grid Worms (when Worms exist).  
- EMP disables relays hard (when EMP exists).  

**Intent:** Gap tools and Worm breaks — not a full replacement for the backbone. On 8×8, early strong relays can **delete** routing strategy; keep them gated.

---

## 7. Towers

All towers need a valid powered connection.  
**Board caps (MVP):** ~10 towers total; e.g. Capacitor ×2, others ×3.

### 7.1 Capacitor

- **Role:** Storage + burst  
- **Cost:** 35 | **Draw:** 3 idle / 6 firing  
- **Combat:** DMG 18 · RoF 1.1/s · Range 3.5  
- **Special:** Store excess (cap 60). Burst 2.5× for 3s. Charged state absorbs limited EMP (later).  

### 7.2 Transformer

- **Role:** Network surgery / control  
- **Cost:** 28 | **Draw:** 4  
- **Combat:** DMG 12 · RoF 1.4/s · Range 3  
- **Special:** Valve (cut downstream). Emergency Sever (cooldown) — critical once Worms exist; still useful for isolating damaged branches.  

### 7.3 Regulator

- **Role:** Protect + restore  
- **Cost:** 32 | **Draw:** 5  
- **Combat:** DMG 9 · RoF 1.6/s · Range 2.5  
- **Special:** 2 charges / wave. Fortify conduits; instant re-route / temp bypass. EMP (later) strips charges.  

### 7.4 Drainer

- **Role:** High-risk DPS  
- **Cost:** 40 | **Draw:** 8 normal / 18 spike  
- **Combat:** 22 / 48 spike · RoF 0.9/s · Range 4  
- **Special:** Spike mode starves downstream; attracts Saboteurs; strong vs sabotage while spiking.  

*Combat numbers are placeholders; roles are not.*

---

## 8. Enemies

### 8.1 Lane fillers (required even in first playable)

Without these, the game is only a sabotage puzzle.

| Enemy | Role | Notes |
|-------|------|--------|
| Scrap Grunt | Baseline HP sponge | Teaches coverage |
| Swarm Mite | High count, low HP | Rewards not over-investing single target only |
| Plated Brute | Armored, slow | Burst / focus fire |
| Runner | Fast, low HP | Punishes gaps and dark towers |

Exact stats TBD in prototype.

### 8.2 Saboteur (first sabotage type — vertical slice)

- HP 70 · medium speed  
- Prefers high-flow / high-downstream-value conduits  
- 1.5s cut channel (loud telegraph); vulnerable while channeling  
- 40% chance to attempt a second cut  
- Elite later: cascade under high load  

### 8.3 EMP Unit (post-slice)

- HP 55 · pulse ~every 4s · radius ~2.75  
- Towers → ~35% effective power ~3s; Regulator −1 charge  
- Prefers high-draw clusters  

### 8.4 Grid Worm (post-slice)

- HP 95 · faster on conduits  
- Travels network toward Core; drains power while latched  
- Eject by severing occupied segment (stun on eject)  
- Reaching Core → heavy **repairable** wear (+ Hard mode permanent option)  
- Reduced damage while latched  
- Ignores pure wireless hops  

### 8.5 Counters

| Threat | Primary | Secondary |
|--------|---------|-----------|
| Saboteur | Regulator, Reinforced, focus during channel | Parallel paths, Capacitor burst |
| EMP | Spacing, Capacitor absorb, kill priority | Charge discipline |
| Worm | Transformer sever/valve, manual cut, sacrificial spur | Drainer on latch, wireless jump |

### 8.6 Optional assists (not required mastery)

- **Priority mark** — one focus target  
- **Power rationing** — lower available output: less load stress / less Saboteur attraction; weaker towers  
- **Manual segment cut** — limited uses or cooldown  

On mobile, generous pause / between-event breather is preferred over demanding perfect mid-wave surgery.

---

## 9. Upgrades (Between Waves)

Paid in **Scrap**. Linear. No refunds.

### 9.1 MVP: two tiers per path

Ship depth via systems first; full 4-tier trees are the design target, not the first build.

**Regulator**  
1. Extra charge (+1) — 45  
2. Fast re-route (0.8s) — 60  

**Transformer**  
1. Quick valve — 40  
2. Surgical cut (CDR + better Worm stun later) — 55  

**Conduits & routing (global)**  
1. Reinforced protocols — 50  
2. Failover systems — 65  

**Capacitor**  
1. Surge buffer — 45  
2. Stabilized discharge — 60  

**Drainer**  
1. Predator protocols — 50  
2. Controlled vortex — 65  

**Core resilience (pick 1–2 for MVP)**  
- Structural reinforcement (cheaper/faster wear repair) — ~60  
- Load masking (soft overload starts later) — ~70  

### 9.2 Full target trees (post-MVP)

Keep previous 4-step paths (Extended Coverage, Network Override, Smart Insulation, Redundant Mesh, Grid Anchor, Execution Mode, Worm Deterrent, etc.) as the long-term roadmap.

---

## 10. Feedback & Visual Language (First-Class Design)

If players cannot **see** grid state, the fantasy fails. Treat this as systems design, not polish.

| State | Visual | Audio |
|-------|--------|--------|
| Healthy flow | Soft pulse along conduits; thickness ∝ throughput | Low grid hum |
| High load (soft) | Pulse quickens; Core meter amber | Hum rises, slight strain |
| Hard overload | Harsh flicker; heat shimmer on Core | Alarm undertone |
| Tower dark | Tower dims, range ghost fades | Soft power-down tick |
| Conduit cut | Snap flash + gap; downstream fade | Sharp disconnect |
| Saboteur channel | Progress ring on segment | Drill / saw telegraph |
| EMP (later) | Radial static wash | Discharge crack |
| Worm latch (later) | Moving bulge on cable toward Core | Wet-metallic crawl |
| Wear pending | Core meter shows “stress debt” between waves | Cooling hiss on repair |

**UI always-on:** Core load %, heat/wear summary, Scrap.  
**Inspector:** one-tap / click “why is this dark?”  
**Color-blind safe:** never rely on red/green alone (shape + pulse rate).

---

## 11. Board Philosophy (8×8)

### 11.1 Why 8×8 stays

- Fully visible on mobile (minimal pan mid-crisis).  
- Strategy lives in **topology + load**, not acreage.  
- Matches ~10 tower cap and diorama art reuse.  

### 11.2 What actually matters

Not “64 cells,” but:

- **Buildable mask** (blocked scenery, prebuilt spine, dead ground)  
- **Core placement** relative to the kill zone (distance must cost)  
- **Path length / approaches**  
- Whether relays can trivially jump the puzzle  

### 11.3 Expansion rule

If maps feel samey → add **masks and modifiers**, not an immediate jump to 12×12.  
Later: mix tight puzzle maps with occasional larger sieges.

**Cell legend (all maps below):**

```
C = Power Core (fixed)
B = Base / lane exit (Integrity sink)
> ^ v < = enemy path step (arrows show direction)
. = buildable empty
# = blocked / scenery (no build, no path)
= = prebuilt industrial conduit (optional; player may reinforce/replace rules TBD)
~ = hazardous ground (buildable at +cost or reduced HP — optional experiment)
P = enemy spawn (lane entrance)
```

Coordinates: **row 0 top → row 7 bottom**, **col 0 left → col 7 right** (row, col).

---

## 12. Map Layouts (Exploration)

Three maps on the **same 8×8 logic grid**, different strategic questions. Use for paper play, whiteboarding, and first greybox.

---

### Map A — “Spine District” (Tutorial / default)

**Teaching goal:** Power must travel; short greedy cables near the path are fragile; one backbone is both efficient and a single point of failure.

**Strategic question:** *Spine along the path vs inland backbone with branches?*

**Layout notes:**

- Core at back-left; base at mid-right exit.  
- Long U-path creates a natural kill corridor on rows 2–5.  
- Blocked pillars force conduits around, not through, center clutter.  
- Ideal first killbox is **not** adjacent to Core — expect ~4–6 cable tiles of real routing.

```
    0 1 2 3 4 5 6 7
0   # # . . . . # #
1   # C . . . . . #
2   P > > > > v . #
3   . . # . . v . .
4   . . # . . v . B
5   . . . < < < . .
6   # . . . . . . #
7   # # . . . . # #
```

**Path sequence (spawn → base):**  
`(2,0)→(2,1)→(2,2)→(2,3)→(2,4)→(2,5)→(3,5)→(4,5)→(5,5)→(5,4)→(5,3)→(5,2)→(5,1)→…`  

*Correction for a clean continuous path — canonical Spine path:*

```
    0 1 2 3 4 5 6 7
0   # # . . . . # #
1   # C . . . . . #
2   P > > > > > v #
3   . . # # . . v .
4   . . # # . . v B
5   . . . . < < < .
6   # . . . . . . #
7   # # . . . . # #
```

**Canonical path:**  
`P(2,0) → (2,1)→(2,2)→(2,3)→(2,4)→(2,5)→(2,6)→(3,6)→(4,6)→B(4,7)`  
with return arm optional for longer maps; for MVP use the **single approach** above (spawn west, exit east).

**Simplified Spine (recommended for v0 greybox):**

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

- Path length 8 cells on row 3 — classic readable lane.  
- Core at (1,1): inland builds need vertical feeders.  
- Bottom `#` block creates a “south yard” vs “north yard” choice (split coverage).  
- Saboteurs on a single feeder from C→lane punish one-cable greed.

**Buildable count:** high (~45). Good for learning.  
**First playable map:** yes.

**Intended competing builds:**

1. North rail of towers with conduit along row 2.  
2. South rail along row 4–5 with longer Core feed.  
3. Split north/south with Transformer junction near (2,1)–(3,1).  

---

### Map B — “Split Yards” (Redundancy exam)

**Teaching goal:** Parallel paths and failover; one cut should not darken everything if you paid for redundancy.

**Strategic question:** *One fat HV spine or two weaker parallel feeds?*

```
    0 1 2 3 4 5 6 7
0   P > > v . . . #
1   # # # v . C . #
2   . . . v . . . .
3   . . . > > > v .
4   . . . # # # v .
5   . . . . . . v B
6   # . . . . . . #
7   # # . . . . # #
```

**Path:**  
`(0,0)→(0,1)→(0,2)→(0,3)→(1,3)→(2,3)→(3,3)→(3,4)→(3,5)→(3,6)→(4,6)→(5,6)→B(5,7)`

**Features:**

- Core at **(1,5)** — east pocket, near late path but separated by geometry.  
- Upper blocked wall `(1,0)–(1,2)` forces early path downward; creates a **west dead zone** that is awkward to power (long cable or later Omni).  
- Mid `#` band `(4,3)–(4,5)` splits board into **upper pocket** (near Core) and **lower approach** (near Base).  
- Natural dual-yard: defend turn at (3,3) and final corridor col 6.

**Pressure pattern:**

- Saboteurs love the single choke feed into the upper pocket.  
- Parallel conduits: Core → south around the mid wall vs Core → west long way.  

**Buildable count:** medium.  
**When to use:** after Spine; first map that grades redundancy.

**Intended competing builds:**

1. Short HV drop from Core into col 6 kill lane (efficient, fragile).  
2. Loop around mid wall with Reinforced + failover upgrade.  
3. Leave west yard empty early (power budget) vs force-extend for crossfire.  

---

### Map C — “Broken Ring” (Distance & sacrifice)

**Teaching goal:** Core is far from the best DPS seats; sacrificial spurs and Transformer valves matter; prebuilt spine is a temptation.

**Strategic question:** *Use the free industrial spine (exposed) or self-build a safer inland ring?*

```
    0 1 2 3 4 5 6 7
0   # P > > > > v #
1   # . . . . . v #
2   # . C = = = v #
3   # . . . . # v #
4   # . . # . # v #
5   # . . # . . v #
6   # . . = = = > B
7   # # # # # # # #
```

**Path:**  
`P(0,1)→(0,2)→(0,3)→(0,4)→(0,5)→(0,6)→(1,6)→(2,6)→(3,6)→(4,6)→(5,6)→(6,6)→B(6,7)`

**Prebuilt conduit `=`:**  
`(2,3)(2,4)(2,5)` and `(6,3)(6,4)(6,5)` — a broken industrial ring stub. Rules for exploration:

- Prebuilt segments are **Standard** HP, **already paid**.  
- Player may **upgrade in place** to Reinforced/HV for Scrap.  
- Grid Worms (later) **love** prebuilt spines.  
- Saboteurs path-value these if they feed many towers.

**Features:**

- Core **(2,2)** centered-left; best tower seats along **col 5–6** are several tiles of cable away.  
- Interior `#` at `(3,5)(4,3)(4,5)(5,3)` create a maze for routing — forces corners and junctions (Transformer heaven).  
- Bottom row mostly rim wall — board reads as a contained diorama.  

**Buildable count:** lower / more puzzle-like.  
**When to use:** map 3 or challenge variant; optional first Worm showcase later.

**Intended competing builds:**

1. Adopt prebuilt `=` and branch to the lane (fast economy, high sabotage value).  
2. Ignore prebuilt; inland private grid with longer loss but quieter threat profile.  
3. Hybrid: use north `=` as sacrificial spur (Worm/Saboteur bait) + real feed south.  

---

## 13. Map Comparison

| | Spine District | Split Yards | Broken Ring |
|--|----------------|-------------|-------------|
| Role | Tutorial / default | Redundancy | Puzzle / temptation |
| Routing distance | Medium | Medium–long to west | Long to kill lane |
| Single-point failure risk | High if greedy | Medium | High if using prebuilt |
| Crossfire geometry | North/south of lane | Turn + final corridor | Vertical lane on col 6 |
| Relay need | Low | Medium (west dead zone) | Medium–high (maze gaps) |
| First playable? | **Yes** | Second | Third / challenge |
| Best teaches | Feeders + load | Parallel / failover | Distance cost + sacrifice |

**Exploration metric:** After 10 runs on one map, do skilled players still disagree about branching, HV vs Reinforced, and load budget? If everyone clones one blueprint, change the **mask**, not only the stats.

---

## 14. Tutorial Wave Flow (Revised)

| Wave | Focus | New element |
|------|--------|-------------|
| 0 | Core, orthogonal conduit, towers need power | Practice Grunts |
| 1 | Shared pool, efficient routing | Multiple towers + Swarm |
| 2 | Conduits can die | **Saboteur** + Regulator |
| 3 | Load / soft overload telegraphs | Brutes + heat UI emphasis |
| 4 | Between-wave upgrades + repair wear | Upgrade panel (2-tier) |
| 5 | Combined pressure | Runners + Saboteurs together |
| 6+ | Training wheels off | Map-specific scripts |

**EMP:** introduce on Map B or later waves of Map A after slice is fun.  
**Worm:** introduce on Map C or a dedicated lab wave.  

Prompts: short, contextual, dismissible. Critical moments use the feedback table in §10.

---

## 15. Art Direction

- Reject pure “neon lines on black” (overused in mobile TD).  
- Lean: **isometric diorama** — chunky, readable, reusable stage, mobile-safe.  
- Energy readable without generic cyber-neon (heat shimmer, particulate dust, warm copper vs cold stressed steel).  
- Audio identity is a pillar: grid hum, cut snap, overload strain.  
- Alternate mood (painterly cyber-city) shelved for cost reasons unless team grows.

---

## 16. Vertical Slice / Prototype Order

**Goal of slice:** *Is drawing power and surviving Saboteurs on Spine District actually fun?*

### In slice

1. 8×8 Spine map (simplified)  
2. Core + Scrap economy + Base Integrity  
3. Orthogonal Standard conduits (Reinforced optional)  
4. All 4 towers (caps enforced)  
5. Lane fillers + **Saboteur only**  
6. Load meter + dark towers + cut feedback  
7. Repairable wear only (no permanent loss)  
8. 2-tier upgrades (subset)  
9. PC + mobile basic: tap/click place, drag pan if needed, large buttons  

### Out of slice

- Diagonal conduits  
- Omni / Beam relays  
- EMP, Grid Worm  
- Mid-wave beam aim  
- Permanent Max Power loss  
- Full 4-tier trees  
- Meta progression / endless  

### Exit criteria (exploration → commit)

- New players understand “towers need cable” within wave 0–1 without a wall of text.  
- At least two **viable** Spine openers (not one solved graph).  
- Saboteur cuts feel dramatic and **readable**, not random.  
- Overload/heat feels like a decision, not fog.  
- Session length ~10–15 minutes for a short wave list.  

If slice fails, fix routing feel / feedback before adding Worms or larger boards.

---

## 17. Open Threads

**High priority**

- [ ] Paper-play or greybox all three maps  
- [ ] Choose cable layer model (exclusive cell vs underlay)  
- [ ] Finalise mid-wave conduit cost modifier  
- [ ] Visual prototype of flow / cut / dark  

**Medium**

- [ ] Omni unlock timing (Map B vs upgrade gate)  
- [ ] Whether prebuilt `=` can be deleted for Scrap refund  
- [ ] Priority mark + rationing: start enabled or in settings  

**Later**

- [ ] Core variants (high cap / fast stress vs low cap / stable)  
- [ ] Extra relay types  
- [ ] Hard mode permanent wear  
- [ ] Endless mutators  
- [ ] Occasional >8×8 siege maps  

---

## 18. Non-Commit Checklist

Use before greenlighting production:

| Question | Good answer looks like |
|----------|------------------------|
| What’s the game? | Infrastructure TD — power grid under siege |
| Why 8×8? | Readable network density; depth in topology |
| How do I spend/earn? | One currency: Scrap |
| How do I lose? | Base Integrity → 0 |
| What’s the first fun test? | Spine + conduits + Saboteur |
| What’s deliberately later? | Worms, EMP, relays, permanent decay, diagonals |

---

## 19. Paper Play (Current Exploration Step)

Desk kit for Map A without an engine:

→ **`Paper_Play_Spine_District.md`**

Includes simplified rules, wave 0–8 script, three opening recipes (North / South / Split), Fast Mode, and a playtest log. Run smoke tests (waves 0–3) before a full campaign or greybox.

---

*End of exploration draft. Current step: paper-play Spine District; greybox only after the fun bar clears.*
