# EMBERVEIL — Main Architecture Document (Phase 3 · Technical Foundation)

> **Status:** Phase 3 MVP · Review: FULL · Owner: engineering-lead (程基岩 / Cheng Jiyan)
> **Engine:** Godot 4 (HTML5 / WebGL2 export) · **Platform:** Web / 小游戏 (instant-play)
> **Upstream:** `design/gdd/index.md` + 6 system GDDs, `design/art/art-bible.md` §9.4, `design/concept/game-concept.md`
> **Original-IP rule:** No Square Enix / FF1 assets, layouts, fonts, or trademarks. Ward-Sigil language + Underdog Stage only.

This document is the engineering contract for Phase 4 (pre-production). It is paired with:
- `docs/architecture/adr/` — ADR-001 (engine), ADR-002 (combat FSM), ADR-003 (data-driven content), ADR-004 (save format)
- `docs/architecture/architecture-review.md` — consistency & gate verdict
- `docs/architecture/phase4-readiness-checklist.md` — pre-Phase-4 readiness gates

---

## 1. Design ↔ Engineering Traceability (GDD → Module)

Every GDD system has exactly one owning module. Cross-cutting systems are shared infrastructure.

| GDD | System | Owning Module | Responsibility | Serves |
|-----|--------|---------------|----------------|--------|
| S1 | Party & Jobs | `PartyManager` | Party of 4 slots, job assignment (max 1 per job), derived stat recompute, aptitude gates | Compose pillar |
| S2 | Turn-based Combat | `CombatController` + `BattleResolver` + `EnemyAI` | Deterministic turn/state machine, 5 commands, affinity damage, win/lose, Run | Readable Tactics pillar |
| S3 | Elements & Ward-Sigil | `ElementRegistry` + `WardCodex` | 7-element enum, affinity matrix, shared party Codex, resonance store | Elemental Literacy pillar |
| S4 | Progression | `ProgressionManager` | XP/level, equipment mods, gold, inventory, resonance growth | Session-Friendly Depth |
| S5 | World Nodes | `WorldDirector` (Town + Dungeon controllers) | 1 Town hub + 4-floor dungeon, rooms, puzzle gate, mini-boss, sigil reward | Explorable World |
| S6 | Save/Load | `SaveManager` | Single RunState schema, safe-node-only writes, versioning + checksum | Session resume |

### 1.1 Cross-Cutting Infrastructure (shared, autoloaded)

| Module | Responsibility | Notes |
|--------|----------------|-------|
| `SettingsManager` | Accessibility (colorblind-assist, reduced-motion, text-scale 100–125%), audio volumes | Loaded first; feeds UI + Combat |
| `RNGService` | **Single seedable PRNG** (battle seed) — sole source of randomness; `class_name`, instantiated per use (not an autoload) | Determinism (ADR-002) |
| `EventBus` | Decoupled signal bus for UI/feedback events only (NOT logic) | Keeps combat logic pure/testable |
| `AssetRegistry` (ContentLoader) | Loads `.tres`/JSON content defs into memory | Data-driven (ADR-003) |
| `SceneManager` (GameDirector) | Scene routing: Boot → Title → Town/Dungeon → Battle overlay; safe-node gating for saves. New Run is exposed **only** via `new_run_confirmed()` (requires a prior confirm dialog) — there is no unconfirmed `new_run()`. | Safe nodes: Town entry, Dungeon floor-clear |
| `SaveManager` | See S6 | — |
| `AudioBus` | **Placeholder** — Phase 4/6 wiring only; emits `sfx/music` events | No audio assets in MVP pipeline yet |
| `Analytics` (optional) | Telemetry hooks (beat cleared, battle result) | Off by default; privacy-safe local only |

> **Autoload count:** 12 autoload singletons + `RNGService` (`class_name`, instantiated per use — **not** an autoload). The 12 autoloads: SettingsManager, EventBus, AssetRegistry, ElementRegistry, WardCodex, SaveManager, PartyManager, ProgressionManager, WorldDirector, SceneManager, AudioBus, Analytics.

> IP guardrail: `AudioBus` and any future art/audio are original-expression only. No SE/FF1 samples enter the pipeline (art-bible §9.2).

---

## 2. Godot 4 Implementation Specifics

