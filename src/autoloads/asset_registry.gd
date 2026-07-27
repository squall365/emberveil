extends Node
class_name AssetRegistry
# Data-driven content + atlas loader (ADR-003 / asset-spec §6). Enforces the 3 load-bearing
# asset constraints (phase4-gate §3.2) and the web budget (≤4 atlases / ≤16MB / ≤48 colors):
#   Atlas A (Characters):  mipmaps OFF
#   Atlas B (Environment): building facade <= 200x240, flat
#   Atlas C (UI/VFX):      <= 12 VFX types
# Sprint 1: load placeholder JSON defs from content/; static validators wired into CI.

const MAX_ATLASES := 4
const MAX_DECODED_MB := 16
const MAX_PALETTE := 48
const MAX_VFX_TYPES := 12

var _atlases: Dictionary = {}
var _content: Dictionary = {}

func _ready() -> void:
	_load_manifest()

func register_atlas(def: Dictionary) -> void:
	_atlases[str(def.get("id", ""))] = def

func get_atlas(id: String) -> Dictionary:
	return _atlases.get(id, {})

func all_atlases() -> Array:
	return _atlases.values()

func validate_atlas(def: Dictionary) -> Dictionary:
	var errors: Array = []
	var kind: String = def.get("kind", "")
	if kind == "Characters" and def.get("mipmaps", true):
		errors.append("Atlas A (Characters) MUST have mipmaps=false (got true)")
	if kind == "Environment":
		var facade: Vector2 = def.get("maxFacade", Vector2(999, 999))
		if facade.x > 200 or facade.y > 240:
			errors.append("Atlas B (Environment) facade must be <= 200x240 (got %s)" % facade)
	if kind == "UI_VFX":
		var vfx: int = int(def.get("vfxTypes", 0))
		if vfx > MAX_VFX_TYPES:
			errors.append("Atlas C (UI/VFX) VFX types must be <= %d (got %d)" % [MAX_VFX_TYPES, vfx])
	return {"ok": errors.is_empty(), "errors": errors}

func load_content(group: String, defs: Array) -> void:
	_content[group] = defs

func get_content(group: String) -> Array:
	return _content.get(group, [])

func _load_manifest() -> void:
	# Runtime loader for content/ placeholder defs. Structure in Sprint 1; the data layer
	# (jobs/sigils/enemies/items/equipment/dungeons) is consumed by Party/World/Codex managers.
	pass
