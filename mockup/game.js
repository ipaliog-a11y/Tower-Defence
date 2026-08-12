/**
 * Grid & Decay — 10×10 mockup
 * Powerlines attach between Core / towers (no cable cells).
 * Wireless links bridge across the road.
 */
(() => {
  "use strict";

  const SIZE = 10;
  const CORE = { r: 0, c: 2 };
  const MAX_INTEGRITY = 10;
  const START_SCRAP = 140;
  const PRESET_LEFTOVER_SCRAP = 75;

  const ENEMY_MOVE_SPEED = 0.62; // slightly slower — path is much longer
  const SPAWN_INTERVAL = 0.55;

  /**
   * Winding path around central factory + rocks (~26 steps).
   * Orthogonal only; never enters BLOCKED cells.
   *
   *   P→→→→→→→┐
   *           ↓
   *     ##    ↓   (central mass)
   *     ##  ←←↓
   *         ↓
   *   ##    ↓     (SW rocks)
   *         →→→→→→B
   */
  const PATH = [
    // north run (spawn west → east)
    [1, 0], [1, 1], [1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [1, 7],
    // down east corridor
    [2, 7], [3, 7], [4, 7], [5, 7], [6, 7],
    // under / past central mass westward
    [6, 6], [6, 5], [6, 4], [6, 3], [6, 2],
    // south dogleg around SW rocks
    [7, 2], [8, 2], [8, 3], [8, 4], [8, 5], [8, 6], [8, 7], [8, 8], [8, 9],
  ];
  const PATH_SET = new Set(PATH.map(([r, c]) => key(r, c)));

  // Scenery the path bends around
  const BLOCKED = new Set([
    // corners
    key(0, 0), key(0, 9), key(9, 0), key(9, 9),
    // central factory (path goes east then under south of it)
    key(3, 3), key(3, 4), key(3, 5),
    key(4, 3), key(4, 4), key(4, 5),
    key(5, 3), key(5, 4), key(5, 5),
    // SW rock mass (path uses col 2 then east on row 8)
    key(7, 0), key(7, 1),
    key(8, 0), key(8, 1),
    key(9, 1), key(9, 2),
    // NE clutter
    key(0, 6), key(0, 7), key(0, 8),
    key(2, 8), key(2, 9),
  ]);

  const COSTS = {
    link: 10,
    wireless: 22,
    capacitor: 35,
    transformer: 28,
    regulator: 32,
    drainer: 40,
  };

  const LINK_RANGE = 2; // standard powerline (chebyshev), land-connected only
  const WIRELESS_RANGE = 4; // can bridge across path / gaps
  const WIRELESS_MAX = 4;
  const LINK_DRAW = 1;
  const WIRELESS_DRAW = 3;

  const TOWER_STATS = {
    capacitor: {
      name: "Capacitor", short: "Ca", drawIdle: 3, drawFire: 6, range: 2, dmg: 8, burst: 22, color: "#61afef",
      role: "Baseline single-target DPS. Burst (B) once per wave.",
    },
    transformer: {
      name: "Transformer", short: "Tf", drawIdle: 4, drawFire: 4, range: 2, dmg: 5, color: "#c678dd",
      role: "Low damage; network control tools later.",
    },
    regulator: {
      name: "Regulator", short: "Rg", drawIdle: 5, drawFire: 5, range: 2, dmg: 4, color: "#98c379",
      role: "Weak shots. Enables Fortify (F) on power links.",
    },
    drainer: {
      name: "Drainer", short: "Dr", drawIdle: 8, drawFire: 10, range: 3, dmg: 11, spikeDmg: 20, spikeDraw: 18, color: "#e06c75",
      role: "Highest DPS. Spike (V) = more damage + load.",
    },
  };

  const ENEMY_DEFS = {
    grunt: { name: "Grunt", hp: 72, speed: 1, leak: 1, scrap: 4, color: "#e5c07b", r: 9 },
    mite: { name: "Mite", hp: 38, speed: 1.1, leak: 1, scrap: 3, color: "#98c379", r: 7 },
    brute: { name: "Brute", hp: 130, speed: 0.85, leak: 2, scrap: 7, color: "#be5046", r: 12, armor: 5 },
    runner: { name: "Runner", hp: 48, speed: 2.15, leak: 1, scrap: 5, color: "#56b6c2", r: 8 },
    saboteur: { name: "Saboteur", hp: 95, speed: 1, leak: 2, scrap: 10, color: "#ff6b4a", r: 10, saboteur: true },
  };

  const WAVES = [
    ["grunt", "grunt", "grunt"],
    ["grunt", "grunt", "grunt", "mite", "grunt"],
    ["grunt", "grunt", "saboteur", "grunt", "grunt", "mite"],
    ["brute", "grunt", "grunt", "brute", "mite", "grunt"],
    ["grunt", "runner", "saboteur", "runner", "grunt", "grunt", "mite"],
    ["mite", "brute", "saboteur", "brute", "grunt", "mite"],
    ["runner", "runner", "runner", "grunt", "saboteur", "runner", "grunt"],
    ["brute", "brute", "runner", "grunt", "brute", "runner", "grunt"],
    ["saboteur", "grunt", "brute", "saboteur", "runner", "brute", "grunt", "runner", "mite"],
  ];

  function key(r, c) {
    return r + "," + c;
  }

  function parseKey(k) {
    const [r, c] = k.split(",").map(Number);
    return { r, c };
  }

  function inBounds(r, c) {
    return r >= 0 && r < SIZE && c >= 0 && c < SIZE;
  }

  function isYard(r, c) {
    if (!inBounds(r, c)) return false;
    if (r === CORE.r && c === CORE.c) return false;
    if (PATH_SET.has(key(r, c))) return false;
    if (BLOCKED.has(key(r, c))) return false;
    return true;
  }

  function chebyshev(r1, c1, r2, c2) {
    return Math.max(Math.abs(r1 - r2), Math.abs(c1 - c2));
  }

  function neighbors4(r, c) {
    return [
      [r - 1, c],
      [r + 1, c],
      [r, c - 1],
      [r, c + 1],
    ].filter(([nr, nc]) => inBounds(nr, nc));
  }

  function nodeKey(node) {
    if (node === "core") return "core";
    return node; // tower cell key
  }

  /** Cells walkable for "same landmass" (not path, not blocked). Core counts as land. */
  function isLandCell(r, c) {
    if (!inBounds(r, c)) return false;
    if (PATH_SET.has(key(r, c))) return false;
    if (BLOCKED.has(key(r, c))) return false;
    return true;
  }

  /**
   * True if two land cells connect without crossing the enemy path
   * (BFS around scenery). Used to decide if a normal powerline is legal.
   */
  function sameLandmass(r1, c1, r2, c2) {
    if (!isLandCell(r1, c1) || !isLandCell(r2, c2)) return false;
    if (r1 === r2 && c1 === c2) return true;
    const start = key(r1, c1);
    const goal = key(r2, c2);
    const seen = new Set([start]);
    const q = [start];
    while (q.length) {
      const k = q.shift();
      if (k === goal) return true;
      const { r, c } = parseKey(k);
      for (const [nr, nc] of neighbors4(r, c)) {
        if (!isLandCell(nr, nc)) continue;
        const nk = key(nr, nc);
        if (seen.has(nk)) continue;
        seen.add(nk);
        q.push(nk);
      }
    }
    return false;
  }

  function linkId(a, b) {
    const ka = nodeKey(a);
    const kb = nodeKey(b);
    return ka < kb ? ka + "|" + kb : kb + "|" + ka;
  }

  function nodePos(node) {
    if (node === "core") return { r: CORE.r, c: CORE.c };
    return parseKey(node);
  }

  // ——— State ———
  const state = {
    scrap: START_SCRAP,
    maxPower: 100,
    heat: 0,
    integrity: MAX_INTEGRITY,
    waveIndex: 0,
    phase: "build",
    towers: new Map(), // cellKey -> { type, firedThisWave, firedRecently }
    links: new Map(), // linkId -> { a, b, wireless, fortified, cuts }
    sellMode: false,
    tool: "capacitor",
    linkFrom: null, // first node for manual link
    fortifyArmed: false,
    enemies: [],
    spawnQueue: [],
    spawnTimer: 0,
    simSpeed: 1,
    burstUsed: false,
    spikeOn: false,
    fortifyCharges: 2,
    waveLeak: 0,
    fx: [],
    lastHits: [],
    channelTick: 0,
    hover: null,
    animT: 0,
  };

  const canvas = document.getElementById("board");
  const ctx = canvas.getContext("2d");
  const logEl = document.getElementById("log");
  const toastEl = document.getElementById("toast");
  const overlay = document.getElementById("overlay");
  const overlayCard = document.getElementById("overlay-card");
  const memoEl = document.getElementById("memo");

  const tools = [
    { id: "link", label: "Powerline", cost: COSTS.link, hotkey: "1", hint: "Click Core/tower, then another" },
    { id: "wireless", label: "Wireless", cost: COSTS.wireless, hotkey: "2", hint: "Crosses the road" },
    { id: "capacitor", label: "Capacitor", cost: COSTS.capacitor, hotkey: "3" },
    { id: "transformer", label: "Transformer", cost: COSTS.transformer, hotkey: "4" },
    { id: "regulator", label: "Regulator", cost: COSTS.regulator, hotkey: "5" },
    { id: "drainer", label: "Drainer", cost: COSTS.drainer, hotkey: "6" },
  ];

  function log(msg, cls = "") {
    const div = document.createElement("div");
    if (cls) div.className = cls;
    div.textContent = msg;
    logEl.prepend(div);
    while (logEl.children.length > 50) logEl.removeChild(logEl.lastChild);
  }

  let toastTimer = null;
  function toast(msg) {
    toastEl.textContent = msg;
    toastEl.classList.remove("hidden");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toastEl.classList.add("hidden"), 1700);
  }

  function showOverlay(title, body, buttons) {
    overlay.classList.remove("hidden");
    overlayCard.innerHTML = "";
    const h = document.createElement("h3");
    h.textContent = title;
    const p = document.createElement("p");
    p.textContent = body;
    overlayCard.appendChild(h);
    overlayCard.appendChild(p);
    const row = document.createElement("div");
    row.className = "row-btns";
    for (const b of buttons) {
      const btn = document.createElement("button");
      btn.className = "btn " + (b.primary ? "primary" : "");
      btn.textContent = b.label;
      btn.onclick = () => {
        overlay.classList.add("hidden");
        b.onClick();
      };
      row.appendChild(btn);
    }
    overlayCard.appendChild(row);
  }

  function hideOverlay() {
    overlay.classList.add("hidden");
  }

  // ——— Power graph ———
  function isNode(node) {
    if (node === "core") return true;
    return state.towers.has(node);
  }

  function countWireless() {
    let n = 0;
    for (const L of state.links.values()) if (L.wireless) n++;
    return n;
  }

  function canLink(a, b, wireless) {
    if (a === b) return { ok: false, reason: "Same node" };
    if (!isNode(a) || !isNode(b)) return { ok: false, reason: "Need Core or towers" };
    const pa = nodePos(a);
    const pb = nodePos(b);
    const dist = chebyshev(pa.r, pa.c, pb.r, pb.c);
    const range = wireless ? WIRELESS_RANGE : LINK_RANGE;
    if (dist < 1) return { ok: false, reason: "Too close" };
    if (dist > range) return { ok: false, reason: `Out of range (max ${range})` };

    if (!wireless && !sameLandmass(pa.r, pa.c, pb.r, pb.c)) {
      return { ok: false, reason: "Path/scenery blocks land link — use Wireless" };
    }
    if (state.links.has(linkId(a, b))) return { ok: false, reason: "Already linked" };
    if (wireless && countWireless() >= WIRELESS_MAX) {
      return { ok: false, reason: `Max ${WIRELESS_MAX} wireless` };
    }
    return { ok: true, dist };
  }

  function poweredNodes() {
    const powered = new Set(["core"]);
    const q = ["core"];
    while (q.length) {
      const cur = q.shift();
      for (const L of state.links.values()) {
        let other = null;
        if (nodeKey(L.a) === cur) other = nodeKey(L.b);
        else if (nodeKey(L.b) === cur) other = nodeKey(L.a);
        if (!other || powered.has(other)) continue;
        if (!isNode(other)) continue;
        powered.add(other);
        q.push(other);
      }
    }
    return powered;
  }

  function isTowerPowered(cellKey, powered) {
    return powered.has(cellKey);
  }

  function linkTax() {
    let t = 0;
    for (const L of state.links.values()) {
      t += L.wireless ? WIRELESS_DRAW : LINK_DRAW;
    }
    return t;
  }

  function computeLoad(useFire) {
    const powered = poweredNodes();
    let draw = 0;
    let poweredTowers = 0;
    for (const [k, t] of state.towers) {
      if (!powered.has(k)) continue;
      poweredTowers++;
      const st = TOWER_STATS[t.type];
      if (useFire || t.firedThisWave || (state.phase === "combat" && t.firedRecently)) {
        draw += t.type === "drainer" && state.spikeOn ? st.spikeDraw : st.drawFire;
      } else {
        draw += st.drawIdle;
      }
    }
    const tax = linkTax();
    draw += tax;
    return { draw, max: state.maxPower, poweredTowers, powered, tax };
  }

  // ——— Build / links ———
  function addLink(a, b, wireless, free) {
    const check = canLink(a, b, wireless);
    if (!check.ok) {
      if (!free) toast(check.reason);
      return false;
    }
    const cost = free ? 0 : wireless ? COSTS.wireless : COSTS.link;
    if (!free && state.scrap < cost) {
      toast("Not enough Scrap");
      return false;
    }
    if (!free) state.scrap -= cost;
    const id = linkId(a, b);
    state.links.set(id, {
      a: nodeKey(a),
      b: nodeKey(b),
      wireless: !!wireless,
      fortified: false,
      cuts: 0,
    });
    if (!free) {
      log(`${wireless ? "Wireless" : "Powerline"} ${nodeKey(a)} ↔ ${nodeKey(b)}`, "good");
      toast(wireless ? "Wireless bridge set" : "Powerline attached");
    }
    return true;
  }

  function autoLinkTower(cellKey, free) {
    const powered = poweredNodes();
    // Prefer standard link to nearest powered node same side; else wireless
    let bestStd = null;
    let bestW = null;
    const candidates = ["core", ...state.towers.keys()].filter((n) => n !== cellKey);

    for (const n of candidates) {
      if (!powered.has(nodeKey(n)) && n !== "core") continue;
      // core always "powered"
      const pStd = canLink(cellKey, n, false);
      if (pStd.ok) {
        if (!bestStd || pStd.dist < bestStd.dist) bestStd = { n, dist: pStd.dist };
      }
      const pW = canLink(cellKey, n, true);
      if (pW.ok) {
        if (!bestW || pW.dist < bestW.dist) bestW = { n, dist: pW.dist };
      }
    }

    // If free (preset), ignore scrap
    if (bestStd) {
      return addLink(cellKey, bestStd.n, false, free);
    }
    if (bestW) {
      return addLink(cellKey, bestW.n, true, free);
    }
    return false;
  }

  function placeTower(r, c, type, free) {
    if (!isYard(r, c)) {
      if (!free) toast(PATH_SET.has(key(r, c)) ? "Not on the road" : "Can't build here");
      return false;
    }
    const k = key(r, c);
    if (state.towers.has(k)) {
      if (!free) toast("Tower here already");
      return false;
    }
    if (state.towers.size >= 12) {
      if (!free) toast("Tower cap (12)");
      return false;
    }
    const cost = free ? 0 : COSTS[type];
    if (!free && state.scrap < cost) {
      toast("Not enough Scrap");
      return false;
    }
    if (!free) state.scrap -= cost;
    state.towers.set(k, { type, firedThisWave: false, firedRecently: false });
    if (!free) log(`Built ${TOWER_STATS[type].name} at ${k}`);

    const linked = autoLinkTower(k, free);
    if (!linked && !free) {
      toast("Tower dark — link it to the grid (Powerline / Wireless)");
      log(`Tower at ${k} has no powerline yet`, "warn");
    }
    return true;
  }

  function pickNodeAt(r, c) {
    if (r === CORE.r && c === CORE.c) return "core";
    const k = key(r, c);
    if (state.towers.has(k)) return k;
    return null;
  }

  function handleLinkClick(r, c, wireless) {
    const node = pickNodeAt(r, c);
    if (!node) {
      toast("Click Core or a tower");
      return;
    }
    if (!state.linkFrom) {
      state.linkFrom = node;
      toast(wireless ? "Wireless: now click the other side" : "Powerline: now click target");
      updateUI();
      return;
    }
    if (state.linkFrom === node) {
      state.linkFrom = null;
      toast("Cancelled");
      updateUI();
      return;
    }
    addLink(state.linkFrom, node, wireless, false);
    state.linkFrom = null;
    updateUI();
  }

  function sellAt(r, c) {
    if (state.phase !== "build") {
      toast("Sell between waves");
      return;
    }
    const k = key(r, c);
    // sell tower + its links
    if (state.towers.has(k)) {
      const t = state.towers.get(k);
      let refund = COSTS[t.type];
      const remove = [];
      for (const [id, L] of state.links) {
        if (L.a === k || L.b === k) {
          refund += L.wireless ? COSTS.wireless : COSTS.link;
          remove.push(id);
        }
      }
      for (const id of remove) state.links.delete(id);
      state.towers.delete(k);
      refund = Math.floor(refund * 0.7);
      state.scrap += refund;
      log(`Sold tower + links for ${refund}`, "good");
      return;
    }
    toast("Click a tower to sell");
  }

  function fortifyNearestLink(r, c) {
    if (state.fortifyCharges <= 0) {
      toast("No fortify charges");
      return;
    }
    // fortify link incident to clicked tower/core, or nearest link
    const node = pickNodeAt(r, c);
    let best = null;
    for (const [id, L] of state.links) {
      if (L.fortified) continue;
      if (node && (L.a === node || L.b === node)) {
        best = id;
        break;
      }
    }
    if (!best && node) {
      // any unfortified
      for (const [id, L] of state.links) {
        if (!L.fortified) {
          best = id;
          break;
        }
      }
    }
    if (!best) {
      toast("No link to fortify — click a linked tower");
      return;
    }
    state.links.get(best).fortified = true;
    state.fortifyCharges--;
    state.fortifyArmed = false;
    log(`Fortified link ${best} (${state.fortifyCharges} left)`, "good");
    toast("Link fortified");
  }

  // ——— Presets ———
  function clearBoard() {
    state.towers.clear();
    state.links.clear();
    state.linkFrom = null;
  }

  function placeFreeTower(type, r, c) {
    return placeTower(r, c, type, true);
  }

  function applyPreset(name) {
    if (state.phase !== "build" && state.phase !== "won" && state.phase !== "lost") {
      toast("Only between waves");
      return;
    }
    resetRun(false);
    state.scrap = PRESET_LEFTOVER_SCRAP;

    if (name === "north") {
      // Early + east bend coverage (all land-linked)
      placeFreeTower("capacitor", 2, 2);
      placeFreeTower("transformer", 2, 4);
      placeFreeTower("regulator", 2, 6);
      placeFreeTower("drainer", 3, 6);
      addLink("core", key(2, 2), false, true);
      addLink(key(2, 2), key(2, 4), false, true);
      addLink(key(2, 4), key(2, 6), false, true);
      addLink(key(2, 6), key(3, 6), false, true);
      log("Preset: North rail — early winding segment", "good");
      toast("North rail + 75 scrap");
    } else if (name === "south") {
      // Chain to mid, wireless hop to late arm (row 7 past rocks)
      placeFreeTower("transformer", 2, 3);
      placeFreeTower("capacitor", 2, 6);
      placeFreeTower("drainer", 4, 6);
      placeFreeTower("regulator", 7, 6);
      addLink("core", key(2, 3), false, true);
      addLink(key(2, 3), key(2, 6), false, true);
      addLink(key(2, 6), key(4, 6), false, true);
      addLink(key(4, 6), key(7, 6), true, true);
      log("Preset: South rail — land to mid, wireless to late path", "good");
      toast("South rail + 75 scrap");
    } else if (name === "split") {
      placeFreeTower("capacitor", 2, 2);
      placeFreeTower("transformer", 2, 6);
      placeFreeTower("drainer", 4, 6);
      placeFreeTower("regulator", 7, 5);
      addLink("core", key(2, 2), false, true);
      addLink(key(2, 2), key(2, 6), false, true);
      addLink(key(2, 6), key(4, 6), false, true);
      addLink(key(4, 6), key(7, 5), true, true);
      log("Preset: Split — early/mid land + wireless late yard", "good");
      toast("Split feed + 75 scrap");
    }
    updateUI();
  }

  function resetRun(showMessage) {
    state.scrap = START_SCRAP;
    state.maxPower = 100;
    state.heat = 0;
    state.integrity = MAX_INTEGRITY;
    state.waveIndex = 0;
    state.phase = "build";
    state.enemies = [];
    state.spawnQueue = [];
    state.spawnTimer = 0;
    state.burstUsed = false;
    state.spikeOn = false;
    state.fortifyCharges = 2;
    state.fortifyArmed = false;
    state.waveLeak = 0;
    state.sellMode = false;
    state.linkFrom = null;
    state.fx = [];
    state.lastHits = [];
    clearBoard();
    if (showMessage) {
      logEl.innerHTML = "";
      log("—— New run —— 10×10 · powerlines on towers", "good");
      toast("Place towers — they auto-link when in range");
    }
    hideOverlay();
    updateUI();
  }

  // ——— Combat helpers ———
  function cellSize() {
    return canvas.width / SIZE;
  }

  function enemyWorldPos(e) {
    const s = cellSize();
    if (e.pathIndex >= PATH.length - 1) {
      const a = PATH[PATH.length - 1];
      return { x: a[1] * s + s / 2, y: a[0] * s + s / 2 };
    }
    const a = PATH[e.pathIndex];
    const b = PATH[Math.min(e.pathIndex + 1, PATH.length - 1)];
    const px = a[1] + (b[1] - a[1]) * e.progress;
    const py = a[0] + (b[0] - a[0]) * e.progress;
    return { x: px * s + s / 2, y: py * s + s / 2 };
  }

  function spawnHitFx(fromPos, toEnemy, dmg, color, towerName) {
    const s = cellSize();
    const to = enemyWorldPos(toEnemy);
    state.fx.push({
      kind: "beam",
      x0: fromPos.c * s + s / 2,
      y0: fromPos.r * s + s / 2,
      x1: to.x,
      y1: to.y,
      color,
      life: 0.22,
      max: 0.22,
    });
    state.fx.push({
      kind: "float",
      x: to.x + (Math.random() * 10 - 5),
      y: to.y - 8,
      text: `-${dmg}`,
      color,
      life: 0.65,
      max: 0.65,
    });
    state.fx.push({
      kind: "flash",
      r: fromPos.r,
      c: fromPos.c,
      color,
      life: 0.16,
      max: 0.16,
    });
    state.lastHits.unshift({ name: towerName, dmg, t: performance.now() });
    if (state.lastHits.length > 6) state.lastHits.pop();
  }

  function updateFx(dt) {
    for (const f of state.fx) f.life -= dt;
    state.fx = state.fx.filter((f) => f.life > 0);
  }

  function enemyCell(e) {
    const idx = Math.min(e.pathIndex, PATH.length - 1);
    return { r: PATH[idx][0], c: PATH[idx][1] };
  }

  function towersInRange(r, c, powered) {
    const list = [];
    for (const [k, t] of state.towers) {
      if (!powered.has(k)) continue;
      const pos = parseKey(k);
      const st = TOWER_STATS[t.type];
      if (chebyshev(pos.r, pos.c, r, c) <= st.range) {
        list.push({ k, t, st, pos });
      }
    }
    return list;
  }

  function damageEnemy(e, amount, meta) {
    const def = ENEMY_DEFS[e.type];
    let dmg = amount;
    if (def.armor) dmg = Math.max(1, dmg - def.armor);
    e.hp -= dmg;
    if (meta) {
      spawnHitFx(meta.pos, e, dmg, meta.color, meta.name);
      meta.tower.firedThisWave = true;
      meta.tower.firedRecently = true;
    }
    return dmg;
  }

  function killEnemy(e) {
    e.alive = false;
    const def = ENEMY_DEFS[e.type];
    state.scrap += def.scrap;
    log(`Killed ${def.name} (+${def.scrap} scrap)`, "good");
  }

  function fireVolleyAt(e, cell, powered) {
    let total = 0;
    for (const tw of towersInRange(cell.r, cell.c, powered)) {
      let dmg = tw.st.dmg;
      if (tw.t.type === "drainer" && state.spikeOn) dmg = tw.st.spikeDmg;
      total += damageEnemy(e, dmg, {
        pos: tw.pos,
        color: tw.st.color,
        name: tw.st.short,
        tower: tw.t,
      });
    }
    return total;
  }

  function pickSaboteurLink(e) {
    const { r, c } = enemyCell(e);
    const candidates = [];
    for (const [id, L] of state.links) {
      const pa = nodePos(L.a);
      const pb = nodePos(L.b);
      // distance to segment midpoint
      const mr = (pa.r + pb.r) / 2;
      const mc = (pa.c + pb.c) / 2;
      const dist = chebyshev(r, c, Math.round(mr), Math.round(mc));
      if (dist > 2) continue;
      let score = L.wireless ? 40 : 20;
      if (L.fortified) score -= 5;
      // prefer links that disconnect more towers
      score += Math.random() * 10;
      candidates.push({ id, score });
    }
    candidates.sort((a, b) => b.score - a.score);
    return candidates[0] || null;
  }

  function cutLink(id) {
    const L = state.links.get(id);
    if (!L) return false;
    if (L.fortified) {
      L.fortified = false;
      log(`Fortify blocked cut on ${id}`, "warn");
      toast("Fortify held!");
      return false;
    }
    state.links.delete(id);
    log(`Saboteur severed ${L.wireless ? "wireless" : "powerline"} ${id}`, "bad");
    toast("Powerline cut!");
    return true;
  }

  function startWave() {
    if (state.phase !== "build") return;
    if (state.waveIndex >= WAVES.length) {
      toast("Campaign complete");
      return;
    }
    const { poweredTowers } = computeLoad(false);
    if (poweredTowers === 0) {
      toast("No powered towers — link them to the Core");
      return;
    }
    state.phase = "combat";
    state.enemies = [];
    state.spawnQueue = WAVES[state.waveIndex].slice();
    state.spawnTimer = 0.25;
    state.burstUsed = false;
    let regs = 0;
    for (const t of state.towers.values()) if (t.type === "regulator") regs++;
    state.fortifyCharges = regs > 0 ? 2 + Math.max(0, regs - 1) : 0;
    state.fortifyArmed = false;
    state.waveLeak = 0;
    state.channelTick = 0;
    state.linkFrom = null;
    for (const t of state.towers.values()) {
      t.firedThisWave = false;
      t.firedRecently = false;
    }
    log(`Wave ${state.waveIndex} started (${state.spawnQueue.length} enemies)`);
    toast(`Wave ${state.waveIndex} · HP ${state.integrity}/${MAX_INTEGRITY}`);
    updateUI();
  }

  function spawnEnemy(type) {
    const def = ENEMY_DEFS[type];
    state.enemies.push({
      type,
      hp: def.hp,
      maxHp: def.hp,
      pathIndex: 0,
      progress: 0,
      alive: true,
      channeling: false,
      channelTime: 0,
      channelTarget: null,
      wantsSecondCut: false,
      cutsDone: 0,
      _channelDmg: 0,
    });
  }

  function endWave() {
    const { draw, max } = computeLoad(true);
    const pct = max > 0 ? (draw / max) * 100 : 0;
    if (pct < 60) state.heat = Math.max(0, state.heat - 2);
    else if (pct < 80) state.heat += 1;
    else if (pct < 100) state.heat += 3;
    else state.heat += 5;

    if (state.heat >= 10) {
      const wear = Math.floor(state.heat / 2);
      state.maxPower = Math.max(40, state.maxPower - wear);
      state.heat = Math.max(0, state.heat - 4);
      log(`Core stress: −${wear} max power (click Core to repair)`, "warn");
    }

    const bonus = state.waveLeak === 0 ? 15 : 8;
    state.scrap += bonus;
    log(
      `Wave ${state.waveIndex} clear · +${bonus} scrap · load ${Math.round(pct)}% · HP ${state.integrity}/${MAX_INTEGRITY}`,
      "good"
    );

    state.waveIndex += 1;
    state.phase = "build";
    state.enemies = [];
    state.spikeOn = false;
    for (const t of state.towers.values()) t.firedRecently = false;

    if (state.waveIndex >= WAVES.length) {
      state.phase = "won";
      showOverlay(
        "District Held",
        `Cleared all waves with ${state.integrity}/${MAX_INTEGRITY} Base HP.`,
        [{ label: "Play again", primary: true, onClick: () => resetRun(true) }]
      );
      return;
    }
    updateUI();
    toast(`Build · HP ${state.integrity}/${MAX_INTEGRITY}`);
  }

  function lose(reason) {
    state.phase = "lost";
    showOverlay("Blackout", reason, [
      { label: "Try again", primary: true, onClick: () => resetRun(true) },
      { label: "North preset", onClick: () => applyPreset("north") },
    ]);
  }

  function updateCombat(dt) {
    if (state.phase !== "combat") return;
    dt *= state.simSpeed;
    const powered = poweredNodes();

    if (state.spawnQueue.length) {
      state.spawnTimer -= dt;
      if (state.spawnTimer <= 0) {
        spawnEnemy(state.spawnQueue.shift());
        state.spawnTimer = SPAWN_INTERVAL;
      }
    }

    state.channelTick += dt;

    for (const e of state.enemies) {
      if (!e.alive) continue;
      const def = ENEMY_DEFS[e.type];

      if (def.saboteur && e.channeling) {
        e.channelTime -= dt;
        if (state.channelTick >= 0.45) {
          const cell = enemyCell(e);
          e._channelDmg = (e._channelDmg || 0) + fireVolleyAt(e, cell, powered);
          state.channelTick = 0;
        }
        if (e._channelDmg >= 20) {
          e.channeling = false;
          e.channelTarget = null;
          e._channelDmg = 0;
          log("Saboteur channel interrupted!", "good");
          toast("Channel broken");
        } else if (e.channelTime <= 0) {
          cutLink(e.channelTarget);
          e.channeling = false;
          e.channelTarget = null;
          e._channelDmg = 0;
          e.cutsDone++;
          if (e.cutsDone === 1 && Math.random() < 0.4) e.wantsSecondCut = true;
        }
        if (e.hp <= 0) killEnemy(e);
        continue;
      }

      e.progress += ENEMY_MOVE_SPEED * (def.speed || 1) * dt;
      while (e.progress >= 1 && e.alive) {
        e.progress -= 1;
        e.pathIndex += 1;

        if (e.pathIndex >= PATH.length) {
          e.alive = false;
          state.integrity -= def.leak;
          state.waveLeak += def.leak;
          log(`${def.name} reached base (−${def.leak}) → ${state.integrity}/${MAX_INTEGRITY}`, "bad");
          toast(`Base hit! ${state.integrity}/${MAX_INTEGRITY}`);
          if (state.integrity <= 0) {
            state.integrity = 0;
            lose("Base integrity collapsed.");
            return;
          }
          break;
        }

        const cell = enemyCell(e);
        fireVolleyAt(e, cell, powered);
        if (e.hp <= 0) {
          killEnemy(e);
          break;
        }

        if (def.saboteur && e.pathIndex < PATH.length - 1 && (!e.cutsDone || e.wantsSecondCut)) {
          const tgt = pickSaboteurLink(e);
          if (tgt) {
            e.channeling = true;
            e.channelTime = 1.5;
            e.channelTarget = tgt.id;
            e._channelDmg = 0;
            e.wantsSecondCut = false;
            log(`Saboteur channeling on link`, "warn");
            toast("Saboteur cutting a powerline!");
            break;
          }
        }
      }
    }

    state.enemies = state.enemies.filter((e) => e.alive);
    if (!state.spawnQueue.length && !state.enemies.length) endWave();
  }

  // ——— Actions ———
  function doBurst() {
    if (state.phase !== "combat") {
      toast("Burst during combat");
      return;
    }
    if (state.burstUsed) {
      toast("Burst used");
      return;
    }
    const powered = poweredNodes();
    const caps = [];
    for (const [k, t] of state.towers) {
      if (t.type === "capacitor" && powered.has(k)) caps.push({ k, p: parseKey(k), t });
    }
    if (!caps.length) {
      toast("Need powered Capacitor");
      return;
    }
    let best = null;
    let bestHp = Infinity;
    for (const e of state.enemies) {
      if (!e.alive) continue;
      const cell = enemyCell(e);
      for (const cap of caps) {
        if (chebyshev(cap.p.r, cap.p.c, cell.r, cell.c) <= TOWER_STATS.capacitor.range) {
          if (e.hp < bestHp) {
            bestHp = e.hp;
            best = e;
          }
        }
      }
    }
    if (!best) {
      toast("No target in range");
      return;
    }
    state.burstUsed = true;
    damageEnemy(best, TOWER_STATS.capacitor.burst, {
      pos: caps[0].p,
      color: "#61afef",
      name: "Ca BURST",
      tower: caps[0].t,
    });
    log("Capacitor BURST!", "warn");
    toast("BURST!");
    if (best.hp <= 0) killEnemy(best);
    updateUI();
  }

  function toggleSpike() {
    let has = false;
    for (const t of state.towers.values()) if (t.type === "drainer") has = true;
    if (!has) {
      toast("Need a Drainer");
      return;
    }
    state.spikeOn = !state.spikeOn;
    toast(state.spikeOn ? "SPIKE ON" : "Spike off");
    updateUI();
  }

  function armFortify() {
    let regs = 0;
    for (const t of state.towers.values()) if (t.type === "regulator") regs++;
    if (regs === 0) {
      toast("Need a Regulator for Fortify");
      return;
    }
    if (state.phase === "build") state.fortifyCharges = Math.max(state.fortifyCharges, 2);
    if (state.fortifyCharges <= 0) {
      toast("No charges");
      return;
    }
    state.fortifyArmed = !state.fortifyArmed;
    state.sellMode = false;
    state.linkFrom = null;
    toast(state.fortifyArmed ? "Click a linked tower to fortify its line" : "Fortify off");
    updateUI();
  }

  // ——— Draw ———
  function draw() {
    const s = cellSize();
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    const powered = poweredNodes();

    for (let r = 0; r < SIZE; r++) {
      for (let c = 0; c < SIZE; c++) {
        const k = key(r, c);
        let fill = "#2a303c";
        if (BLOCKED.has(k)) fill = "#14161b";
        if (PATH_SET.has(k)) fill = "#3d4555";
        if (r === CORE.r && c === CORE.c) fill = "#1e3a4a";
        if (r === PATH[PATH.length - 1][0] && c === PATH[PATH.length - 1][1]) fill = "#4a3060";
        ctx.fillStyle = fill;
        ctx.fillRect(c * s + 1, r * s + 1, s - 2, s - 2);
        ctx.strokeStyle = "rgba(0,0,0,0.3)";
        ctx.strokeRect(c * s + 0.5, r * s + 0.5, s - 1, s - 1);
      }
    }

    // path labels (P / arrows follow winding direction)
    ctx.fillStyle = "rgba(232,234,239,0.32)";
    ctx.font = `${Math.floor(s * 0.2)}px sans-serif`;
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    for (let i = 0; i < PATH.length; i++) {
      const [r, c] = PATH[i];
      let label = "·";
      if (i === 0) label = "P";
      else if (i === PATH.length - 1) label = "B";
      else {
        const [pr, pc] = PATH[i - 1];
        const dr = r - pr;
        const dc = c - pc;
        if (dc === 1) label = "›";
        else if (dc === -1) label = "‹";
        else if (dr === 1) label = "v";
        else if (dr === -1) label = "^";
      }
      ctx.fillText(label, c * s + s / 2, r * s + s / 2);
    }
    {
      const [br, bc] = PATH[PATH.length - 1];
      ctx.fillStyle = "rgba(224,179,240,0.95)";
      ctx.font = `bold ${Math.floor(s * 0.14)}px sans-serif`;
      ctx.fillText(`${state.integrity}/${MAX_INTEGRITY}`, bc * s + s / 2, br * s + s * 0.78);
    }

    // powerlines
    for (const L of state.links.values()) {
      const pa = nodePos(L.a);
      const pb = nodePos(L.b);
      const live = powered.has(L.a) && powered.has(L.b);
      // one end powered is enough for "energized" look from core side
      const energized = powered.has(L.a) || powered.has(L.b);
      ctx.strokeStyle = L.wireless
        ? energized
          ? "rgba(80,220,255,0.9)"
          : "rgba(80,220,255,0.25)"
        : energized
          ? "rgba(209,154,102,0.95)"
          : "rgba(209,154,102,0.3)";
      ctx.lineWidth = L.wireless ? 3 : 2.5;
      ctx.setLineDash(L.wireless ? [7, 5] : []);
      ctx.beginPath();
      ctx.moveTo(pa.c * s + s / 2, pa.r * s + s / 2);
      ctx.lineTo(pb.c * s + s / 2, pb.r * s + s / 2);
      ctx.stroke();
      ctx.setLineDash([]);
      if (L.fortified) {
        ctx.strokeStyle = "#61afef";
        ctx.lineWidth = 2;
        ctx.setLineDash([2, 3]);
        ctx.beginPath();
        ctx.moveTo(pa.c * s + s / 2, pa.r * s + s / 2);
        ctx.lineTo(pb.c * s + s / 2, pb.r * s + s / 2);
        ctx.stroke();
        ctx.setLineDash([]);
      }
    }

    // pending link ghost
    if (state.linkFrom && state.hover) {
      const from = nodePos(state.linkFrom);
      const wireless = state.tool === "wireless";
      ctx.strokeStyle = wireless ? "rgba(80,220,255,0.5)" : "rgba(209,154,102,0.5)";
      ctx.setLineDash([4, 4]);
      ctx.beginPath();
      ctx.moveTo(from.c * s + s / 2, from.r * s + s / 2);
      ctx.lineTo(state.hover.c * s + s / 2, state.hover.r * s + s / 2);
      ctx.stroke();
      ctx.setLineDash([]);
    }

    // core
    {
      const x = CORE.c * s + s / 2;
      const y = CORE.r * s + s / 2;
      ctx.fillStyle = "#61afef";
      ctx.beginPath();
      ctx.arc(x, y, s * 0.28, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = "#0d1117";
      ctx.font = `bold ${Math.floor(s * 0.2)}px sans-serif`;
      ctx.fillText("C", x, y + 1);
    }

    // attack beams
    for (const f of state.fx) {
      if (f.kind !== "beam") continue;
      const a = f.life / f.max;
      ctx.globalAlpha = a;
      ctx.strokeStyle = f.color;
      ctx.lineWidth = 2 + 2 * a;
      ctx.beginPath();
      ctx.moveTo(f.x0, f.y0);
      ctx.lineTo(f.x1, f.y1);
      ctx.stroke();
      ctx.globalAlpha = 1;
    }

    // towers
    for (const [k, t] of state.towers) {
      const { r, c } = parseKey(k);
      const x = c * s + s / 2;
      const y = r * s + s / 2;
      const on = powered.has(k);
      const st = TOWER_STATS[t.type];
      const hs = s * 0.3;
      ctx.globalAlpha = on ? 1 : 0.35;
      ctx.fillStyle = st.color;
      ctx.fillRect(x - hs, y - hs, hs * 2, hs * 2);
      const flash = state.fx.find((f) => f.kind === "flash" && f.r === r && f.c === c);
      if (flash) {
        ctx.strokeStyle = "#fff";
        ctx.lineWidth = 3;
        ctx.strokeRect(x - hs - 2, y - hs - 2, hs * 2 + 4, hs * 2 + 4);
      }
      if (t.type === "drainer" && state.spikeOn) {
        ctx.strokeStyle = "#ff8a7a";
        ctx.lineWidth = 2;
        ctx.strokeRect(x - hs, y - hs, hs * 2, hs * 2);
      }
      if (state.linkFrom === k) {
        ctx.strokeStyle = "#50dcff";
        ctx.lineWidth = 2;
        ctx.strokeRect(x - hs - 3, y - hs - 3, hs * 2 + 6, hs * 2 + 6);
      }
      ctx.fillStyle = "#0d1117";
      ctx.font = `bold ${Math.floor(s * 0.18)}px sans-serif`;
      ctx.fillText(st.short, x, y);
      ctx.font = `${Math.floor(s * 0.12)}px sans-serif`;
      ctx.fillStyle = on ? "rgba(255,255,255,0.7)" : "rgba(255,255,255,0.35)";
      const dmgShow = t.type === "drainer" && state.spikeOn ? st.spikeDmg : st.dmg;
      ctx.fillText(`${dmgShow}`, x, y + hs + 8);
      ctx.globalAlpha = 1;
      if (!on) {
        ctx.fillStyle = "rgba(0,0,0,0.4)";
        ctx.fillRect(x - hs, y - hs, hs * 2, hs * 2);
        ctx.fillStyle = "#e06c75";
        ctx.font = `bold ${Math.floor(s * 0.13)}px sans-serif`;
        ctx.fillText("OFF", x, y);
      }
    }

    // enemies
    for (const e of state.enemies) {
      if (!e.alive) continue;
      const def = ENEMY_DEFS[e.type];
      const pos = enemyWorldPos(e);
      ctx.beginPath();
      ctx.fillStyle = def.color;
      ctx.arc(pos.x, pos.y, def.r, 0, Math.PI * 2);
      ctx.fill();
      if (e.channeling) {
        ctx.strokeStyle = "#fff";
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(pos.x, pos.y, def.r + 4, 0, Math.PI * 2 * Math.max(0, e.channelTime / 1.5));
        ctx.stroke();
      }
      ctx.fillStyle = "#fff";
      ctx.font = "bold 9px sans-serif";
      ctx.fillText(def.name, pos.x, pos.y - def.r - 12);
      const w = 26;
      ctx.fillStyle = "#000";
      ctx.fillRect(pos.x - w / 2, pos.y - def.r - 7, w, 4);
      ctx.fillStyle = e.hp / e.maxHp > 0.4 ? "#98c379" : "#e06c75";
      ctx.fillRect(pos.x - w / 2, pos.y - def.r - 7, w * Math.max(0, e.hp / e.maxHp), 4);
    }

    for (const f of state.fx) {
      if (f.kind !== "float") continue;
      const a = f.life / f.max;
      ctx.globalAlpha = a;
      ctx.fillStyle = f.color;
      ctx.font = `bold ${11 + 3 * a}px sans-serif`;
      ctx.fillText(f.text, f.x, f.y - (1 - a) * 16);
      ctx.globalAlpha = 1;
    }

    if (state.hover) {
      const { r, c } = state.hover;
      ctx.strokeStyle = "rgba(94,200,192,0.8)";
      ctx.lineWidth = 2;
      ctx.strokeRect(c * s + 2, r * s + 2, s - 4, s - 4);
      if (state.phase === "build" && TOWER_STATS[state.tool]) {
        const st = TOWER_STATS[state.tool];
        ctx.strokeStyle = "rgba(94,200,192,0.22)";
        ctx.beginPath();
        ctx.arc(c * s + s / 2, r * s + s / 2, st.range * s, 0, Math.PI * 2);
        ctx.stroke();
      }
    }

    ctx.fillStyle = "rgba(255,255,255,0.4)";
    ctx.font = "11px sans-serif";
    ctx.textAlign = "left";
    ctx.fillText(`${SIZE}×${SIZE} · ${state.phase.toUpperCase()}`, 8, 14);
  }

  // ——— UI ———
  function setHpBars() {
    const ratio = Math.max(0, state.integrity / MAX_INTEGRITY);
    const pct = Math.round(ratio * 100) + "%";
    const text = `${state.integrity} / ${MAX_INTEGRITY}`;
    document.getElementById("stat-hp").textContent = text;
    document.getElementById("base-banner-text").textContent = text;
    const fill = document.getElementById("hp-fill");
    const fillBig = document.getElementById("hp-fill-big");
    fill.style.width = pct;
    fillBig.style.width = pct;
    fill.classList.toggle("low", ratio <= 0.34);
    fill.classList.toggle("mid", ratio > 0.34 && ratio <= 0.6);
    fillBig.classList.toggle("low", ratio <= 0.34);
    fillBig.classList.toggle("mid", ratio > 0.34 && ratio <= 0.6);
    document.getElementById("stat-hp-wrap").classList.toggle("danger", state.integrity <= 4);
    document.getElementById("base-banner").classList.toggle("danger", state.integrity <= 4);
  }

  function buildStaticLegends() {
    const towerRoot = document.getElementById("tower-legend");
    if (towerRoot) {
      towerRoot.innerHTML = Object.entries(TOWER_STATS)
        .map(([id, st]) => {
          const spike =
            st.spikeDmg != null
              ? ` · Spike ${st.spikeDmg} dmg / draw ${st.spikeDraw}`
              : "";
          const burst = st.burst != null ? ` · Burst ${st.burst}` : "";
          return `<div class="legend-card">
            <div class="title"><span class="swatch" style="background:${st.color}"></span>${st.short} ${st.name}
              <span style="margin-left:auto;color:var(--muted);font-weight:500">${COSTS[id]} scrap</span></div>
            <div class="stats">DMG ${st.dmg}${burst}${spike}<br>
              Range ${st.range} · Draw idle ${st.drawIdle} / fire ${st.drawFire}</div>
            <div class="role">${st.role}</div>
          </div>`;
        })
        .join("");
    }

    const boardRoot = document.getElementById("board-legend");
    if (boardRoot) {
      boardRoot.innerHTML = `
        <table class="legend-table">
          <tr><th>Item</th><th>Notes</th></tr>
          <tr><td>Path length</td><td>${PATH.length} cells (winding)</td></tr>
          <tr><td style="color:#d19a66">Powerline</td><td>Range ${LINK_RANGE} · ${COSTS.link} scrap · +${LINK_DRAW} load · land-connected only</td></tr>
          <tr><td style="color:#50dcff">Wireless</td><td>Range ${WIRELESS_RANGE} · ${COSTS.wireless} scrap · +${WIRELESS_DRAW} load · max ${WIRELESS_MAX} · bridges path/scenery gaps</td></tr>
          <tr><td>Core C</td><td>Power source · click to repair max power</td></tr>
          <tr><td>P → B</td><td>Enemy lane · no towers</td></tr>
          <tr><td># dark</td><td>Scenery · no build · path routes around</td></tr>
          <tr><td>Saboteur</td><td>Cuts links · Fortify (F) blocks one cut</td></tr>
        </table>`;
    }
  }

  function updateMemo() {
    const load = computeLoad(state.phase === "combat");
    const pct = load.max ? Math.round((load.draw / load.max) * 100) : 0;
    const hits = state.lastHits
      .filter((h) => performance.now() - h.t < 2500)
      .map((h) => `${h.name} −${h.dmg}`)
      .join(" · ");

    const dark = [];
    const on = [];
    for (const [k, t] of state.towers) {
      const name = TOWER_STATS[t.type].short;
      if (load.powered.has(k)) on.push(`${name}@${k}`);
      else dark.push(`${name}@${k}`);
    }

    memoEl.innerHTML = `<div class="live"><strong>Phase:</strong> ${state.phase}
<strong>Base HP:</strong> ${state.integrity}/${MAX_INTEGRITY}
<strong>Load:</strong> ${load.draw}/${load.max} (${pct}%) · line tax ${load.tax}
<strong>Links:</strong> ${state.links.size} (${countWireless()} wireless)
<strong>On:</strong> ${on.join(", ") || "—"}
<strong>OFF:</strong> ${dark.join(", ") || "none"}
<strong>Hits:</strong> ${hits || "—"}
<strong>Link pick:</strong> ${state.linkFrom || "—"}</div>
<p class="hint" style="margin:8px 0 0">Path has <b>${PATH.length}</b> steps around scenery. Wireless only needed when land is split by the path or range is too far.</p>`;
  }

  function updateUI() {
    const { draw, max } = computeLoad(state.phase === "combat");
    document.getElementById("stat-scrap").textContent = state.scrap;
    document.getElementById("stat-load").textContent = `${draw}/${max}`;
    document.getElementById("stat-heat").textContent = String(state.heat);
    document.getElementById("stat-wave").textContent = String(
      Math.min(state.waveIndex, WAVES.length - 1)
    );
    setHpBars();

    const loadStat = document.getElementById("stat-load").parentElement;
    const ratio = max ? draw / max : 0;
    loadStat.classList.toggle("hot", ratio >= 0.8 && ratio < 1);
    loadStat.classList.toggle("danger", ratio >= 1);

    const next = state.waveIndex < WAVES.length ? WAVES[state.waveIndex] : [];
    const counts = {};
    for (const t of next) counts[t] = (counts[t] || 0) + 1;
    document.getElementById("wave-preview").textContent =
      state.waveIndex >= WAVES.length
        ? "Campaign complete"
        : "Next: " +
          Object.entries(counts)
            .map(([t, n]) => `${n}× ${ENEMY_DEFS[t].name}`)
            .join(", ");

    document.getElementById("action-status").textContent =
      `Burst ${state.burstUsed ? "used" : "ready"} · Spike ${state.spikeOn ? "ON" : "off"} · Fortify ${state.fortifyCharges}` +
      (state.linkFrom ? ` · linking from ${state.linkFrom}` : "");

    document.getElementById("btn-burst").classList.toggle("ready", state.phase === "combat" && !state.burstUsed);
    document.getElementById("btn-spike").classList.toggle("on", state.spikeOn);
    document.getElementById("btn-fortify").classList.toggle("on", state.fortifyArmed);

    document.getElementById("btn-wave").disabled =
      state.phase !== "build" || state.waveIndex >= WAVES.length;
    document.getElementById("btn-wave").textContent =
      state.phase === "combat" ? "Wave in progress…" : `Start wave ${state.waveIndex}`;
    document.getElementById("btn-speed").textContent = `×${state.simSpeed}`;

    document.querySelectorAll(".tool").forEach((el) => {
      el.classList.toggle("active", el.dataset.id === state.tool && !state.sellMode);
    });
    document.getElementById("btn-sell").classList.toggle("active", state.sellMode);

    updateMemo();
  }

  function buildToolsUI() {
    const root = document.getElementById("tools");
    root.innerHTML = "";
    for (const t of tools) {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "tool";
      btn.dataset.id = t.id;
      btn.innerHTML = `${t.label}<span class="cost">${t.cost} scrap · key ${t.hotkey}${t.hint ? " · " + t.hint : ""}</span>`;
      btn.onclick = () => {
        state.tool = t.id;
        state.sellMode = false;
        state.fortifyArmed = false;
        if (t.id !== "link" && t.id !== "wireless") state.linkFrom = null;
        updateUI();
      };
      root.appendChild(btn);
    }
  }

  function canvasPos(evt) {
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    const clientX = evt.clientX ?? evt.touches?.[0]?.clientX;
    const clientY = evt.clientY ?? evt.touches?.[0]?.clientY;
    const x = (clientX - rect.left) * scaleX;
    const y = (clientY - rect.top) * scaleY;
    return { r: Math.floor(y / cellSize()), c: Math.floor(x / cellSize()) };
  }

  function onPointer(evt) {
    const { r, c } = canvasPos(evt);
    if (!inBounds(r, c)) return;

    if (state.fortifyArmed) {
      fortifyNearestLink(r, c);
      updateUI();
      return;
    }
    if (state.sellMode) {
      sellAt(r, c);
      updateUI();
      return;
    }
    if (state.phase === "build" && r === CORE.r && c === CORE.c && state.tool !== "link" && state.tool !== "wireless") {
      if (state.maxPower < 100 && state.scrap >= 3) {
        const room = 100 - state.maxPower;
        const buy = Math.min(room, Math.min(5, Math.floor(state.scrap / 3)));
        state.scrap -= buy * 3;
        state.maxPower += buy;
        log(`Repaired +${buy} max power`, "good");
        toast(`Repaired +${buy}`);
      } else if (state.tool === "link" || state.tool === "wireless") {
        handleLinkClick(r, c, state.tool === "wireless");
      } else {
        toast(state.maxPower >= 100 ? "Core healthy — use Link tool to connect from C" : "Need scrap to repair");
      }
      updateUI();
      return;
    }

    if (state.tool === "link" || state.tool === "wireless") {
      handleLinkClick(r, c, state.tool === "wireless");
      updateUI();
      return;
    }

    if (state.phase !== "build") {
      toast("Build between waves");
      return;
    }

    if (TOWER_STATS[state.tool]) {
      placeTower(r, c, state.tool, false);
      updateUI();
    }
  }

  let last = performance.now();
  function frame(now) {
    const dt = Math.min(0.05, (now - last) / 1000);
    last = now;
    updateCombat(dt);
    updateFx(dt);
    draw();
    if (((now / 200) | 0) !== (((now - dt * 1000) / 200) | 0)) updateUI();
    else setHpBars();
    requestAnimationFrame(frame);
  }

  function init() {
    buildToolsUI();
    canvas.addEventListener("click", onPointer);
    canvas.addEventListener("mousemove", (e) => {
      const p = canvasPos(e);
      state.hover = inBounds(p.r, p.c) ? p : null;
    });
    canvas.addEventListener("mouseleave", () => {
      state.hover = null;
    });
    canvas.addEventListener(
      "touchend",
      (e) => {
        e.preventDefault();
        if (e.changedTouches[0]) onPointer(e.changedTouches[0]);
      },
      { passive: false }
    );

    document.getElementById("btn-wave").onclick = startWave;
    document.getElementById("btn-speed").onclick = () => {
      state.simSpeed = state.simSpeed === 1 ? 2 : state.simSpeed === 2 ? 3 : 1;
      updateUI();
    };
    document.getElementById("btn-burst").onclick = doBurst;
    document.getElementById("btn-spike").onclick = toggleSpike;
    document.getElementById("btn-fortify").onclick = armFortify;
    document.getElementById("btn-sell").onclick = () => {
      state.sellMode = !state.sellMode;
      state.fortifyArmed = false;
      state.linkFrom = null;
      toast(state.sellMode ? "Sell: click tower" : "Sell off");
      updateUI();
    };
    document.getElementById("btn-reset").onclick = () => resetRun(true);
    document.getElementById("btn-north").onclick = () => applyPreset("north");
    document.getElementById("btn-south").onclick = () => applyPreset("south");
    document.getElementById("btn-split").onclick = () => applyPreset("split");

    window.addEventListener("keydown", (e) => {
      if (e.code === "Space") {
        e.preventDefault();
        startWave();
      }
      if (e.code === "Escape") {
        state.sellMode = false;
        state.fortifyArmed = false;
        state.linkFrom = null;
        updateUI();
      }
      const map = {
        Digit1: "link",
        Digit2: "wireless",
        Digit3: "capacitor",
        Digit4: "transformer",
        Digit5: "regulator",
        Digit6: "drainer",
      };
      if (map[e.code]) {
        state.tool = map[e.code];
        state.sellMode = false;
        if (map[e.code] !== "link" && map[e.code] !== "wireless") state.linkFrom = null;
        updateUI();
      }
      if (e.key === "b" || e.key === "B") doBurst();
      if (e.key === "v" || e.key === "V") toggleSpike();
      if (e.key === "f" || e.key === "F") armFortify();
    });

    buildStaticLegends();
    resetRun(true);
    log(`Winding path: ${PATH.length} cells around scenery. Tower legend is beside the map.`);
    showOverlay(
      "Winding path · 10×10",
      `Enemies follow a long route (${PATH.length} steps) around the factory and rocks. Powerlines attach to towers. Use Wireless when the path blocks a land link. Tower stats stay in the legend panel.`,
      [
        { label: "North rail", primary: true, onClick: () => applyPreset("north") },
        { label: "South rail", onClick: () => applyPreset("south") },
      ]
    );
    requestAnimationFrame(frame);
  }

  init();
})();
