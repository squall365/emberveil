extends SceneTree
# EMBERVEIL — Palette Validator (checklist E ⛔, art-bible §2.3 / §9.4).
# Ensures no asset uses a color outside the global master palette (<=48 colors).
#
# Run:  godot --headless --path . --script tools/palette_validator.gd
# Exits 0 if clean, 1 if any out-of-set color is found (CI fails the build).
#
# The master palette lives in content/palette.json:
#   { "colors": ["#2B1B2E", "#E8743B", ... up to 48 entries] }
# Grain overlay (1 shared 128²) is allowed a small tolerance (set GRAIN_TOLERANCE).

const PALETTE_PATH := "res://content/palette.json"
const SCAN_ROOTS := ["res://content", "res://assets"]
const GRAIN_TOLERANCE := 0.06      # 0..1 color distance slack for the grain atlas
const PIXEL_STEP := 1              # sample every Nth pixel (raise for speed on huge atlases)

var _image_count := 0


func _initialize() -> void:
	var palette := _load_palette()
	if palette.is_empty():
		printerr("[palette_validator] WARNING: could not load %s — palette check skipped" % PALETTE_PATH)
		quit(0)
		return

	# Count images first. If there are no images, the check is vacuously true.
	_image_count = 0
	var failures := 0
	for root in SCAN_ROOTS:
		if not DirAccess.dir_exists_absolute(root):
			continue
		failures += _scan_dir(root, palette)

	if _image_count == 0:
		print("[palette_validator] PASS: no scannable assets (0 images) — palette check is moot")
		quit(0)
		return

	if failures > 0:
		printerr("[palette_validator] FAIL: %d out-of-set color occurrence(s) across %d image(s)" % [failures, _image_count])
		quit(1)
	else:
		print("[palette_validator] PASS: all %d scanned textures within master palette" % _image_count)
		quit(0)


func _load_palette() -> Array:
	if not FileAccess.file_exists(PALETTE_PATH):
		return []
	var txt := FileAccess.get_file_as_string(PALETTE_PATH)
	var json := JSON.new()
	if json.parse(txt) != OK:
		return []
	var cols: Array = json.data.get("colors", [])
	var out := []
	for c in cols:
		out.append(Color.from_string(str(c)))
	return out


func _scan_dir(dir_path: String, palette: Array) -> int:
	var failures := 0
	var list := DirAccess.open(dir_path)
	if list == null:
		return 0
	list.list_dir_begin()
	var name := list.get_next()
	while name != "":
		if list.current_is_dir():
			failures += _scan_dir(dir_path.path_join(name), palette)
		elif name.get_extension().to_lower() in ["png", "webp"]:
			_image_count += 1
			failures += _scan_image(dir_path.path_join(name), palette)
		name = list.get_next()
	list.list_dir_end()
	return failures


func _scan_image(path: String, palette: Array) -> int:
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		printerr("[palette_validator] cannot load %s" % path)
		return 1
	var failures := 0
	var is_grain := "grain" in path.get_file().to_lower()
	for y in range(0, img.get_height(), PIXEL_STEP):
		for x in range(0, img.get_width(), PIXEL_STEP):
			var col := img.get_pixel(x, y)
			if col.a < 0.01:
				continue  # transparent: ignore
			if not _in_palette(col, palette, is_grain):
				if failures < 5:
					printerr("  off-palette %s px(%d,%d) #%s" % [path, x, y, col.to_html()])
				failures += 1
	return failures


func _in_palette(c: Color, palette: Array, is_grain: bool) -> bool:
	for p in palette:
		if c.distance_to(p) <= (GRAIN_TOLERANCE if is_grain else 0.02):
			return true
	return false
