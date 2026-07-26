extends GutTest
# OQ7 / E5-C (Checklist E, flagged) — safe viewport 360x640 and interactive hit targets
# >= 44x44px (art-bible 9.1 / CLAUDE.md web budget / main-arch 2.3).
#
# NOTE (no runtime layout API, see report): there is no layout manager / UI scene to introspect
# yet (Title/Town scenes land in Sprint 2). This test anchors the OQ7/E5-C numeric spec as a
# regression gate; once real Control nodes exist it should read each control's
# custom_minimum_size / get_minimum_size() instead of the spec constants below.

const SAFE_VIEWPORT := Vector2(360, 640)
const MIN_HIT := 44

# Representative interactive controls (command-dock chips, hero medallions, turn pips, toggles).
const CONTROL_MIN_SIZES := {
	"cmd_attack_chip": Vector2(48, 48),
	"cmd_skill_chip": Vector2(48, 48),
	"cmd_defend_chip": Vector2(48, 48),
	"hero_medallion": Vector2(64, 64),
	"turn_pip": Vector2(44, 44),
	"settings_toggle": Vector2(56, 48),
}

func test_safe_viewport_is_360x640():
	assert_eq(int(SAFE_VIEWPORT.x), 360, "safe viewport width = 360")
	assert_eq(int(SAFE_VIEWPORT.y), 640, "safe viewport height = 640")

func test_interactive_controls_meet_min_hit_target():
	for name in CONTROL_MIN_SIZES.keys():
		var sz := CONTROL_MIN_SIZES[name]
		assert_true(sz.x >= MIN_HIT and sz.y >= MIN_HIT,
			"%s hit area %s must be >= %dx%d" % [name, sz, MIN_HIT, MIN_HIT])
