# Combat System GDD — EMBERVEIL (MVP)

> File: `design/gdd/combat.md` · Owner: design-strategist · Status: Phase 2 MVP
> Upstream: concept §2.1 / §3, art-bible §6.2 / §7
> Scope: 4-hero turn-based command combat. Expansion (L2+): job-change abilities, deeper AI, status depth, boss phases — noted only.

## 1. 系统概述（目标与范围）
Deliver readable, command-driven, turn-based combat that realizes the pillars **Readable Command-Driven Tactics** and **Party Synergy**. No real-time / ATB; every turn is a deliberate menu choice. MVP covers: initiative order, the five command types, elemental damage via the shared Ward Codex + per-hero aptitude, win/lose, basic enemy AI, and Run. Out of scope (L2+): smart multi-target AI, large status-effect sets, boss phases.

## 2. 核心规则
- **Initiative:** at battle start, all combatants sorted by `SPD` desc → turn queue. Tie-break: party slot index asc, then seeded RNG. No ATB.
- **Turn:** the active unit issues ONE command (§4). After resolution, advance queue.
- **Commands:**
  - `Attack` — physical: `dmg = max(1, round(ATK*1.0 - target.DEF*0.5)) * affinityMult * variance`.
  - `Skill` — job ability (Party-Jobs §3); fixed or job-element.
  - `Elemental` — pick a spell from the **shared Ward Codex** (Elements §3) the hero may cast: requires (a) sigil attuned, (b) `hero.aptitude[elem] > 0`, (c) `MP ≥ spell.cost`. `dmg = max(1, round(MAG * spell.power * hero.aptitude[elem] * (1 + resonance[elem]*0.1) - target.RES*0.5)) * affinityMult * variance`.
  - `Defend` — incoming damage this round ×0.5; restore `ceil(maxMP*0.10)` MP.
  - `Item` — consume one inventory item (Progression §6), e.g. heal.
  - `Run` (top ribbon, out-of-turn) — see §7.
- **Affinity (`affinityMult`)** from Elements affinity matrix: strong = 1.5, weak = 0.67, neutral = 1.0 (Elements §2).
- **Variance:** ±10%, seeded per action for save/load reproducibility.
- **Win/Lose:** battle ends when all enemies `HP ≤ 0` (win → XP to Progression) or all heroes `HP ≤ 0` (game over → reload last safe save).

## 3. 数据模型与状态
- `Combatant { id, side(ally|enemy), name, HP, maxHP, MP, maxMP, ATK, DEF, MAG, RES, SPD, statusEffects[], affinity(element|none), aiProfile? }`
- `BattleState { queue[combatantId], turnPointer, phase(pre|select|resolve|post), log[], isBoss }`
- `Action { actorId, type, targetIds[], payload(ref to skill/spell/item) }`
- MVP status effects: `Slow` (SPD ×0.6 next sort), `Guard` (Defend flag), `Mark` (+dmg taken). State machine: `PreBattle → PlayerSelect* → Resolve → CheckEnd → (loop | PostBattle)`.

## 4. 交互与输入（UX 流程）
- Composition: **Underdog Stage** (art-bible §6.2) — enemies in upper arc, party band lower-center, command dock bottom-left (soft-rounded chips, NOT a full-width window). Safe at 360×640, hit targets ≥44×44px.
- Flow: active hero highlighted → dock shows that hero's available commands (greyed if uncastable) → sub-menu (target / spell) → confirm → resolve animation → next.
- Element / state shown by **shape** (Ward-Sigil grammar, art-bible §7.3) + label, never color alone (accessibility §9.1).
- Top ribbon: turn-order pips (round = ally, sharp = enemy), Run, Settings. Enemy affinity hint shown on focus only.

## 5. 进度与成长
- On win, Combat emits `XP` to Progression (per enemy `xpValue`). No in-combat progression besides HP/MP/status.
- Party levels (Progression) raise base stats consumed here; resonance (Elements/Progression) raises Elemental output.
- Cleared floors / won battles persist via Save-Load.

## 6. 内容清单（MVP）
- Enemies (dungeon, ~6 types + 1 mini-boss): `Huskling` (physical), `Frostmote` (Frost-affinity), `Stoneling` (Stone-affinity, high DEF), plus Storm-affinity foe; Gale/Umbral foes = L2. Mini-boss `Sigil-Twisted Warden` (cracked Ward-Ring, art-bible §8.2).
- Spells: from the 4 MVP sigils (Elements §6).
- Items: `Herb` (heal 30% HP), `Ember Tonic` (heal 30% MP), `Bulk Salve` (heal all 20%, L2).

## 7. 边界与平衡（edge case & 初值）
- **Defend-stall:** Defend yields no progress (no XP / no win); enemies keep acting → no infinite safe loop. Optional: enemy aggression escalates after N rounds (flag for tuning).
- **Deadlock:** if both sides only Defend, enemies escalate → resolves.
- **Run:** disabled vs `isBoss`. Success = `clamp(0.5 + (avgAllySPD - avgEnemySPD)*0.02, 0.1, 0.95)`; on fail, enemies act first next round. No XP on successful flee.
- **Uncastable Elemental:** greyed; if forced via hotkey at 0 MP → fallback to Attack with toast "No MP".
- **Overkill:** damage clamped ≥1; HP floored at 0.
- **Dominant-strategy check:** affinity is a symmetric 7-cycle (each element strong vs exactly 1, weak vs exactly 1) → no single element/command dominates. ✓ (design-theory red line respected.)
- **Initial numbers:** ATK/DEF by job (Party-Jobs §3); affinity 1.5/0.67; variance ±10%; MP costs 4–10; level cap 20.

## 8. 依赖与开放问题
- Depends on: **Party-Jobs** (command kits, stats, aptitude), **Elements** (spell list, affinity matrix, Codex, resonance), **Progression** (XP sink, leveled stats, items), **Save-Load** (outcome persisted; mid-battle state NOT persisted).
- Open: exact variance / AI-aggression tuning; whether `Skill` can crit (defer); multi-target AI (L2); full status-effect set (L2).
