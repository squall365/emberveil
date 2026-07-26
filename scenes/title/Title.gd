extends Control
# Title scene — minimal stub. Sprint 1 placeholder: starts a new run and hops to Town.
# Sprint 2 polish: real logo art, animated title, save-list, settings entry, IP guard.

func _ready() -> void:
	$StartButton.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	SceneManager.new_run_confirmed()
	SceneManager.go_to("Town")
