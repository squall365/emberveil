# EMBERVEIL — Phase 4 Epic / Story Breakdown (P4-EPIC-003)

> Owner: engineering-lead (程基岩) · Date: 2026-07-26 · Review: FULL
> Inputs: `docs/architecture/main-architecture.md`, `docs/architecture/architecture-review.md`, `docs/architecture/phase4-readiness-checklist.md`, `design/gdd/*`
> Engine: Godot 4 (HTML5/WebGL2) · Platform: Web / 小游戏 · **Pure-offline single-player**

## 0. Scope Guardrail — Pure Offline (locked user decision)

The studio lead confirmed: **pure offline single-player**. Therefore this breakdown contains
**NO** network / cloud-sync / account / login systems. `Analytics` is off by default. Title goes
straight to **Continue / New Run**. Cloud-save, accounts, and async social features are **L4+**
(per concept §5.2) and are explicitly OUT of MVP and OUT of this Epic set. Any such story that
appears later must be a new Epic under L4, not retrofitted here.

## 1. Epic Inventory (8 foundation Epics)

| Epic | Name | Owning GDD systems | Checklist ⛔ gate | One-liner |
|------|------|--------------------|------------------|-----------|
| E1 | Project Scaffold | — (cross-cutting) | A | Godot 4 project, gl_compatibility, export preset, repo layout, CLAUDE.md |
| E2 | Autoloads & Module Wiring | S1, S3, S4, S5 (managers) + cross-cutting | B | SettingsManager, RNGService, EventBus, AssetRegistry, ElementRegistry+WardCodex, Save/Party/Progression managers, SceneManager/WorldDirector, AudioBus placeholder |
| E3 | Deterministic Combat FSM | S2 | C | Pure BattleResolver, FSM phases, seeded RNG, EnemyAI, lint guard, combat scene (Underdog Stage) |
| E4 | Save / Load System | S6 | D | RunState schema, serialize/deserialize, migration, checksum, safe-node-only writes |
| E5 | Asset Pipeline & Audit | — (cross-cutting) | E | Palette validator (≤48), atlas audit (≤4×1024², ≤16MB, 1×128² grain), viewport test |
| E6 | Data-Driven Content | S1, S2, S3, S4, S5 (data) | F | Author MVP defs as .tres/JSON; content-lint CI; extension proof (L2) |
| E7 | Test Harness & CI | — (cross-cutting) | G | GUT install, unit/integration/smoke suites, GitHub Actions CI (godot --headless + asset audit) |
| E8 | Balance Spike | S2, S3, S4 (tuning) | H | Lock ATK/DEF/MAG/RES/SPD, xpToNext, spell power/cost, variance, AI aggression BEFORE combat numbers implemented |
| E9 | Town / Dungeon 地图（Feature UI 垂直切片） | S5 (World Nodes) · S2 (战斗衔接) · S6 (安全存档) | — | World 常驻+真实切换、Hearthmoor 5 节点、Sundered Ward 4 层、CombatController 衔接 BattleResolver、回城+安全节点存档、ux-spec §3 输入（Sprint 2 首冲刺可玩核心） |

## 2. GDD System Coverage Matrix

Every MVP GDD system maps to at least one Epic (foundation ⛔ + feature stories where needed):

| GDD | System | Owning module | Epic(s) | Feature stories |
|-----|--------|--------------|---------|-----------------|
| S1 | Party & Jobs | `PartyManager` | E2 (wiring) + E6 (job data) | E2-I Party composition/Barracks UI (Later) |
| S2 | Combat | `CombatController`+`BattleResolver`+`EnemyAI` | E3 + E6 (enemy/spell data) | E3 combat scene + commands (Sprint 1 partial) |
| S3 | Elements & Ward-Sigil | `ElementRegistry`+`WardCodex` | E2 (wiring) + E6 (sigil/spell data) | E3 Ward Codex casting in dock (Later) |
| S4 | Progression | `ProgressionManager` | E2 (wiring) + E6 (item/equip data) | E2-K Progression UI (Later) |
| S5 | World Nodes | `WorldDirector` (Town+Dungeon) | E2 (routing) + E6 (dungeon def) | **E9** Town/Dungeon 地图（Sprint 2 首冲刺可玩核心：E9.1 World 骨架 / E9.2 Town / E9.3 Dungeon / E9.5 回城存档） |
| S6 | Save/Load | `SaveManager` | E4 | full in Sprint 1 |

## 3. Dependency Graph & Suggested Execution Order

```
E1 Project Scaffold ──► E2 Autoloads ──┬─► E3 Combat FSM ──┐
   │                  (B ⛔)            │   (C ⛔)          │
   ├─► E7 Test Harness (G ⛔, shift-left, runs throughout)  │
   │                  (parallel with E1/E2)                │
   ├─► E5 Asset Audit (E ⛔, needs content dirs)            │
   └─► E6 Data-Driven Content (F ⛔, needs E2 AssetRegistry)┘
                                  │
              E8 Balance Spike (H ⛔) ── feeds numeric lock into E3/E6 BEFORE combat impl locks
```

**Topological order (sprints):**
1. **E1** (scaffold) — first, unblocks everything.
2. **E7 base** + **E5 base** — test infra + asset audit stood up early (shift-left; CI green from day 1).
3. **E2** (autoloads) — depends on E1.
4. **E6** (content data) — depends on E2 (AssetRegistry); supplies data to E3/E4.
5. **E3** (combat FSM) + **E4** (save) — depend on E2; can run in parallel.
6. **E8** (balance spike) — runs in parallel; MUST complete before combat *numbers* are locked (structure lands earlier with placeholder/data-driven values).

## 4. Story ID Convention

`E{epic#}-{letter}` (e.g. `E2-A`). Each story carries: User Story · GDD/Checklist ref · DoD ·
Acceptance Criteria (testable) · Sprint tag · ⛔ blocker flag · Depends-on.

## 5. Sprint Allocation

- **Sprint 1** (this plan → `production/sprint-1-plan.md`): all ⛔ stories from E1, E2, E3, E4, E7,
  plus E5/E6 scaffolding stubs. Exits when checklist A/B/C/D ⛔ are green.
- **Sprint 2+**: **E9** Town/Dungeon 地图可玩核心（垂直切片）；remaining E3/E4 feature depth, E5/E6 full content, E8 lock, S1/S3/S4 feature UIs.
