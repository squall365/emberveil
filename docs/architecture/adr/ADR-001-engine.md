# ADR-001 — Engine Selection: Godot 4 (HTML5 / WebGL2)

- **Status:** Accepted
- **Date:** 2026-07-26
- **Deciders:** engineering-lead (程基岩), studio lead (游承峰)
- **Supersedes:** —

## Context

EMBERVEIL is a web / 小游戏 (instant-play) turn-based party JRPG. Hard constraints from
`design/art/art-bible.md` §9.4 and the concept doc:

- Instant-play in a browser; broad reach on low-end mobile web.
- **Texture budget:** ≤ 4 × 1024² atlases, ≤ 16 MB decoded, 1 shared 128² grain.
- **Viewport:** safe at 360×640; ≥ 44px hit targets; responsive (no fixed-res art).
- **Palette:** ≤ 48 colors.
- Original-IP only (no SE/FF1 assets) — engine must not pull in any licensed IP.

We need a mature scene/UI/resource pipeline without a multi-MB per-title framework tax, and the
ability to ship a deterministic, testable combat core. The candidate engines were **Godot 4 HTML5**,
**Unity WebGL**, and **pure web (Canvas/WebGL from scratch)**.

## Decision

Adopt **Godot 4 with the HTML5 / WebGL2 (`gl_compatibility`) export** as the engine.

- GDScript as the primary scripting language; GDExtension reserved only for verified hot paths.
- Single PCK + HTML/JS/WASM shell; small enough initial footprint with proper export config.
- `Control`/`Container` UI nodes for responsive HUD (Underdog Stage) at 360×640.
- Godot `Resource` system for data-driven content (see ADR-003).
- Headless CI via `--headless` + GUT for verification-driven tests.

## Consequences

**Positive**
- Built-in scene tree, signal system, and `Resource`/`.tres` pipeline accelerate content-as-data.
- Control-node UI is resolution-independent → honors the 360×640 / 44px / responsive mandate natively.
- Mature HTML5 export; WebGL2 (`gl_compatibility`) maximizes low-end device coverage.
- Small runtime; no per-title framework royalty; no SE/FF1 code/assets in the engine.

**Negative / costs**
- Web is **single-threaded** — no threads; async must use coroutines/`yield` (architecture §5).
- WebGL2 caps some shader effects; must rely on value-range + flat palette, not complex shaders (matches art-bible §5).
- Must actively enforce 16 MB texture / 48-color budgets via CI audit (budgets not auto-enforced).
- Godot HTML5 audio uses WebAudio; `AudioBus` wiring deferred to Phase 4/6 (placeholder now).

## Alternatives Considered

1. **Unity WebGL** — Rejected. Larger initial download (~tens of MB WASM) strains the instant-play
   mini-game goal on low-end mobile; heavier runtime; licensing/overhead not justified for a
   menu-driven, palette-limited 2D game. Strong engine, wrong fit for this budget class.
2. **Pure web (Canvas/WebGL, hand-rolled)** — Rejected. Maximum control over bytes, but we would
   re-implement scene graph, UI layout, input, audio, and resource loading ourselves — months of
   non-game work, and high risk of reinventing Godot's solved problems. Only justified if the
   engine itself were an IP liability (it is not).
3. **Godot 4 + GDExtension-heavy** — Partially rejected. GDExtension (C#/C++) for everything adds
   build complexity and WASM size; GDScript is sufficient for a turn-based, non-real-time game.
   GDExtension kept as an *escape hatch* for profiled hot paths only.

## Validation

- Export shell boots to Title under 3 s on a 3G-class emulation (architecture §5 budget).
- A `Control`-based Underdog Stage scene renders tappable at 360×640 with ≥44px targets (smoke test).
- CI asset audit fails the build if texture/atlas/palette budgets are exceeded.
