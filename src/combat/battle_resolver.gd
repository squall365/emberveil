extends RefCounted
class_name BattleResolver
# Pure combat math + deterministic action resolver (ADR-002 / combat §2).
# resolve_action(state, action, rng) is a PURE function: identical (state, action, rng)
# always yields identical (new_state, events). ALL randomness is drawn from the injected
# RNGService only — never global RNG calls (combat RNG lint enforces this).
# No hardcoded balance numbers: affinity/resonance/variance are passed in; tuning lives in
# content/ (ADR-003, E8 spike). Sprint 2 (E9.4): 5-command paths (Attack/Skill/Elemental/
# Defend/Item/Run) all resolve through this single pure entry point.

const VARIANCE_MIN := 0.9
const VARIANCE_MAX := 1.1

# PLACEHOLDER costs/scales (E8 spike tunes). Kept here as named constants so balance lives
# in one place; no per-enemy/per-hero literals scattered through the resolver.
const MP_SKILL_COST := 4
const MP_ELEMENTAL_COST := 6
const ITEM_HEAL_RATIO := 0.3
const GUARD_MULT := 0.5

# Attack: max(1, round(ATK*1.0 - DEF*0.5)) * affinityMult * variance
static func attack_damage(attacker: Dictionary, defender: Dictionary, affinity_mult: float, variance: float) -> float:
	var base: float = float(attacker.get("ATK", 0)) * 1.0 - float(defender.get("DEF", 0)) * 0.5
	return max(1.0, round(base) * affinity_mult * variance)

# Elemental: max(1, round(MAG*power*apt*(1+res*0.1) - RES*0.5)) * affinityMult * variance
static func elemental_damage(caster: Dictionary, defender: Dictionary, spell: Dictionary, affinity_mult: float, variance: float) -> float:
	# PLACEHOLDER aptitude coercion: ally combatants carry a per-element aptitude dict
	# (resolved in E3-F/G); here a dict falls back to 1.0 so the path can't crash.
	var apt_raw = caster.get("aptitude", 1.0)
	var apt: float = 1.0
	if apt_raw is float or apt_raw is int:
		apt = float(apt_raw)
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
	var is_boss: bool = bool(new_state.get("isBoss", false))
	# Exactly ONE variance draw per action keeps the RNG stream deterministic.
	var variance: float = rng.draw_range(VARIANCE_MIN, VARIANCE_MAX)

	# Guard set on a previous turn is consumed when this actor acts again.
	if actor.has("guard"):
		actor.erase("guard")

	for tid in target_ids:
		var target: Dictionary = _find(new_state, tid)
		if target.is_empty():
			continue
		var dmg := 0
		match atype:
			"Attack":
				var aff: float = ElementRegistry.affinity(str(actor.get("affinity", "none")), str(target.get("affinity", "none")))
				dmg = int(attack_damage(actor, target, aff, variance))
			"Skill":
				# Physical-leaning ability: ATK + 0.5*MAG, scaled by affinity + variance. Costs MP.
				if int(actor.get("MP", 0)) >= MP_SKILL_COST:
					actor["MP"] = int(actor.get("MP", 0)) - MP_SKILL_COST
					var base_f: float = float(actor.get("ATK", 0)) + 0.5 * float(actor.get("MAG", 0)) - 0.5 * float(target.get("DEF", 0))
					var aff: float = ElementRegistry.affinity(str(actor.get("affinity", "none")), str(target.get("affinity", "none")))
					dmg = int(max(1.0, round(base_f) * aff * variance))
				else:
					var aff: float = ElementRegistry.affinity(str(actor.get("affinity", "none")), str(target.get("affinity", "none")))
					dmg = int(attack_damage(actor, target, aff, variance))
			"Elemental":
				# Cast the caster's own affinity element. Costs MP. Uses elemental_damage.
				if int(actor.get("MP", 0)) >= MP_ELEMENTAL_COST:
					actor["MP"] = int(actor.get("MP", 0)) - MP_ELEMENTAL_COST
					var spell := {"power": 1.0, "resonance": 0}
					var aff: float = ElementRegistry.affinity(str(actor.get("affinity", "none")), str(target.get("affinity", "none")))
					dmg = int(elemental_damage(actor, target, spell, aff, variance))
				else:
					var aff: float = ElementRegistry.affinity(str(actor.get("affinity", "none")), str(target.get("affinity", "none")))
					dmg = int(attack_damage(actor, target, aff, variance))
			"Defend":
				# No damage. Guard halves the NEXT incoming hit on this actor.
				actor["guard"] = true
				print("[Resolver] guard SET on ", str(actor_id))
				events.append({"actor": actor_id, "target": str(tid), "type": atype, "dmg": 0})
				log_entries.append("%s guards" % actor_id)
				continue
			"Item":
				# Placeholder heal (no inventory coupling yet, E3-F/G): heal target by ratio of maxHP.
				var heal: int = int(float(target.get("maxHP", 100)) * ITEM_HEAL_RATIO)
				target["HP"] = min(int(target.get("maxHP", 100)), int(target.get("HP", 0)) + heal)
				events.append({"actor": actor_id, "target": str(tid), "type": atype, "heal": heal})
				log_entries.append("%s uses item on %s for %d" % [actor_id, str(tid), heal])
				continue
			"Run":
				if is_boss:
					# Boss disables Run (combat §7): no-op, battle continues.
					events.append({"actor": actor_id, "target": str(tid), "type": atype, "dmg": 0, "blocked": true})
					log_entries.append("%s cannot flee the Warden" % actor_id)
					continue
				new_state["fled"] = true
				events.append({"actor": actor_id, "target": str(tid), "type": atype, "dmg": 0, "fled": true})
				log_entries.append("%s flees" % actor_id)
				continue
		# Affinity-guarded damage reduction (Defend from a previous turn).
		if target.has("guard"):
			print("[Resolver] guard ACTIVE for ", str(tid), " origDmg=", dmg, " halved=", int(float(dmg) * GUARD_MULT))
			dmg = int(float(dmg) * GUARD_MULT)
			# Guard persists for all hits this round; cleared by caller.
		target["HP"] = max(0, int(target.get("HP", 0)) - dmg)
		events.append({"actor": actor_id, "target": str(tid), "type": atype, "dmg": dmg})
		log_entries.append("%s %s -> %s for %d" % [actor_id, atype, str(tid), dmg])

	new_state["log"] = log_entries
	return [new_state, events]

static func _find(state: Dictionary, id: String) -> Dictionary:
	for c in state.get("combatants", []):
		if str(c.get("id", "")) == id:
			return c
	return {}
