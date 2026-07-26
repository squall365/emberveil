extends Node
class_name PartyManager
# 4 slots, max 1 per job. Derived stats are recomputed on demand and NEVER persisted
# (save test asserts maxHP/ATK absent from the blob). Sprint 1: structure + derive_stats.

const MAX_SLOTS := 4

var _members: Array = []

func add_member(def: Dictionary) -> bool:
	if _members.size() >= MAX_SLOTS:
		return false
	for m in _members:
		if m.get("jobId") == def.get("jobId"):
			return false  # max 1 per job
	_members.append(def.duplicate(true))
	return true

func remove_member(slot: int) -> void:
	if slot >= 0 and slot < _members.size():
		_members.remove_at(slot)

func get_member(slot: int) -> Dictionary:
	if slot >= 0 and slot < _members.size():
		return _members[slot]
	return {}

func all_members() -> Array:
	return _members.duplicate(true)

func derive_stats(member: Dictionary) -> Dictionary:
	# Pure derivation from job base + level. PLACEHOLDER formula (E8 balance spike tunes it).
	var level: int = int(member.get("level", 1))
	var base_hp := 100 + level * 10
	var base_atk := 10 + level * 2
	var base_def := 8 + level * 2
	var base_mag := 6 + level
	return {
		"jobId": member.get("jobId", "vanguard"),
		"level": level,
		"maxHP": base_hp,
		"maxMP": 10,
		"ATK": base_atk,
		"DEF": base_def,
		"MAG": base_mag,
		"RES": base_def,
		"SPD": 8
	}
