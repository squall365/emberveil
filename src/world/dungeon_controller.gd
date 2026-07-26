extends Node
class_name DungeonController
# E9.3 / E9.4 / E9.5 — The Sundered Ward (4 floors, node-stepping). Owns the per-floor room
# track and the room cursor. Room cursor + cleared-room tracking are SESSION state (not
# persisted) to avoid dirty-continue room-skips (GAP-2). Launches CombatRoom/BossRoom battles
# as a Battle.tscn overlay (never serialized). Writes battle outcomes back through
# SceneManager + PartyManager + ProgressionManager, persisting ONLY at safe nodes (decision 2.6).

const DUNGEON_PATH := "res://content/dungeons.json"
const ENCOUNTERS_PATH := "res://content/encounters.json"
const ENEMIES_PATH := "res://content/enemies.json"
const DUNGEON_ID := "sundered_ward"

var _dungeon_def: Dictionary = {}
var _floor_idx: int = 0
var _rooms: Array = []                  # rooms of the current floor
var _room_cursor: int = 0              # session cursor within the floor
var _session_cleared: Array = []       # GAP-2: session-only cleared room ids
var _in_puzzle: bool = false
var _puzzle_order: Array = []
var _puzzle_progress: int = 0
var _puzzle_solved: bool = false
var _stone_focus: int = 0
var _current_room_id: String = ""
var _current_room_idx: int = 0
var _current_encounter_id: String = ""
var _current_is_boss: bool = false

func _ready() -> void:
	_refresh_ui()

func setup(params: Dictionary = {}) -> void:
	_load_def()
	_floor_idx = int(params.get("floorIdx", 0))
	_enter_floor(_floor_idx)

func _load_def() -> void:
	var data = _load_json(DUNGEON_PATH)
	if data == null:
		return
	var arr: Array = data if typeof(data) == TYPE_ARRAY else []
	for d in arr:
		if str(d.get("id", "")) == DUNGEON_ID:
			_dungeon_def = d
			return

func _enter_floor(floor_idx: int) -> void:
	_floor_idx = floor_idx
	_session_cleared = []
	_in_puzzle = false
	_puzzle_progress = 0
	_puzzle_solved = false
	_stone_focus = 0
	_room_cursor = 0
	var floor_def: Dictionary = _floor_by_idx(floor_idx)
	_rooms = floor_def.get("rooms", []) if not floor_def.is_empty() else []
	_room_cursor = _frontier()
	_refresh_ui()

func _floor_by_idx(floor_idx: int) -> Dictionary:
	for f in _dungeon_def.get("floors", []):
		if int(f.get("idx", -1)) == floor_idx:
			return f
	return {}

# First uncleared room index; _rooms.size() if all cleared.
func _frontier() -> int:
	for i in _rooms.size():
		if not _session_cleared.has(_rooms[i].get("id", "")):
			return i
	return _rooms.size()

# ---- cursor / navigation (GAP-2: cannot skip an uncleared room) ----
func _move_cursor(delta: int) -> void:
	var target := clampi(_room_cursor + delta, 0, _rooms.size() - 1)
	if target > _frontier():
		return  # would skip an uncleared room -> blocked
	_room_cursor = target
	_refresh_ui()

func _current_room() -> Dictionary:
	if _room_cursor < 0 or _room_cursor >= _rooms.size():
		return {}
	return _rooms[_room_cursor]

# ---- room entry (fixed trigger; no random encounters, decision 2.3) ----
func _enter_current_room() -> void:
	var room: Dictionary = _current_room()
	if room.is_empty():
		return
	_current_room_id = str(room.get("id", ""))
	_current_room_idx = _room_cursor
	if _session_cleared.has(_current_room_id):
		return  # already done this session; door open, no re-trigger
	match str(room.get("type", "")):
		"combat":
			_start_battle(str(room.get("encounterId", "")), false)
		"boss":
			_start_battle(str(room.get("encounterId", "")), true)
		"puzzle":
			_enter_puzzle(room)
		"reward":
			_open_reward(room)

# ---- battle launch (E9.4) ----
func _start_battle(encounter_id: String, is_boss: bool) -> void:
	_current_encounter_id = encounter_id
	_current_is_boss = is_boss
	var party: Array = PartyManager.build_party_combatants()
	var enemies: Array = _build_enemy_combatants(encounter_id)
	var combatants: Array = party + enemies
	for i in combatants.size():
		combatants[i]["slot"] = i
	var rng := RNGService.new()
	rng.seed(_battle_seed(_floor_idx, _current_room_idx, is_boss))
	var state := {
		"combatants": combatants,
		"queue": BattleQueue.initiative_order(combatants),
		"turnPointer": 0,
		"phase": BattleFSM.Phase.PreBattle,
		"log": [],
		"isBoss": is_boss
	}
	var battle = load("res://scenes/battle/Battle.tscn").instantiate()
	battle.setup(state, rng, self)
	get_tree().get_root().add_child(battle)   # overlay; never serialized

