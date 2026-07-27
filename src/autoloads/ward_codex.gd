extends Node
class_name WardCodex
# Shared sigil Set + resonance (GDD Ward Codex). Holds attunement state for the active run.
# Sprint 1: structure + pure helpers; persistence flows through RunState.codex.

var _attuned: Array = []
var _discovered: Array = []
var _resonance: Dictionary = {}

func attune(sigil_id: String) -> void:
	if not _attuned.has(sigil_id):
		_attuned.append(sigil_id)
	if not _discovered.has(sigil_id):
		_discovered.append(sigil_id)

func discover(sigil_id: String) -> void:
	if not _discovered.has(sigil_id):
		_discovered.append(sigil_id)

func set_resonance(element: String, value: int) -> void:
	_resonance[element] = value

func get_resonance(element: String) -> int:
	return int(_resonance.get(element, 0))

func snapshot() -> Dictionary:
	return {
		"attunedSigilIds": _attuned.duplicate(),
		"discoveredSigilIds": _discovered.duplicate(),
		"resonance": _resonance.duplicate()
	}

func restore(snap: Dictionary) -> void:
	_attuned = snap.get("attunedSigilIds", []).duplicate()
	_discovered = snap.get("discoveredSigilIds", []).duplicate()
	_resonance = snap.get("resonance", {}).duplicate()