### 2.1 Autoload (Singleton) Strategy

Load order matters — dependencies first. Registered in `Project Settings > Autoload`:

```
1. SettingsManager   # reads localStorage/settings, applies accessibility
2. EventBus          # global signal bus
3. AssetRegistry     # scans content/ folder, builds def tables
4. ElementRegistry   # element enum + affinity matrix (from AssetRegistry)
5. WardCodex         # shared party Codex + resonance (from SaveManager/AssetRegistry)
6. SaveManager       # loads RunState if present
7. PartyManager      # current party/heroes (from SaveManager + AssetRegistry)
8. ProgressionManager# XP/level/equipment/inventory/resonance (from SaveManager)
9. WorldDirector     # scene composition owner
10. SceneManager     # routing (depends on WorldDirector/SaveManager)
11. AudioBus         # placeholder (Phase 4/6)
12. Analytics        # optional, off by default
```

> **RNGService is a `class_name` (instantiable), NOT an autoload singleton.** Combat / AI build
> seeded instances via `RNGService.new()` so determinism tests can construct independent RNGs
> (the integration test relies on this). It remains the sole randomness source (ADR-002).

Rationale: pure-data managers (EventBus, AssetRegistry, ElementRegistry) load before stateful ones (Party, Progression, Save). `CombatController` is **not** an autoload — it is instantiated per battle inside `Battle.tscn` (see §2.3) to keep combat state scoped and disposable.

### 2.2 Scene Tree Layout

```
Root (GameDirector / SceneManager owns swap)
 ├─ Boot.tscn            # splash, read SettingsManager, decide Continue/New
 ├─ Title.tscn           # Continue / New Run (New Run → confirm dialog, S6)
 ├─ World.tscn           # persistent hub; hosts Town OR Dungeon as child
 │   ├─ Town.tscn        # nodes: Inn(Rest)/Market(Shop)/Barracks/ Sage(Quest)/Shrine(Save)
 │   └─ Dungeon.tscn     # 4 floors × rooms; launches Battle overlay on CombatRoom
 └─ Battle.tscn          # overlay scene (Underdog Stage); returns result to World
```

- `World.tscn` stays resident; Town/Dungeon are instanced/removed by `WorldDirector` to preserve RunState across node transitions (no full reload = no save-scum risk, S6).
- `Battle.tscn` is added via `get_tree().get_root().add_child()` (or `SceneManager.change_scene_to_file` with a callback), **never** serialized mid-battle (S6: mid-combat state NOT persisted).

### 2.3 Scene Composition — Underdog Stage (combat.md §4, art-bible §6.2)

Built entirely from **Control nodes + Containers + responsive anchors** (no fixed pixel art). Layout:

```
┌─────────────────────────────┐  TopRibbon (Control/HCenter): turn pips, Run, Settings
│   EnemyArc (VBox+Arc offset) │  enemies staggered upper-back-arc; scale = depth cue
│        ◠  ◠  ◠              │
│                             │
│   PartyBand (CenterBottom)  │  4 hero medallions, overlapping silhouettes (one unit)
│                             │
│  ⦿hero [Cmd][Cmd][Cmd]      │  CommandDock (bottom-left, HBox of soft-rounded chips)
│         [context panel]     │  NOT a full-width window (FF1-inverted, art-bible §6.1)
└─────────────────────────────┘
```

- Safe at **360×640**; all interactive controls ≥ **44×44px** (art-bible §9.1).
- Stage/dock split ≈ **58% / 42%** portrait; dock → right rail on landscape (responsive anchors).
- Element/state shown by **shape** (Ward-Sigil grammar) + label, never color alone (accessibility §9.1).

### 2.4 Signaling / EventBus Approach

`EventBus` is a `Node` autoload exposing typed `Signal`s. It carries **UI/feedback** events only:

```gdscript
signal battle_event(payload: Dictionary)
signal save_event(payload: Dictionary)
signal scene_changed(node: String, params: Dictionary)
signal settings_changed(settings: Dictionary)
signal codex_updated(payload: Dictionary)
signal progression_event(payload: Dictionary)
signal underdog_stage_changed(tier: int)
```