# GAP-11 / ADR-002: deterministic, DERIVED (non-persisted) battle nonce. Same (seed, floor,
# room, boss) => same battle. No counter is stored; no save is mutated.
func _battle_seed(floor_idx: int, room_idx: int, is_boss: bool) -> int:
	var run_seed: int = int(SceneManager.get_run_state().get("seed", 1))
	return (run_seed + floor_idx * 100 + room_idx * 10 + (1 if is_boss else 0)) & 0x7FFFFFFF

func _build_enemy_combatants(encounter_id: String) -> Array:
	var enc: Dictionary = _find_encounter(encounter_id)
	if enc.is_empty():
		return []
	var out: Array = []
	for eid in enc.get("enemyIds", []):
		var e: Dictionary = _find_enemy(str(eid))
		if e.is_empty():
			continue
		out.append({
			"id": "enemy_" + str(eid),
			"side": "enemy",
			"name": str(e.get("name", eid)),
			"level": 1,
			"HP": int(e.get("HP", 1)),
			"maxHP": int(e.get("HP", 1)),
			"MP": int(e.get("MP", 0)),
			"maxMP": int(e.get("MP", 0)),
			"ATK": int(e.get("ATK", 0)),
			"DEF": int(e.get("DEF", 0)),
			"MAG": int(e.get("MAG", 0)),
			"RES": int(e.get("RES", 0)),
			"SPD": int(e.get("SPD", 0)),
			"affinity": str(e.get("affinity", "none")),
			"aptitude": {},
			"aiProfile": "default",
			"xpValue": int(e.get("xpValue", 0))
		})
	return out

func _find_encounter(encounter_id: String) -> Dictionary:
	var data = _load_json(ENCOUNTERS_PATH)
	if data == null:
		return {}
	for e in data:
		if str(e.get("id", "")) == encounter_id:
			return e
	return {}

func _find_enemy(enemy_id: String) -> Dictionary:
	var data = _load_json(ENEMIES_PATH)
	if data == null:
		return {}
	for e in data:
		if str(e.get("id", "")) == enemy_id:
			return e
	return {}

# ---- battle resolution callback (E9.4 / E9.5) ----
func _on_battle_resolved(result: Dictionary) -> void:
	if str(result.get("outcome", "")) == "lose":
		_reload_last_safe_save()
		return
	# WIN: write ally hp/mp/level/xp back into PartyManager (carry across rooms, decision 2.5).
	var state: Dictionary = result.get("state", {})
	var allies: Array = state.get("combatants", []).filter(
		func(c): return str(c.get("side", "")) == "ally")
	PartyManager.record_ally_outcome(allies)
	# Apply the encounter XP split across the run-state party (final writer => survives sync).
	var enc: Dictionary = _find_encounter(_current_encounter_id)
	var enemy_xp: int = int(enc.get("xpValue", 0)) if not enc.is_empty() else 0
	var drops: Dictionary = enc.get("drops", {}) if not enc.is_empty() else {}
	var rs: Dictionary = SceneManager.get_run_state()
	PartyManager.sync_to_run_state(rs)
	ProgressionManager.apply_battle_xp(enemy_xp, rs.get("party", []))
	rs["runProgress"]["gold"] = int(rs.get("runProgress", {}).get("gold", 0)) + int(drops.get("gold", 0))
	SceneManager.commit_run_state(rs)
	_mark_room_cleared(_current_room_id)
	EventBus.progression_event.emit({"xp": enemy_xp})
	if _current_is_boss:
		WardCodex.attune("stone")   # unlock Stone element
		EventBus.codex_updated.emit({"sigil": "stone", "action": "attune"})
		var rs2: Dictionary = SceneManager.get_run_state()
		rs2["worldState"]["dungeon"]["bossDefeated"] = true
		SceneManager.commit_run_state(rs2)
		SaveManager.save(SceneManager.get_run_state(), true)   # sigil-attune safe node
	if _floor_fully_cleared():
		WorldDirector.clear_floor(_floor_idx)   # safe node save + clearedFloors
		_advance_floor_or_return()

func _floor_fully_cleared() -> bool:
	for r in _rooms:
		if not _session_cleared.has(str(r.get("id", ""))):
			return false
	return true

func _advance_floor_or_return() -> void:
	if _floor_idx >= 3:
		WorldDirector.return_to_town()   # F4 boss cleared -> back to Town (decision 2.6)
	else:
		WorldDirector.enter_dungeon(_floor_idx + 1)   # next floor; swaps Dungeon (fresh session)

# ---- reward (first-clear only; dedup via worldState.chestsOpened) ----
func _open_reward(room: Dictionary) -> void:
	var rs: Dictionary = SceneManager.get_run_state()
	var chests: Array = rs.get("worldState", {}).get("dungeon", {}).get("chestsOpened", [])
	if chests.has(str(room.get("id", ""))):
		return  # already opened (persisted dedup)
	var reward: Dictionary = room.get("reward", {})
	rs["runProgress"]["gold"] = int(rs.get("runProgress", {}).get("gold", 0)) + int(reward.get("gold", 0))
	var inv: Dictionary = rs.get("runProgress", {}).get("inventory", {})
	for it in reward.get("items", []):
		var iid: String = str(it.get("itemId", ""))
		var qty: int = int(it.get("qty", 1))
		inv[iid] = int(inv.get(iid, 0)) + qty
	rs["runProgress"]["inventory"] = inv
	rs["worldState"]["dungeon"]["chestsOpened"].append(str(room.get("id", "")))
	SceneManager.commit_run_state(rs)
	_mark_room_cleared(str(room.get("id", "")))

