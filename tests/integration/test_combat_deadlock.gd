extends GutTest
# OQ7 / C2 (Checklist C) — a battle must terminate (no FSM deadlock). A normal, scripted battle
# reaches a terminal phase; the all-Defend escalation path is pending the battle-loop +
# enemy-escalation util (see API-mismatch report / QA R7).
#
# NOTE: the existing determinism test scripts ATTACK actions, so the all-Defend convergence path
# is currently UNVERIFIED. This file anchors the anti-deadlock contract; the pending test should
# become a real assertion once BattleLoop/escalation lands.

func test_normal_battle_reaches_terminal_phase():
	# Drive a scripted attack battle to a win; the FSM must be able to reach Victory.
	var heroes := [
		{"id": "h0", "side": "ally", "HP": 120, "maxHP": 120, "ATK": 30, "DEF": 10, "affinity": "none"},
	]
	var foes := [
		{"id": "e0", "side": "enemy", "HP": 30, "maxHP": 30, "ATK": 8, "DEF": 4, "affinity": "none"},
	]
	var combatants := heroes + foes
	var state := {
		"queue": ["h0", "e0"], "turnPointer": 0, "phase": "PreBattle", "log": [],
		"combatants": combatants
	}
	var rng := RNGService.new(); rng.seed(42)
	var fsm := BattleFSM.new()
	fsm.transition(BattleFSM.Phase.PlayerInput)
	var any_enemy := true
	var any_ally := true
	for i in range(20):
		var actor := combatants[i % combatants.size()]
		var target := foes[0] if actor["side"] == "ally" else heroes[0]
		var res := BattleResolver.resolve_action(state,
			{"actorId": actor["id"], "type": "Attack", "targetIds": [target["id"]]}, rng)
		state = res[0]
		any_enemy = false
		any_ally = false
		for c in state["combatants"]:
			if c["HP"] > 0:
				if c["side"] == "enemy":
					any_enemy = true
				else:
					any_ally = true
		if not any_enemy or not any_ally:
			break
	# drive the FSM to the matching terminal phase
	if not any_enemy:
		fsm.transition(BattleFSM.Phase.Resolve)
		fsm.transition(BattleFSM.Phase.CheckEnd)
		fsm.transition(BattleFSM.Phase.Victory)
	elif not any_ally:
		fsm.transition(BattleFSM.Phase.Resolve)
		fsm.transition(BattleFSM.Phase.CheckEnd)
		fsm.transition(BattleFSM.Phase.Defeat)
	assert_true(fsm.is_over(), "battle can reach a terminal FSM phase (no infinite loop)")

func test_all_defend_no_deadlock_is_pending():
	pending("All-Defend deadlock resolution needs a battle-loop + enemy-escalation util " \
			"(not in src yet — QA R7 / OQ7). The existing determinism test scripts attacks, " \
			"so the all-Defend convergence path is unverified until that util lands.")
