extends GutTest
# C1 (Checklist C) — BattleResolver.resolve_action is a PURE function:
# the input state is never mutated; dmg >= 1; HP floored at 0 (combat 2 / QA C1).
#
# NOTE (API mismatch, see report): resolve_action does NOT currently clamp HP to 0 on
# overkill (it can go negative). The HP-floor assertion below encodes the C1 contract and
# will fail until clamping lands.

func _build_state() -> Dictionary:
	return {
		"queue": ["h0", "e0"],
		"turnPointer": 0,
		"phase": "PreBattle",
		"log": [],
		"combatants": [
			{"id": "h0", "side": "ally", "HP": 120, "maxHP": 120, "ATK": 30, "DEF": 10, "affinity": "none"},
			{"id": "e0", "side": "enemy", "HP": 40, "maxHP": 40, "ATK": 8, "DEF": 4, "affinity": "none"}
		]
	}

func test_input_state_is_not_mutated():
	var state := _build_state()
	var state_copy := state.duplicate(true)
	var rng := RNGService.new(); rng.seed(42)
	var action := {"actorId": "h0", "type": "Attack", "targetIds": ["e0"]}
	var result := BattleResolver.resolve_action(state, action, rng)
	assert_eq(state["combatants"][1]["HP"], 40, "input state HP untouched")
	assert_eq(state["log"], [], "input state log untouched")
	assert_eq(state, state_copy, "entire input state identical after resolve_action")
	assert_ne(result[0], state, "returned new_state is a distinct object")

func test_damage_is_at_least_one():
	var state := _build_state()
	var rng := RNGService.new(); rng.seed(7)
	var action := {"actorId": "h0", "type": "Attack", "targetIds": ["e0"]}
	var result := BattleResolver.resolve_action(state, action, rng)
	var new_state: Dictionary = result[0]
	for entry in new_state["log"]:
		assert_true(entry["dmg"] >= 1, "damage must be >= 1 (got %d)" % entry["dmg"])

func test_hp_floored_at_zero():
	# C1: HP must never go below 0. Overkill should clamp to 0, not go negative.
	var state := _build_state()
	state["combatants"][1]["HP"] = 5  # near-dead foe
	var rng := RNGService.new(); rng.seed(3)
	var action := {"actorId": "h0", "type": "Attack", "targetIds": ["e0"]}
	var result := BattleResolver.resolve_action(state, action, rng)
	var new_state: Dictionary = result[0]
	assert_true(new_state["combatants"][1]["HP"] >= 0,
		"HP must be >= 0 after overkill (got %d)" % new_state["combatants"][1]["HP"])
