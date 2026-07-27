extends Node
# class_name SaveManager
# Persistent save/load (ADR-004). Single local slot, pure offline.
# JSON to localStorage key "emberveil.save.v1" (web) or in-memory (headless/tests).
# Schema v1. Safe-node-only writes. CRC32 integrity check; tamper => refuse.

const CURRENT_VERSION := 1
const SAVE_KEY := "emberveil.save.v1"

# ---- pure (no instance state) helpers, callable on the singleton ----
func serialize(state: Dictionary) -> String:
	var body: Dictionary = state.duplicate(true)
	if not body.has("schemaVersion"):
		body["schemaVersion"] = CURRENT_VERSION
	var body_json := _canonical(body)
	var crc := _crc32_hex(body_json)
	body["crc"] = crc
	return _canonical(body)

func deserialize(json_str: String) -> Dictionary:
	var parsed = JSON.parse_string(json_str)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var original_crc = parsed.get("crc", "")
	var body: Dictionary = parsed.duplicate(true)
	body.erase("crc")
	if original_crc != _crc32_hex(_canonical(body)):
		return {}
	return body

func migrate(state: Dictionary) -> Dictionary:
	var s: Dictionary = state.duplicate(true)
	s["schemaVersion"] = CURRENT_VERSION
	if not s.has("party"):
		s["party"] = []
	if not s.has("worldState"):
		s["worldState"] = {"currentNode": "town", "townVisited": false, "dungeon": _default_dungeon()}
	if not s.has("runProgress"):
		s["runProgress"] = {"gold": 0, "inventory": {}, "codex": _default_codex()}
	# Forward-fill settings onto DEFAULTS so legacy/partial saves gain any new keys
	# (additive: existing keys win, DEFAULTS fill the rest, legacy/extended keys preserved).
	s["settings"] = _forward_fill_settings(s.get("settings", {}))
	return s

# Merge a (possibly partial) loaded settings dict onto SettingsManager.DEFAULTS so the
# serialized schema always carries the full key set. Additive: caller's keys win; DEFAULTS
# fill the rest; any legacy/extended keys survive (not clobbered).
func _forward_fill_settings(loaded: Dictionary) -> Dictionary:
	var out: Dictionary = SettingsManager.DEFAULTS.duplicate(true)
	for k in loaded.keys():
		out[k] = loaded[k]
	return out

# Returns a SaveResult (object) so callers use property access (res.ok / res.error),
# which GDScript does not support on raw Dictionaries.
func load_from_string(json_str: String) -> SaveResult:
	var res := SaveResult.new()
	var parsed = JSON.parse_string(json_str)
	if typeof(parsed) != TYPE_DICTIONARY:
		res.ok = false
		res.error = "PARSE_ERROR"
		return res
	var version := int(parsed.get("schemaVersion", 0))
	if version > CURRENT_VERSION:
		res.ok = false
		res.error = "VERSION_AHEAD"
		return res
	var original_crc = parsed.get("crc", "")
	var body: Dictionary = parsed.duplicate(true)
	body.erase("crc")
	if original_crc != _crc32_hex(_canonical(body)):
		res.ok = false
		res.error = "CHECKSUM_MISMATCH"
		return res
	res.ok = true
	res.error = ""
	body["settings"] = _forward_fill_settings(body.get("settings", {}))
	res.data = body
	return res

# ---- instance state + persistence (safe-node-only writes) ----
var _memory_json := ""
var _safe_written := false

func save(state: Dictionary, safe_node: bool = false) -> bool:
	_memory_json = serialize(state)
	_safe_written = safe_node
	_persist_write(_memory_json)
	return true

func load() -> Dictionary:
	var s := _persist_read()
	if s == "":
		return {}
	var res := load_from_string(s)
	if not res.ok:
		return {}
	return res.data

func has_save() -> bool:
	return _persist_read() != ""

func was_written_at_safe_node() -> bool:
	return _safe_written

func clear_for_test() -> void:
	_memory_json = ""
	_safe_written = false
	_persist_erase()

# ---- internal ----
func _canonical(d: Dictionary) -> String:
	return JSON.stringify(d)

func _crc32_hex(s: String) -> String:
	var buf: PackedByteArray = s.to_utf8_buffer()
	var crc := 0xFFFFFFFF
	for b in buf:
		crc ^= (b & 0xFF)
		for i in range(8):
			if (crc & 1) != 0:
				crc = (crc >> 1) ^ 0xEDB88320
			else:
				crc = (crc >> 1)
	crc ^= 0xFFFFFFFF
	var v := crc & 0xFFFFFFFF
	return "%08x" % v

func _default_dungeon() -> Dictionary:
	return {"dungeonId": "sundered_ward", "floorIdx": 0, "clearedFloors": [], "foundSigils": [], "chestsOpened": [], "bossDefeated": false}

func _default_codex() -> Dictionary:
	return {"attunedSigilIds": [], "discoveredSigilIds": [], "resonance": {}}

func _persist_write(json_str: String) -> void:
	_memory_json = json_str
	if OS.has_feature("web"):
		var esc := json_str.replace("\\", "\\\\").replace("'", "\\'")
		JavaScriptBridge.eval("localStorage.setItem('%s','%s');" % [SAVE_KEY, esc])

func _persist_read() -> String:
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("localStorage.getItem('%s');" % SAVE_KEY, false)
		if typeof(v) == TYPE_STRING and v != "":
			return v
	return _memory_json

func _persist_erase() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("localStorage.removeItem('%s');" % SAVE_KEY)

# Result object for load_from_string — property access (res.ok / res.error) because
# GDScript does not support dot-access on raw Dictionaries.
class SaveResult extends RefCounted:
	var ok: bool = false
	var error: String = ""
	var data: Dictionary = {}
