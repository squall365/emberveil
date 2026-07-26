# Epic E7 — Test Harness & CI (checklist G, cross-cutting)

**Goal:** A GUT-based, CI-green test pyramid (unit/integration/smoke) run headless in GitHub Actions,
plus the asset audit gate. Satisfies every ⛔ item in checklist G. **Owning systems:** cross-cutting.
**Depends on:** E1 (CI), E3/E4 (subjects under test).

## Story E7-A · GUT Install + tests/ Structure
- **User Story:** As an engineer, I want GUT wired and a `tests/` tree, so we write tests before code (verification-driven, main-arch §6).
- **Ref:** checklist G ⛔; main-arch §6.
- **DoD:** `addons/gut` present; `tests/{unit,integration,smoke}` exist with `README.md`; GUT test dir points to `tests/`.
- **Acceptance (testable):**
  1. CI: `godot --headless -s addons/gut/gut_cmdln.gd` discovers the `tests/` tree (empty-suite run exits 0).
  2. `tests/README.md` documents how to run locally + in CI.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E1-C

## Story E7-B · Unit Suite (affinity / save / damage)
- **User Story:** As an engineer, I want core math unit-tested, so regressions are caught pre-merge.
- **Ref:** checklist G ⛔; main-arch §6.1; ADR-002.
- **DoD:** `tests/unit/test_affinity.gd` (symmetric 7-cycle, 1.5/0.67/1.0), `tests/unit/test_save_roundtrip.gd` (serialize/deserialize, migration, checksum, corruption refusal), `tests/unit/test_combat_math.gd` (damage formulas + clamping). All green.
- **Acceptance (testable):**
  1. Unit: affinity symmetry + exact multipliers assert (byte-match GDD).
  2. Unit: save round-trip + migration + checksum scenarios green.
  3. Unit: damage ≥1, HP floor 0, formula equals expected for pinned inputs.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E7-A, E2-E, E4, E3-A

## Story E7-C · Integration Suite (combat FSM + save↔load)
- **User Story:** As an engineer, I want end-to-end logic integration tested, so modules compose correctly.
- **Ref:** checklist G ⛔; main-arch §6.2.
- **DoD:** `tests/integration/test_combat_fsm_determinism.gd` (fixed seed → deterministic win/lose + identical log), `tests/integration/test_save_load_roundtrip.gd` (write at safe node → reload identical; mid-combat absent).
- **Acceptance (testable):**
  1. Integration: same (seed, action list) ⇒ identical outcome hash (E3-C).
  2. Integration: safe-node save→load restores RunState; mid-combat state correctly absent (E4-D).
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E7-A, E3, E4

## Story E7-D · Smoke Harness (Boot→…→Save)
- **User Story:** As an engineer, I want a full happy-path smoke, so a build that can't reach save is blocked before Phase 4 (checklist G ⛔).
- **Ref:** checklist G ⛔; main-arch §6.3; E2-G.
- **DoD:** `tests/smoke/test_boot_to_save.gd` drives Boot→Title(Continue/New)→Town→Dungeon floor→CombatRoom→win→safe-node Save; asserts each node reached + save written.
- **Acceptance (testable):**
  1. Smoke: full path reaches safe-node save with no error; CI gates merges on it.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E7-A, E2-G, E3-F, E4-D, E6-A

## Story E7-E · FPS / Heap Debug HUD
- **User Story:** As an engineer, I want a debug overlay, so I can budget frames/memory against main-arch §5.
- **Ref:** checklist G; main-arch §5.
- **DoD:** A debug HUD (toggle) shows FPS, frame ms (logic/render), texture MB, object count; off in shipping.
- **Acceptance (testable):**
  1. Unit/smoke: HUD toggles; reports ≤16MB texture when within budget.
- **Sprint:** 1 · **⛔ Blocker:** no · **Depends:** E1-A
