extends Node
class_name AudioBus
# Placeholder audio events (ux-spec §6.1). No audio assets in Sprint 1; play() is a no-op
# contract so call sites compile. Event names are the stable interface for Sprint 2.

const EVENTS := [
	"sfx.ui_confirm", "sfx.ui_cancel", "sfx.ui_nav",
	"sfx.combat_attack", "sfx.combat_skill", "sfx.combat_elemental",
	"sfx.combat_hit", "sfx.combat_defeat", "sfx.victory",
	"music.town", "music.dungeon", "music.boss"
]

var _last_event: String = ""

func play(event_name: String) -> void:
	if not EVENTS.has(event_name):
		return
	_last_event = event_name

func last_event() -> String:
	return _last_event
