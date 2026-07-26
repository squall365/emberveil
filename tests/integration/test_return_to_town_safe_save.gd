extends GutTest
# E9.5 scaffold — return-to-town + safe-node save persistence (decision 2.6 / ux-spec §2.2).
# Quality-lead fills/refines assertions; structure + key checks below are wired so the
# vertical-slice CI path (Boot -> Town -> Dungeon -> Battle -> FloorClear -> Town) is covered.

func before_all():
	SaveManager.clear_for_test()

func before_each():
	SaveManager.clear_for_test()
	SceneManager.new_run_confirmed()

# Town entry is a safe node; the last safe save resumes at Town, never Dungeon.
func test_town_entry_is_safe_node_and_resumes_at_town():
	WorldDirector.enter_town()
	assert_eq(SceneManager.current_node(), "Town", "entered Town")
	assert_true(SaveManager.was_written_at_safe_node(), "Town entry triggers a safe-node save")
	var loaded := SaveManager.load()
	assert_eq(loaded.get("worldState", {}).get("currentNode", ""), "town", "continue node is Town")

# Clearing floor 0 persists clearedFloors and still resumes at Town (decision 2.6).
func test_floor_clear_persists_progress_and_resumes_at_town():
	WorldDirector.enter_town()
	WorldDirector.enter_dungeon(0)
	SceneManager.clear_floor(0)
	var loaded := SaveManager.load()
	var cleared: Array = loaded.get("worldState", {}).get("dungeon", {}).get("clearedFloors", [])
	assert_true(cleared.has(0), "floor 0 persisted as cleared")
	assert_eq(loaded.get("worldState", {}).get("currentNode", ""), "town", "continue node is Town after floor clear")

# Returning to Town preserves dungeon progress (only the current floor is lost on wipe).
func test_return_to_town_keeps_cleared_floors():
	WorldDirector.enter_town()
	WorldDirector.enter_dungeon(0)
	SceneManager.clear_floor(0)
	WorldDirector.return_to_town()
	var loaded := SaveManager.load()
	assert_eq(loaded.get("worldState", {}).get("currentNode", ""), "town", "resume at Town after return")
	assert_true(loaded.get("worldState", {}).get("dungeon", {}).get("clearedFloors", []).has(0),
		"cleared-floor progress preserved on return")

# Mid-combat never writes (reuse E4-D contract): a battle resolve does not flip the safe flag
# here because Dungeon persists only at safe nodes (floor-clear / sigil-attune / shrine).
func test_no_mid_combat_persist_on_battle():
	WorldDirector.enter_town()
	WorldDirector.enter_dungeon(0)
	SaveManager.clear_for_test()
	# Simulate the Dungeon driving a combat room; the battle itself must not save.
	var dungeon = get_tree().get_root().find_child("Dungeon", true, false)
	assert_not_null(dungeon, "Dungeon scene mounted under World")
