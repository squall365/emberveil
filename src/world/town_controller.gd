extends Node
class_name TownController
# E9.2 — Hearthmoor node map (5 Ward-Sigil nodes). S2 interactive = {Rest, Sage, Shrine};
# locked = {Shop, Barracks} (decision 2.8). Reads worldState via SceneManager (GAP-3);
# writes safe saves via SaveManager (Shrine) / PartyManager (Rest). Never persists mid-action.
#
# Ward-Sigil identification is shape + label (never colour alone, accessibility §9.1): each
# node carries a sigilShape token surfaced in its label. True Ward-Sigil vector art is an
# original-IP art deliverable (not duplicated here); the token + text label satisfy the
# non-colour identification contract for the MVP slice.

const NODES := [
	{"id": "rest",     "displayName": "Rest (Inn)", "sigilShape": "hearth", "action": "rest",     "locked": false},
	{"id": "shop",     "displayName": "Market",     "sigilShape": "coin",   "action": "shop",     "locked": true},
	{"id": "barracks", "displayName": "Barracks",   "sigilShape": "banner", "action": "barracks", "locked": true},
	{"id": "sage",     "displayName": "Sage",       "sigilShape": "eye",    "action": "sage",     "locked": false},
	{"id": "shrine",   "displayName": "Shrine",     "sigilShape": "ward",   "action": "shrine",   "locked": false},
]

var _focus: int = 0

func _ready() -> void:
	_connect_buttons()
	_refresh_ui()
	_add_town_background()
	_add_party_display()

func setup(_params: Dictionary = {}) -> void:
	_focus = 0
	_connect_buttons()
	_refresh_ui()
	_add_town_background()
	_add_party_display()

func _connect_buttons() -> void:
	for nd in NODES:
		var btn = get_node_or_null("Nodes/" + nd["id"])
		if btn != null and not btn.pressed.is_connected(_on_node_pressed.bind(nd)):
			btn.pressed.connect(_on_node_pressed.bind(nd))

func _on_node_pressed(nd: Dictionary) -> void:
	_activate_node(str(nd["action"]), bool(nd["locked"]))

func _activate_node(action: String, locked: bool) -> void:
	if locked:
		# Locked in S2 (decision 2.8): greyed + toast "coming soon" (UI hook).
		EventBus.save_event.emit({"node": action, "blocked": true})
		return
	match action:
		"rest":
			_rest_full_heal()
		"sage":
			_enter_dungeon_via_sage()
		"shrine":
			_save_at_shrine()

func _rest_full_heal() -> void:
	var rs: Dictionary = SceneManager.get_run_state()
	var party: Array = rs.get("party", [])
	for m in party:
		var s: Dictionary = PartyManager.derive_stats(m)
		m["hp"] = int(s.get("maxHP", 100))
		m["mp"] = int(s.get("maxMP", 10))
	rs["party"] = party
	SceneManager.commit_run_state(rs)
	EventBus.progression_event.emit({"rest": true})

# Sage accepts the quest, then opens the dungeon entrance (gated by boss-defeated). The dungeon
# entry is a no-arg call so it resumes to the saved floorIdx (GAP-4).
func _enter_dungeon_via_sage() -> void:
	var ws: Dictionary = SceneManager.get_world_state()
	var quest_accepted: bool = bool(ws.get("questAccepted", false))
	if not quest_accepted:
		var rs: Dictionary = SceneManager.get_run_state()
		rs["worldState"]["questAccepted"] = true
		SceneManager.commit_run_state(rs)
		quest_accepted = true   # re-read after mutation
	var boss_defeated: bool = bool(ws.get("dungeon", {}).get("bossDefeated", false))
	if quest_accepted and not boss_defeated:
		WorldDirector.enter_dungeon()

func _save_at_shrine() -> void:
	SceneManager.commit_run_state(SceneManager.get_run_state())
	SaveManager.save(SceneManager.get_run_state(), true)  # Shrine is a manual safe node
	EventBus.save_event.emit({"node": "shrine"})

# --- map_input contract (ux-spec §3) ---
func _map_move(dir: String) -> void:
	var n: int = NODES.size()
	if dir in ["ui_up", "ui_left"]:
		_focus = (_focus - 1 + n) % n
	elif dir in ["ui_down", "ui_right"]:
		_focus = (_focus + 1) % n
	_refresh_ui()

func _map_accept() -> void:
	if _focus < 0 or _focus >= NODES.size():
		return
	var node: Dictionary = NODES[_focus]
	_activate_node(str(node["action"]), bool(node["locked"]))

func _map_cancel() -> void:
	# Pause menu hook (S2: no-op; safe-node gating owned by SaveManager).
	EventBus.scene_changed.emit("Town", {"pause": true})

# --- UI (MVP: 5 node buttons; focus ring = parchment glow; locked = greyed) ---
func _refresh_ui() -> void:
	for i in NODES.size():
		var btn = get_node_or_null("Nodes/" + NODES[i]["id"])
		if btn == null:
			continue
		if bool(NODES[i]["locked"]):
			btn.modulate = Color(0.5, 0.5, 0.5)
		elif i == _focus:
			btn.modulate = Color(1.0, 0.85, 0.5)
		else:
			btn.modulate = Color(1, 1, 1)

func _add_town_background() -> void:
	var existing := get_node_or_null("TownBackground")
	if existing != null:
		existing.queue_free()
	if not FileAccess.file_exists("assets/backgrounds/town_bg.png"):
		return
	var tex := load("res://assets/backgrounds/town_bg.png")
	if tex == null:
		return
	var bg := TextureRect.new()
	bg.name = "TownBackground"
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var vs := get_viewport().get_visible_rect().size
	bg.position = Vector2.ZERO
	bg.size = vs
	bg.modulate = Color(1, 1, 1, 0.5)
	get_parent().add_child(bg)
	get_parent().move_child(bg, 0)  # behind town UI

func _add_party_display() -> void:
	var old := get_node_or_null("PartyInfo")
	if old != null:
		old.queue_free()
	var vs := get_viewport().get_visible_rect().size
	var container := VBoxContainer.new()
	container.name = "PartyInfo"
	container.position = Vector2(20, vs.y - 120)
	add_child(container)

	var party: Array = SceneManager.get_run_state().get("party", [])
	if party.is_empty():
		return
	for m in party:
		var s: Dictionary = PartyManager.derive_stats(m)
		var hp: int = int(m.get("hp", -1))
		var mp: int = int(m.get("mp", -1))
		if hp < 0: hp = s.get("maxHP", 100)
		if mp < 0: mp = s.get("maxMP", 10)
		var label := Label.new()
		label.text = "%s  LV%d  HP:%d/%d  MP:%d/%d" % [
			str(m.get("jobId", "?")).capitalize(),
			s.get("level", 1), hp, s.get("maxHP", 100), mp, s.get("maxMP", 10)
		]
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.949, 0.851, 0.627, 1.0))
		container.add_child(label)
	for i in NODES.size():
		var btn = get_node_or_null("Nodes/" + NODES[i]["id"])
		if btn == null:
			continue
		if bool(NODES[i]["locked"]):
			btn.modulate = Color(0.5, 0.5, 0.5)
		elif i == _focus:
			btn.modulate = Color(1.0, 0.85, 0.5)
		else:
			btn.modulate = Color(1, 1, 1)
