extends Node
class_name SceneManager
# Scene routing + safe-node save orchestration (E2-G / E4-D / E6-A).
# Sprint 1: tracked the LOGICAL current node and drove safe-node saves. Sprint 2
# (E9.1/GAP-3) adds read-only accessors + a single commit writer so World children
# (Town/Dungeon) can read worldState and write battle outcomes back. Real scene-tree
# swaps live in WorldDirector._swap_world_child.
# Pure offline: New Run is local (no cloud/account). Mid-combat state is NEVER persisted
# (safe-node-only rule) — only Town entry and floor clear are safe nodes.

var _current_node := "Boot"
var _run_state: Dictionary = {}

func current_node() -> String:
	return _current_node

# GAP-3: read-only accessors so Town/Dungeon scene scripts can read the run/world state
# without SceneManager leaking its private _run_state dict as a mutable reference.
func get_run_state() -> Dictionary:
	return _run_state.duplicate(true)

func get_world_state() -> Dictionary:
	return _run_state.get("worldState", {})

func new_run_confirmed() -> void:
	# Pure-offline: no cloud/login/account. Create the run locally.
	# GAP-12: seed the default 4-job party so Dungeon entry always has 4 combatants.
	_run_state = _default_run_state()
	PartyManager.new_run_defaults()
	_run_state["party"] = PartyManager.all_members()

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
	# Advance the saved current-floor pointer so a resume (decision 2.6) enters the NEXT
	# floor, not the one just cleared. Out-of-range past the last floor is harmless: the
	# boss clear path returns to Town instead of re-entering.
	_run_state["worldState"]["dungeon"]["floorIdx"] = int(floor_idx) + 1
	_run_state["worldState"]["currentNode"] = "town"
	SaveManager.save(_run_state, true)  # floor clear IS a safe node

# E9.4: commit a (mutated) run-state back into the authoritative holder so subsequent
# safe-node saves (Town entry / floor clear) persist battle outcomes (xp / hp / mp / gold).
# Read via get_run_state() (GAP-3); write via this single owner method only.
func commit_run_state(rs: Dictionary) -> void:
	_run_state = _ensure_run(rs)

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
