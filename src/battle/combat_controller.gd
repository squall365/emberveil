extends Node
# Sprint 3 — player-driven battle loop. One encounter; added as root overlay by the
# Dungeon, queue_freed on resolution. MVP: "Attack" button resolves all allies, then
# enemies auto-respond. Repeat until one side wipes. No save mid-battle (anti-scum).

var _state: Dictionary = {}
var _rng: RNGService = null
var _callback: Object = null
var _is_boss: bool = false
var _outcome: String = "ongoing"
var _gui: Control = null

func setup(state: Dictionary, rng: RNGService, callback: Object) -> void:
	_state = state.duplicate(true)
	_rng = rng
	_callback = callback
	_is_boss = bool(_state.get("isBoss", false))
	# Defer GUI build so get_viewport() has valid rect (not 0x0 during setup).
	call_deferred("_build_gui")

func _build_gui() -> void:
	var vs := get_viewport().get_visible_rect().size
	_gui = Control.new()
	_gui.position = Vector2.ZERO
	_gui.size = vs
	add_child(_gui)

	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = vs
	bg.color = Color(0.169, 0.106, 0.180, 0.92)
	_gui.add_child(bg)

	var label := Label.new()
	label.name = "Title"
	label.position = Vector2(20, 20)
	label.size = Vector2(vs.x - 40, 28)
	label.add_theme_font_size_override("font_size", 22 if _is_boss else 18)
	label.add_theme_color_override("font_color", Color(0.949, 0.851, 0.627, 1.0))
	label.text = "Boss: Sigil-Twisted Warden" if _is_boss else "Battle: Enemy encounter"
	_gui.add_child(label)

	var btn := Button.new()
	btn.text = "Attack"
	btn.position = Vector2(vs.x - 320, vs.y - 60)
	btn.size = Vector2(140, 44)
	btn.pressed.connect(_on_attack_pressed)
	_gui.add_child(btn)

	var defend_btn := Button.new()
	defend_btn.text = "Defend"
	defend_btn.position = Vector2(vs.x - 170, vs.y - 60)
	defend_btn.size = Vector2(140, 44)
	defend_btn.pressed.connect(_on_defend_pressed)
	_gui.add_child(defend_btn)

	var skill_btn := Button.new()
	skill_btn.text = "Skill"
	skill_btn.position = Vector2(vs.x - 320, vs.y - 110)
	skill_btn.size = Vector2(140, 44)
	skill_btn.disabled = true
	_gui.add_child(skill_btn)

	var item_btn := Button.new()
	item_btn.text = "Item"
	item_btn.position = Vector2(vs.x - 170, vs.y - 110)
	item_btn.size = Vector2(140, 44)
	item_btn.disabled = true
	_gui.add_child(item_btn)

	# Message label at bottom
	var msg := Label.new()
	msg.name = "Message"
	msg.position = Vector2(20, vs.y - 100)
	msg.size = Vector2(vs.x - 40, 28)
	msg.add_theme_color_override("font_color", Color(0.851, 0.851, 0.851, 1.0))
	msg.text = "Tap Attack to begin."
	_gui.add_child(msg)
	_refresh_display()

func _refresh_display() -> void:
	for c in _gui.get_children():
		if c.has_meta("hp_bar"):
			c.queue_free()

	var allies: Array = _combatants_by_side("ally")
	var enemies: Array = _combatants_by_side("enemy")

	for i in allies.size():
		_draw_hp_bar(allies[i], Vector2(10, 50 + i * 36), Color(0.467, 0.765, 0.478, 1.0))
	for i in enemies.size():
		_draw_hp_bar(enemies[i], Vector2(420, 50 + i * 36), Color(0.784, 0.275, 0.275, 1.0))

