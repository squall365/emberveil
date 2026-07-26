extends Node
# class_name ProgressionManager
# XP / level / equipment / resonance (E2-K). Sprint 1: structure + pure add_xp/level calc.
# Sprint 2 (E9.4/GAP-8): apply_battle_xp splits a battle's total XP across the party and
# writes levels back into the run-state party (xp_for_level = 100*level per GAP-10).

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

# GAP-8: distribute a battle's total XP evenly across the (living) party members and level
# them up. Mutates the passed party array in place (caller persists it via SceneManager).
func apply_battle_xp(total_xp: int, party: Array) -> void:
	if party.is_empty() or total_xp <= 0:
		return
	var n := party.size()
	var base := int(total_xp / n)
	var rem := int(total_xp % n)
	for i in n:
		var share := base + (1 if i < rem else 0)
		add_xp(party[i], share)

func equip(member: Dictionary, slot: String, item_id: String) -> void:
	if not member.has("equipment"):
		member["equipment"] = {}
	member["equipment"][slot] = item_id
