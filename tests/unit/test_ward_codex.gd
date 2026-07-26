extends GutTest
# B5 (Checklist B) — WardCodex is a Set: re-attuning the same sigil is a no-op (idempotent),
# and resonance survives snapshot/restore.

func test_re_attune_is_idempotent():
	var codex := WardCodex.new()
	codex.attune("ember")
	codex.attune("ember")  # re-attune
	codex.attune("ember")
	var snap := codex.snapshot()
	assert_eq(snap["attunedSigilIds"].size(), 1, "re-attuning same sigil does not duplicate")
	assert_true(snap["attunedSigilIds"].has("ember"))

func test_discover_is_idempotent():
	var codex := WardCodex.new()
	codex.discover("frost")
	codex.discover("frost")
	var snap := codex.snapshot()
	assert_eq(snap["discoveredSigilIds"].size(), 1, "discovering same sigil twice is idempotent")

func test_resonance_recorded_and_restored():
	var codex := WardCodex.new()
	codex.set_resonance("ember", 3)
	assert_eq(codex.get_resonance("ember"), 3)
	codex.set_resonance("ember", 5)
	assert_eq(codex.get_resonance("ember"), 5, "resonance overwrites, not accumulates")
	var snap := codex.snapshot()
	var restored := WardCodex.new()
	restored.restore(snap)
	assert_eq(restored.get_resonance("ember"), 5, "resonance survives snapshot/restore")
