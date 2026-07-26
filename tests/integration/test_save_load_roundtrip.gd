extends GutTest
# D1 / D2 / D3 (Checklist D) — persistence-level round-trip, migration, and integrity refusal.
# Uses the SaveManager singleton. load_from_string returns a SaveResult RefCounted exposing
# .ok / .error / .data property access (ADR-004).

const SEED_STATE := {
	"schemaVersion": 1,
	"seed": 987654321,
	"party": [
		{"slot": 0, "jobId": "vanguard", "level": 1, "xp": 0, "hp": 120, "mp": 10,
		 "equipment": {"weapon": "greatblade", "armor": null, "accessory": null}}
	],
	"runProgress": {"gold": 0, "inventory": {"herb": 2},
		"codex": {"attunedSigilIds": ["ember"], "discoveredSigilIds": ["ember"],
				  "resonance": {"ember": 0, "frost": 0, "stone": 0, "gale": 0, "lumen": 0, "umbra": 0}}},
	"worldState": {"currentNode": "town", "townVisited": true,
		"dungeon": {"dungeonId": "sundered_ward", "floorIdx": 0, "clearedFloors": [],
					"foundSigils": [], "chestsOpened": [], "bossDefeated": false}},
	"settings": {
		"masterVolume": 1.0, "sfxVolume": 1.0, "musicVolume": 1.0,
		"subtitle": true, "highContrast": false, "dyslexiaFont": false,
		"colorblindAssist": false, "reducedMotion": false, "audioVisualParity": false,
		"textScale": 1.0, "controlRemap": {}
	}
}

func before_all():
	SaveManager.clear_for_test()

func test_save_load_roundtrip_deep_equal():
	SaveManager.save(SEED_STATE, true)
	var loaded := SaveManager.load()
	assert_eq(loaded, SEED_STATE, "save() -> load() deep-equals original RunState")

func test_derived_stats_not_persisted():
	SaveManager.save(SEED_STATE, true)
	var raw := SaveManager._persist_read()  # in-memory blob (headless)
	assert_false(raw.contains("\"maxHP\""), "derived maxHP must not be persisted")
	assert_false(raw.contains("\"ATK\""), "derived ATK must not be persisted")

func test_migration_v1_to_current():
	var v1 := SEED_STATE.duplicate(true)
	v1["schemaVersion"] = 1
	var migrated := SaveManager.migrate(v1)
	assert_eq(migrated["schemaVersion"], SaveManager.CURRENT_VERSION, "migrated to current version")
	assert_true(migrated.has("party"), "party present after migrate")
	assert_true(migrated.has("worldState"), "worldState present after migrate")

func test_checksum_tamper_refused():
	var blob := SaveManager.serialize(SEED_STATE)
	var tampered := blob.replace("\"gold\":0", "\"gold\":99999")
	var res := SaveManager.load_from_string(tampered)
	assert_false(res.ok, "tampered checksum refused")
	assert_eq(res.error, "CHECKSUM_MISMATCH")

func test_forward_version_refused():
	var future := SEED_STATE.duplicate(true)
	future["schemaVersion"] = SaveManager.CURRENT_VERSION + 1
	var res := SaveManager.load_from_string(SaveManager.serialize(future))
	assert_false(res.ok, "newer-than-supported save refused")
	assert_eq(res.error, "VERSION_AHEAD")

func test_forward_fill_settings_adds_default_keys():
	# G3 / OQ4 / R1: a partial/legacy settings blob gains every DEFAULTS key
	# (e.g. controlRemap, audioVisualParity) through _forward_fill_settings, while
	# any caller-supplied override wins.
	var partial := {"textScale": 1.25}
	var filled := SaveManager._forward_fill_settings(partial)
	assert_true(filled.has("controlRemap"), "forward-fill adds extended default key controlRemap")
	assert_true(filled.has("audioVisualParity"), "forward-fill adds extended default key audioVisualParity")
	assert_eq(filled["textScale"], 1.25, "caller override wins over default")
	assert_eq(filled["masterVolume"], 1.0, "missing key filled from DEFAULTS")

# R1 legacy save: partial settings + an unknown/extended key. _forward_fill_settings must
# (a) backfill the full DEFAULTS schema and (b) preserve the legacy extended key (additive).
func test_legacy_save_settings_forward_filled():
	var legacy := SEED_STATE.duplicate(true)
	legacy["settings"] = {"textScale": 1.0, "legacyOldKey": "keep_me"}
	var res := SaveManager.load_from_string(SaveManager.serialize(legacy))
	assert_true(res.ok, "legacy save loads")
	var loaded_settings: Dictionary = res.data["settings"]
	for k in SettingsManager.DEFAULTS.keys():
		assert_true(loaded_settings.has(k), "forward-filled DEFAULTS key present: %s" % k)
	assert_eq(loaded_settings.get("textScale"), 1.0, "override textScale preserved")
	assert_eq(loaded_settings.get("legacyOldKey"), "keep_me", "legacy extended setting preserved")
