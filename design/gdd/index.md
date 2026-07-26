# EMBERVEIL — GDD Index & System Decomposition (Phase 2, MVP)

> File: `design/gdd/index.md` · Owner: design-strategist · Status: Phase 2 MVP · Review: FULL
> Upstream: `design/concept/game-concept.md`, `design/art/art-bible.md`
> Original-IP rule: all systems use original expression (Ward-Sigils, not crystals; Underdog Stage, not FF1 layout). No Square Enix assets.

---

## 1. System Inventory (MVP)

| # | System | GDD File | One-line scope |
|---|--------|----------|----------------|
| S1 | Party & Jobs | [party-jobs.md](party-jobs.md) | 4-hero party, 4 original jobs, stats, kits, elemental aptitude |
| S2 | Turn-based Command Combat | [combat.md](combat.md) | Initiative, 5 commands, elemental damage, win/lose, AI, Run |
| S3 | Elements & Ward-Sigil | [elements.md](elements.md) | 7-element taxonomy, affinity matrix, shared Ward Codex, resonance |
| S4 | Progression | [progression.md](progression.md) | XP/level, equipment, gold, inventory, sigil resonance |
| S5 | World Nodes | [world-nodes.md](world-nodes.md) | 1 Town hub + 1 Dungeon (floors, rooms, puzzle, mini-boss) |
| S6 | Save/Load & Session State | [save-load.md](save-load.md) | Single RunState schema, autosave+manual, safe-node-only writes |

All six use the unified 8-section template (概述 / 核心规则 / 数据模型 / 交互输入 / 进度成长 / 内容清单 / 边界平衡 / 依赖开放问题).

---

## 2. Dependency Ordering (地基 → 组合)

Build order respects "who is referenced by whom." `Save-Load` and `Elements` are the contracts everything else reads; `World-Nodes` is the top-level composition.

```
LAYER 0 — FOUNDATION (contracts, no MVP upstream deps)
  S6 save-load.md      ── defines RunState schema; every system serializes INTO it
  S3 elements.md       ── element enum + affinity matrix + Ward-Sigil/Codex; referenced widely

LAYER 1
  S1 party-jobs.md     ── reads S3 (element enum for aptitude), S6 (persist schema)

LAYER 2
  S4 progression.md    ── reads S6, S3 (resonance set); consumes S2 XP at runtime

LAYER 3
  S2 combat.md         ── reads S1 (kits/stats/aptitude), S3 (spells/affinity/Codex/resonance),
                          S4 (rewards/leveled stats/items), S6 (session)

LAYER 4 — COMPOSITION
  S5 world-nodes.md    ── composes S1+S2+S3+S4+S6
```

**Dependency arrows (A → B means "A depends on B"):**

```
world-nodes ──► combat ──► party-jobs ──► elements ──► save-load
     │              │            │              │
     │              ├──────────► elements ──────┤
     │              │            │              │
     │              └──────────► progression ───┤
     │                           │              │
     └──────────────────────────► progression ──┘
progression ──► combat (runtime XP sink; combat emits, progression applies)
```

