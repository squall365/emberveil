extends Control
# EMBERVEIL Title — absolute positioning, no containers needed.

func _ready() -> void:
	var vs := get_viewport().get_visible_rect().size
	var cx := vs.x / 2.0

	# Backdrop
	var bg := ColorRect.new()
	bg.set_position(Vector2.ZERO)
	bg.set_size(vs)
	bg.color = Color(0.169, 0.106, 0.180, 1.0)   # #2B1B2E Deep Plum
	add_child(bg)

	# Title logo (image fallback to text)
	if FileAccess.file_exists("assets/ui/emberveil_logo.png"):
		var img_logo := TextureRect.new()
		img_logo.texture = load("res://assets/ui/emberveil_logo.png")
		img_logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		img_logo.position = Vector2(cx - 200, vs.y * 0.05)
		img_logo.size = Vector2(400, 100)
		add_child(img_logo)
	else:
		var logo := Label.new()
		logo.text = "EMBERVEIL"
		logo.position = Vector2(0, cx * 0.1)
		logo.size = Vector2(vs.x, 60)
		logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		logo.add_theme_font_size_override("font_size", 36)
		logo.add_theme_color_override("font_color", Color(0.949, 0.851, 0.627, 1.0))
		add_child(logo)

	# Start button
	var btn := Button.new()
	btn.text = "Start"
	btn.position = Vector2(cx - 110, vs.y * 0.55)
	btn.size = Vector2(220, 48)
	btn.pressed.connect(_on_start_pressed)
	add_child(btn)


func _on_start_pressed() -> void:
	SceneManager.new_run_confirmed()
	# Defer the scene swap; Godot 4.7 complains about busy parent otherwise.
	get_tree().call_deferred("change_scene_to_file", "res://scenes/world/World.tscn")
