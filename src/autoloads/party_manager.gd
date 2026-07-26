extends Node
class_name PartyManager
# 4 slots, max 1 per job. Derived stats recomputed on demand and NEVER persisted
# (save test asserts maxHP/ATK absent from the blob). Sprint 2 (E9.4/GAP-9): assemble
# battle combatants and write battle outcomes back into the run-state party.

const MAX_SLOTS := 4

# Fixed 4-job default party (GDD decision 2.7 / GAP-12). Affinity + Stone aptitude feed
# BattleResolver (affinity check) and the boss Stone-unlock check. PLACEHOLDER — E8 spike
# may retune the numbers.
const DEFAULT_JOBS := ["vanguard", "channeler", "skirmisher", "warden"]
const JOB_AFFINITY := {"vanguard": "none", "channeler": "ember", "warden": "stone", "skirmisher": "storm"}
const JOB_STONE_APTITUDE := {"vanguard": 0.3, "warden": 0.5, "channeler": 1.0, "skirmisher": 0.4}

var _members: Array = []

func new_run_defaults() -> void:
	_members = []
	for jid in DEFAULT_JOBS:
		_members.append({"jobId": jid, "level": 1, "xp": 0, "hp": -1, "mp": -1})

func load_party(party: Array) -> void:
	_members = party.duplicate(true)

# Rest (Inn) / Shrine full heal: reset hp/mp to -1 ("full") so build_party_combatants
# restores max. Persisted on the next Town safe-node save.
func full_heal() -> void:
	for m in _members:
		m["hp"] = -1
		m["mp"] = -1

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

# GAP-9: assemble the 4 ally combatants for a battle from the current party (or the fixed
# 4-job fallback if the run party is somehow empty — GAP-12 safety net). Current hp/mp come
# from the member dict; -1 means "full".
func build_party_combatants() -> Array:
	var members := _members.duplicate(true)
	if members.is_empty():
		for jid in DEFAULT_JOBS:
			members.append({"jobId": jid, "level": 1, "xp": 0})
	var out: Array = []
	for m in members:
		var jid: String = str(m.get("jobId", "vanguard"))
		var s := derive_stats(m)
		var cur_hp: int = int(m.get("hp", -1))
		var cur_mp: int = int(m.get("mp", -1))
		out.append({
			"id": "ally_" + jid,
			"side": "ally",
			"name": jid,
			"jobId": jid,
			"level": s["level"],
			"HP": s["maxHP"] if cur_hp < 0 else cur_hp,
			"maxHP": s["maxHP"],
			"MP": s["maxMP"] if cur_mp < 0 else cur_mp,
			"maxMP": s["maxMP"],
			"ATK": s["ATK"], "DEF": s["DEF"], "MAG": s["MAG"], "RES": s["RES"], "SPD": s["SPD"],
			"affinity": JOB_AFFINITY.get(jid, "none"),
			"aptitude": {"stone": JOB_STONE_APTITUDE.get(jid, 0.0)},
			"xpValue": 0
		})
	return out

# Update in-memory members from post-battle ally combatants. Only hp/mp are taken from the
# combatants (level/xp come from ProgressionManager.apply_battle_xp on the run-state party,
# which runs first). Keyed by combatant id "ally_<jobId>".
func record_ally_outcome(ally_combatants: Array) -> void:
	for c in ally_combatants:
		if str(c.get("side", "")) != "ally":
			continue
		var jid: String = str(c.get("jobId", ""))
		for m in _members:
			if str(m.get("jobId", "")) == jid:
				m["hp"] = int(c.get("HP", m.get("hp", -1)))
				m["mp"] = int(c.get("MP", m.get("mp", -1)))

# GAP-9: write in-memory member stats (hp/mp/level/xp) back into the run-state party and
# return the updated run_state. Keeps the authoritative RunState in sync after a battle.
func sync_to_run_state(run_state: Dictionary) -> Dictionary:
	var party: Array = run_state.get("party", []).duplicate(true)
	var by_job: Dictionary = {}
	for i in party.size():
		by_job[str(party[i].get("jobId", ""))] = i
	for m in _members:
		var jid: String = str(m.get("jobId", ""))
		if by_job.has(jid):
			var idx: int = by_job[jid]
			party[idx]["level"] = int(m.get("level", party[idx].get("level", 1)))
			party[idx]["xp"] = int(m.get("xp", party[idx].get("xp", 0)))
			party[idx]["hp"] = int(m.get("hp", party[idx].get("hp", -1)))
			party[idx]["mp"] = int(m.get("mp", party[idx].get("mp", -1)))
	run_state["party"] = party
	return run_state