# ---- puzzle (decision 2.4: wrong order => full reset; leaving room resets) ----
func _enter_puzzle(room: Dictionary) -> void:
	if _session_cleared.has(str(room.get("id", ""))):
		return  # already solved this session; door open
	_in_puzzle = true
	_puzzle_order = room.get("puzzleOrder", [])
	_puzzle_progress = 0
	_puzzle_solved = false
	_stone_focus = 0
	_refresh_ui()

func _on_stone_tapped(element: String) -> void:
	if not _in_puzzle or _puzzle_solved:
		return
	if _puzzle_progress >= _puzzle_order.size():
		return
	if element == str(_puzzle_order[_puzzle_progress]):
		_puzzle_progress += 1
		if _puzzle_progress >= _puzzle_order.size():
			_puzzle_solved = true
			_in_puzzle = false
			_mark_room_cleared(_current_room_id)
		else:
			# Move the focus ring to the next expected stone so the hint + ring stay aligned.
			_stone_focus = mini(_puzzle_progress, _puzzle_order.size() - 1)
			_refresh_ui()
	else:
		_reset_puzzle()   # decision 2.4: full group reset, no soft-lock
		EventBus.progression_event.emit({"puzzle": "disrupted"})

func _reset_puzzle() -> void:
	_puzzle_progress = 0
	_stone_focus = 0
	_refresh_ui()

func _exit_puzzle() -> void:
	_in_puzzle = false
	_reset_puzzle()

# ---- session marking (GAP-2: not persisted) ----
func _mark_room_cleared(room_id: String) -> void:
	if not _session_cleared.has(room_id):
		_session_cleared.append(room_id)
	_room_cursor = _frontier()
	_refresh_ui()

# ---- wipe -> last safe save (E9.5, decision 2.6) ----
func _reload_last_safe_save() -> void:
	var rs: Dictionary = SaveManager.load()
	if rs.is_empty():
		rs = SceneManager.get_run_state()
	PartyManager.load_party(rs.get("party", []))
	WardCodex.restore(rs.get("runProgress", {}).get("codex", {}))
	WorldDirector.return_to_town()   # resume always at Town

# ---- backtrack to Town (preserves dungeon progress) ----
func _backtrack_to_town() -> void:
	WorldDirector.return_to_town()

# ---- map_input contract (ux-spec §3) ----
func _map_move(dir: String) -> void:
	if _in_puzzle:
		if dir in ["ui_up", "ui_left"]:
			_stone_focus = maxi(0, _stone_focus - 1)
		elif dir in ["ui_down", "ui_right"]:
			_stone_focus = mini(_puzzle_order.size() - 1, _stone_focus + 1)
		_refresh_ui()
		return
	if dir == "ui_left":
		_move_cursor(-1)
	elif dir == "ui_right":
		_move_cursor(1)

func _map_accept() -> void:
	if _in_puzzle:
		if _puzzle_progress < _puzzle_order.size():
			_on_stone_tapped(str(_puzzle_order[_stone_focus]))
		return
	_enter_current_room()

func _map_cancel() -> void:
	if _in_puzzle:
		_exit_puzzle()
		return
	_backtrack_to_town()

# ---- UI (MVP: room track rendered as buttons; focus ring = parchment glow) ----
func _refresh_ui() -> void:
	var info = get_node_or_null("Info")
	if info != null:
		info.text = "The Sundered Ward — Floor %d" % (_floor_idx + 1)
	var rooms_node = get_node_or_null("Rooms")
	if rooms_node == null:
		return
	for child in rooms_node.get_children():
		child.queue_free()
	for i in _rooms.size():
		var r: Dictionary = _rooms[i]
		var btn := Button.new()
		var rid: String = str(r.get("id", ""))
		var cleared: bool = _session_cleared.has(rid)
		var label: String = str(r.get("type", "")).capitalize()
		if _in_puzzle and i == _room_cursor:
			label = "Tap: %s" % str(_puzzle_order[_stone_focus]) if _stone_focus < _puzzle_order.size() else "Puzzle"
		btn.text = label + (" [x]" if cleared else "")
		btn.custom_minimum_size = Vector2(220, 44)   # >= 44x44 hit target
		btn.disabled = cleared and str(r.get("type", "")) != "puzzle"
		if i == _room_cursor:
			btn.modulate = Color(1.0, 0.85, 0.5)
		else:
			btn.modulate = Color(1, 1, 1)
		btn.pressed.connect(_on_room_button_pressed.bind(i))
		rooms_node.add_child(btn)

func _on_room_button_pressed(idx: int) -> void:
	_room_cursor = idx
	_refresh_ui()
	_enter_current_room()

# ---- JSON loader (data-driven; import-independent, works headless) ----
static func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text := f.get_as_text()
	f.close()
	return JSON.parse_string(text)