Notes:
- `Combat ↔ Progression` is a **runtime contract**, not a build blocker: Combat emits `XP` events; Progression applies them and returns leveled stats. No circular build dependency.
- `Save-Load` is depended on by all but depends on none (it serializes the other systems' state structs — those structs are finalized in their own GDDs).

---

## 3. Cross-GDD Consistency Conclusions (self-review)

### 3.1 Interface / dataflow contracts — PASS
| Interface | Producer | Consumer | Status |
|---|---|---|---|
| Element enum `Ember,Frost,Storm,Stone,Gale,Lumen,Umbra` | elements §2 | party-jobs (aptitude keys), combat (spell elem), world (puzzle), progression (resonance) | ✅ identical, single source of truth |
| Affinity `1.5 / 0.67 / 1.0` | elements §2 | combat §2 damage formula | ✅ constants match |
| Shared Ward Codex (`attunedSigilIds` Set + `resonance` Map) | elements §3 | combat (Elemental cmd), world (puzzle/discovery), progression (resonance), save-load (persist) | ✅ consistent Set semantics (no-dup attune) |
| Per-hero `aptitude[elem]` gate | party-jobs §3 | combat (Elemental castability), elements (color) | ✅ |
| `XP` sink | combat (emit) | progression (apply + level) | ✅ |
| Leveled stats / equipment mods | progression | combat (base stats) | ✅ derived at runtime, not double-stored |
| Safe-node save writes | world (nodes) + save-load (triggers) | all growth systems | ✅ both agree: writes only at Town / floor-clear |

### 3.2 Design-theory re-check vs the 5 pillars (concept §1)
| Pillar | Served by | Verdict |
|---|---|---|
| Party Synergy Over Individual Power | Shared Ward Codex + per-hero aptitude + 4-hero band; jobs cover roles | ✅ |
| Readable Command-Driven Tactics | combat commands, no ATB, Underdog Stage, shape-based states | ✅ |
| Elemental Literacy as Mastery | affinity matrix + sigil discovery + dungeon puzzle | ✅ |
| Explorable Handcrafted World | town + dungeon nodes | ✅ (overworld L3) |
| Session-Friendly Depth | short loops (1 floor / 1 sigil), autosave checkpoints, Rest = free full heal | ✅ |

- **MDA:** Mechanics (S1–S6) → Dynamics (pre-planning, discovery-driven power curve) → Aesthetics (Challenge/Discovery/Fellowship prioritized; Submission/Expression de-prioritized) — consistent with concept §2.
- **SDT:** Autonomy (party comp, exploration, multiple solutions) · Competence (leveling, resonance, visible mastery) · Relatedness (band framing) — all present.
- **Flow:** graded difficulty; MVP dungeon 3–5 floors; optional hard mini-boss as ceiling. ✅
- **No dominant strategy:** affinity is a symmetric 7-cycle (each element strong vs exactly 1, weak vs exactly 1) → no single element/command dominates. ✅ (red line respected)

---

## 4. Conflicts / Gaps

### 4.1 Resolved interpretation (was a spec ambiguity in concept §5.1)
The concept said MVP = "**2–3 attunable Ward-Sigils** granting spells" AND "**at least 4 elements usable** (Ember/Frost/Storm/Stone)" AND the dungeon gives "**one Ward-Sigil reward**." Reconciled as: **3 sigils attunable at start/Town (Ember, Frost, Storm) + 1 from the dungeon (Stone) = 4 sigils / 4 playable elements by MVP end.** This is now consistent across elements §6, combat §6, world §6. (Flagged as an interpretation decision for lead sign-off — see §5.1.)

### 4.2 Residual gaps (non-blocking)
- Exact numeric tuning (XP curve, affinity, spell power/cost, AI aggression) is first-pass; a balance pass is required before engineering lock (open §5.3).
- Status-effect set is minimal at MVP (Slow/Guard/Mark); larger set deferred to L2.
- Bash output capture was unreliable during authoring; files verified via Read/Grep and land in the project root `design/gdd/`.

---

## 5. Open Decisions (for lead / engineering-lead)

1. **Shared Ward Codex vs per-hero sigil attunement** — *Committed design:* party-level shared Codex + per-hero `aptitude` gate + per-hero MP. Rationale: reinforces "band as one unit" + Elemental Literacy. **Open:** exact aptitude coefficients and MP economy need playtest tuning.
2. **MVP party composition rule** — allow duplicates or enforce **max 1 per job**? Recommend max-1-per-job to prevent a 4×Channeler dominant comp. Needs lead call.
3. **Save slots** — MVP = single local slot (+ confirm dialog on New Run). Multiple/cloud = L4.
4. **Dungeon length** — recommend **4 floors** (concept allows 3–5).
5. **Balance pass ownership** — designate design+engineering to lock numbers in a tuning spike before implementation.
6. **Job-change / mastery (L2)**, **overworld + Driftwing (L3)**, **story arcs (L4)**, **post-game (L5)** — all out of MVP, tagged 后续 in each GDD; not expanded.

---

*End of GDD Index (Phase 2 MVP). Six system GDDs + this index are ready for the engineering-lead to implement against; all references are self-consistent and original-IP compliant.*
