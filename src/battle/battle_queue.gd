extends RefCounted
class_name BattleQueue
# Shared, deterministic turn queue for combat (ADR-002 / E9.4). Initiative order is SPD
# descending; ties broken by slot ascending (deterministic — no RNG needed for ordering).
# Dead combatants (HP<=0) are skipped. One instance per battle, owned by CombatController.

var _order: Array = []      # combatant ids in initiative order for the current round
var _acted: Array = []      # ids that have acted this round
var _combatants: Array = [] # reference list for living checks

func setup(combatants: Array) -> void:
	_combatants = combatants
	_rebuild()
	_acted = []

# Static helper: returns the initiative-ordered list of living combatant ids. Used to fill
# BattleState["queue"] (GDD §3.5) and as the live ordering source.
static func initiative_order(combatants: Array) -> Array:
	var living: Array = combatants.filter(func(c): return int(c.get("HP", 0)) > 0)
	living.sort_custom(_cmp)
	return living.map(func(c): return str(c.get("id", "")))

func _rebuild() -> void:
	_order = initiative_order(_combatants)

func new_round() -> void:
	_acted = []
	_rebuild()

# Next living actor that hasn't acted this round, in initiative order. "" if round done.
func next_actor() -> String:
	for id in _order:
		if _acted.has(id):
			continue
		if _is_alive(id):
			return id
	return ""

func mark_acted(id: String) -> void:
	if not _acted.has(id):
		_acted.append(id)

func _is_alive(id: String) -> bool:
	for c in _combatants:
		if str(c.get("id", "")) == id:
			return int(c.get("HP", 0)) > 0
	return false

# Sort comparator: a precedes b when a has higher SPD, or equal SPD and lower slot.
static func _cmp(a: Dictionary, b: Dictionary) -> bool:
	var sa := int(a.get("SPD", 0))
	var sb := int(b.get("SPD", 0))
	if sa != sb:
		return sa > sb
	return int(a.get("slot", 0)) < int(b.get("slot", 0))
