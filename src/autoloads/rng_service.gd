extends RefCounted
# class_name RNGService
# Deterministic seedable PRNG (ADR-002). The SOLE randomness source for combat/replays.
# xorshift32 — no global RNG, no threads, identical output across platforms for a given seed,
# so (seed, action-list) replays are bit-stable. Instantiated via RNGService.new(); NOT an
# autoload singleton (the architecture autoload list carries the same name only as a class).

var _s: int = 1

func seed(s: int) -> void:
	_s = s & 0x7FFFFFFF
	if _s == 0:
		_s = 1

func next_uint32() -> int:
	var x := _s
	x ^= (x << 13) & 0xFFFFFFFF
	x ^= (x >> 17)
	x ^= (x << 5) & 0xFFFFFFFF
	_s = x & 0xFFFFFFFF
	return _s

func next_float() -> float:
	# Advance the state, then normalise to [0, 1).
	return float(next_uint32()) / 4294967296.0

func draw_range(a: float, b: float) -> float:
	return a + (b - a) * next_float()

func draw_int(a: int, b: int) -> int:
	return a + int(next_float() * float(b - a + 1))
