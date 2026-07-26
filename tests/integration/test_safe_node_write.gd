extends GutTest
# D4 (Checklist D) — only safe nodes (Town entry, floor clear) persist; mid-combat NEVER
# writes. A safe save never carries battleState (safe-node-only rule, ADR-004 / main-arch 4).

func before_all():
	SaveManager.clear_for_test()

func test_mid_combat_does_not_persist():
	SceneManager.new_run_confirmed()
	SceneManager.enter_combat_and_resolve("smoke_encounter", "win")
	assert_false(SaveManager.was_written_at_safe_node(), "no safe write during combat")
	assert_false(SaveManager.has_save(), "nothing persisted mid-combat")

func test_town_entry_is_safe_node_without_battle_state():
	SaveManager.clear_for_test()
	SceneManager.new_run_confirmed()
	SceneManager.go_to("Town")
	assert_true(SaveManager.was_written_at_safe_node(), "Town entry triggers safe-node save")
	var loaded := SaveManager.load()
	assert_false(loaded.has("battleState"), "safe save never carries battleState")

func test_floor_clear_is_safe_node():
	SaveManager.clear_for_test()
	SceneManager.new_run_confirmed()
	SceneManager.go_to("Town")
	SceneManager.clear_floor(0)
	assert_true(SaveManager.was_written_at_safe_node(), "floor clear triggers safe-node save")
	var loaded := SaveManager.load()
	var cleared := loaded.get("worldState", {}).get("dungeon", {}).get("clearedFloors", [])
	assert_true(cleared.has(0), "floor 0 marked cleared")
	assert_false(loaded.has("battleState"), "floor-clear save never carries battleState")
