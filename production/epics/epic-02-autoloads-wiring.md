# Epic E2 — Autoloads & Module Wiring (checklist B)

**Goal:** All cross-cutting singletons + system-owning managers registered and functional, satisfying
every ⛔ item in checklist B, plus routing + later feature UIs for S1/S3/S4/S5.
**Owning systems:** S1 (PartyManager), S3 (ElementRegistry/WardCodex), S4 (ProgressionManager),
S5 (WorldDirector routing) + cross-cutting. **Depends on:** E1.

## Story E2-A · SettingsManager Autoload
- **User Story:** As a player, I want my accessibility/audio prefs applied at boot, so the game respects my needs every session.
- **Ref:** checklist B ⛔; art-bible §9.1; save-load §4.
- **DoD:** `SettingsManager` autoload registered; reads `emberveil.settings.v1`; applies colorblind-assist / reduced-motion / text-scale(100–125%) / master+sfx volume; exposes typed getters.
- **Acceptance (testable):**
  1. Unit: `load()` returns defaults when no storage; applies stored values when present.
  2. Unit: `text_scale` clamps to [1.0, 1.25]; `reduced_motion` default false.
  3. Integration: boot applies settings before Title builds (assert in smoke).
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E1-D

## Story E2-B · RNGService (seedable PRNG)
- **User Story:** As an engineer, I want one seedable RNG as the sole randomness source, so combat is deterministic & testable (ADR-002).
- **Ref:** checklist B ⛔; ADR-002; main-arch §2.1, §3.2.
- **DoD:** `RNGService` autoload exposes `seed(s)`, `next_float()`, `next_int(a,b)`, `next_variance()` (±10%); pure given seed.
- **Acceptance (testable):**
  1. Unit: same seed ⇒ identical sequence of 1000 draws.
  2. Unit: `next_variance()` ∈ [0.9, 1.1] for 1000 draws.
  3. Lint: no `randi()/randf()/OS.rand()` in `src/combat`, `src/battle` (CI).
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E1-D

## Story E2-C · EventBus (UI-only signal bus)
- **User Story:** As an engineer, I want a typed signal bus for UI/feedback, so game logic stays pure & testable (main-arch §2.4).
- **Ref:** checklist B ⛔; main-arch §2.4; ADR-002.
- **DoD:** `EventBus` autoload with typed Signals (combat_*, progression_*, world_*, codex_*, save_*); docs state signals are post-update notifications only.
- **Acceptance (testable):**
  1. Unit: emitting `combat_action_resolved` does NOT mutate BattleState (logic lives in resolver).
  2. Lint/Review: no `BattleState` mutation inside EventBus handler bodies.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E1-D

## Story E2-D · AssetRegistry (content loader)
- **User Story:** As an engineer, I want content loaded from data into memory at boot, so code never hardcodes content (ADR-003).
- **Ref:** checklist B ⛔; ADR-003; main-arch §2.5.
- **DoD:** `AssetRegistry` scans `content/`, builds id→def tables (jobs, elements, sigils, spells, enemies, items, equipment, dungeons); fails fast on missing/duplicate id.
- **Acceptance (testable):**
  1. Integration: loads all MVP defs (E6) with zero missing/duplicate ids.
  2. Unit: duplicate id ⇒ load throws with the offending id.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E1-D, E6-A (defs exist)

## Story E2-E · ElementRegistry + WardCodex
- **User Story:** As an engineer, I want the 7-element enum + affinity matrix + shared party Codex available globally, so combat/world read a single source of truth.
- **Ref:** checklist B ⛔; elements §2/§3; main-arch §3.3.
- **DoD:** `ElementRegistry` exposes `ALL`, `affinity(a,b)` (1.5/0.67/1.0), `strong_vs/weak_vs` (symmetric 7-cycle). `WardCodex` holds `attunedSigilIds:Set`, `resonance:Map`, `discoveredSet`; Set semantics (re-attune = no-op).
- **Acceptance (testable):**
  1. Unit: `affinity("Ember","Frost")==1.5`, `affinity("Frost","Ember")==0.67`, neutral==1.0.
  2. Unit: each element strong vs exactly 1, weak vs exactly 1 (symmetric cycle assert).
  3. Unit: re-attuning same sigil leaves Codex unchanged (no dupe).
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E2-D

## Story E2-F · SaveManager + PartyManager + ProgressionManager
- **User Story:** As a player, I want my run, party, and progress state held coherently, so a save restores exactly what I had.
- **Ref:** checklist B ⛔; save-load §3; party-jobs §3; progression §2/§3.
- **DoD:** `SaveManager` owns RunState load/save (delegates to E4). `PartyManager` holds 4 slots, max-1-per-job rule, recomputes derived stats from Job+Progression. `ProgressionManager` applies XP/level, equipment mods, resonance from combat events.
- **Acceptance (testable):**
  1. Unit: `PartyManager.assign(jobId)` rejects a 2nd copy of a job (max-1-per-job).
  2. Unit: derived stats recompute = base + growth*level + equipment mods (no double store).
  3. Integration: on `combat_ended(win)`, ProgressionManager credits XP; level-up applies growth.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E2-D, E4 (save schema)

