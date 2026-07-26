extends GutTest
# C2 (Checklist C) — FSM phases are all reachable and guarded; turn-queue ordering follows
# SPD desc, tie-break slot asc, skip dead (combat 3.2 / QA C2).
#
# Phase transitions are exercised on BattleFSM. Turn-queue ordering is asserted via a test-side
# helper because BattleFSM currently owns ONLY phase logic — there is no shared turn-queue util
# in src (see API-mismatch report; recommend extracting BattleQueue so ordering is unit-tested
# at the source rather than re-implemented per test).

func test_all_phases_reachable():
	var fsm := BattleFSM.new()
	assert_true(fsm.transition(BattleFSM.Phase.PlayerInput), "PreBattle -> PlayerInput")
	assert_true(fsm.transition(BattleFSM.Phase.Resolve), "PlayerInput -> Resolve")
	assert_true(fsm.transition(BattleFSM.Phase.CheckEnd), "Resolve -> CheckEnd")
	assert_true(fsm.transition(BattleFSM.Phase.Victory), "CheckEnd -> Victory")
	assert_true(fsm.is_over(), "Victory is a terminal phase")

func test_invalid_transitions_rejected():
	var fsm := BattleFSM.new()
	assert_false(fsm.transition(BattleFSM.Phase.Resolve), "cannot jump PreBattle -> Resolve")
	assert_false(fsm.can_transition(BattleFSM.Phase.PreBattle, BattleFSM.Phase.Victory),
		"PreBattle -> Victory rejected")
	var f2 := BattleFSM.new()
	f2.transition(BattleFSM.Phase.PlayerInput)
	f2.transition(BattleFSM.Phase.Resolve)
	f2.transition(BattleFSM.Phase.CheckEnd)
	assert_false(f2.transition(BattleFSM.Phase.PlayerInput),
		"CheckEnd cannot loop back to PlayerInput without win/lose")

func test_turn_queue_ordered_by_spd_desc_then_slot():
	# C2 turn-order contract: SPD desc, tie-break slot asc, skip HP<=0.
	var combatants := [
		{"id": "a", "slot": 0, "SPD": 8, "HP": 50},
		{"id": "b", "slot": 1, "SPD": 10, "HP": 50},
		{"id": "c", "slot": 2, "SPD": 8, "HP": 0},   # dead -> skipped
		{"id": "d", "slot": 3, "SPD": 10, "HP": 50}  # tie with b, higher slot -> later
	]
	var queue := _build_turn_queue(combatants)
	assert_eq(queue, ["b", "d", "a"], "expected order: SPD desc, tie-break slot asc, dead skipped")

func _build_turn_queue(combatants: Array) -> Array:
	var alive := combatants.filter(func(c): return int(c["HP"]) > 0)
	alive.sort_custom(func(x, y):
		if x["SPD"] != y["SPD"]:
			return x["SPD"] > y["SPD"]   # SPD desc
		return x["slot"] < y["slot"]      # tie-break slot asc
	)
	return alive.map(func(c): return c["id"])
