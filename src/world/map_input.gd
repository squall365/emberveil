extends Node
class_name MapInput
# E9.6 — shared logical-action router for Town/Dungeon (ux-spec §3). Translates ui_* presses
# into direction / accept / cancel callbacks on the owning scene controller. The controller
# (TownController / DungeonController) implements: _map_move(dir), _map_accept(), _map_cancel().
# Touch input is always available through the on-screen nodes (accessibility: no remap blocks
# touch). Rebinding only re-maps keyboard via SettingsManager -> InputMap; it never touches
# this routing or the RNG (input is a view-layer concern, architecture §2.4).

const _DIRS := ["ui_up", "ui_down", "ui_left", "ui_right"]

func _unhandled_input(event: InputEvent) -> void:
	for d in _DIRS:
		if event.is_action_pressed(d):
			_owner()._map_move(d)
			return
	if event.is_action_pressed("ui_accept"):
		_owner()._map_accept()
	elif event.is_action_pressed("ui_cancel"):
		_owner()._map_cancel()

func _owner() -> Node:
	return get_parent()