**Hard rule (testability):** game-state mutations happen **only** inside `BattleResolver` pure functions and the managers — never as a side effect of an `EventBus` signal. Signals are emitted *after* state is updated, for the view layer to animate. This preserves determinism (ADR-002).

### 2.5 Resource-as-Data Pattern (data-driven, ADR-003)

All content is authored as Godot `Resource` (`.tres`) or JSON, never hardcoded in scripts. `AssetRegistry` loads them once at boot.

| Def Resource | GDD source | Key fields |
|--------------|-----------|-----------|
| `JobDef` | party-jobs §3 | id, name, baseStats, growthPerLevel, kit[], aptitude{}, skills[], startGear[] |
| `HeroDef` (runtime, derived) | party-jobs §3 | slot, jobId, level, xp, hp, mp, equipment{} |
| `ElementDef` | elements §2/§3 | id, sigilGlyph ref, color hex |
| `WardSigilDef` | elements §3/§6 | id, element, spells[], discovered, attuned |
| `SpellDef` | elements §3 | id, element, name, cost, power, target, unlockResonance, applyStatus? |
| `EnemyDef` | combat §6 | id, name, stats, affinity, aiProfile, xpValue |
| `ItemDef` | progression §6 | id, type, mods, cost, sell |
| `EquipmentDef` | progression §2/§6 | id, slot, mods |
| `DungeonDef` / `RoomDef` | world-nodes §3 | floors[Room[]], bossRoom |
| `RunState` (serialized) | save-load §3 | schemaVersion, seed, party, runProgress, worldState, settings, savedAt |

- MVP content = 4 jobs, 4 sigils (Ember/Frost/Storm/Stone), ~6 enemies + 1 mini-boss, ~3 items, ~6 equipment, 1 dungeon (4 floors).
- L2–L5 = **add data files** (e.g. 8 jobs, 7 sigils, more dungeons) with **zero code change** (open decision: index §5.4–5.6).

---

## 3. Combat as a Deterministic Turn/State Machine (ADR-002)

Combat is a pure-data FSM. The **only** sources of truth are `BattleState` (queue + turnPointer + phase + log) and `RNGService(seed)`. No `Time`, no global `rand`, no hidden state.

### 3.1 State Diagram

```
        ┌──────────────────────────────────────────────────────────┐
        │                                                          │
        ▼                                                          │
   ┌──────────┐   build BattleState, sort queue by SPD (seeded    │
   │ PreBattle│   tie-break), turnPointer=0, isBoss set           │
   └────┬─────┘                                                    │
        ▼                                                          │
   ┌────────────┐  active unit = ally → wait for Action input     │
   │ PlayerSelect│ (UI emits Action via EventBus; logic stays here)│
   └────┬───────┘                                                  │
        │ active unit = enemy → EnemyAI computes Action           │
        ▼                                                          │
   ┌────────────┐  BattleResolver.resolve_action(state, action,   │
   │ ResolveAction│ rng) → (new_state, BattleDiff, log[])         │
   │            │  variance ±10% rolled via rng with seed+turn#   │
   └────┬───────┘                                                  │
        ▼                                                          │
   ┌────────────┐  EventBus.battle_event(diff) → UI     │
   │  Animate   │  plays feedback (NON-authoritative)             │
   └────┬───────┘                                                  │
        ▼                                                          │
   ┌────────────┐  all enemies HP≤0 → win; all heroes HP≤0 → lose;│
   │  CheckEnd  │  else advance turnPointer (skip dead) → loop    │
   └────┬───────┘                                                  │
        │ win/lose                                                  │
        ▼                                                          │
   ┌────────────┐  emit progression_event(win); ProgressionManager.add_xp(member, amount)  │
   │ PostBattle │  (runtime contract, combat↔progression)│
   └────────────┘  WorldDirector returns to Town/Dungeon           │
```

### 3.2 Single Source of Truth Contracts

- **Turn order:** `BattleState.queue: Array[CombatantId]` sorted by `SPD` desc at `PreBattle`; tie-break = party slot index asc, then `RNGService.next()` (seeded). Turn advances via `turnPointer = (turnPointer + 1) % queue.size()`, skipping combatants with `HP ≤ 0`.
- **RNG:** `RNGService` holds the **battle seed** (from `RunState.seed` + battle nonce). Every random draw (initiative tie-break, ±10% variance) flows through it. Fixed seed ⇒ identical battle ⇒ reproducible tests & save/load.
- **Pure resolver:** `BattleResolver.resolve_action(state, action, rng) -> (state, diff, log)` — referentially transparent given inputs. No `OS`/`Time`/global state reads.

