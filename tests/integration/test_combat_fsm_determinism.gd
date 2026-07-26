extends GutTest
# STUB — targets BattleResolver + BattleState (Epic E3-A/B/C, ADR-002).
# Core determinism contract: same (seed, action list) => identical log + outcome.

func _build_battle(seed_val: int) -> Dictionary:
	var heroes = [
		{"id": "h0", "side": "ally", "name": "Vanguard", "HP": 120, "maxHP": 120, "MP": 10,
		 "ATK": 14, "DEF": 12, "MAG": 4, "RES": 10, "SPD": 8, "statusEffects": [], "affinity": "none"},
		{"id": "h1", "side": "ally", "name": "Channeler", "HP": 70, "maxHP": 70, "MP": 40,
		 "ATK": 6, "DEF": 5, "MAG": 16, "RES": 9, "SPD": 10, "statusEffects": [], "affinity": "ember"},
	]
	var foes = [
		{"id": "e0", "side": "enemy", "name": "Huskling", "HP": 40, "maxHP": 40, "MP": 0,
		 "ATK": 10, "DEF": 6, "MAG": 4, "RES": 4, "SPD": 7, "statusEffects": [], "affinity": "none"},
		{"id": "e1", "side": "enemy", "name": "Frostmote", "HP": 36, "maxHP": 36, "MP": 0,
		 "ATK": 8, "DEF": 4, "MAG": 10, "RES": 6, "SPD": 9, "statusEffects": [], "affinity": "frost"},
	]
	var combatants = heroes + foes
	# PreBattle sort by SPD desc, tie-break slot asc (deterministic via RNGService if tied)
	combatants.sort_custom(func(a, b): return a["SPD"] > b["SPD"])
	return {
		"queue": combatants.map(func(c): return c["id"]),
		"turnPointer": 0,
		"phase": "PreBattle",
		"log": [],
		"isBoss": false,
		"combatants": combatants
	}

func _scripted_actions() -> Array:
	# allies Attack; foes Attack — enough turns to reach an outcome
	return [
		{"actorId": "h1", "type": "Attack", "targetIds": ["e0"]},
		{"actorId": "h0", "type": "Attack", "targetIds": ["e1"]},
		{"actorId": "e1", "type": "Attack", "targetIds": ["h1"]},
		{"actorId": "e0", "type": "Attack", "targetIds": ["h0"]},
		{"actorId": "h1", "type": "Attack", "targetIds": ["e0"]},
		{"actorId": "h0", "type": "Attack", "targetIds": ["e1"]},
	]

func _run(seed_val: int) -> Dictionary:
	var rng = RNGService.new()
	rng.seed(seed_val)
	var state = _build_battle(seed_val)
	for action in _scripted_actions():
		var res = BattleResolver.resolve_action(state, action, rng)
		state = res[0]
	return state

func test_fixed_seed_deterministic():
	var sA = _run(42)
	var sB = _run(42)
	assert_eq(sA["log"], sB["log"], "same seed+actions => identical log")
	assert_eq(_outcome(sA), _outcome(sB), "same seed+actions => identical outcome")

func test_different_seed_differs():
	var sA = _run(42)
	var sB = _run(7)
	# variance draws differ => logs differ (proves RNG is seeded, not constant)
	assert_ne(sA["log"], sB["log"], "different seed => different variance")

func _outcome(state: Dictionary) -> String:
	var any_enemy = false
	var any_ally = false
	for c in state["combatants"]:
		if c["HP"] > 0:
			if c["side"] == "enemy": any_enemy = true
			else: any_ally = true
	if not any_enemy: return "win"
	if not any_ally: return "lose"
	return "ongoing"
