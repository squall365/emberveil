# EMBERVEIL — UX Specification (Phase 4 · Pre-Production)

> **World:** Veyra · **Engine:** Godot 4 (HTML5 / WebGL2) · **Platform:** Web / 小游戏 (instant-play)
> **Safe viewport:** 360×640 · **Review:** FULL · **Author:** design-strategist (文策渊 / Vince Coyer)
> **Upstream:** `design/concept/game-concept.md`, `design/art/art-bible.md`, `design/gdd/*`, `docs/architecture/main-architecture.md` §1.1/§2.3/§4, `design/art/accessibility.md` §4, `design/reviews/phase3-architecture-review.md` (CONCERN #5, #6)
> **Hard IP rule:** No Square Enix / FF1 assets, layouts, or fonts. Original Ward-Sigil language & Underdog Stage composition only.
> **User decision (locked):** pure offline single-player — no cloud, no login, save = localStorage only, Analytics default OFF. No network/account UX is designed anywhere in this document.

---

## 0. Purpose & Scope

This document is the **single UX contract for Phase 4**. It converts the settled concept, art-bible, six GDDs, architecture, and accessibility tiering into implementable UX surfaces. It explicitly closes the two cross-member consistency gaps flagged by the studio lead in the Phase 3 review:

- **CONCERN #5** → §4 *SettingsManager contract* enumerates **every** accessibility §4 switch and writes the **expanded `settings` schema** that extends `main-architecture.md` §4.
- **CONCERN #6** → §3 *Input Scheme & Control Remap* supplies the missing input-rebind module the architecture lacked, owned by `SettingsManager` and applied through Godot `InputMap`.

Scope is **MVP (Basic + Standard tiers)**; Comprehensive items are specified as non-blocking extensions the architecture must not preclude.

---

## 1. Platform & Offline-First Constraints (apply everywhere)

| Constraint | Rule | Source |
|---|---|---|
| Viewport | Safe at **360×640** CSS px; responsive anchors; no fixed-resolution art | art-bible §6.3, architecture §5 |
| Hit targets | Every interactive HUD/command element ≥ **44×44px** | art-bible §9.1, accessibility §4 #3 |
| Palette | Global master ≤ **48 colors**; shape carries element ID | art-bible §2.3/§9.4 |
| Motion | `prefers-reduced-motion` is the **default**; in-game toggle overrides; **fade-only, never flash** | accessibility §4 #7, art-bible §7.1 |
| Offline | No login/account; settings + save persist via `localStorage`; Analytics OFF by default | user-locked decision, save-load §1 |
| Text | Minimum body ≈ **14px @360**; parchment-on-plum only; in-app Text-Scale (do not rely on browser zoom) | accessibility §3, art-bible §9.1 |

---

## 2. Screen Flow / State Map (Deliverable 1)

### 2.1 State Diagram

```
                         ┌──────────────────────────────────────────────┐
                         │                BOOT (Boot.tscn)               │
                         │  read SettingsManager (global settings key)   │
                         │  read SaveManager (RunState if present)       │
                         └───────────────┬──────────────────────────────┘
                                         │
                                         ▼
                         ┌──────────────────────────────────────────────┐
                         │        TITLE (Title.tscn)                     │
                         │  If save exists → [Continue] (primary)        │
                         │                [New Run]                      │
                         │  If no save     → [New Run] only (+ Continue  │
                         │                  greyed/disabled)             │
                         └───────┬───────────────────────┬──────────────┘
              [New Run]          │                       │ [Continue]
                  │              │                       │
                  │              ▼                       ▼
                  │   ┌─────────────────────┐   load RunState → resume at
                  │   │ NEW-RUN CONFIRM     │   saved safe node (Town or
                  │   │ dialog (S6)         │   dungeon floor entry)
                  │   │ "Overwrite save?"   │   └─► TOWN or DUNGEON
                  │   └─────────┬───────────┘
                  │             │ confirm
                  │             ▼
                  │      fresh RunState → TOWN (Hearthmoor)
                  ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │                      WORLD (World.tscn, resident)                  │
   │  ├─ TOWN (Town.tscn)  — safe node: Rest/Shop/Barracks/Sage/Shrine  │
   │  └─ DUNGEON (Dungeon.tscn) — 4 floors (see 2.3)                    │
   │                                                                    │
   │  Pause (ui_cancel) → PAUSE MENU: Resume / Settings / Save(safe)   │
   │  Save writes ONLY at safe nodes (Town / floor-clear / sigil-       │
   │  attune / quest-complete). Manual save at Shrine + pause@safe.    │
   └───────────────┬───────────────────────────┬──────────────────────┘
                   │ enter CombatRoom           │ quest accepted →
                   │ (or boss room)             │ dungeon entry
                   ▼                             │
   ┌─────────────────────────────────┐          │
   │ BATTLE OVERLAY (Battle.tscn)     │          │
   │ Underdog Stage composition       │          │
   │ FSM: PreBattle→PlayerSelect→     │          │
   │ Resolve→Animate→CheckEnd→        │          │
   │ (loop | PostBattle)              │          │
   │ *** NEVER serialized mid-battle  │          │
   │     (S6: no mid-combat persist)  │          │
   └──────────┬──────────────────────┘          │
      win │    │ lose (party wipe)              │
          ▼    ▼                                 │
   XP→Prog.  reload last safe save              │
   autosave   (Town or floor entry)             │
   @floor-    — no progress lost beyond         │
   clear      that floor (world-nodes §7)       │
          │                                     │
          └────────────► return to WORLD ◄──────┘
```

### 2.2 Transition / Persistence Table

| From → To | Trigger | Entry condition | Exit | Persistence rule |
|---|---|---|---|---|
| Boot → Title | boot complete | settings + save read | — | none (read-only) |
| Title → New Run | tap New Run | always | confirm dialog | creates fresh `RunState`; **no overwrite until confirm** |
| Title → Continue | tap Continue | save exists | — | loads `RunState`; resumes at `worldState.currentNode` |
| Town → Dungeon | Sage gives quest + enter | quest accepted | — | `townVisited=true` autosaved |
| Dungeon → Floor N+1 | clear floor N | all rooms of floor N cleared | autosave (safe node) | `clearedFloors+=[N]`; XP/gold applied |
| World → Battle | enter CombatRoom / BossRoom | room type = combat | Battle overlay added (not swapped) | **none mid-battle** |
| Battle → World (win) | `combat_ended(win)` | all enemies HP≤0 | overlay removed | XP emitted → Progression; **autosave at floor-clear / boss** |
| Battle → World (lose) | `combat_ended(lose)` | all heroes HP≤0 | overlay removed | reload **last safe save**; no mid-combat restore |
| World → Pause | `ui_cancel` | any time (safe node only for Save) | Resume | Settings changes persist live (global key) |
| Pause → Save | tap Save | only at safe node | — | `save_written` event; writes `RunState` |

**Safe-node gating (hard):** writes occur only at Town-enter, floor-clear, sigil-attune, quest-complete (save-load §2). Battle is an overlay that is added/removed, **never serialized** (architecture §2.2). A party wipe reloads the last safe node — this is the only "retry" path and is intentional anti-save-scum (save-load §7).

### 2.3 Dungeon Floor Sub-Flow (4 floors, MVP)

Each floor is a sequence of `Room`s (world-nodes §2): `CombatRoom` → `PuzzleRoom` (Ember→Frost→Storm stone order) → `RewardRoom` (chest/sigil). Floor 4 ends in `BossRoom` = mini-boss `Sigil-Twisted Warden` → drops **Stone Sigil** (unlocks Stone element). Advancing a floor **autosaves** (safe node). Backtracking to Town is allowed via Shrine/exit; dungeon progress persists.

---

## 3. Input Scheme & Control Remap (Deliverable 2) — RESOLVES CONCERN #6

The architecture §1.1 lacked an `InputManager`. This section defines the missing module: **`SettingsManager` owns a persisted `controlRemap` table; it is applied to Godot's global `InputMap` at boot and on every change.** This is the canonical fix for accessibility §4 #6 (Control Remap KB+touch).

### 3.1 Canonical Logical Action Set

All input is expressed as **logical actions** (not raw keys). The game logic and UI bind to actions; keys/touch are just bindings onto them.

| Action ID | Purpose | Scope |
|---|---|---|
| `ui_accept` | Confirm / activate focused control | global |
| `ui_cancel` | Back / open Pause | global |
| `ui_up` / `ui_down` / `ui_left` / `ui_right` | Directional navigation / focus move | global |
| `cmd_attack` | Command: Attack | battle |
| `cmd_skill` | Command: Skill | battle |
| `cmd_elemental` | Command: Elemental (Ward Codex spell) | battle |
| `cmd_defend` | Command: Defend | battle |
| `cmd_item` | Command: Item | battle |
| `cmd_run` | Command: Run (out-of-turn, top ribbon) | battle |
| `select_hero_1..4` | Select / target party slot 1–4 | battle |
| `toggle_settings` | Open Settings from anywhere (alias of pause→settings) | global |

### 3.2 Default Bindings (Basic tier — fixed)

| Action | Keyboard default | Touch default (always present) |
|---|---|---|
| `ui_accept` | `Enter`, `Space` | tap focused control |
| `ui_cancel` | `Escape` | tap Back / Pause chip |
| `ui_up/down/left/right` | `Arrow` keys / `W A S D` | swipe / on-screen d-pad (optional) |
| `cmd_attack` | `1` | Attack chip (bottom dock) |
| `cmd_skill` | `2` | Skill chip |
| `cmd_elemental` | `3` | Elemental chip |
| `cmd_defend` | `4` | Defend chip |
| `cmd_item` | `5` | Item chip |
| `cmd_run` | `R` | Run chip (top ribbon) |
| `select_hero_1..4` | `F1`–`F4` | tap party medallion |
| `toggle_settings` | `Escape` (via pause) | tap Settings (top ribbon / pause) |

**Basic rule:** these defaults are hard-coded in `SettingsManager.DEFAULTS` and cannot be removed; they are the accessibility floor (accessibility §4 #6). Touch input is **always available** through the on-screen chips/medallions regardless of remap state — touch users are never blocked.

### 3.3 Control Remap Mechanism (Standard tier)

**Ownership.** `SettingsManager` is the single owner of `controlRemap`. It is persisted (see §4.3) and applied to Godot `InputMap` on boot and on every edit. No other module writes bindings.

**Apply pipeline (boot / runtime):**
1. `SettingsManager` loads `controlRemap.bindings`.
2. For each action: `InputMap.erase_action(action)` (if custom) then re-add via `InputMap.add_action` + `InputMap.action_add_event(action, event)`.
3. Built-in `ui_*` actions are likewise re-bound from the table (Godot permits erasing/adding events on built-in actions).

**Remap Screen UX (Settings → Controls):**
- Lists every logical action (§3.1) with its current binding(s) and a **semantic text label** (SR foundation, accessibility §4 #5/#8).
- **Keyboard rebind:** user taps "Rebind" → next physical key press is captured as an `InputEventKey` → written to table → `InputMap` re-applied live.
- **Touch rebind:** the on-screen command chips are the canonical touch surface and are always tappable. For tablets/large screens, an optional **persistent virtual control strip** lets the player assign *which* actions get a dedicated on-screen button and in what order; this assignment is stored per-action in `controlRemap` (`touchSlot` index) and rendered by the HUD (§5). Default = all 5 commands + Run + Pause present.
- **Conflict handling:** if a captured key is already bound to another action, the screen **rejects** the binding, highlights both actions in ember-orange, and prompts *"Key already used by <action>. Swap / Cancel."* Default policy = **reject + offer swap** (no silent overwrite).
- **Reset to default:** a single "Reset all controls" button restores `SettingsManager.DEFAULTS` and clears `controlRemap` overrides.

**Tiers:**
- **Basic:** fixed default mapping (§3.2) — ships regardless.
- **Standard:** full player remap of keyboard **and** touch button assignment (this section).
- **Comprehensive:** + gamepad remap & presets (post-MVP; architecture must not block — `controlRemap` stores device-agnostic bindings so gamepad can be added later without schema change).

### 3.4 Implementation Contract (for engineering-lead)

```gdscript
# SettingsManager (autoload, loaded first)
func apply_control_remap(table: Dictionary) -> void:
    for action in table.bindings.keys():
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        # clear current events, re-add from persisted table
        for ev in InputMap.action_get_events(action):
            InputMap.action_erase_event(action, ev)
        for spec in table.bindings[action]:
            InputMap.action_add_event(action, _spec_to_event(spec))

func capture_next_key() -> InputEventKey:
    # Remap screen: buffer the next InputEventKey from the viewport
    # (await InputEventKey), return it; UI handles conflict check.
    ...

func rebind(action: String, spec: Dictionary) -> bool:
    if _conflicts(action, spec): return false   # UI offers swap
    controlRemap.bindings[action] = [spec]
    persist_settings()                           # global key (§4.3)
    apply_control_remap(controlRemap)
    return true
```

> Determinism note: rebinding never touches `BattleResolver` or `RNGService`. Input is a view-layer concern only (architecture §2.4 hard rule preserved).

---

## 4. SettingsManager Contract (Deliverable 3) — RESOLVES CONCERN #5

### 4.1 Every Accessibility §4 Switch, Enumerated

The Phase 3 review found `SettingsManager` covered only `colorblindAssist / reducedMotion / textScale`. Below is the **complete** §4 switch set; each is now an explicit `SettingsManager` field and a `settings`-schema key.

| # | Accessibility §4 switch | SettingsManager field | Tier | Notes |
|---|---|---|---|---|
| 1 | Reduced-Motion toggle | `reducedMotion: bool` | Standard | overrides OS; fade-only |
| 2 | Text-Scale 100–150% | `textScale: float` | Basic→Comp | MVP 1.0–1.25; Comprehensive 1.5 + slider |
| 3 | Control Remap (KB+touch) | `controlRemap: object` | Standard | §3.3 |
| 4 | Colorblind-Assist toggle | `colorblindAssist: bool` | Standard | adds shape/label outlines |
| 5 | Dyslexia-Friendly Font toggle | `dyslexiaFont: bool` | Standard | humanist rounded sans swap |
| 6 | Subtitle settings | `subtitle: object` | Standard→Comp | enabled/size/bg/position |
| 7 | Audio/Visual cue parity | `audioVisualParity: bool` | Standard | every sfx has visual pair (§6) |
| 8 | High-Contrast theme | `highContrast: bool` | Comprehensive | does not block MVP |
| 9 | Audio volumes | `masterVolume` / `sfxVolume` (+ `musicVolume`) | Basic | existing fields retained |
| — | 44px / 360×640 / responsive | (layout system, not a toggle) | Basic | enforced in HUD (§5), not a setting |
| — | `prefers-reduced-motion` default | (OS read → seeds `reducedMotion`) | Basic | §1 |
| — | Visual-cue system / SR labels | (feedback + semantic labels) | Basic/Standard | §6, §4 #5/#8 |

### 4.2 Expanded `settings` Schema (extends `main-architecture.md` §4)

This **extends** the existing block (existing scalar fields preserved exactly; new fields added). It is additive — no existing key is renamed or removed, so the locked save-load serializer stays valid. `musicVolume` is additive (Comprehensive; MVP keeps `1.0`).

```json
{
  "settings": {
    "masterVolume": 1.0,
    "sfxVolume": 1.0,
    "musicVolume": 1.0,
    "colorblindAssist": false,
    "reducedMotion": false,
    "textScale": 1.0,
    "dyslexiaFont": false,
    "highContrast": false,
    "audioVisualParity": true,
    "subtitle": {
      "enabled": true,
      "size": 1.0,
      "background": true,
      "position": "bottom"
    },
    "controlRemap": {
      "version": 1,
      "bindings": {
        "ui_accept":     [ { "device": "key", "keycode": "Enter" }, { "device": "key", "keycode": "Space" } ],
        "ui_cancel":     [ { "device": "key", "keycode": "Escape" } ],
        "ui_up":         [ { "device": "key", "keycode": "Up" } ],
        "ui_down":       [ { "device": "key", "keycode": "Down" } ],
        "ui_left":       [ { "device": "key", "keycode": "Left" } ],
        "ui_right":      [ { "device": "key", "keycode": "Right" } ],
        "cmd_attack":    [ { "device": "key", "keycode": "1" } ],
        "cmd_skill":     [ { "device": "key", "keycode": "2" } ],
        "cmd_elemental": [ { "device": "key", "keycode": "3" } ],
        "cmd_defend":    [ { "device": "key", "keycode": "4" } ],
        "cmd_item":      [ { "device": "key", "keycode": "5" } ],
        "cmd_run":       [ { "device": "key", "keycode": "R" } ],
        "select_hero_1": [ { "device": "key", "keycode": "F1" } ],
        "select_hero_2": [ { "device": "key", "keycode": "F2" } ],
        "select_hero_3": [ { "device": "key", "keycode": "F3" } ],
        "select_hero_4": [ { "device": "key", "keycode": "F4" } ]
      }
    }
  }
}
```

**Field contracts:**
- `textScale` (1.0–1.5): UI scales; must **not clip core HUD** at 1.0/1.25/1.5 (architecture §5). MVP clamps to 1.25; Comprehensive frees to 1.5.
- `subtitle.size` (1.0–1.5), `subtitle.background` (parchment backing on), `subtitle.position` (`bottom`|`top`). Standard = enabled + backing + speaker labels; Comprehensive adds size/bg/position.
- `audioVisualParity` default **true**; when true, the feedback system (§6) guarantees a visual pair for every `AudioBus` event. Turning it off is not offered (it is a safety floor) — flag if product wants it user-toggleable.
- `controlRemap.version` enables future migration of the bindings table.

### 4.3 Settings Storage Ownership (offline-only)

To satisfy accessibility §4 #1 (*"settings reachable before any combat; sane on first load; persist across sessions"*) **and** the locked `RunState.settings` mirror, the contract is:

- `SettingsManager` is the **single owner** of live settings.
- It persists to a **global key `emberveil.settings.v1`** (independent of any run). This makes settings reachable from the very first Title screen and survivable across `New Run` / no-save states.
- `RunState.settings` (existing schema) becomes a **mirror** written at safe-node save for portability/debug; on load, the **global key wins** (last-write-wins) so settings are consistent regardless of which save is resumed.
- All writes are `localStorage` only; no network. Analytics remain OFF by default (architecture §1.1).

> **Open decision (see §9):** whether to fully drop `settings` from `RunState` (keep only the global key) or retain it purely as a mirror. This spec assumes the mirror model; either is acceptable to engineering.

---

## 5. HUD / Command Layout — Underdog Stage (Deliverable 4)

### 5.1 Regions (combat.md §4, art-bible §6.2, architecture §2.3)

```
PORTRAIT (360×640 safe) — stage/dock ≈ 58% / 42%
┌───────────────────────────┐
│ TOP RIBBON (H ~48px)       │  turn-order pips · Run · Settings
│   ENEMY ARC (upper back)   │  foes staggered, scale = depth
│        ◠   ◠   ◠           │
│                           │
│   PARTY BAND (center-bottom)│ 4 overlapping medallions = ONE unit
│   ⦿ ⦿ ⦿ ⦿                 │
│  [medallion] [Cmd][Cmd][Cmd]│ COMMAND DOCK (bottom-left)
│             [context panel] │  active hero's commands only
└───────────────────────────┘

LANDSCAPE — dock → RIGHT RAIL (responsive anchors)
┌──────────────────────────┬──────────┐
│ TOP RIBBON                │ PARTY    │
│ ENEMY ARC                 │ BAND     │
│                           │ ⦿⦿⦿⦿    │
│ PARTY BAND (center)       │ COMMAND  │
│                           │ DOCK     │
│                           │ [Cmd][..]│
└──────────────────────────┴──────────┘
```

### 5.2 Component Spec

| Component | Size / rule | Notes |
|---|---|---|
| Top ribbon | height ≥ 44px; turn pips round=ally / sharp=enemy (shape grammar) | Run + Settings chips ≥44px |
| Enemy arc | upper-back arc; scale + vertical offset = depth (no blur/DOF) | affinity hint on focus only (low clutter) |
| Party band | 4 medallions, overlapping "one unit"; selected hero lifts ~6px | ring HP/MP fill (not bars); status badge crisp-geometric |
| Command dock | bottom-left HBox of **soft-rounded chips**, each ≥44×44px | shows ONLY active hero's commands; others hidden to keep stage visible |
| Context panel | beside dock; target/spell sub-menu | greyed if uncastable (e.g., 0 MP Elemental → toast "No MP") |
| Medallion | circular portrait + HP/MP ring + status badge | tap = `select_hero_N` |

### 5.3 Command Dock Interaction

Active hero highlighted → dock expands that hero's 5 command chips (Attack/Skill/Elemental/Defend/Item) → choose → context panel (target or spell) → confirm (`ui_accept`) → resolve animation (EventBus `combat_action_resolved`) → next. `Run` lives in the top ribbon (out-of-turn). No full-width bottom command window (FF1-inverted; art-bible §6.1).

### 5.4 Focus / Keyboard Navigation + 44px Rule

- Keyboard navigation moves a **parchment glow focus ring** (≥2px) between chips/medallions; `ui_up/down/left/right` traverse; `ui_accept` activates.
- **Every** interactive element ≥44×44px at 360×640 (accessibility §4 #3, architecture §5). Layout primitives enforce this minimum.
- No hover-only reveals (web/touch parity, accessibility §3).

### 5.5 Element / State = Shape + Label

- Every element/state is identified by **Ward-Sigil shape** (art-bible §7.3) **+ text label** — never color alone (accessibility §9.1). Color is reinforcement.
- Enemy affinity hint (STRONG/WEAK) shown as a crisp-geometric badge + label on focus.
- `colorblindAssist` overlays shape/label outlines on top of color (accessibility §4 #1).

---

## 6. Feedback System (Deliverable 5)

Every audio cue has a **paired visual indicator**; `audioVisualParity` (default true) guarantees the pair. `AudioBus` is a placeholder in Phase 4 — the event **names** below are the contract for the audio-director (Phase 6) to fill.

### 6.1 AudioBus Event Catalog (placeholder names → audio-director fills)

| Event name | Trigger | Category |
|---|---|---|
| `sfx.ui_navigate` | focus moves between controls | UI |
| `sfx.ui_confirm` | chip/control activated | UI |
| `sfx.ui_cancel` | back / pause opened | UI |
| `sfx.combat_turn_ally` | ally turn begins (`combat_turn_started`) | Battle |
| `sfx.combat_turn_enemy` | enemy turn begins | Battle |
| `sfx.combat_attack` | Attack resolves | Battle |
| `sfx.combat_skill` | Skill resolves | Battle |
| `sfx.combat_elemental` | Elemental spell resolves | Battle |
| `sfx.combat_defend` | Defend applied | Battle |
| `sfx.combat_item` | Item used | Battle |
| `sfx.combat_hit` | any damage landed | Battle |
| `sfx.combat_low_hp` | a hero drops below 30% HP | Battle (warning) |
| `sfx.status_applied` | Slow/Guard/Mark applied | Battle |
| `sfx.status_cleared` | status removed | Battle |
| `sfx.affinity_strong` / `sfx.affinity_weak` | affinity badge shown | Battle |
| `sfx.win` / `sfx.lose` | `combat_ended` | Battle |
| `sfx.sigil_attuned` | `codex_sigil_attuned` | World |
| `sfx.floor_cleared` | `world_floor_cleared` | World |
| `sfx.save_written` | `save_written` (ok) | System |
| `music.town` / `music.dungeon` / `music.battle` | scene/state BGM (optional tracks) | Music |

### 6.2 Visual ↔ Audio Pairing Table

| Cue | Audio (`AudioBus`) | Paired visual | Reduced-motion behavior |
|---|---|---|---|
| Turn prompt | `combat_turn_ally` / `_enemy` | active hero ring **pulse** + "▶ Your turn" banner; enemy arc tint | static highlight, **no pulse** |
| Low HP | `combat_low_hp` | medallion ring → steady ember tint + small badge | steady tint, **no blink/flash** |
| State applied | `status_applied` | crisp-geometric status badge appears on combatant | fade-in only |
| Affinity hit | `affinity_strong`/`_weak` | shape+label badge "STRONG/WEAK" | fade-in only |
| Save | `sfx.save_written` | small "Saved" toast + Shrine glow | fade-in only |
| Sigil attune | `sfx.sigil_attuned` | sigil "ignite" = **fade + glow** (art-bible §7.1) | fade only, never flash |

### 6.3 Reduced-Motion = Fade-Only (hard rule)

When `reducedMotion` is on (or OS `prefers-reduced-motion` and not overridden), **all** feedback uses fade/glow transitions; **no flashing, no screen-shake, no blink**. Low-HP uses a *steady* tint rather than a pulsing one. Reduced-Motion/VFX also act as a **performance guard** (architecture §5): cap particles, drop glow/blur passes.

---

## 7. Offline-Only UX Notes (Deliverable 6)

- **No login / account flow.** Title goes straight to **Continue / New Run**; no email, no server, no session token anywhere.
- **Instant play.** Boot reads settings + save, then Title in <3s target (architecture §5). No download/login gate.
- **Settings persist via `localStorage`** (`emberveil.settings.v1`, §4.3) — applied on first Title, reachable before combat, survive across sessions and `New Run`.
- **Quick-resume.** On launch, if a save exists, `Continue` is the primary CTA and resumes at the saved safe node (Town or dungeon floor entry). No mid-combat resume (battle overlay never serialized).
- **Single local slot** (save-load §6). `New Run` requires a confirm dialog to prevent accidental overwrite.
- **Privacy.** Local only, no PII; Analytics OFF by default; no telemetry prompts.

---

## 8. Accessibility Mapping Table (Deliverable 7)

Each accessibility feature (from `accessibility.md` §2 matrix / §4 constraints) → implementing UX surface → tier. Cumulative: Standard includes Basic; Comprehensive includes both.

| # | Feature | Implementing UX surface (this doc) | SettingsManager field | Basic | Standard | Comprehensive |
|---|---|---|---|---|---|---|
| 1 | Colorblind safety | Ward-Sigil shape (art) + outline overlay (§5.5) | `colorblindAssist` | ✓ shape baked in | ✓ + outline | ✓ + enemy-tint parity |
| 2 | Text scaling | HUD layout (§5) + in-app scale | `textScale` | ✓ 14px min | ✓ ≤1.25 | ✓ ≤1.5 + slider |
| 3 | Text contrast | palette (art) + HC theme | `highContrast` | ✓ AA 9.3:1 | ✓ AAA body | ✓ + HC theme |
| 4 | Subtitles | subtitle panel (§6.2) | `subtitle` | ✓ text dialogue | ✓ + backing + labels | ✓ size/bg/pos |
| 5 | Reduced-motion | feedback system (§6.3) | `reducedMotion` | ✓ OS default, fade-only | ✓ in-game toggle | ✓ + red-VFX/shake |
| 6 | Control remap | InputMap + remap screen (§3) | `controlRemap` | ✓ fixed KB+touch | ✓ remap KB+touch | ✓ + gamepad/presets |
| 7 | 44px targets | layout system (§5.4) | — (layout) | ✓ hard rule | ✓ + focus ring | ✓ + adj. sizing |
| 8 | Screen-reader / text-alt | semantic labels on all UI (§3.3, §5) | — (code) | ✓ text labels | ✓ semantic expose | ◐ best-effort SR tree |
| 9 | Vibration alternative | visual pulse language (§6) | — (feedback) | ✓ visual cue | ✓ consistent pulse | ✓ + haptics |
| 10 | Pause / save-on-safe-node | screen flow (§2.2) | — (save) | ✓ pause@safe | ✓ save@safe | ✓ cross-session continue |
| 11 | Dyslexia font | font swap (§5 typography) | `dyslexiaFont` | ✓ rounded humanist | ✓ toggle | ✓ + spacing opts |
| 12 | Audio cues w/ visual | feedback pairing (§6) | `audioVisualParity` | ✓ critical pairs | ✓ all pairs | ✓ + vol channels |

---

## 9. Open Questions for Lead

1. **Settings storage ownership (recommended decision):** adopt the **global `emberveil.settings.v1` key as authoritative + `RunState.settings` as mirror** (§4.3). Alternative: remove `settings` from `RunState` entirely. Needs lead sign-off so engineering-lead updates the save serializer accordingly. *(This is the only item that could touch the locked save schema.)*
2. **`musicVolume` now or defer?** I added it additively (default 1.0) so Comprehensive "separate channels" is unblocked. MVP can keep it at 1.0; confirm we want it in the schema now vs. later.
3. **Touch-remap granularity:** §3.3 specifies on-screen button *assignment/order* as the touch-remap surface (chips themselves are always tappable). Confirm this satisfies "Control Remap (touch)" for MVP, or whether full button-repositioning drag is required (would need HUD anchor work).
4. **`audioVisualParity` user-toggle:** currently default true and treated as a safety floor (not offered in UI). Confirm product does not need it user-toggleable.

---

## 10. Traceability

| This doc | Upstream |
|---|---|
| §2 screen flow | world-nodes §2/§4, save-load §2/§4/§7, combat §4, architecture §2.2/§3 |
| §3 input/remap | accessibility §4 #6, architecture §1.1 (missing InputManager), combat §4 commands |
| §4 settings contract | accessibility §4 (all 9 constraints), main-architecture §4 (extends), save-load §4/§6 |
| §5 HUD | art-bible §6.2/§7, combat §4, architecture §2.3, accessibility §9.1 |
| §6 feedback | accessibility §4 #6/#7, architecture §1.1 (`AudioBus` placeholder), §2.4 (`EventBus`) |
| §7 offline | user-locked decision, save-load §1, architecture §1.1 |
| §8 mapping | accessibility §2 matrix + §4 constraints |

*End of UX Specification (Phase 4). Downstream: engineering-lead (§3.4, §4.3), audio-director (§6.1, Phase 6). Original-IP compliant: Ward-Sigils + Underdog Stage only; no FF1/SE expression.*
