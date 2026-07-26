extends Node
# Boot scene — hands off to Title. SceneManager tracks the logical node, then we
# physically swap the scene tree so Title.gd can present the UI.

func _ready() -> void:
	SceneManager.go_to("Title")
	# Defer the scene swap until after _ready finishes; Godot 4.7 complains the
	# parent is busy adding/removing children otherwise.
	get_tree().call_deferred("change_scene_to_file", "res://scenes/title/Title.tscn")
