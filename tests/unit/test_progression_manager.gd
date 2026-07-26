extends GutTest
# B6 (Checklist B) — ProgressionManager records XP on combat end and recomputes level/derived.
#
# NOTE (API mismatch, see report): there is no combat_ended method on ProgressionManager.
# The combat->XP linkage is exercised here via the live add_xp API (the battle FSM is expected
# to call add_xp when combat resolves). The alive xp_for_level formula is 100*level.

func test_add_xp_records_and_levels_up():
	var pm := ProgressionManager.new()
	var member := {"jobId": "vanguard", "level": 1, "xp": 0}
	pm.add_xp(member, 50)
	assert_eq(member["xp"], 50, "50 xp recorded at level 1")
	assert_eq(member["level"], 1, "still level 1 under threshold")
	pm.add_xp(member, 60)  # cumulative 110 >= xp_for_level(1)=100
	assert_eq(member["level"], 2, "crossed threshold => level 2")
	assert_eq(member["xp"], 10, "overflow xp carried to next level")

func test_xp_for_level_formula():
	# Live implementation: xp_for_level(l) = 100 * l.
	assert_eq(ProgressionManager.xp_for_level(1), 100)
	assert_eq(ProgressionManager.xp_for_level(5), 500)

func test_combat_end_records_xp():
	# Mirrors B6: a winning combat must credit XP. Driven via the live add_xp API.
	var pm := ProgressionManager.new()
	var hero := {"jobId": "channeler", "level": 3, "xp": 0}
	pm.add_xp(hero, 750)  # 300 to L4 + 400 to L5, 50 remainder
	assert_eq(hero["level"], 5, "channeler reaches level 5 with 750 xp")
	assert_eq(hero["xp"], 50, "remaining xp = 50")
