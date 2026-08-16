extends RefCounted
class_name SaveMigrations

const SaveSchemaScript = preload("res://scripts/save/save_schema.gd")


static func from_json(text: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {}
	return to_current(parsed)


static func to_current(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	var version := int(data.get("schema_version", 0))
	if version > SaveSchemaScript.CURRENT_VERSION:
		return {}
	if version == SaveSchemaScript.CURRENT_VERSION:
		var current := SaveSchemaScript.with_defaults(data)
		return current if SaveSchemaScript.is_valid(current) else {}
	return _from_legacy(data)


static func _from_legacy(data: Dictionary) -> Dictionary:
	var result := SaveSchemaScript.blank()
	var campaign_format := int(data.get("campaign_format", 1))
	var campaign_index := int(data.get("campaign_mi", 0))
	if campaign_format < 2 and campaign_index >= 6 and not bool(data.get("campaign_done", false)):
		campaign_index += 1
		campaign_format = 2
	result["player"] = {
		"has_position": bool(data.get("has_pos", false)),
		"position": [
			float(data.get("px", 0.0)),
			float(data.get("py", 0.0)),
			float(data.get("pz", 0.0)),
		],
		"yaw": float(data.get("yaw", 0.0)),
		"health": float(data.get("health", 100.0)),
		"armor": float(data.get("armor", 0.0)),
	}
	result["economy"]["cash"] = int(data.get("cash", SaveSchemaScript.STARTING_CASH))
	result["economy"]["reputation"] = int(data.get("reputation", data.get("missions_completed", 0)))
	result["heat"]["police"] = int(data.get("wanted_level", 0))
	result["heat"]["faction"] = int(data.get("faction_level", 0))
	result["collectibles"]["scrimshaw_mask"] = int(data.get("scrimshaw_mask", 0))
	result["businesses"]["owned_mask"] = int(data.get("owned_business_mask", 0))
	result["legacy_campaign"] = {
		"format": campaign_format,
		"opener_complete": bool(data.get("opener_complete", false)),
		"mission_index": campaign_index,
		"mission_step": int(data.get("campaign_step", 0)),
		"done": bool(data.get("campaign_done", false)),
		"missions_completed": int(data.get("missions_completed", 0)),
	}
	var cheats: Variant = data.get("cheats", {})
	result["cheats"] = cheats if cheats is Dictionary else {}
	return result
