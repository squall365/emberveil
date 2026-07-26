extends GutTest
# B1 (Checklist B) — SettingsManager load/apply + accessibility contract.
# Global key "emberveil.settings.v1" is authoritative; RunState.settings is a mirror
# (phase4-gate 3.1). text_scale is clamped to [1.0, 1.25] per ux-spec 4.2 / QA B1.
#
# NOTE (API mismatch, see report): SettingsManager.set_value does NOT currently clamp
# textScale — the [1.0, 1.25] clamp is a B1 requirement not yet implemented. The clamp
# assertion below encodes the contract and will fail until clamping lands.

const SETTINGS_KEY := "emberveil.settings.v1"

func test_defaults_loaded_without_storage():
	var sm := SettingsManager.new()
	assert_eq(sm.get_value("textScale"), 1.0, "default textScale = 1.0")
	assert_eq(sm.get_value("reducedMotion"), false, "default reducedMotion = false")
	assert_eq(sm.get_value("masterVolume"), 1.0, "default masterVolume = 1.0")
	assert_eq(sm.get_value("colorblindAssist"), false, "default colorblindAssist = false")

func test_apply_stores_and_reads_back():
	var sm := SettingsManager.new()
	sm.set_value("reducedMotion", true)
	assert_eq(sm.get_value("reducedMotion"), true, "set_value then get_value reflects applied value")
	sm.set_value("colorblindAssist", true)
	assert_eq(sm.get_value("colorblindAssist"), true, "second setting applied independently")

func test_text_scale_clamped_to_range():
	# B1: text_scale must stay within [1.0, 1.25].
	var sm := SettingsManager.new()
	sm.set_value("textScale", 2.0)
	assert_true(sm.get_value("textScale") <= 1.25,
		"textScale must not exceed 1.25 (got %s)" % sm.get_value("textScale"))
	sm.set_value("textScale", 0.5)
	assert_true(sm.get_value("textScale") >= 1.0,
		"textScale must not drop below 1.0 (got %s)" % sm.get_value("textScale"))

func test_settings_key_constant_is_authoritative():
	assert_eq(SettingsManager.SETTINGS_KEY, SETTINGS_KEY, "global settings key matches spec")

func test_mirror_to_run_state_copies_settings():
	var sm := SettingsManager.new()
	sm.set_value("reducedMotion", true)
	var run_state := {}
	run_state = sm.mirror_to_run_state(run_state)
	assert_true(run_state.has("settings"), "settings mirrored into RunState")
	assert_eq(run_state["settings"].get("reducedMotion"), true, "mirror carries applied value")
