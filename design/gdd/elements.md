# Elements & Ward-Sigil GDD — EMBERVEIL (MVP)

> File: `design/gdd/elements.md` · Owner: design-strategist · Status: Phase 2 MVP
> Upstream: concept §2.1 / §3, art-bible §7.3 / §2.3
> Scope: MVP content exposes 4 elements (Ember/Frost/Storm/Stone) via sigils; the system defines all 7. Gale/Lumen/Umbra spells = L2+ (system-ready, not expanded).

## 1. 系统概述（目标与范围）
Define the seven-element taxonomy, the affinity matrix, and the Ward-Sigil system (magic source + world-puzzle key). Realizes **Elemental Literacy as Mastery** and the original macguffin trope (Ward-Sigils stand in for "crystals" — no Square Enix expression). MVP content exposes 4 elements via sigils; the system supports all 7.

## 2. 核心规则
- **Elements (7):** `Ember, Frost, Storm, Stone, Gale, Lumen, Umbra`. Identified by **SHAPE** (Ward-Sigil grammar), color is reinforcement only (art-bible §7.3, §9.1).
- **Affinity (symmetric 7-cycle):** each element is strong vs exactly the next, weak vs the previous:
  `Ember ▸ Frost ▸ Storm ▸ Stone ▸ Gale ▸ Lumen ▸ Umbra ▸ Ember`
  `affinityMult = 1.5` if attacker strong, `0.67` if weak, `1.0` otherwise (consumed by Combat §2). The symmetric cycle guarantees no dominant element (design-theory red line).
- **Ward-Sigils:** each Sigil = one element + a spell list. Attuned into the **shared Ward Codex** (party-level, NOT per-hero) → unlocks those spells for any hero with `aptitude > 0` for that element.
- **Resonance:** per-element level 0–5; raises spell power `+10%/level` and unlocks the all-enemy spell at ≥3 (Progression §2).

## 3. 数据模型与状态
- `Element { id, sigilGlyph(grammar ref §7.3), color(hex) }`
- `WardSigil { id, element, spells[SpellRef], discovered(bool), attuned(bool) }`
- `WardCodex { attunedSigilIds:Set, resonance:Map<element, 0..5> }`
- `Spell { id, element, name, cost(MP), power, target(single|all), unlockResonance, applyStatus? }`

## 4. 交互与输入
- **Attune:** at a pedestal (World/Town) or on pickup → added to Codex (Set semantics, no dupes).
- **Cast (Combat):** `Elemental` command → choose a Codex spell the hero can cast (aptitude>0, MP≥cost) → target.
- **Puzzle (World):** activate in-world sigil-stones in element order → gated door (uses element identity, shape-readable).

## 5. 进度与成长
- Resonance grows via use / defeating enemies of that element / attuning (Progression §2). Higher resonance = stronger, wider spells.
- New sigils discovered in World expand the Codex — coverage = power (the "discovery = power" beat).

## 6. 内容清单（MVP）
- MVP Sigils (4): **Ember, Frost, Storm** (attunable in Town/start) + **Stone** (dungeon reward). Gale/Lumen/Umbra = L2+ (system-ready).
- Spells per MVP sigil (2 each; 2nd unlocks at resonance ≥ 3):
  - Ember: `Ember Lash` (MP4, power1.3, single), `Cinderfall` (MP10, power1.0, all)
  - Frost: `Frostbite` (MP4, power1.3, single, Slow), `Rimewake` (MP10, power1.0, all)
  - Storm: `Bolt` (MP4, power1.4, single), `Stormcall` (MP10, power1.1, all)
  - Stone: `Stonejaw` (MP5, power1.5, single, pierce RES), `Bulkward` (MP8, party DEF buff)
- Colors (art-bible §2.3): Ember `#E8743B`, Frost `#6FB7E8`, Storm `#C98A3B`, Stone `#7BA05B`; Gale `#3FA7A0`, Lumen `#E8EEF2`, Umbra `#2E2438`.

## 7. 边界与平衡（edge case & 初值）
- **Symmetric affinity** → no dominant element (red-line OK).
- **Codex Set semantics** → re-attuning the same sigil is a no-op (no dupes / exploit).
- **Resonance cap 5** bounds power (+50% max).
- **Aptitude gate** prevents a Vanguard from nuking with magic (class identity preserved).
- **Uncastable** (no sigil / 0 aptitude / no MP) → greyed in dock.
- **Colorblind:** shape carries ID; provide colorblind-assist toggle (art-bible §9.1).

## 8. 依赖与开放问题
- Depends on: **Party-Jobs** (aptitude gate), **Combat** (consumes spells/affinity), **Progression** (resonance/XP), **World-Nodes** (sigil discovery + puzzles), **Save-Load** (persists Codex/resonance).
- Open: exact spell power/cost tuning; resonance gain rate; whether Gale/Lumen/Umbra spells differ in kind (L2).
