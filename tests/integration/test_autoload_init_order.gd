extends GutTest
# R3 — the autoload singletons initialize in dependency order; SettingsManager (which applies the
# InputMap remap at boot) is ready before SceneManager. No null crashes after boot.
#
# NOTE (API mismatch, see report): QA plan / CLAUDE.md reference "13 autoloads" (counting
# RNGService*), but RNGService is an instantiable class_name, NOT an autoload — project.godot
# registers 12 autoload singletons. This test validates the 12 that actually exist.

const EXPECTED_ORDER := [
	"SettingsManager", "EventBus", "AssetRegistry", "ElementRegistry", "WardCodex",
	"SaveManager", "PartyManager", "ProgressionManager", "WorldDirector",
	"SceneManager", "AudioBus", "Analytics"
]

func test_autoloads_registered_in_expected_order():
	var parsed := _parse_autoload_order()
	assert_eq(parsed, EXPECTED_ORDER, "project.godot autoload order matches the contract")

func test_settings_manager_initialized_before_scene_manager():
	var order := _parse_autoload_order()
	var si := order.find("SettingsManager")
	var smi := order.find("SceneManager")
	assert_true(si >= 0 and smi >= 0, "both autoloads present")
	assert_true(si < smi, "SettingsManager loads before SceneManager (InputMap remap ready)")

func test_all_autoloads_non_null_after_boot():
	assert_not_null(SettingsManager, "SettingsManager autoload present")
	assert_not_null(EventBus, "EventBus autoload present")
	assert_not_null(AssetRegistry, "AssetRegistry autoload present")
	assert_not_null(ElementRegistry, "ElementRegistry autoload present")
	assert_not_null(WardCodex, "WardCodex autoload present")
	assert_not_null(SaveManager, "SaveManager autoload present")
	assert_not_null(PartyManager, "PartyManager autoload present")
	assert_not_null(ProgressionManager, "ProgressionManager autoload present")
	assert_not_null(WorldDirector, "WorldDirector autoload present")
	assert_not_null(SceneManager, "SceneManager autoload present")
	assert_not_null(AudioBus, "AudioBus autoload present")
	assert_not_null(Analytics, "Analytics autoload present")

func _parse_autoload_order() -> Array:
	var order := []
	var f := FileAccess.open("res://project.godot", FileAccess.READ)
	if f == null:
		return order
	var in_section := false
	while not f.eof_reached():
		var line := f.get_line()
		if line.begins_with("[autoload]"):
			in_section = true
			continue
		if in_section:
			if line.begins_with("[") and line.ends_with("]"):
				break
			if line.strip_edges() == "":
				continue
			var eq := line.find("=")
			if eq > 0:
				order.append(line.substr(0, eq).strip_edges())
	return order
