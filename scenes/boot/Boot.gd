extends Node
# Boot scene — hands off to Title. SceneManager tracks the logical node, then we
# physically swap the scene tree so Title.gd can present the UI.

func _ready() -> void:
	SceneManager.go_to("Title")
	get_tree().change_scene_to_file("res://scenes/title/Title.tscn")
