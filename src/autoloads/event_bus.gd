extends Node
class_name EventBus
# UI-only event backbone. Logic MUST NOT mutate state here (ADR-002); scenes subscribe
# and react. Keeps gameplay/sim decoupled from presentation.

signal battle_event(payload: Dictionary)
signal save_event(payload: Dictionary)
signal scene_changed(node: String, params: Dictionary)
signal settings_changed(settings: Dictionary)
signal codex_updated(payload: Dictionary)
signal progression_event(payload: Dictionary)
signal underdog_stage_changed(tier: int)
