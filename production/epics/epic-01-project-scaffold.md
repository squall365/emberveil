# Epic E1 — Project Scaffold (checklist A)

**Goal:** A bootable, CI-tracked Godot 4 HTML5 project that satisfies every ⛔ item in checklist A.
**Owning systems:** cross-cutting. **Depends on:** nothing (first epic).

## Story E1-A · Godot 4 Project + gl_compatibility
- **User Story:** As an engineer, I want a Godot 4 (latest-stable) project configured for WebGL2, so that the build runs on low-end mobile web per ADR-001.
- **Ref:** checklist A ⛔; ADR-001; main-arch §5.
- **DoD:** `project.godot` sets `rendering/renderer/rendering_method=gl_compatibility`; project opens in editor; a minimal Boot scene exists.
- **Acceptance (testable):**
  1. `godot --headless --path . --quit` exits 0 with no import errors.
  2. `project.godot` contains `gl_compatibility` rendering method (grep/ConfigFile assert in CI).
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** none

## Story E1-B · CLAUDE.md (tech preferences)
- **User Story:** As a contributor, I want a `CLAUDE.md` stating engine version, GDScript-primary, and GDExtension-escape-hatch policy, so that tooling and future agents align.
- **Ref:** checklist A ⛔; main-arch §7.4.
- **DoD:** `CLAUDE.md` at repo root documents: Godot 4 version pin, GDScript primary, GDExtension only for profiled hot paths, repo layout, test command.
- **Acceptance (testable):**
  1. `CLAUDE.md` exists and references `docs/architecture/main-architecture.md`.
  2. CI lint confirms it is non-empty and lists the engine version.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** none

## Story E1-C · HTML5/WebGL2 Export Preset + CI boot-to-Title
- **User Story:** As an engineer, I want an HTML5 export preset and a CI job that boots to Title headless, so that regressions are caught before merge.
- **Ref:** checklist A ⛔; main-arch §2.2 (Boot→Title).
- **DoD:** `export_presets.cfg` has a WebGL2 preset; GitHub Actions builds it and runs `godot --headless` boot that reaches Title without error.
- **Acceptance (testable):**
  1. CI step produces `index.html` + `.wasm`/`.pck` artifacts.
  2. Headless boot logs `TITLE_REACHED` (or scene-path == Title) within timeout.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E1-A

## Story E1-D · Repo Layout (src / content / tests / docs)
- **User Story:** As a contributor, I want a consistent repo layout, so that code, data, tests, and docs are discoverable.
- **Ref:** checklist A ⛔; main-arch §1, §2.5.
- **DoD:** `src/` (autoloads+modules), `content/` (.tres/JSON defs), `tests/` (GUT), `docs/architecture/` exist; `.gitignore` covers `.godot/`, `*.import` caches.
- **Acceptance (testable):**
  1. CI asserts the four root dirs exist.
  2. `git status` clean of `.godot/` after a headless run.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** none
