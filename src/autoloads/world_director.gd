extends Node
class_name WorldDirector
# Town + Dungeon routing (E2-L/M). Delegates logical state to SceneManager and physically
# mounts Town/Dungeon as children of the resident World node (architecture 2.2). Sprint 2
# (E9.1): real scene swaps via _swap_world_child; GAP-4 no-arg resume to saved floor;
# E9.5: return_to_town (resume always at Town, decision 2.6).

const WORLD_SCENE := "res://scenes/world/World.tscn"
const TOWN_SCENE := "res://scenes/town/Town.tscn"
const DUNGEON_SCENE := "res://scenes/dungeon/Dungeon.tscn"

var _world_root: Node = null

func enter_town() -> void:
	SceneManager.go_to("Town")
	_ensure_world()
	_swap_world_child(TOWN_SCENE)

func enter_dungeon(floor_idx: int = -1) -> void:
	# GAP-4: no-arg call resumes to the saved dungeon floor, not always floor 0.
	var dungeon: Dictionary = SceneManager.get_world_state().get("dungeon", {})
	var f := floor_idx if floor_idx >= 0 else int(dungeon.get("floorIdx", 0))
	SceneManager.go_to("Dungeon", {"floorIdx": f})
	_ensure_world()
	_swap_world_child(DUNGEON_SCENE, {"floorIdx": f})

func clear_floor(floor_idx: int) -> void:
	SceneManager.clear_floor(floor_idx)

# E9.5: return to Town after wipe / backtrack. Resumes at Town (decision 2.6); dungeon
# progress (clearedFloors / floorIdx) is preserved in worldState for the next Sage entry.
func return_to_town() -> void:
	SceneManager.go_to("Town")
	_ensure_world()
	_swap_world_child(TOWN_SCENE)

# GAP-1: mount Town/Dungeon as a child of the resident World node. The World node itself
# is resident (never reloaded mid-run) so RunState is never reloaded => no save-scum.
func _swap_world_child(scene_path: String, params: Dictionary = {}) -> void:
	var world := _ensure_world()
	if world == null:
		push_warning("[WorldDirector] no World root; skipping scene swap for %s" % scene_path)
		return
	for child in world.get_children():
		if child.has_meta("world_child"):
			child.queue_free()
	var scn := load(scene_path)
	if scn == null:
		push_warning("[WorldDirector] failed to load %s" % scene_path)
		return
	var inst := scn.instantiate()
	inst.set_meta("world_child", true)
	world.add_child(inst)
	if inst.has_method("setup"):
		inst.setup(params)

func _ensure_world() -> Node:
	if _world_root != null and is_instance_valid(_world_root):
		return _world_root
	var tree := get_tree()
	if tree != null and tree.current_scene != null and tree.current_scene.has_meta("is_world"):
		_world_root = tree.current_scene
		return _world_root
	if tree != null:
		var scn := load(WORLD_SCENE)
		if scn != null:
			_world_root = scn.instantiate()
			_world_root.set_meta("is_world", true)
			tree.get_root().add_child(_world_root)
	return _world_root
