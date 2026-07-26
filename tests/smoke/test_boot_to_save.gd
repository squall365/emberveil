extends GutTest
# STUB — end-to-end happy path (checklist G ⛔). Targets SceneManager + SaveManager
# (Epics E2-G, E3-F, E4-D, E6-A). Boot→Title→Town→Dungeon→Combat→win→safe-node Save.

func before_all():
	# ensure a clean slate for the smoke run
	SaveManager.clear_for_test()

func test_boot_reaches_title():
	assert_true(SceneManager.current_node() in ["Boot", "Title"], "boot resolves to Title")
	SceneManager.go_to("Title")
	assert_eq(SceneManager.current_node(), "Title")

func test_new_run_then_town():
	SceneManager.new_run_confirmed()   # pure-offline: no cloud/account; direct New Run
	SceneManager.go_to("Town")
	assert_eq(SceneManager.current_node(), "Town")
	# entering Town is a safe node => autosave fired
	assert_true(SaveManager.was_written_at_safe_node(), "Town entry triggers safe-node save")

func test_dungeon_floor_then_combat_win_then_save():
	SceneManager.go_to("Dungeon", {"floorIdx": 0})
	assert_eq(SceneManager.current_node(), "Dungeon")
	# drive a CombatRoom to a win (scripted)
	var result = SceneManager.enter_combat_and_resolve("smoke_encounter", "win")
	assert_eq(result, "win")
	# clear the floor => another safe-node save
	SceneManager.clear_floor(0)
	assert_true(SaveManager.was_written_at_safe_node(), "floor clear triggers safe-node save")

func test_reload_restores_runstate():
	var loaded = SaveManager.load()
	assert_false(loaded.is_empty(), "a save exists after the happy path")
	assert_eq(loaded.get("worldState", {}).get("currentNode"), "town")
	# mid-combat state must NOT be persisted (safe-node-only rule)
	assert_false(loaded.has("battleState"), "mid-combat battle state absent from save")
