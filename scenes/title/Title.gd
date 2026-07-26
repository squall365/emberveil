extends Control
# EMBERVEIL Title — builds UI procedurally with anchor presets so layout
# works regardless of viewport size.

func _ready() -> void:
	# Backdrop.
	var bg := ColorRect.new()
	bg.color = Color("#2B1B2E")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Center column.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 32)
	center.add_child(col)

	# Title label.
	var logo := Label.new()
	logo.text = "EMBERVEIL"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 36)
	logo.add_theme_color_override("font_color", Color("#F2D9A0"))
	col.add_child(logo)

	# Start button.
	var btn := Button.new()
	btn.text = "Start"
	btn.custom_minimum_size = Vector2(220, 48)
	col.add_child(btn)
	btn.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	SceneManager.new_run_confirmed()
	SceneManager.go_to("Town")
