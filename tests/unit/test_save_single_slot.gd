extends GutTest
# D5 (Checklist D) — single local slot; New Run overwrites only after confirm; Continue hidden
# when no save exists. Data-layer invariants exercised via SaveManager + SceneManager.
#
# NOTE (API mismatch, see report): SceneManager exposes only new_run_confirmed() (the confirmed
# path). There is no separate unconfirmed new_run() to reject; the dialog-confirm gate lives in
# the Title scene which calls new_run_confirmed() after acceptance. The single-slot + visibility
# invariants below are testable at the data layer.

func before_all():
	SaveManager.clear_for_test()

func test_single_slot_overwrites_do_not_append():
	SaveManager.clear_for_test()
	SaveManager.save({"schemaVersion": 1, "seed": 1}, true)
	SaveManager.save({"schemaVersion": 1, "seed": 2}, true)
	var loaded := SaveManager.load()
	assert_eq(loaded.get("seed"), 2, "last write wins (single slot overwrites)")
	assert_ne(loaded.get("seed"), 1, "earlier write not preserved alongside")

func test_has_save_reflects_presence():
	SaveManager.clear_for_test()
	assert_false(SaveManager.has_save(), "no save after clear -> Continue should be hidden")
	SaveManager.save({"schemaVersion": 1, "seed": 1}, true)
	assert_true(SaveManager.has_save(), "save present -> Continue available")

func test_confirmed_new_run_writes_single_slot():
	SaveManager.clear_for_test()
	SceneManager.new_run_confirmed()
	SceneManager.go_to("Town")  # Town entry is a safe node -> persists
	assert_true(SaveManager.has_save(), "confirmed New Run + Town writes single slot")
	var loaded := SaveManager.load()
	assert_true(loaded.has("worldState"), "saved run has worldState")
	assert_false(loaded.has("battleState"), "safe save never carries battleState")
