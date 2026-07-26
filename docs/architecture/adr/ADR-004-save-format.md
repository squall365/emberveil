# ADR-004 — Save Format, Versioning & Migration

- **Status:** Accepted
- **Date:** 2026-07-26
- **Deciders:** engineering-lead (程基岩), studio lead (游承峰)
- **Supersedes:** —

## Context

`save-load.md` (S6) defines persistence: a single `RunState` schema that every system serializes
into; **single local slot MVP**; writes only at safe nodes (no mid-combat save-scum); `New Run`
requires confirm; a `schemaVersion` for migration; graceful handling of corruption/quota. The web
mini-game stores in `localStorage` (`emberveil.save.v1`), a few KB, JSON.

We must choose a serialization format and a migration strategy that stays debuggable, tiny, and
forward/backward safe as content grows (L2–L5 add fields to `RunState`).

## Decision

- **Format:** **JSON** to `localStorage` key `emberveil.save.v1`. Human-readable, trivially
  debuggable, tiny at MVP size, and easy to diff/migrate. Optional `checksum` (CRC32) for corruption
  detection (cheap, no crypto needed for a local single-player save).
- **Single slot.** `New Run` overwrites only after an explicit confirm dialog (S6 §7).
- **Safe-node-only writes:** `SaveManager` exposes `save_at_safe_node()`; called by `SceneManager`
  on Town-enter, floor-clear, sigil-attune, quest-complete. Mid-combat state is **never** written
  (reload returns to pre-battle safe point).
- **Versioning / migration:**
  - On load, read `schemaVersion`.
  - If `schemaVersion < CURRENT` → run ordered up-migration functions `[v1→v2→…]` that fill/
    transform fields; then persist the migrated copy.
  - If `schemaVersion > CURRENT` → **refuse load**, show a message (no corrupt/forward-only restore).
  - If `checksum` present → validate; mismatch ⇒ refuse + "save failed/corrupt" message.
- **Privacy:** local only, no PII (cloud = L4, out of MVP).

## Consequences

**Positive**
- JSON is debuggable in devtools; testers can inspect/edit saves; migration logic is plain code.
- Single slot + confirm + safe-node writes fully implement the anti-save-scum design (world-nodes §7).
- Migration path supports L2–L5 field additions without breaking old saves.
- Checksum catches the common `localStorage` corruption / partial-write case.

**Negative / costs**
- JSON is larger than binary; at "a few KB" this is irrelevant, but L5 (endless dungeon history) could
  grow — mitigated by storing only references + scalars (ADR-003), never embedded content, and
  capping inventory (progression §7).
- Must write + maintain migration functions per version; a CI test asserts every `vN→vN+1` round-trips.
- `localStorage` can be full/blocked (private mode) → `SaveManager` must degrade gracefully
  ("save failed, continue in-session") without crashing.

## Alternatives Considered

1. **Binary + checksum (custom packer)** — Rejected for MVP. Smaller/faster, but undebuggable without
   a tool, harder to migrate, and unnecessary at a few-KB size. Revisit only if L5 save size balloons.
2. **SQLite / IndexedDB relational store** — Rejected. Overkill for one flat `RunState` object; adds a
   web dependency and complexity with no benefit at this scale.
3. **No versioning (overwrite blindly)** — Rejected. Any content/schema change would corrupt old saves
   or crash on load — unacceptable under FULL review and the L2–L5 longevity requirement.

## Validation

- Unit: serialize→deserialize round-trip equals original `RunState`.
- Unit: corrupt `checksum` ⇒ load refused with message; `schemaVersion > CURRENT` ⇒ refused.
- Unit: migration `v1→v2` transforms a v1 save into a valid v2 save (CI covers each step).
- Integration: smoke test writes at a safe node, reloads, and restores identical `RunState`; a
  mid-combat quit correctly loses only the in-progress battle (reloads to pre-battle safe point).
