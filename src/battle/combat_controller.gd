extends Node
class_name CombatController
# E9.4 — drives a real, deterministic battle loop for one encounter. Instantiated PER battle
# by the Dungeon scene (Battle.tscn root), never as an autoload. Receives a fully-built
# BattleState + an injected RNGService + a result callback (the Dungeon). Resolves actions
# through BattleResolver (pure) and EnemyAI; emits battle_event on EventBus for UI only.
#
# NEVER writes saves (anti-save-scum): the callback (Dungeon) owns persistence at safe nodes.
# The Battle node is added as an overlay (get_tree().get_root().add_child) by the Dungeon and
# is queue_freed here when the battle ends — never serialized (architecture §2.2).

var _state: Dictionary = {}
var _rng: RNGService = null
var _callback: Object = null
var _fsm: BattleFSM = null
var _queue: BattleQueue = null
var _is_boss: bool = false
var _outcome: String = "ongoing"

func setup(state: Dictionary, rng: RNGService, callback: Object) -> void:
	_state = state.duplicate(true) if state != null else {}
	_rng = rng
	_callback = callback
	_is_boss = bool(_state.get("isBoss", false))
	_fsm = BattleFSM.new()
	_fsm.transition(BattleFSM.Phase.PlayerInput)
	_queue = BattleQueue.new()
	_queue.setup(_state.get("combatants", []))
	_resolve_loop()

# Synchronous, deterministic resolution. Allies auto-Attack the lowest-HP enemy (UI hook point
# for E3-F/G commands); enemies use EnemyAI. Loop is guarded against non-termination.
func _resolve_loop() -> void:
	var guard := 0
	while guard < 4000:
		guard += 1
		var aid := _queue.next_actor()
		if aid == "":
			_queue.new_round()
			aid = _queue.next_actor()
			if aid == "":
				break
		var actor := _find(aid)
		if actor.is_empty():
			_queue.mark_acted(aid)
			continue
		var action: Dictionary
		if str(actor.get("side", "")) == "ally":
			action = _auto_ally_action(actor)
		else:
			action = EnemyAI.new().choose_action(_state, actor, _rng)
		var res := BattleResolver.resolve_action(_state, action, _rng)
		_state = res[0]
		EventBus.battle_event.emit({"actorId": aid, "action": action, "events": res[1]})
		_queue.mark_acted(aid)
		if _check_end():
			break
	_finish()

# MVP ally policy: Attack the lowest-HP living enemy. Defend if no enemy remains.
func _auto_ally_action(actor: Dictionary) -> Dictionary:
	var enemies := _state.get("combatants", []).filter(
		func(c): return str(c.get("side", "")) == "enemy" and int(c.get("HP", 0)) > 0)
	if enemies.is_empty():
		return {"actorId": str(actor.get("id", "")), "type": "Defend", "targetIds": []}
	var tgt: Dictionary = enemies[0]
	for e in enemies:
		if int(e.get("HP", 0)) < int(tgt.get("HP", 0)):
			tgt = e
	return {"actorId": str(actor.get("id", "")), "type": "Attack", "targetIds": [str(tgt.get("id", ""))]}

func _check_end() -> bool:
	var any_enemy := false
	var any_ally := false
	for c in _state.get("combatants", []):
		if int(c.get("HP", 0)) > 0:
			if str(c.get("side", "")) == "enemy":
				any_enemy = true
			else:
				any_ally = true
	if not any_enemy:
		_outcome = "win"
		_fsm.transition(BattleFSM.Phase.Victory)
		return true
	if not any_ally:
		_outcome = "lose"
		_fsm.transition(BattleFSM.Phase.Defeat)
		return true
	return false

func _find(id: String) -> Dictionary:
	for c in _state.get("combatants", []):
		if str(c.get("id", "")) == id:
			return c
	return {}

func _finish() -> void:
	# Pass the final state so the Dungeon can write ally hp/mp/level/xp back.
	var result := {"outcome": _outcome, "state": _state}
	if _callback != null and _callback.has_method("_on_battle_resolved"):
		_callback._on_battle_resolved(result)
	queue_free()
