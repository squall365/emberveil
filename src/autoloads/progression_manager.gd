extends Node
class_name ProgressionManager
# XP / level / equipment / resonance (E2-K). Sprint 1: structure + pure add_xp/level calc.

const MAX_LEVEL := 50

func xp_for_level(level: int) -> int:
	return 100 * level

func add_xp(member: Dictionary, amount: int) -> Dictionary:
	var xp: int = int(member.get("xp", 0)) + amount
	var level: int = int(member.get("level", 1))
	while level < MAX_LEVEL and xp >= xp_for_level(level):
		xp -= xp_for_level(level)
		level += 1
	member["xp"] = xp
	member["level"] = level
	return member

func equip(member: Dictionary, slot: String, item_id: String) -> void:
	if not member.has("equipment"):
		member["equipment"] = {}
	member["equipment"][slot] = item_id
