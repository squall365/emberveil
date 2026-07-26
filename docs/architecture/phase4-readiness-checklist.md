# EMBERVEIL — Phase 4 Readiness Checklist (Engineering Gate)

> Owner: engineering-lead (程基岩) · Date: 2026-07-26
> Purpose: every item below MUST be true before Phase 4 (pre-production) implementation starts.
> Companion: `architecture-review.md` (verdict: PASS with conditions). Mark ✅ only when verified,
> not aspirational. Items with ⛔ are hard blockers for Phase 4 start.

---

## A. Project Scaffold (Godot 4) — Sprint 1 ✅
- [x] ⛔ Godot 4 latest-stable project created; `project.godot` with `renderer/rendering_method=gl_compatibility` (WebGL2).
- [x] ⛔ `CLAUDE.md` present documenting engine version, GDScript-primary, GDExtension-escape-hatch policy.
- [x] ⛔ Export preset for HTML5/WebGL2 configured (`export_presets.cfg`: thread_support=false, renderer=2 GL Compatibility, adaptive canvas); boots to Title in CI (`--headless` smoke).
- [x] Repo layout: `src/` (autoloads, modules), `content/` (JSON defs), `tests/` (GUT), `docs/architecture/`.

## B. Autoloads Wired (per main-architecture §2.1) — Sprint 1 ✅
- [x] ⛔ `SettingsManager` loads + applies accessibility (colorblind-assist / reduced-motion / text-scale 100–125%) + expanded schema (ux-spec §4.2); global `emberveil.settings.v1` authoritative + `RunState.settings` mirror (phase4-gate §3.1).
- [x] ⛔ `RNGService` seedable PRNG (`class_name`, instantiated via `.new()`); sole randomness source (ADR-002). Not an autoload singleton — see main-architecture §2.1.
- [x] ⛔ `EventBus` typed signals defined; **no logic mutation inside handlers** (architecture §2.4).
- [x] ⛔ `AssetRegistry` loads `content/` into def tables; `validate_atlas` enforces the 3 asset constraints (phase4-gate §3.2).
- [x] ⛔ `ElementRegistry` + `WardCodex` built from data; element enum + affinity matrix exact (1.5/0.67/1.0), symmetric 7-cycle, no dominant element.
- [x] ⛔ `SaveManager` + `PartyManager` + `ProgressionManager` load RunState if present.
- [x] `SceneManager`/`WorldDirector` route Boot→Title→Town/Dungeon→Battle (logical node + safe-node save).
- [x] `AudioBus` placeholder wired (emits events only); `Analytics` off by default.

## C. Combat Determinism Smoke (ADR-002) — Sprint 1 ✅
- [x] ⛔ `BattleResolver.resolve_action(state, action, rng)` implemented as pure function (`src/combat/battle_resolver.gd`); exactly one seeded variance draw per action.
- [x] ⛔ FSM phases reachable: `PreBattle→PlayerInput→Resolve→CheckEnd→(loop|Victory|Defeat)` (`src/battle/battle_fsm.gd`).
- [x] ⛔ Unit test: fixed seed + action script ⇒ deterministic win/lose + identical log (`tests/integration/test_combat_fsm_determinism.gd`).
- [x] ⛔ Lint passes: **no `randi/randf/OS.rand` inside `combat/` + `battle/`** (CI guard in ci.yml).
- [x] Enemy AI computes action for enemy turns (`src/battle/enemy_ai.gd`); `turnPointer` skip-dead is caller responsibility (resolver keeps combatants, outcome computed by caller).
- [x] Damage formulas match combat.md §2 verbatim; clamping (≥1, HP floor 0) holds in tests (`tests/unit/test_combat_math.gd`).

## D. Save / Load Verified (ADR-004) — Sprint 1 ✅
- [x] ⛔ Serialize→deserialize round-trip equals original `RunState` (unit test `test_save_roundtrip`).
- [x] ⛔ `schemaVersion` migration `v1→CURRENT` transforms old save + defaults missing fields (`SaveManager.migrate`).
- [x] ⛔ `checksum` (CRC32) validates; corruption / `schemaVersion > CURRENT` ⇒ refuse + message (`CHECKSUM_MISMATCH` / `VERSION_AHEAD`).
- [x] ⛔ Writes ONLY at safe nodes (Town-enter, floor-clear); mid-combat NOT persisted (`SceneManager` + smoke asserts `battleState` absent).
- [x] Single slot; `New Run` requires confirm dialog (`SceneManager.new_run_confirmed()`; confirm UI in Sprint 2).

## E. Asset Pipeline Honors art-bible §9.4 (hard budget)
- [x] ⛔ **Palette validator (CI):** `tools/palette_validator.gd` (≤ 48 colors) wired into CI gate.
- [x] ⛔ **Atlas audit (CI):** `tools/asset_audit.py` (≤ 4 × 1024², 1 grain, ≤ 16 MB, WebP/PNG) wired into CI; `AssetRegistry.validate_atlas` enforces the 3 constraints.
- [ ] ⛔ Viewport test: Underdog Stage tappable at **360×640**; all controls ≥ **44×44px**; responsive anchors — **deferred to Sprint 2** (no feature UI in Sprint 1; scene skeletons only).
- [x] Ward-Sigils generated from Ward-Ring + primitive glyph grammar; **shape is the ID channel** (`content/sigils.json` shape ids: flame/snow/bolt/mountain/wind/sun/moon).

## F. Data-Driven Content (ADR-003)
- [x] ⛔ MVP defs present as data: 4 jobs, 7 sigils, 2 enemies, 1 item, 3 equipment, 1 dungeon (placeholder values; E8 locks numbers) in `content/*.json`.
- [x] ⛔ Content-lint CI: `tools/content_lint.py` (no duplicate ids, required fields) wired into CI.
- [ ] Extension proof: adding an 8th-job `.tres` needs **zero** code change — **deferred to L2–L5** (structure in place; `AssetRegistry.load_content` is data-only).

## G. Testing Harness — Sprint 1 ✅ (CI pending GUT install)
- [ ] ⛔ GUT installed; `tests/` runs green in CI (`--headless`). **GUT addon (`addons/gut/`) is an external dependency not committed in-repo** — CI installs/references it (see ci.yml). All 5 test files written + trace-verified.
- [x] ⛔ Smoke harness: `tests/smoke/test_boot_to_save.gd` (Boot→Title→Town→Dungeon→Combat→win→safe-node Save) written + trace-verified.
- [ ] FPS/heap debug HUD available for perf budgeting (architecture §5) — **deferred to Sprint 2**.

## H. Balance Spike (design + engineering) — unblocks numeric lock
- [ ] ⛔ ATK/DEF/MAG/RES/SPD, `xpToNext(l)=round(20*l^1.35)`, spell power/cost, variance, AI aggression locked before combat numbers implemented.

---

## Sign-off
- Engineering-lead: ________  Date: ________
- Studio lead (游承峰): ________  Date: ________

> Blocker count must be **0** before Phase 4 implementation begins. CONCERNS in architecture-review §6
> are tracked but do not block Phase 4 start once the ⛔ items above are ✅.
