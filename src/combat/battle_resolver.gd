extends RefCounted
class_name BattleResolver
# Pure combat math + deterministic action resolver (ADR-002 / combat §2).
# resolve_action(state, action, rng) is a PURE function: identical (state, action, rng)
# always yields identical (new_state, events). ALL randomness is drawn from the injected
# RNGService only — never global RNG calls (combat RNG lint enforces this).
# No hardcoded balance numbers: affinity/resonance/variance are passed in; tuning lives in
# content/ (ADR-003, E8 spike).

const VARIANCE_MIN := 0.9
const VARIANCE_MAX := 1.1

# Attack: max(1, round(ATK*1.0 - DEF*0.5)) * affinityMult * variance
static func attack_damage(attacker: Dictionary, defender: Dictionary, affinity_mult: float, variance: float) -> float:
	var base: float = float(attacker.get("ATK", 0)) * 1.0 - float(defender.get("DEF", 0)) * 0.5
	return max(1.0, round(base) * affinity_mult * variance)

# Elemental: max(1, round(MAG*power*apt*(1+res*0.1) - RES*0.5)) * affinityMult * variance
static func elemental_damage(caster: Dictionary, defender: Dictionary, spell: Dictionary, affinity_mult: float, variance: float) -> float:
	var apt: float = float(caster.get("aptitude", 1.0))
	var res: float = float(spell.get("resonance", 0))
	var base: float = float(caster.get("MAG", 0)) * float(spell.get("power", 1.0)) * apt * (1.0 + res * 0.1) - float(defender.get("RES", 0)) * 0.5
	return max(1.0, round(base) * affinity_mult * variance)

# Resolve a single action against a battle state. Returns [new_state, events].
# new_state is a deep copy; the input state is never mutated (pure).
static func resolve_action(state: Dictionary, action: Dictionary, rng: RNGService) -> Array:
	var new_state: Dictionary = state.duplicate(true)
	var log_entries: Array = new_state.get("log", [])
	if typeof(log_entries) != TYPE_ARRAY:
		log_entries = []

	var actor_id: String = str(action.get("actorId", ""))
	var actor: Dictionary = _find(new_state, actor_id)
	var events: Array = []

	if actor.is_empty():
		log_entries.append("error: no actor %s" % actor_id)
		new_state["log"] = log_entries
		return [new_state, events]

	var atype: String = str(action.get("type", "Attack"))
	var target_ids: Array = action.get("targetIds", [])
	# Exactly ONE variance draw per action keeps the RNG stream deterministic.
	var variance: float = rng.draw_range(VARIANCE_MIN, VARIANCE_MAX)

	for tid in target_ids:
		var target: Dictionary = _find(new_state, tid)
		if target.is_empty():
			continue
		var dmg := 0
		if atype == "Attack":
			var aff: float = ElementRegistry.affinity(str(actor.get("affinity", "none")), str(target.get("affinity", "none")))
			dmg = int(attack_damage(actor, target, aff, variance))
			target["HP"] = max(0, int(target.get("HP", 0)) - dmg)
		# Skill/Elemental/Defend/Item/Run share the same deterministic path in E3-F/G;
		# Sprint 1 wires Attack (covers smoke + determinism contract).
		events.append({"actor": actor_id, "target": str(tid), "type": atype, "dmg": dmg})
		log_entries.append("%s %s -> %s for %d" % [actor_id, atype, str(tid), dmg])

	new_state["log"] = log_entries
	return [new_state, events]

static func _find(state: Dictionary, id: String) -> Dictionary:
	for c in state.get("combatants", []):
		if str(c.get("id", "")) == id:
			return c
	return {}
