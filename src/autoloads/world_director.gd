extends Node
class_name WorldDirector
# Town + Dungeon routing (E2-L/M). Delegates scene swaps to SceneManager. Sprint 1: structure.

func enter_town() -> void:
	SceneManager.go_to("Town")

func enter_dungeon(floor_idx: int = 0) -> void:
	SceneManager.go_to("Dungeon", {"floorIdx": floor_idx})

func clear_floor(floor_idx: int) -> void:
	SceneManager.clear_floor(floor_idx)
