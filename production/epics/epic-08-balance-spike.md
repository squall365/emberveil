# Epic E8 — Balance Spike (checklist H, tuning)

**Goal:** Lock all numeric tuning BEFORE combat numbers are implemented, per lead decision (phase2 §22.5;
architecture-review CONCERN 1; main-arch §7.1). Design + engineering joint spike. Satisfies ⛔ checklist H.
**Owning systems:** S2/S3/S4 (tuning). **Depends on:** E2-E (affinity), E6 (data shape) — runs in parallel
with E3/E4 structure; its OUTPUT replaces placeholder values in E6 content + E3 formulas.

> Discipline: combat *structure* (E3) lands first with data-driven placeholder values; E8 locks the
> real numbers. Implementation must NOT hardcode; values live in `content/` (ADR-003). E8 is the gate
> that turns "placeholder" into "shippable."

## Story E8-A · Lock Base Stats & Growth
- **User Story:** As a designer+engineer, I want base stats + per-level growth locked, so combat feels fair (party-jobs §3).
- **Ref:** checklist H ⛔; party-jobs §3/§7; combat §7.
- **DoD:** Spike agrees HP/MP/ATK/DEF/MAG/RES/SPD base + `growthPerLevel` for the 4 jobs; stat floor ≥1; level cap 20. Values written to `content/jobs/*.tres`.
- **Acceptance (testable):**
  1. Review/spike doc: numbers justified vs a reference encounter; no stat path dominates.
  2. Unit: derived stats from locked values stay within sane bounds at level 20.
- **Sprint:** 1 (spike) · **⛔ Blocker:** yes · **Depends:** E2-E, E6-A

## Story E8-B · Lock Progression Curve
- **User Story:** As a designer+engineer, I want XP/level/resonance locked, so growth is paced (progression §2/§7).
- **Ref:** checklist H ⛔; progression §2/§7.
- **DoD:** Lock `xpToNext(l)=round(20*l^1.35)`, level cap 20, resonance cap 5 (+50%), resonance gain triggers (attune / ≥3 defeats / use-threshold), inventory cap (99/stack, 30 slots), gold sink pricing.
- **Acceptance (testable):**
  1. Unit: `xpToNext` matches formula for sampled levels; level-up applies growth.
  2. Review: XP from a dungeon clear ≈ expected pace (no grind floor violation per progression §7).
- **Sprint:** 1 (spike) · **⛔ Blocker:** yes · **Depends:** E6-A

## Story E8-C · Lock Spell Power / Cost / Variance / Affinity
- **User Story:** As a designer+engineer, I want spell numbers + variance locked, so elemental combat is balanced (elements §6; combat §2/§7).
- **Ref:** checklist H ⛔; elements §6; combat §2.
- **DoD:** Lock per-spell `power`/`cost`(MP4–10), `variance` ±10% (seeded), resonance scaling (+10%/level), status magnitudes (Slow 0.6, Mark +dmg). Affinity stays 1.5/0.67/1.0 (fixed by GDD).
- **Acceptance (testable):**
  1. Unit: a balanced reference battle (fixed seed) ends in expected turn count range.
  2. Review: no element dominates (symmetric 7-cycle preserved); MP economy sustainable.
- **Sprint:** 1 (spike) · **⛔ Blocker:** yes · **Depends:** E8-A, E2-E

## Story E8-D · Lock Enemy AI Aggression
- **User Story:** As a designer+engineer, I want AI escalation locked, so Defend-stalls/deadlocks resolve (combat §7).
- **Ref:** checklist H ⛔; combat §7.
- **DoD:** Lock `aiProfile` aggression + the N-round escalation threshold that breaks Defend-only / both-sides-Defend deadlocks; Run success constants confirmed.
- **Acceptance (testable):**
  1. Integration: a both-sides-Defend scenario resolves within N rounds (no infinite loop).
  2. Unit: Run success ∈ [0.1, 0.95] and disabled vs boss.
- **Sprint:** 1 (spike) · **⛔ Blocker:** yes · **Depends:** E3-E
