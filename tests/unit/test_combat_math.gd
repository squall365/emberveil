extends GutTest
# STUB — targets BattleResolver pure helpers (Epic E3-A). Formulas verbatim from combat §2.
# Variance pinned to 1.0 so results are integer-exact; clamping asserted.

# Attack: max(1, round(ATK*1.0 - DEF*0.5)) * affinityMult * variance
func test_attack_damage_neutral():
	var dmg = BattleResolver.attack_damage({"ATK": 20}, {"DEF": 0}, 1.0, 1.0)
	assert_eq(dmg, 20)

func test_attack_damage_strong():
	var dmg = BattleResolver.attack_damage({"ATK": 20}, {"DEF": 0}, 1.5, 1.0)
	assert_eq(dmg, 30)

func test_attack_damage_weak():
	var dmg = BattleResolver.attack_damage({"ATK": 20}, {"DEF": 0}, 0.67, 1.0)
	assert_almost_eq(dmg, 13.4, 0.01)

func test_attack_damage_clamped_min_1():
	# huge defense drives base negative => clamped to 1
	var dmg = BattleResolver.attack_damage({"ATK": 5}, {"DEF": 999}, 1.0, 1.0)
	assert_eq(dmg, 1)

# Elemental: max(1, round(MAG*power*apt* (1+res*0.1) - RES*0.5)) * affinityMult * variance
func test_elemental_damage_base():
	var dmg = BattleResolver.elemental_damage(
		{"MAG": 16, "aptitude": 1.0}, {"RES": 0},
		{"power": 1.3, "resonance": 0}, 1.0, 1.0)
	assert_eq(dmg, 21)  # round(16*1.3) = round(20.8) = 21

func test_elemental_damage_resonance_scales():
	var dmg = BattleResolver.elemental_damage(
		{"MAG": 16, "aptitude": 1.0}, {"RES": 0},
		{"power": 1.3, "resonance": 5}, 1.0, 1.0)
	assert_eq(dmg, 31)  # round(20.8 * 1.5) = round(31.2) = 31

func test_elemental_damage_hp_floor():
	# overkill clamp: result never below 1
	var dmg = BattleResolver.elemental_damage(
		{"MAG": 1, "aptitude": 0.0}, {"RES": 999},
		{"power": 1.0, "resonance": 0}, 0.67, 1.0)
	assert_eq(dmg, 1)
