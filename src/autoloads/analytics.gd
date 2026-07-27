extends Node
class_name Analytics
# Analytics is OFF (pure-offline decision). track() is a no-op placeholder so call sites
# compile and the data layer stays intact for a future opt-in build. No telemetry emitted.

func track(event: String, data: Dictionary = {}) -> void:
	# No-op placeholder — pure-offline build. Parameters intentionally unused.
	pass

func is_enabled() -> bool:
	return false
