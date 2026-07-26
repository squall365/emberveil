extends Node
# World scene — resident root. On _ready, automatically mounts Town as the active
# world child (architecture §2.2). RunState is never reloaded here (decision 2.6,
# GAP-1, anti-save-scum).

func _ready() -> void:
	# State was already set by Title.gd (SceneManager.new_run_confirmed before scene swap).
	WorldDirector.enter_town()