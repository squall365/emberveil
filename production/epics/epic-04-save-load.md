# Epic E4 — Save / Load System (checklist D, GDD S6)

**Goal:** A single-slot, safe-node-only, versioned & checksummed local save that satisfies every ⛔ item
in checklist D. **Owning system:** S6. **Depends on:** E2 (SaveManager wiring, SettingsManager), E6 (content ids).

## Story E4-A · RunState Schema + Serialize/Deserialize Round-Trip
- **User Story:** As a player, I want my run persisted to localStorage and restored exactly, so I can resume short sessions.
- **Ref:** checklist D ⛔; save-load §2/§3; ADR-004; main-arch §4.
- **DoD:** `RunState { schemaVersion, seed, party[4], runProgress, worldState, settings, savedAt }` (ids lowercase canonical of GDD enum per main-arch §4). `SaveManager.save(state)` → JSON at `emberveil.save.v1`; `load()` → identical object.
- **Acceptance (testable):**
  1. Unit: `deserialize(serialize(s))` deep-equals `s` for a populated RunState.
  2. Unit: derived stats are NOT stored (recomputed on load) — round-trip ignores them.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E2-F

## Story E4-B · schemaVersion Migration v1→v2
- **User Story:** As an engineer, I want old saves migrated forward, so content growth (L2–L5) never corrupts a player's file (ADR-004).
- **Ref:** checklist D ⛔; ADR-004; main-arch §4.
- **DoD:** `migrate(vN) -> vN+1` functions registered in order; on load, apply chain until `CURRENT`; persist migrated copy.
- **Acceptance (testable):**
  1. Unit: a v1 fixture transforms into a valid v2 RunState (all required v2 fields present/defaulted).
  2. CI: covers each migration step round-trips.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E4-A

## Story E4-C · Checksum + Corruption / Forward-Version Refusal
- **User Story:** As an engineer, I want corrupt or newer-than-supported saves refused safely, so the game never loads a broken state (save-load §7).
- **Ref:** checklist D ⛔; ADR-004; save-load §7.
- **DoD:** Optional CRC32 `checksum` validates on load; mismatch ⇒ refuse + "save corrupt" message. `schemaVersion > CURRENT` ⇒ refuse + message (no crash).
- **Acceptance (testable):**
  1. Unit: tampered checksum ⇒ load returns `null` + error flag.
  2. Unit: `schemaVersion > CURRENT` ⇒ load refused (no partial restore).
  3. Unit: valid checksum ⇒ loads normally.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E4-A, E4-B

## Story E4-D · Safe-Node-Only Writes (mid-combat NOT persisted)
- **User Story:** As a player, I want saves written only at safe nodes, so I can't save-scum a lost battle (world-nodes §7; save-load §2).
- **Ref:** checklist D ⛔; save-load §2; world-nodes §7; main-arch §4.
- **DoD:** `SaveManager.save_at_safe_node()` is the only public writer; called by SceneManager on Town-enter, floor-clear, sigil-attune, quest-complete. Battle scene never calls save; reload returns to pre-battle safe point.
- **Acceptance (testable):**
  1. Integration: writing mid-combat is a no-op (or blocked) — only safe-node calls persist.
  2. Integration: quitting mid-battle reloads to the pre-battle safe node (battle state absent).
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E4-A, E2-G

## Story E4-E · Single Slot + New Run Confirm
- **User Story:** As a player, I want a single slot with a confirm before overwrite, so I never lose a run by accident (save-load §4/§7).
- **Ref:** checklist D; save-load §4/§7; concept (pure-offline: no cloud/account).
- **DoD:** Title offers Continue / New Run; New Run shows confirm dialog; overwrite only after confirm. No login/account flow (pure-offline decision).
- **Acceptance (testable):**
  1. Unit: `new_run()` without confirm is rejected; with confirm overwrites single slot.
  2. UI: Continue hidden when no save exists.
- **Sprint:** 1 · **⛔ Blocker:** no · **Depends:** E4-A, E2-A
