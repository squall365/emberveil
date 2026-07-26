extends GutTest
# STUB — targets SaveManager (Epic E4-A/B/C) + RunState schema (main-arch §4, ADR-004).
# IDs are lowercase canonical of the GDD enum (main-arch §4 convention).

const SEED_STATE = {
	"schemaVersion": 1,
	"seed": 123456789,
	"party": [
		{"slot": 0, "jobId": "vanguard", "level": 1, "xp": 0, "hp": 120, "mp": 10,
		 "equipment": {"weapon": "greatblade", "armor": null, "accessory": null}}
	],
	"runProgress": {
		"gold": 0,
		"inventory": {"herb": 2},
		"codex": {
			"attunedSigilIds": ["ember", "frost", "storm"],
			"discoveredSigilIds": ["ember", "frost", "storm"],
			"resonance": {"ember": 0, "frost": 0, "storm": 0, "stone": 0, "gale": 0, "lumen": 0, "umbra": 0}
		}
	},
	"worldState": {
		"currentNode": "town", "townVisited": true,
		"dungeon": {"dungeonId": "sundered_ward", "floorIdx": 0, "clearedFloors": [],
					"foundSigils": [], "chestsOpened": [], "bossDefeated": false}
	},
	"settings": {"masterVolume": 1.0, "sfxVolume": 1.0, "colorblindAssist": false,
				 "reducedMotion": false, "textScale": 1.0}
}

func test_serialize_deserialize_roundtrip():
	var json_str = SaveManager.serialize(SEED_STATE)
	var loaded = SaveManager.deserialize(json_str)
	assert_eq(loaded, SEED_STATE, "round-trip must be byte-identical")

func test_derived_stats_not_stored():
	# Progression/Party recompute derived stats; they must not be in the persisted blob.
	var json_str = SaveManager.serialize(SEED_STATE)
	assert_false(json_str.contains("\"maxHP\""), "derived maxHP must not be persisted")
	assert_false(json_str.contains("\"ATK\""), "derived ATK must not be persisted")

func test_migration_v1_to_current():
	var v1 = SEED_STATE.duplicate(true)
	v1["schemaVersion"] = 1
	var migrated = SaveManager.migrate(v1)
	assert_eq(migrated["schemaVersion"], SaveManager.CURRENT_VERSION, "migrated to current")
	# every required v-current field present (defaulted if absent in v1)
	assert_true(migrated.has("party"))
	assert_true(migrated.has("worldState"))

func test_checksum_tamper_refused():
	var json_str = SaveManager.serialize(SEED_STATE)
	var tampered = json_str.replace("\"gold\":0", "\"gold\":99999")
	var res = SaveManager.load_from_string(tampered)
	assert_false(res.ok, "tampered checksum must be refused")
	assert_eq(res.error, "CHECKSUM_MISMATCH")

func test_forward_version_refused():
	var future = SEED_STATE.duplicate(true)
	future["schemaVersion"] = SaveManager.CURRENT_VERSION + 1
	var res = SaveManager.load_from_string(SaveManager.serialize(future))
	assert_false(res.ok, "newer-than-supported save refused (no corrupt restore)")
	assert_eq(res.error, "VERSION_AHEAD")
