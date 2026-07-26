# EMBERVEIL — Sprint 1 Plan (Draft)

> Epic source: `production/epics/` · Checklist: `docs/architecture/phase4-readiness-checklist.md`
> Owner: engineering-lead · Scope: foundation only (Phase 4 pre-production, first sprint)

## 1. Sprint Goal

Stand up a **bootable, CI-green Godot 4 HTML5 foundation** that satisfies every ⛔ blocker in
checklists **A (scaffold), B (autoloads), C (combat FSM), D (save/load)**, plus the **G (test
harness)** smoke — so Phase 4 can proceed with feature work on a verified base.

## 2. In Scope (Sprint 1)

| Area | Epic / Stories | Why |
|------|---------------|-----|
| Scaffold | E1-A..D (all ⛔) | Project, gl_compatibility, export preset + CI boot, CLAUDE.md, repo layout |
| Autoloads | E2-A..F (all ⛔) | SettingsManager, RNGService, EventBus, AssetRegistry, ElementRegistry+WardCodex, Save/Party/Progression managers |
| Combat FSM | E3-A..D (⛔) + E3-E/F/G (structure) | Pure BattleResolver + formulas, FSM phases, determinism test, RNG lint, EnemyAI, Underdog Stage scene, 5 commands |
| Save/Load | E4-A..D (all ⛔) + E4-E | RunState round-trip, migration, checksum/refusal, safe-node-only writes, single slot + confirm |
| Test Harness | E7-A..D (all ⛔) | GUT install, unit/integration/smoke suites green in CI |
| Audit scaffolding | E5-A..C, E6-A..B (stubs) | asset_audit.py, palette_validator.gd, content_lint.py, MVP content defs + lint wired into CI |

**Combat numbers are PLACEHOLDERS in Sprint 1** (data-driven); the **balance spike (E8)** locks
real values before content is declared "complete" — structure lands now, numbers follow E8.

## 3. Out of Scope (deferred to Sprint 2+)

- S1/S3/S4/S5 **feature UIs**: Party/Barracks (E2-I), Ward Codex casting dock (E2-J), Progression
  shop/equipment (E2-K), Town scene (E2-L), Dungeon scene/floors/puzzle/boss (E2-M).
- L2–L5 content expansion (E6-C extension proof).
- **Any network / cloud / account / login system** — pure-offline decision; Title = Continue/New Run
  only. These belong to L4+ and are explicitly excluded from MVP and this sprint.

## 4. Deliverable Increments (suggested order)

1. **Bootstrap (Day 1–2):** E1-A..D → repo builds, headless boot-to-Title, CI skeleton (E7-A base).
2. **Singletons (Day 2–4):** E2-A..F → managers wired; ElementRegistry passes affinity tests (E7-B).
3. **Persistence (Day 3–5):** E4-A..E → save round-trip/migration/checksum/safe-node green (E7-B/C).
4. **Combat core (Day 4–8):** E3-A..E → deterministic resolver + FSM + EnemyAI; determinism test green (E7-C); RNG lint active.
5. **Scene + commands (Day 6–9):** E3-F/G → Underdog Stage scene + 5 commands drive a scripted win.
6. **Audit + content (Day 5–9):** E5-A..C, E6-A..B → MVP defs authored; asset/palette/content lint in CI.
7. **Smoke (Day 9–10):** E7-D → Boot→Title→Town→Dungeon→Combat→win→safe-node Save passes CI.

## 5. Exit Criteria (all must be true)

- [ ] Checklist **A/B/C/D ⛔** items all ✅ (verified, not aspirational).
- [ ] **G smoke** `tests/smoke/test_boot_to_save.gd` passes in CI.
- [ ] **Unit/integration** suites green: affinity symmetry (1.5/0.67/1.0), save round-trip +
      migration + checksum refusal, combat FSM determinism (fixed seed).
- [ ] **CI gates green:** `godot --headless` boot, GUT, `asset_audit.py` (≤16MB / ≤4 atlases / 1
      grain), `palette_validator.gd` (≤48 colors), content-lint, combat RNG lint.
- [ ] **IP gate:** no SE/FF1 assets; Underdog Stage composition (not FF1); Ward-Sigil shape IDs.

## 6. Risks / Watch-items

- **E8 dependency:** combat *structure* lands in Sprint 1, but playtest-valid numbers need the
  balance spike — keep all values in `content/` (ADR-003); never hardcode.
- **Headless CI Godot download:** pin `GODOT_VERSION`; mirror if github releases are flaky.
- **WebP dimension parsing** in `asset_audit.py` assumes VP8X/VP8L/VP8; if a file fails to parse,
  the script errors loudly (export as VP8X/VP8L per art-bible §4.2).
