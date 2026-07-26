extends Node
class_name SceneManager
# Scene routing + safe-node save orchestration (E2-G / E4-D / E6-A).
# Sprint 1: tracks the LOGICAL current node and drives safe-node saves. Real scene-tree
# swaps (change_scene) land in Sprint 2; here go_to() updates logical state + persists.
# Pure offline: New Run is local (no cloud/account). Mid-combat state is NEVER persisted
# (safe-node-only rule) — only Town entry and floor clear are safe nodes.

var _current_node := "Boot"
var _run_state: Dictionary = {}

func current_node() -> String:
	return _current_node

func new_run_confirmed() -> void:
	# Pure-offline: no cloud/login/account. Create the run locally.
	_run_state = _default_run_state()

func go_to(node: String, params: Dictionary = {}) -> void:
	_current_node = node
	if node == "Town":
		_run_state = _ensure_run(_run_state)
		_run_state["worldState"]["currentNode"] = "town"
		_run_state["worldState"]["townVisited"] = true
		SaveManager.save(_run_state, true)  # Town entry IS a safe node
	elif node == "Dungeon":
		_run_state = _ensure_run(_run_state)
		# Dungeon is a sub-state of the Town hub; transient, NOT a safe node.
		_run_state["worldState"]["currentNode"] = "town"
		if params.has("floorIdx"):
			_run_state["worldState"]["dungeon"]["floorIdx"] = int(params["floorIdx"])
	# Title / Battle: transient, no persistence.
	EventBus.scene_changed.emit(_current_node, params)

# Scripted combat resolution for the smoke path. Mid-combat is never persisted.
func enter_combat_and_resolve(encounter_id: String, outcome: String) -> String:
	return outcome

func clear_floor(floor_idx: int) -> void:
	_run_state = _ensure_run(_run_state)
	if not _run_state["worldState"]["dungeon"]["clearedFloors"].has(floor_idx):
		_run_state["worldState"]["dungeon"]["clearedFloors"].append(floor_idx)
	_run_state["worldState"]["currentNode"] = "town"
	SaveManager.save(_run_state, true)  # floor clear IS a safe node

func _ensure_run(state: Dictionary) -> Dictionary:
	if state == null or state.is_empty():
		return _default_run_state()
	return state

func _default_run_state() -> Dictionary:
	return {
		"schemaVersion": SaveManager.CURRENT_VERSION,
		"seed": 1,
		"party": [],
		"runProgress": {"gold": 0, "inventory": {}, "codex": _default_codex()},
		"worldState": {"currentNode": "town", "townVisited": false, "dungeon": _default_dungeon()},
		"settings": {}
	}

func _default_dungeon() -> Dictionary:
	return {"dungeonId": "sundered_ward", "floorIdx": 0, "clearedFloors": [], "foundSigils": [], "chestsOpened": [], "bossDefeated": false}

func _default_codex() -> Dictionary:
	return {"attunedSigilIds": [], "discoveredSigilIds": [], "resonance": {}}