### 3.3 Damage Formulas (verbatim from combat.md §2, single source)

```
Attack : dmg = max(1, round(ATK*1.0 - target.DEF*0.5)) * affinityMult * variance
Elemental: dmg = max(1, round(MAG*spell.power*aptitude[elem]*(1+resonance[elem]*0.1)
                              - target.RES*0.5)) * affinityMult * variance
affinityMult : strong=1.5, weak=0.67, neutral=1.0   (elements §2)
variance     : in [0.9, 1.1], seeded per action      (combat §2)
Defend       : incoming dmg ×0.5 this round; +ceil(maxMP*0.10) MP
Overkill     : dmg floored ≥1; HP floored at 0
```

> Affinity & element values are **copied exactly** from GDD; the architecture-review §3 asserts byte-equality.

---

## 4. Save Format Spec (consistent with save-load.md S6, ADR-004)

- **Storage:** `localStorage` key `emberveil.save.v1` (web mini-game). JSON, a few KB. Optional `checksum` (CRC32) for corruption detection.
- **Single slot.** New Run overwrites only after a **confirm dialog** (S6 §7). Writes occur **only at safe nodes** (enter Town, clear dungeon floor, attune sigil, complete Quest) — never mid-combat (S6 §2, world-nodes §7).
- **ID casing convention:** GDD enum names are TitleCase (`Ember`, `Vanguard`); storage/code ids are
  their lowercase canonical forms (`ember`, `vanguard`). The enum in §3.3 is the semantic single
  source of truth; the lowercase ids in this schema are its storage form (1:1 mapping, no alias/typo).
- **Schema (v1):**

```json
{
  "schemaVersion": 1,
  "seed": 123456789,
  "savedAt": "2026-07-26T01:11:19Z",
  "settings": {
    "masterVolume": 1.0, "sfxVolume": 1.0,
    "colorblindAssist": false, "reducedMotion": false, "textScale": 1.0
  },
  "party": [
    { "slot":0, "jobId":"vanguard", "level":1, "xp":0, "hp":120, "mp":10,
      "equipment": { "weapon":"greatblade", "armor":null, "accessory":null } }
  ],
  "runProgress": {
    "gold": 0,
    "inventory": { "herb": 2 },
    "codex": {
      "attunedSigilIds": ["ember","frost","storm"],
      "discoveredSigilIds": ["ember","frost","storm"],
      "resonance": { "ember":0,"frost":0,"storm":0,"stone":0,"gale":0,"lumen":0,"umbra":0 }
    }
  },
  "worldState": {
    "currentNode": "town",
    "townVisited": true,
    "dungeon": { "dungeonId":"sundered_ward", "floorIdx":0,
                 "clearedFloors":[], "foundSigils":[], "chestsOpened":[], "bossDefeated":false }
  },
  "checksum": "crc32hex"
}
```

- **Versioning / migration (ADR-004):** on load, read `schemaVersion`. If `< CURRENT` → run up-migration steps `[v1→v2→…]`; if `> CURRENT` → **refuse load + show message** (no corrupt restore). `checksum` validated when present.
- **Privacy:** local only, no PII (cloud = L4, out of MVP).

---

## 5. Web / HTML5 Performance Budget (honors art-bible §9.4)

All budgets are **hard gates** enforced by a CI asset-audit (see checklist). Target device: low-end mobile web (e.g. 2–4 GB RAM, software/limited GPU).

