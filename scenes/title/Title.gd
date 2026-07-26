extends Control
# EMBERVEIL Title — builds UI procedurally (avoids tspn format issues).
# Sprint 1 placeholder → Sprint 2+: swap to real art logo.

func _ready() -> void:
	# Dark background — size will be set after the viewport is known.
	# Use a ColorRect with ember dark theme.
	var bg := ColorRect.new()
	bg.color = Color("#2B1B2E")
	bg.set_anchor(SIDE_LEFT, 0.0)
	bg.set_anchor(SIDE_RIGHT, 1.0)
	bg.set_anchor(SIDE_TOP, 0.0)
	bg.set_anchor(SIDE_BOTTOM, 1.0)
	add_child(bg)

	# Center the content vertically.
	var center := CenterContainer.new()
	center.set_anchor(SIDE_LEFT, 0.0)
	center.set_anchor(SIDE_RIGHT, 1.0)
	center.set_anchor(SIDE_TOP, 0.0)
	center.set_anchor(SIDE_BOTTOM, 1.0)
	add_child(center)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 32)
	center.add_child(col)

	var logo := Label.new()
	logo.text = "EMBERVEIL"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 36)
	logo.add_theme_color_override("font_color", Color("#F2D9A0"))
	col.add_child(logo)

	var btn := Button.new()
	btn.text = "Start"
	btn.custom_minimum_size = Vector2(220, 48)
	btn.pressed.connect(_on_start_pressed)
	col.add_child(btn)


func _on_start_pressed() -> void:
	SceneManager.new_run_confirmed()
	SceneManager.go_to("Town")
