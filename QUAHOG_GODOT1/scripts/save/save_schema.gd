extends RefCounted
class_name SaveSchema

const CURRENT_VERSION := 3
const STARTING_CASH := 40


static func blank() -> Dictionary:
	return {
		"schema_version": CURRENT_VERSION,
		"saved_at": "",
		"source_build_sha": "local",
		"player": {
			"has_position": false,
			"position": [0.0, 0.0, 0.0],
			"yaw": 0.0,
			"health": 100.0,
			"armor": 0.0,
		},
		"economy": {"cash": STARTING_CASH, "reputation": 0},
		"heat": {"police": 0, "faction": 0},
		"mission": {"snapshot": {}, "claimed_rewards": []},
		"businesses": {
			"owned_mask": 0,
			"revenue_accumulator": 0.0,
			"next_revenue_event": 75.0,
			"income_accumulator": 0.0,
		},
		"collectibles": {"scrimshaw_mask": 0},
		"activities": {},
		"vehicle": {"identity": "", "condition": 1.0},
		"world": {"day_phase": 0.0, "raining": false, "gloria_storm": false},
		"settings": {
			"graphics": {"quality": 1},
			"audio": {"master_db": 0.0, "music_db": 0.0, "sfx_db": 0.0},
			"input": {},
			"accessibility": {
				"subtitles": true,
				"subtitle_size": 1.0,
				"high_contrast": false,
				"reduced_motion": false,
			},
		},
		"legacy_campaign": {
			"format": 2,
			"opener_complete": false,
			"mission_index": 0,
			"mission_step": 0,
			"done": false,
			"missions_completed": 0,
		},
		"cheats": {},
	}


static func with_defaults(data: Dictionary) -> Dictionary:
	var result := blank()
	_merge_known(result, data)
	result["schema_version"] = CURRENT_VERSION
	return result


static func is_valid(data: Dictionary) -> bool:
	if int(data.get("schema_version", -1)) != CURRENT_VERSION:
		return false
	for section in [
		"player", "economy", "heat", "mission", "businesses", "collectibles",
		"activities", "vehicle", "world", "settings", "legacy_campaign", "cheats",
	]:
		if not data.get(section, null) is Dictionary:
			return false
	var position: Variant = data["player"].get("position")
	if not position is Array or position.size() != 3:
		return false
	if not data["mission"].get("claimed_rewards", null) is Array:
		return false
	if not data["settings"].get("graphics", null) is Dictionary:
		return false
	if not data["settings"].get("audio", null) is Dictionary:
		return false
	if not data["settings"].get("input", null) is Dictionary:
		return false
	if not data["settings"].get("accessibility", null) is Dictionary:
		return false
	return true


static func _merge_known(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if not target.has(key):
			continue
		if target[key] is Dictionary and source[key] is Dictionary:
			_merge_known(target[key], source[key])
		else:
			target[key] = source[key]
