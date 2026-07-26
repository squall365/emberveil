# ADR-003 — Content-as-Data (Resources / JSON)

- **Status:** Accepted
- **Date:** 2026-07-26
- **Deciders:** engineering-lead (程基岩), studio lead (游承峰)
- **Supersedes:** —

## Context

The studio lead's locked decisions (phase2 review §22) require **L2–L5 (job-change, overworld +
Driftwing, story arcs, post-game) to scale WITHOUT requiring refactoring** — content must be
data-driven. The MVP scope is small (4 jobs, 4 sigils, 1 dungeon) but the expansion paths add
jobs (→8), sigils (→7), dungeons (→many), towns, and story. Godot 4's `Resource` system is the
natural fit.

If content (jobs, spells, enemies, dungeon layout) were hardcoded as constants in scripts, every
L2–L5 addition would force code edits, recompilation, and regression risk — directly violating the
"no refactor" requirement.

## Decision

Author **all game content as data**, loaded by `AssetRegistry` at boot:

- Godot `Resource` subtypes (`.tres`) for: `JobDef`, `ElementDef`, `WardSigilDef`, `SpellDef`,
  `EnemyDef`, `ItemDef`, `EquipmentDef`, `DungeonDef`/`RoomDef`. (See architecture §2.5.)
- Engine code **reads** defs; it never embeds content values. Adding content = add/replace a `.tres`
  (or JSON mirror) file — no script change.
- A content **manifest** (folder scan or index) lets `AssetRegistry` build lookup tables by id;
  missing/duplicate ids fail fast at load (defensive against typos).
- `RunState` (save) persists *references* (ids) + progression scalars, never embedded content.

## Consequences

**Positive**
- L2–L5 = drop-in data files; zero engine-code refactor (satisfies lead decision).
- Designers (design-strategist) can tune content in the Godot editor without touching scripts.
- Content is versioned alongside save migration (ADR-004) — a new sigil id just needs its `.tres`.
- Smaller, more readable code; content diffs are isolated from logic diffs in review.

**Negative / costs**
- Need a schema/validation layer (ids unique, required fields present) — `AssetRegistry` validates
  on load; a CI "content lint" guards it.
- `.tres` is Godot-binary-ish text; a JSON mirror (or pure JSON) may be preferred for some tables to
  ease external tooling/diffing. Decision: `.tres` for editor-authored defs, JSON for dungeon/room
  graphs if hand-authored at scale.
- Slightly higher boot cost to load + validate tables (negligible at MVP size; cached after load).

## Alternatives Considered

1. **Hardcoded constants/tables in scripts** — Rejected. Fastest to write initially, but every L2–L5
   feature requires code changes → directly violates the "no refactor" lock-in. High regression risk.
2. **Full scripting / modding sandbox (e.g. Lua)** — Rejected as over-engineering for MVP. Godot
   `Resource` already gives data-driven authoring without a scripting layer; modding is out of scope.
3. **Database (SQLite / external store)** — Rejected. Content is static author-time data, not runtime
   queries; a DB adds weight and a web-loading dependency for no benefit at this scale.

## Validation

- Integration: `AssetRegistry` builds every def table from `content/` with no missing/duplicate ids.
- Extension test (Phase 4): adding an 8th job `.tres` (L2-shaped) requires **zero** code change and
  appears in Barracks with correct kit/aptitude.
- Content-lint CI fails on duplicate ids / missing required fields.
