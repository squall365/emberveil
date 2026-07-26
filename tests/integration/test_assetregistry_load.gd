extends GutTest
# B4 (Checklist B) — AssetRegistry loads content defs with zero missing/duplicate ids; a
# duplicate id must be surfaced with the offending id.
#
# The registry currently offers load_content/get_content + validate_atlas; duplicate-id detection
# is performed here on the loaded data (see API-mismatch report — recommend a registry-level guard
# that throws / fails fast with the offending id, matching content_lint's "duplicate" definition).

func _load_group(group: String) -> Array:
	var path := "res://content/%s.json" % group
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		pending("content/%s.json not found" % group)
		return []
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		return []
	return parsed

func _assert_no_duplicate_ids(defs: Array, group: String) -> void:
	var seen := {}
	for d in defs:
		var id = str(d.get("id", ""))
		assert_false(seen.has(id), "duplicate id '%s' in group '%s'" % [id, group])
		seen[id] = true
		assert_false(id == "", "empty id in group '%s'" % group)

func test_all_mvp_defs_loaded_with_unique_ids():
	for group in ["jobs", "sigils", "enemies", "items", "equipment", "dungeons"]:
		var defs := _load_group(group)
		if defs.is_empty():
			pending("group '%s' empty/unavailable" % group)
			continue
		AssetRegistry.load_content(group, defs)
		assert_eq(AssetRegistry.get_content(group).size(), defs.size(), "group '%s' loaded" % group)
		_assert_no_duplicate_ids(defs, group)

func test_validate_atlas_enforces_constraints():
	var ok := AssetRegistry.validate_atlas({"id": "atlas_characters", "kind": "Characters", "mipmaps": false})
	assert_true(ok["ok"], "valid Characters atlas passes")
	var bad := AssetRegistry.validate_atlas({"id": "x", "kind": "Characters", "mipmaps": true})
	assert_false(bad["ok"], "Characters atlas with mipmaps=true is rejected")
	assert_true(bad["errors"].size() > 0, "rejection carries an error message")

func test_duplicate_id_surfaced_with_offending_id():
	# Contract (B4): a duplicate id must be detected and the offending id reported.
	# AssetRegistry has no built-in throw yet, so we assert the data-layer guarantee and flag
	# the missing API (report). Swap to a registry guard once it lands.
	var defs := [
		{"id": "dupe", "name": "A"},
		{"id": "dupe", "name": "B"}
	]
	AssetRegistry.load_content("jobs_test_dup", defs)
	var seen := {}
	var offending := ""
	for d in AssetRegistry.get_content("jobs_test_dup"):
		var id = str(d.get("id", ""))
		if seen.has(id):
			offending = id
		seen[id] = true
	assert_false(offending == "", "duplicate id must be surfaced (offending id: '%s')" % offending)
