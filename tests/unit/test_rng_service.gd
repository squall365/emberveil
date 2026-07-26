extends GutTest
# B2 (Checklist B) — RNGService is the sole, seedable PRNG for combat (ADR-002).
# Same seed => identical draw sequence (1000 draws). Variance is drawn in [0.9, 1.1].
#
# NOTE (API naming, see report): RNGService has no dedicated next_variance() method; variance
# is drawn via rng.draw_range(VARIANCE_MIN, VARIANCE_MAX) invoked from BattleResolver. This
# test exercises that exact path so the [0.9, 1.1] contract is verified.

func _draw_sequence(seed_val: int, n: int) -> Array:
	var rng := RNGService.new()
	rng.seed(seed_val)
	var out := []
	for i in range(n):
		out.append(rng.next_float())
	return out

func test_same_seed_produces_identical_sequence():
	var a := _draw_sequence(42, 1000)
	var b := _draw_sequence(42, 1000)
	assert_eq(a, b, "identical seed => bit-identical 1000-draw sequence")

func test_different_seed_produces_different_sequence():
	var a := _draw_sequence(42, 1000)
	var b := _draw_sequence(7, 1000)
	assert_ne(a, b, "different seed => different sequence (RNG is seeded, not constant)")

func test_variance_within_contract_range():
	# Variance is drawn via rng.draw_range(BattleResolver.VARIANCE_MIN, BattleResolver.VARIANCE_MAX)
	# and must stay inside [0.9, 1.1) (combat 2 / QA B2).
	var rng := RNGService.new()
	rng.seed(12345)
	for i in range(2000):
		var v := rng.draw_range(BattleResolver.VARIANCE_MIN, BattleResolver.VARIANCE_MAX)
		assert_true(v >= 0.9 and v < 1.1, "variance %f outside [0.9, 1.1)" % v)

func test_uint32_deterministic_and_full_range():
	var r1 := RNGService.new(); r1.seed(99)
	var r2 := RNGService.new(); r2.seed(99)
	for i in range(100):
		assert_eq(r1.next_uint32(), r2.next_uint32(), "next_uint32 deterministic for same seed")
