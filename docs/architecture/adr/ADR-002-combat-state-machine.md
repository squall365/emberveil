# ADR-002 — Deterministic, Seedable Combat State Machine

- **Status:** Accepted
- **Date:** 2026-07-26
- **Deciders:** engineering-lead (程基岩), studio lead (游承峰)
- **Supersedes:** —

## Context

Combat (GDD S2) is turn-based, command-driven, ATB-free. Requirements from `combat.md`:
initiative sort by `SPD` (seeded tie-break), ±10% variance "seeded per action for save/load
reproducibility", a clean phase machine (`PreBattle → PlayerSelect → Resolve → CheckEnd → …`),
and no hidden state. The game also needs **testability** (FULL review), potential **replay/debug**,
and future-proofing.

Naive approaches let randomness leak from `OS.rand()`, `Time`, or signal side-effects, making
battles non-reproducible and untestable, and breaking save/load variance fidelity.

## Decision

Model combat as a **pure-data finite state machine** with a single source of truth:

- `BattleState { queue[], turnPointer, phase, log[], isBoss }` — the only mutable combat state.
- `RNGService` — one **seedable PRNG** (battle seed = `RunState.seed` + battle nonce). The **sole**
  source of randomness (initiative tie-breaks, ±10% variance).
- `BattleResolver.resolve_action(state, action, rng) -> (new_state, BattleDiff, log[])` — a
  **referentially transparent** function: same inputs ⇒ same outputs, no `OS`/`Time`/global reads.
- Phases: `PreBattle → PlayerSelect → ResolveAction → Animate → CheckEnd → (loop | PostBattle)`.
  `Animate` is view-only; all mutations happen in `ResolveAction`.
- `EventBus` carries UI/feedback signals **emitted after** state updates — never a trigger for logic.

All combat randomness is routed through `RNGService`. Game logic never reads global RNG directly.

## Consequences

**Positive**
- **Verification-driven:** unit tests assert exact damage and full-battle outcomes with a fixed seed;
  variance determinism is provable. (architecture §6.1–6.2)
- **Save/load fidelity:** the ±10% variance is reproducible from the seed — no divergence on reload.
- **Replay/debug-ready:** record `(seed, action list)` ⇒ deterministic replay; great for bug reports.
- **No hidden state:** `BattleState` is the only truth; UI is a pure function of it.

**Negative / costs**
- Discipline cost: every new random draw must go through `RNGService`, not `rand()`. Enforced by
  code review + a lint check (no `randi`/`randf`/`OS.rand` in `combat/` and `battle/` trees).
- The resolver must stay side-effect-free; managers (Progression XP, Save) are called from
  `PostBattle`, never mid-resolve.
- Slightly more boilerplate (explicit `BattleDiff` structs) vs. mutating objects in place.

## Alternatives Considered

1. **Non-deterministic combat** (read global RNG freely) — Rejected. Untestable, breaks save/load
   variance reproducibility, no replay. Incompatible with FULL-review testability mandate.
2. **Lockstep / networked deterministic model** (full netcode) — Rejected as over-engineering for a
   single-player web mini-game. We keep the *determinism property* (seedable PRNG + pure resolver)
   without the networking machinery; can be extended later if multiplayer (L4+) is ever scoped.
3. **Event/signal-driven state** (mutate state inside `EventBus` handlers) — Rejected. Makes logic
   order-dependent on signal connections, destroying testability and the single-source-of-truth
   guarantee. Signals are demoted to post-update notifications only.

## Validation

- Unit: `test_determinism` — same `(seed, actions)` ⇒ byte-identical `log` + outcome.
- Unit: `test_variance_in_range` — 1000 rolls all within [0.9, 1.1].
- Lint: no `randi/randf/OS.rand` references inside `combat/` + `battle/` directories.
- Integration: scripted battle reaches deterministic win/lose; `turnPointer` skips dead units.