func _draw_hp_bar(c: Dictionary, pos: Vector2, color: Color) -> void:
	var max_hp: int = int(c.get("maxHP", 1))
	var hp: int = int(c.get("HP", 0))
	var ratio: float = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	var name: String = str(c.get("name", c.get("id", "?")))
	var guard_tag := " [Defended]" if c.has("guard") else ""

	var label := Label.new()
	label.position = pos
	label.size = Vector2(180, 16)
	label.text = "%s%s  %d / %d" % [name, guard_tag, hp, max_hp]
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.949, 0.851, 0.627, 1.0))
	label.set_meta("hp_bar", true)
	_gui.add_child(label)

	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(pos.x, pos.y + 17)
	bar_bg.size = Vector2(180, 12)
	bar_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	bar_bg.set_meta("hp_bar", true)
	_gui.add_child(bar_bg)

	var bar := ColorRect.new()
	bar.position = Vector2(pos.x + 1, pos.y + 18)
	bar.size = Vector2(178.0 * ratio, 10)
	bar.color = color
	bar.set_meta("hp_bar", true)
	_gui.add_child(bar)


func _on_attack_pressed() -> void:
	_resolve_all_allies()
	if _outcome != "ongoing":
		return
	_resolve_all_enemies()
	if _outcome != "ongoing":
		return
	_clear_all_guard()
	_refresh_display()
	_get_msg_label().text = "Tap Attack to continue."


func _on_defend_pressed() -> void:
	for c in _combatants_by_side("ally"):
		var action := {"actorId": str(c.get("id", "")), "type": "Defend", "targetIds": []}
		var res: Array = BattleResolver.resolve_action(_state, action, _rng)
		_state = res[0]
	if _outcome != "ongoing":
		return
	_resolve_all_enemies()
	if _outcome != "ongoing":
		return
	_clear_all_guard()
	_refresh_display()
	_get_msg_label().text = "Defended! Your turn."


func _resolve_all_allies() -> void:
	for c in _combatants_by_side("ally"):
		if int(c.get("HP", 0)) <= 0:
			continue
		var action := _auto_ally_action(c)
		var res: Array = BattleResolver.resolve_action(_state, action, _rng)
		_state = res[0]
		if _check_end():
			return


func _resolve_all_enemies() -> void:
	for c in _combatants_by_side("enemy"):
		if int(c.get("HP", 0)) <= 0:
			continue
		var ai := EnemyAI.new()
		var action := ai.choose_action(_state, c, _rng)
		var res: Array = BattleResolver.resolve_action(_state, action, _rng)
		_state = res[0]
		if _check_end():
			return


func _auto_ally_action(actor: Dictionary) -> Dictionary:
	var enemies: Array = _state.get("combatants", []).filter(
		func(c): return str(c.get("side", "")) == "enemy" and int(c.get("HP", 0)) > 0)
	if enemies.is_empty():
		return {"actorId": str(actor.get("id", "")), "type": "Defend", "targetIds": []}
	var tgt: Dictionary = enemies[0]
	for e in enemies:
		if int(e.get("HP", 0)) < int(tgt.get("HP", 0)):
			tgt = e
	return {"actorId": str(actor.get("id", "")), "type": "Attack", "targetIds": [str(tgt.get("id", ""))]}


func _check_end() -> bool:
	var any_enemy := false
	var any_ally := false
	for c in _state.get("combatants", []):
		if int(c.get("HP", 0)) > 0:
			if str(c.get("side", "")) == "enemy":
				any_enemy = true
			elif str(c.get("side", "")) == "ally":
				any_ally = true
	if not any_enemy:
		_outcome = "win"
		_get_msg_label().text = "Victory!"
		if _is_boss:
			_get_msg_label().text = "Victory! Stone Sigil obtained!"
			get_tree().create_timer(2.0).timeout.connect(_finish)
			return true
		call_deferred("_finish")
		return true
	if not any_ally:
		_outcome = "lose"
		_get_msg_label().text = "Defeat..."
		call_deferred("_finish")
		return true
	return false


func _combatants_by_side(side: String) -> Array:
	var out: Array = []
	for c in _state.get("combatants", []):
		if str(c.get("side", "")) == side and int(c.get("HP", 0)) > 0:
			out.append(c)
	return out


func _clear_all_guard() -> void:
	for c in _state.get("combatants", []):
		if c.has("guard"):
			c.erase("guard")


func _get_msg_label() -> Label:
	return _gui.get_node("Message") as Label


func _finish() -> void:
	var result := {"outcome": _outcome, "state": _state}
	if _callback != null and _callback.has_method("_on_battle_resolved"):
		_callback._on_battle_resolved(result)
	queue_free()
