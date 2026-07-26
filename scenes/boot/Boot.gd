extends Node
# Boot scene (E1). Minimal: hands off to Title via SceneManager. The real boot splash /
# asset preload lands in Sprint 2. No global RNG, no blocking work on the main thread.

func _ready() -> void:
	SceneManager.go_to("Title")
