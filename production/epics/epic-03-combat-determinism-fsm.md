# Epic E3 — Deterministic Combat FSM (checklist C, GDD S2)

**Goal:** A pure-data, seedable turn/state machine for combat that satisfies every ⛔ item in checklist C
and implements the 5 command verbs + Underdog Stage scene. **Owning system:** S2. **Depends on:** E2
(RNGService, EventBus, ElementRegistry, WardCodex, PartyManager, ProgressionManager), E6 (enemy/spell data).

## Story E3-A · BattleResolver Pure Function + Damage Formulas
- **User Story:** As an engineer, I want combat damage computed by a pure function, so results are testable & reproducible (ADR-002).
- **Ref:** checklist C ⛔; combat §2; main-arch §3.2/§3.3.
- **DoD:** `BattleResolver.resolve_action(state, action, rng) -> (new_state, BattleDiff, log[])`. Implements formulas verbatim:
  - `Attack: max(1, round(ATK*1.0 - target.DEF*0.5)) * affinityMult * variance`
  - `Elemental: max(1, round(MAG*spell.power*aptitude[elem]*(1+resonance[elem]*0.1) - target.RES*0.5)) * affinityMult * variance`
  - `Defend: incoming*0.5; +ceil(maxMP*0.10) MP`
  - `Overkill: dmg≥1; HP floored at 0`
- **Acceptance (testable):**
  1. Unit: given fixed inputs, Attack/Elemental output equals hand-computed expected (affinity 1.5/0.67/1.0, variance pinned).
  2. Unit: dmg never < 1; HP never < 0 after resolve.
  3. Unit: resolver is side-effect-free — input `state` unchanged; new state returned.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E2-B, E2-E

## Story E3-B · FSM Phases + Turn Order
- **User Story:** As an engineer, I want explicit battle phases with deterministic turn order, so the loop is diagram-able & testable (main-arch §3.1).
- **Ref:** checklist C ⛔; combat §3; main-arch §3.1/§3.2.
- **DoD:** Phases `PreBattle→PlayerSelect→ResolveAction→Animate→CheckEnd→(loop|PostBattle)` reachable. `PreBattle` sorts `queue` by SPD desc, tie-break = party slot asc then `RNGService.next()`; `turnPointer` advances mod queue, skipping HP≤0.
- **Acceptance (testable):**
  1. Unit: queue sorted by SPD desc; identical SPD → slot-index asc; still tied → seeded order deterministic.
  2. Unit: after a unit dies, `turnPointer` skips it (no action on dead).
  3. Integration: full phase sequence traverses without getting stuck (no infinite select when all enemies Defend — enemy escalation resolves deadlock per combat §7).
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E3-A, E2-B

## Story E3-C · Determinism Unit Test (fixed seed)
- **User Story:** As an engineer, I want a regression test proving battles are reproducible, so save/load variance fidelity holds (ADR-002).
- **Ref:** checklist C ⛔; ADR-002; main-arch §6.2.
- **DoD:** A scripted battle (fixed seed + action script) asserts byte-identical `log[]` + win/lose outcome across runs.
- **Acceptance (testable):**
  1. Unit: two runs of the same (seed, action list) ⇒ identical serialized outcome hash.
  2. Unit: different seed ⇒ different variance draws (proves RNG seeded, not constant).
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E3-A, E3-B

## Story E3-D · Lint Guard (no global RNG in combat/battle)
- **User Story:** As an engineer, I want CI to forbid global RNG in combat code, so determinism discipline can't regress (ADR-002).
- **Ref:** checklist C ⛔; ADR-002; main-arch §6.2.
- **DoD:** CI grep/lint fails if `randi(`/`randf(`/`OS.rand`/`rand()` appear under `src/combat` or `src/battle`.
- **Acceptance (testable):**
  1. CI: injecting a `randi()` call in `src/combat` ⇒ pipeline fails.
  2. CI: clean tree ⇒ passes.
- **Sprint:** 1 · **⛔ Blocker:** yes · **Depends:** E1-C (CI)

## Story E3-E · EnemyAI Computes Action
- **User Story:** As a player, I want enemies that choose sensible actions on their turn, so battles are real (combat §2/§6).
- **Ref:** checklist C; combat §3 (aiProfile); main-arch §3.1.
- **DoD:** `EnemyAI.decide(combatant, state, rng) -> Action` from `aiProfile` (e.g. prefer strong-affinity attack / skill; escalate after N rounds per combat §7).
- **Acceptance (testable):**
  1. Unit: AI returns a valid Action for its profile (target alive, MP sufficient or fallback Attack).
  2. Integration: enemy turns resolve through the same `BattleResolver` (no special path).
- **Sprint:** 1 · **⛔ Blocker:** no · **Depends:** E3-A, E3-B

## Story E3-F · Combat Scene (Underdog Stage)
- **User Story:** As a player, I want the battle laid out as the Underdog Stage, so it's readable at 360×640 and original (not FF1).
- **Ref:** checklist (smoke needs it); combat §4; art-bible §6.2/§9.1.
- **DoD:** `Battle.tscn` uses Control/Container + responsive anchors: enemy arc (top), party band (lower-center), command dock (bottom-left, soft-rounded chips), top ribbon (turn pips/Run/Settings). All controls ≥44×44px; stage/dock ≈58/42; shape+label for element/state.
- **Acceptance (testable):**
  1. Layout test: at 360×640 every interactive control ≥44×44px and on-screen.
  2. IP: composition is Underdog Stage, not FF1 enemies-right/party-left (review gate).
- **Sprint:** 1 · **⛔ Blocker:** no (but required by G smoke) · **Depends:** E3-A..E, E2-G

## Story E3-G · Five Command Verbs + Run
- **User Story:** As a player, I want Attack/Skill/Elemental/Defend/Item (+Run) available each turn, so I can play tactically (combat §2/§4).
- **Ref:** combat §2 (commands), §7 (Run); main-arch §2.3.
- **DoD:** Each command builds an `Action` consumed by `BattleResolver`. `Run` disabled vs boss; success = `clamp(0.5+(avgAllySPD-avgEnemySPD)*0.02, 0.1, 0.95)`; fail ⇒ enemies act first; no XP on flee.
- **Acceptance (testable):**
  1. Unit: each command yields a resolver-valid Action; Defend sets Guard + restores MP.
  2. Unit: Run vs boss ⇒ always fails (disabled); Run success within [0.1, 0.95].
  3. Unit: successful flee ⇒ no XP granted; battle ends.
- **Sprint:** 1 · **⛔ Blocker:** no · **Depends:** E3-A, E2-F, E2-J (Elemental later)
