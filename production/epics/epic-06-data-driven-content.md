# Epic E6 — Data-Driven Content (checklist F, ADR-003)

**Goal:** Author all MVP content as data so L2–L5 scales with zero code change (lead decision, ADR-003).
Satisfies every ⛔ item in checklist F. Supplies defs consumed by E2/E3/E4/E5.
**Owning systems:** S1/S2/S3/S4/S5 (data). **Depends on:** E1 (content dir), E2-D (AssetRegistry loader).

## Story E6-A · Author MVP Defs as Data
- **User Story:** As a designer, I want jobs/sigils/enemies/items/equipment/dungeon defined in data, so I tune without touching code (ADR-003).
- **Ref:** checklist F ⛔; ADR-003; main-arch §2.5; GDD content lists.
- **DoD:** `content/` holds `.tres`/JSON for: 4 jobs (Vanguard/Channeler/Skirmisher/Warden with stats, growth, kit, aptitude, skills, startGear), 4 sigils (Ember/Frost/Storm/Stone + spells), ~6 enemies + 1 mini-boss (`Sigil-Twisted Warden`), ~3 items (Herb/Ember Tonic/Bulk Salve-L2), ~6 equipment, 1 dungeon (`The Sundered Ward`, 4 floors). Element ids are lowercase canonical of GDD enum.
- **Acceptance (testable):**
  1. Integration: `AssetRegistry` loads all defs with zero missing/duplicate ids (E2-D).
  2. Review: values match GDD content lists (party-jobs §3, elements §6, progression §6, world-nodes §6, combat §6).
  3. Unit: affinity/element refs in content resolve to `ElementRegistry` entries (no typos).
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E2-D, E2-E

## Story E6-B · Content-Lint CI
- **User Story:** As an engineer, I want a CI gate on content integrity, so typos/omissions fail fast (ADR-003).
- **Ref:** checklist F ⛔; ADR-003; main-arch §2.5.
- **DoD:** A content-lint (in `tools/asset_audit.py` or a `content_lint.gd`) asserts: unique ids per table, required fields present, enum refs valid, numeric ranges sane (stats ≥1, MP costs 4–10, resonance ≤5, level cap 20).
- **Acceptance (testable):**
  1. CI: duplicate id ⇒ fail naming the table+id.
  2. CI: missing required field or bad enum ref ⇒ fail.
  3. CI: clean content ⇒ pass.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E6-A

## Story E6-C · Extension Proof (L2 zero-code-change)
- **User Story:** As an engineer, I want proof that L2 content needs no code change, so the "no refactor" lock-in holds (lead decision, phase2 §22.6).
- **Ref:** checklist F; ADR-003; main-arch §4 (extensibility).
- **DoD:** Adding an 8th job `.tres` (L2-shaped) + a 5th sigil appears in Barracks/Codex with correct kit/aptitude — with **zero** script edits.
- **Acceptance (testable):**
  1. Demo/Test: drop `job_8.tres` + `sigil_5.tres`; `AssetRegistry` picks them up; Barracks lists them; no code change required.
- **Sprint:** Later · **⛔ Blocker:** no · **Depends:** E6-A, E2-D, E2-I, E2-J
