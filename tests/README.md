# EMBERVEIL — Test Harness (GUT)

Verification-driven (tests before code). Runs headless in CI via `godot --headless`.

## Structure

```
tests/
├─ unit/            # pure, fast, no scene tree
│  ├─ test_affinity.gd          # element affinity: symmetric 7-cycle, 1.5/0.67/1.0
│  ├─ test_save_roundtrip.gd    # RunState serialize/deserialize, migration, checksum, refusal
│  └─ test_combat_math.gd       # damage formulas (Attack/Elemental) + clamping
├─ integration/     # module composition
│  └─ test_combat_fsm_determinism.gd  # fixed seed ⇒ deterministic battle outcome+log
├─ smoke/           # full happy path
│  └─ test_boot_to_save.gd      # Boot→Title→Town→Dungeon→Combat→win→safe-node Save
└─ README.md
```

## Run locally

```bash
# full suite (headless)
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests

# single script
godot --headless --path . -s addons/gut/gut_cmdln.gd -gunit=res://tests/unit/test_affinity.gd
```

## CI (GitHub Actions)

See `.github/workflows/ci.yml`. Pipeline:
1. `godot --headless` import + boot-to-Title smoke (checklist A/C ⛔).
2. GUT unit + integration + smoke suites (checklist G ⛔).
3. `python tools/asset_audit.py` — texture/atlas budget (checklist E ⛔).
4. `godot --headless --script tools/palette_validator.gd` — 48-color palette (checklist E ⛔).
5. content-lint + combat RNG lint guards.

Any step non-zero ⇒ pipeline fails (no merge).

## Status

These files are **stubs** targeting the planned API from `docs/architecture/` (ADR-002/004,
main-arch §3–§4). They compile-green once Epics E2/E3/E4 land. Assertions are written to the
GDD-exact contracts (affinity 1.5/0.67/1.0; save round-trip; determinism) so they become the
regression gate the moment implementation arrives.
