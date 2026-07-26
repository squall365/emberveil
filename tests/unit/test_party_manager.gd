extends GutTest
# B6 (Checklist B) — PartyManager rejects a 2nd member of the same job (max 1 per job) and
# recomputes derived stats on demand (and never persists them).

func test_rejects_duplicate_job():
	var pm := PartyManager.new()
	assert_true(pm.add_member({"jobId": "vanguard", "level": 1}), "first vanguard accepted")
	assert_false(pm.add_member({"jobId": "vanguard", "level": 1}), "second vanguard rejected (max 1 per job)")
	assert_eq(pm.all_members().size(), 1, "only one vanguard in party")

func test_derive_stats_recompute_by_level():
	var pm := PartyManager.new()
	var low := pm.derive_stats({"jobId": "vanguard", "level": 1})
	var high := pm.derive_stats({"jobId": "vanguard", "level": 5})
	# base_hp = 100 + level*10 => 110 vs 150
	assert_eq(low["maxHP"], 110, "level 1 vanguard maxHP = 110")
	assert_eq(high["maxHP"], 150, "level 5 vanguard maxHP = 150")
	assert_gt(high["maxHP"], low["maxHP"], "derived maxHP scales with level")

func test_derive_stats_does_not_persist():
	# derive_stats returns a fresh dict; the stored member carries no derived fields.
	var pm := PartyManager.new()
	pm.add_member({"jobId": "channeler", "level": 2})
	var member := pm.get_member(0)
	assert_false(member.has("maxHP"), "stored member has no derived maxHP")
	assert_false(member.has("ATK"), "stored member has no derived ATK")
