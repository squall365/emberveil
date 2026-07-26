# EMBERVEIL — Engineering Guide (CLAUDE.md)

Original-IP turn-based party JRPG. **Godot 4.3, `gl_compatibility` (WebGL2), HTML5 / web / 小游戏.**
**Pure offline, single local slot, no cloud / login / account.** Analytics OFF.

> Engineering contract & ADRs: **`docs/architecture/main-architecture.md`** (paired with `docs/architecture/adr/`).

## Hard boundaries (do not violate)
- **No Square Enix / Final Fantasy 1 assets.** Original-IP only. The Underdog Stage is a
  bespoke composition; Ward-Sigil shapes use original IDs (see `content/sigils.json`).
- **Web budget:** ≤4×1024² atlases (A Characters / B Environment / C UI-VFX / D 512 grain),
  ≤16 MB decoded, ≤48 colors, 360×640 safe area, ≥44 px hit targets.
- **Three asset constraints (phase4-gate §3.2):** Atlas A mipmaps OFF; Atlas B building facade
  ≤200×240 flat; Atlas C ≤12 VFX types. Enforced in `AssetRegistry.validate_atlas` + CI.
- **Determinism:** all combat randomness flows through `RNGService` only. No `randi()`/`randf()`/
  `OS.rand` inside `src/combat` or `src/battle` (CI lint guard fails the build otherwise).
- **Safe-node-only saves:** only Town entry and Dungeon floor-clear persist. Mid-combat state is
  NEVER written.

## Autoload order (see `project.godot`)
`SettingsManager → RNGService* → EventBus → AssetRegistry → ElementRegistry → WardCodex →
SaveManager → PartyManager → ProgressionManager → WorldDirector → SceneManager → AudioBus → Analytics`
(`RNGService` is an instantiable `class_name`, **not** an autoload singleton — combat tests build
seeded instances via `RNGService.new()`.)

**12 autoloads + RNGService `class_name`** — the 12 autoloads are the nodes listed above (RNGService
appears with a `*` only to mark its dependency slot; it is never registered as an autoload).

## Coding standards by layer
- **gameplay / content:** data-driven. No hardcoded balance numbers — values live in `content/`
  (ADR-003). Tuning is the E8 spike's job.
- **core / combat:** pure functions, zero hot-path allocation where possible, deterministic.
- **ai:** debuggable, deterministic given (state, actor, rng).
- **ui:** never holds game state; subscribes to `EventBus`; reads via managers.
- **network:** N/A (pure offline) — server-authoritative rule is moot; all authority is local.

## Run / verify
- Editor: open `project.godot`, F5 boots `scenes/boot/Boot.tscn`.
- Tests (GUT, must be installed at `addons/gut/`): `godot --headless -s addons/gut/gut_cmdln.gd
  -gdir=res://tests -gexit`
- CI (`.github/workflows/ci.yml`) gates: headless boot, GUT, `asset_audit.py`,
  `palette_validator.gd`, `content_lint.py`, combat RNG lint.

## Save format (ADR-004)
JSON → `localStorage["emberveil.save.v1"]`. Fields: `schemaVersion`, `seed`, `party[]`,
`runProgress`, `worldState`, `settings`, `crc` (CRC32 hex over the body). Derived stats
(`maxHP`/`ATK`/…) are NOT persisted. Version ahead → refused; checksum mismatch → refused.
