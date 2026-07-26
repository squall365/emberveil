extends Node
# class_name SettingsManager
# Settings storage (phase4-gate §3.1). Global key "emberveil.settings.v1" is AUTHORITATIVE;
# RunState.settings is a mirror. Expanded schema (ux-spec §4.2). ADDITIVE fields only — the
# locked save serializer is never broken. For web, persisted in localStorage; headless keeps
# in-memory defaults (no persistence needed for tests).

const SETTINGS_KEY := "emberveil.settings.v1"

const DEFAULTS := {
	"masterVolume": 1.0,
	"sfxVolume": 1.0,
	"musicVolume": 1.0,
	"subtitle": true,
	"highContrast": false,
	"dyslexiaFont": false,
	"colorblindAssist": false,
	"reducedMotion": false,
	"audioVisualParity": false,
	"textScale": 1.0,
	"controlRemap": {}
}

var _settings: Dictionary = DEFAULTS.duplicate(true)

func _ready() -> void:
	load_from_global()

func load_from_global() -> void:
	_settings = DEFAULTS.duplicate(true)
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("localStorage.getItem('%s');" % SETTINGS_KEY, false)
		if typeof(raw) == TYPE_STRING and raw != "":
			var parsed = JSON.parse_string(raw)
			if typeof(parsed) == TYPE_DICTIONARY:
				_merge(parsed)
	_apply_to_input_map()

func save_to_global() -> void:
	var json := JSON.stringify(_settings)
	if OS.has_feature("web"):
		var esc := json.replace("\\", "\\\\").replace("'", "\\'")
		JavaScriptBridge.eval("localStorage.setItem('%s','%s');" % [SETTINGS_KEY, esc])

func get_value(key: String, default = null):
	if _settings.has(key):
		return _settings[key]
	return default

func set_value(key: String, value) -> void:
	if key == "textScale":
		value = clamp(float(value), 1.0, 1.25)
	_settings[key] = value
	save_to_global()
	EventBus.settings_changed.emit(_settings)

func mirror_to_run_state(run_state: Dictionary) -> Dictionary:
	run_state["settings"] = _settings.duplicate(true)
	return run_state

func apply_control_remap(remap: Dictionary) -> void:
	_settings["controlRemap"] = remap
	_apply_to_input_map()
	save_to_global()
	EventBus.settings_changed.emit(_settings)

func _apply_to_input_map() -> void:
	var remap: Dictionary = _settings.get("controlRemap", {})
	for action in InputMap.get_actions():
		if remap.has(action):
			InputMap.action_erase_events(action)
			for ev in remap[action]:
				InputMap.action_add_event(action, ev)

func _merge(parsed: Dictionary) -> void:
	for k in parsed.keys():
		_settings[k] = parsed[k]
