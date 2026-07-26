extends GutTest
# STUB — targets ElementRegistry (Epic E2-E). Passes once the registry lands.
# Contract: elements §2 — strong=1.5, weak=0.67, neutral=1.0; symmetric 7-cycle
# Ember▸Frost▸Storm▸Stone▸Gale▸Lumen▸Umbra▸Ember. (IDs are GDD enum names, TitleCase.)

func test_affinity_exact_multipliers():
	assert_eq(ElementRegistry.affinity("Ember", "Frost"), 1.5, "Ember strong vs Frost")
	assert_eq(ElementRegistry.affinity("Frost", "Storm"), 1.5)
	assert_eq(ElementRegistry.affinity("Stone", "Gale"), 1.5)
	assert_eq(ElementRegistry.affinity("Ember", "Umbra"), 0.67, "Ember weak vs previous (Umbra)")
	assert_eq(ElementRegistry.affinity("Frost", "Ember"), 0.67)
	assert_eq(ElementRegistry.affinity("Ember", "Stone"), 1.0, "non-adjacent => neutral")
	assert_eq(ElementRegistry.affinity("Ember", "Ember"), 1.0, "same element convention => neutral")

func test_affinity_symmetric_seven_cycle():
	for e in ElementRegistry.ALL:
		var strong = ElementRegistry.strong_vs(e)
		var weak = ElementRegistry.weak_vs(e)
		assert_ne(strong, weak, "strong and weak targets differ for %s" % e)
		assert_eq(ElementRegistry.affinity(e, strong), 1.5, "%s strong=1.5" % e)
		assert_eq(ElementRegistry.affinity(e, weak), 0.67, "%s weak=0.67" % e)
	# cycle direction follows the GDD exactly
	assert_eq(ElementRegistry.strong_vs("Ember"), "Frost")
	assert_eq(ElementRegistry.strong_vs("Frost"), "Storm")
	assert_eq(ElementRegistry.strong_vs("Umbra"), "Ember")

func test_affinity_no_dominant_element():
	# Design-theory red line: each element strong vs exactly ONE other => no dominance.
	var strong_count = {}
	for a in ElementRegistry.ALL:
		for b in ElementRegistry.ALL:
			if a == b:
				continue
			if ElementRegistry.affinity(a, b) > 1.0:
				strong_count[a] = strong_count.get(a, 0) + 1
	for e in ElementRegistry.ALL:
		assert_eq(strong_count.get(e, 0), 1, "%s is strong vs exactly one element" % e)
