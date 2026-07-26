extends GutTest
# B3 (Checklist B) — EventBus carries UI/feedback signals only; emitting a battle signal
# MUST NOT mutate the BattleState (ADR-002 2.4 hard rule: state mutations happen only inside
# BattleResolver pure functions and the managers, never as a side effect of an EventBus signal).
#
# NOTE (API mismatch, see report): the live signal is EventBus.battle_event, not
# combat_action_resolved as named in QA B3 / main-arch 2.4. The purity contract is identical;
# this test uses the actual signal name.

func _make_battle_state() -> Dictionary:
	return {
		"queue": ["h0", "e0"],
		"turnPointer": 0,
		"phase": "PreBattle",
		"log": [],
		"combatants": [
			{"id": "h0", "side": "ally", "HP": 120, "maxHP": 120, "affinity": "none"},
			{"id": "e0", "side": "enemy", "HP": 40, "maxHP": 40, "affinity": "none"}
		]
	}

func test_emit_battle_event_does_not_mutate_battle_state():
	var state := _make_battle_state()
	var snapshot := state.duplicate(true)
	# emit the live battle signal with the state as payload; subscribers must not mutate it
	EventBus.battle_event.emit(state)
	assert_eq(state, snapshot, "BattleState unchanged after emitting battle_event")

func test_emit_save_event_does_not_mutate_state():
	var state := _make_battle_state()
	var snapshot := state.duplicate(true)
	EventBus.save_event.emit({"ok": true})
	assert_eq(state, snapshot, "unrelated signal leaves BattleState untouched")