## Story E2-G · SceneManager + WorldDirector Routing
- **User Story:** As a player, I want seamless Boot→Title→Town/Dungeon→Battle flow, so the world feels continuous and saves stay consistent.
- **Ref:** checklist B; main-arch §2.2; world-nodes §2.
- **DoD:** `SceneManager` swaps scenes; `WorldDirector` keeps `World.tscn` resident, instances Town/Dungeon, launches `Battle.tscn` as overlay; never serializes mid-battle.
- **Acceptance (testable):**
  1. Integration (smoke): Boot→Title→Town→Dungeon→Battle→win→safe-node Save reaches each node.
  2. Unit: battle scene is an overlay (not persisted); reload returns to pre-battle safe point.
- **Sprint:** 1 · **⛔ Blocker:** no · **Depends:** E2-A..F, E3, E4

## Story E2-H · AudioBus Placeholder
- **User Story:** As an engineer, I want an audio event bus stub, so sfx/music can be wired in Phase 4/6 without refactoring.
- **Ref:** checklist B; main-arch §1.1; architecture-review CONCERN 3.
- **DoD:** `AudioBus` autoload exposes `play_sfx(id)` / `play_music(id)` that no-op or log; emits events only; no audio assets imported.
- **Acceptance (testable):**
  1. Unit: calling `play_sfx` with unknown id logs, does not crash.
  2. Review: no SE/FF1 audio asset referenced (IP guardrail).
- **Sprint:** 1 · **⛔ Blocker:** no · **Depends:** E1-D

## Story E2-I · Party Composition / Barracks UI (Later)
- **User Story:** As a player, I want to compose my 4-hero party at Town Barracks, so I can express the Compose verb.
- **Ref:** party-jobs §4; world-nodes §6 (Barracks).
- **DoD:** Barracks node lists jobs; assign enforces max-1-per-job; greyed uncastable; persists via SaveManager.
- **Acceptance (testable):** UI blocks assigning a duplicate job; persisted assignment reloads identically.
- **Sprint:** Later · **⛔ Blocker:** no · **Depends:** E2-F, E6

## Story E2-J · Ward Codex Casting in Combat Dock (Later)
- **User Story:** As a player, I want to pick Codex spells in the command dock, so elemental magic is usable when aptitude+MP allow.
- **Ref:** elements §4; combat §2 (Elemental); art-bible §7.3.
- **DoD:** Elemental command sub-menu lists castable Codex spells (sigil attuned ∧ aptitude>0 ∧ MP≥cost); greys otherwise with shape+label.
- **Acceptance (testable):** Uncastable spell hidden/greyed; cast consumes MP; affinity applied via resolver.
- **Sprint:** Later · **⛔ Blocker:** no · **Depends:** E2-E, E3

## Story E2-K · Progression UI (equipment/shop/inventory) (Later)
- **User Story:** As a player, I want to manage gear, shop, and items in Town, so I grow my party.
- **Ref:** progression §4; world-nodes §6 (Market/Inn).
- **DoD:** Market buy/sell with gold; equipment swap applies mods live; inventory cap enforced.
- **Acceptance (testable):** Equipping updates derived stats; sell price < buy price (no dupe economy).
- **Sprint:** Later · **⛔ Blocker:** no · **Depends:** E2-F, E6

## Story E2-L · Town Scene + Nodes (Later)
- **User Story:** As a player, I want a safe Town hub, so I can rest/shop/compose/save between dungeon runs.
- **Ref:** world-nodes §2/§6; Hearthmoor.
- **DoD:** Town scene with Inn/Market/Barracks/Sage/Shrine nodes; safe zone (no encounters); Rest = full heal.
- **Acceptance (testable):** Entering Town triggers autosave; Rest restores HP/MP.
- **Sprint:** Later · **⛔ Blocker:** no · **Depends:** E2-G, E2-I, E2-K

## Story E2-M · Dungeon Scene + Floors/Rooms/Puzzle/Boss (Later)
- **User Story:** As a player, I want a 4-floor dungeon with combat/puzzle/reward/mini-boss, so I get a complete beat.
- **Ref:** world-nodes §2/§6; combat §6 (mini-boss).
- **DoD:** Dungeon from `DungeonDef`; 4 floors × rooms (Combat/Puzzle/Reward/Boss); puzzle = sigil-stone order; mini-boss drops Stone Sigil; floor-clear autosaves.
- **Acceptance (testable):** Clearing a floor triggers safe-node save; puzzle resets on leave (no soft-lock); boss defeat attunes Stone.
- **Sprint:** Later · **⛔ Blocker:** no · **Depends:** E2-G, E3, E6