| Budget | Target | Enforcement |
|--------|--------|-------------|
| Initial download | PCK+JS+WASM ≤ ~20 MB raw; gzip ~5–8 MB | Build report in CI |
| First paint (title) | < 3 s on 3G-class; < 1.5 s broadband | Boot→Title smoke |
| Steady frame | 60 fps; ≤ 16.6 ms/frame; logic ≤ 8–10 ms, render ≤ 6 ms | Godot profiler + FPS HUD (debug) |
| Draw calls | ≤ 50–100/frame at MVP (atlas-batched, single grain overlay, UI batched) | Frame capture / `RenderingServer` stats |
| Texture atlases | ≤ **4 × 1024²**; **1 shared 128² grain**; ≤ **16 MB decoded** | Atlas audit script (fail build if exceeded) |
| Texture format | WebP/PNG only; mipmaps on (env/UI), off/keep for crisp sigils | Export preset + audit |
| Memory ceiling | Resident working set ≤ ~80–120 MB; tab ≤ ~256–512 MB | Heap/texture tracker (debug) |
| Palette | Global master ≤ **48 colors**; no out-of-set color w/o sign-off | Palette validator (CI) |
| Viewport | Safe **360×640**; hit targets ≥ **44×44px**; responsive anchors | Manual + automated layout test |

- **Renderer:** `gl_compatibility` (WebGL2) for broad low-end support (ADR-001).
- **Single-thread:** web has no threads — use `yield`/coroutines for async loads; never block the frame.
- **GC discipline:** object pooling for `BattleDiff`/log entries; no per-frame allocations in hot path.

---

## 6. Testing Strategy (Verification-Driven — tests BEFORE code)

Tooling: **GUT** (Godot Unit Test) for unit/integration; a smoke harness (`SceneManager` boot script) for end-to-end. Tests live in `tests/`; CI runs them on every PR.

### 6.1 Unit (pure, headless)
- **Combat math:** `Attack`/`Elemental` damage equals expected for fixed inputs; clamping (≥1, HP floor 0) holds.
- **Affinity matrix:** symmetric 7-cycle — each element strong vs exactly 1, weak vs exactly 1; `1.5 / 0.67 / 1.0` exact (asserts GDD match).
- **Determinism:** same `(seed, action sequence)` ⇒ identical battle log & outcome (ADR-002).
- **Ward Codex:** Set semantics — re-attune same sigil = no-op; aptitude gate blocks uncastable element.
- **Progression:** `xp_for_level(level) = 100*level`; level-up applies `growthPerLevel`; resonance cap 5.
- **Save:** serialize→deserialize round-trip equals original; checksum validates; migration v1→v2 applies; corrupt/mismatch refused.

### 6.2 Integration
- **Turn loop:** scripted full battle (fixed seed + action script) reaches deterministic win/lose; `turnPointer` skips dead correctly.
- **Save→Load round-trip:** write at safe node → reload → `RunState` identical; mid-combat state correctly absent.
- **Content load:** `AssetRegistry` builds all def tables from data; missing/duplicate defs fail fast.

### 6.3 Smoke (boot→…→save)
`Boot → Title (Continue/New) → Town → Dungeon floor → CombatRoom → win → safe-node Save`. Must pass green before Phase 4 starts.

### 6.4 Sample GUT stub (illustrative — real file in Phase 4)
```gdscript
# tests/combat/test_affinity.gd
extends GutTest
func test_affinity_strong_equals_1_5():
    assert_eq(ElementRegistry.affinity("Ember","Frost"), 1.5)
    assert_eq(ElementRegistry.affinity("Frost","Storm"), 1.5)
func test_affinity_cycle_is_symmetric():
    for e in ElementRegistry.ALL:
        assert_eq(ElementRegistry.affinity(e, ElementRegistry.strong_vs(e)), 1.5)
        assert_eq(ElementRegistry.affinity(e, ElementRegistry.weak_vs(e)), 0.67)
```

---

## 7. Open Engineering Items (carry to Phase 4)

1. **Balance spike (BLOCKS numeric lock):** design + engineering must lock ATK/DEF/MAG/RES/SPD, XP curve, spell power/cost, variance, AI aggression *before* implementing combat numbers (lead decision §5.5; phase2 CONCERN). Architecture is ready; values are data, not code.
2. **Audio (forward dep):** `AudioBus` placeholder only; audio-director (Phase 4/6) defines sfx/music events.
3. **Atlas/palette audit tooling:** must exist in CI before art import (§5) to enforce 16 MB / 48-color caps.
4. **No `CLAUDE.md`** present in repo at Phase 3 start — tech preferences to be added by lead; this doc assumes Godot 4 latest-stable, GDScript primary, GDExtension reserved for hot paths only.

*End of Main Architecture (Phase 3). See ADRs and architecture-review.md for decisions and gate verdict.*
