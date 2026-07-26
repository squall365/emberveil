extends RefCounted
class_name EnemyAI
# Picks an enemy action for a battle turn (E3-E). Deterministic given (state, actor, rng).
# Sprint 1: simple priority — Attack the lowest-HP living ally. Structure only; the real
# policy (including Ward/Sigil reactions) is tuned in the E8 balance spike. No global RNG.

func choose_action(state: Dictionary, actor: Dictionary, rng: RNGService) -> Dictionary:
	var actor_id: String = str(actor.get("id", ""))
	var allies: Array = []
	for c in state.get("combatants", []):
		if c.get("side") == "ally" and int(c.get("HP", 0)) > 0:
			allies.append(c)
	if allies.is_empty():
		return {"actorId": actor_id, "type": "Defend", "targetIds": []}
	var target: Dictionary = allies[0]
	for a in allies:
		if int(a.get("HP", 0)) < int(target.get("HP", 0)):
			target = a
	# rng is threaded through for future stochastic policies; unused in Sprint 1.
	_ = rng
	return {"actorId": actor_id, "type": "Attack", "targetIds": [str(target.get("id", ""))]}
