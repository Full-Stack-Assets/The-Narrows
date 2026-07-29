extends RefCounted
class_name MissionDefinition

enum ObjectiveType {
	REACH,
	INTERACT,
	ENTER_VEHICLE,
	DEFEAT_ENCOUNTER,
	LOSE_HEAT,
	SURVIVE,
	DIALOGUE,
}

const TYPE_NAMES: Dictionary = {
	"reach": ObjectiveType.REACH,
	"interact": ObjectiveType.INTERACT,
	"enter_vehicle": ObjectiveType.ENTER_VEHICLE,
	"defeat_encounter": ObjectiveType.DEFEAT_ENCOUNTER,
	"lose_heat": ObjectiveType.LOSE_HEAT,
	"survive": ObjectiveType.SURVIVE,
	"dialogue": ObjectiveType.DIALOGUE,
}

var id: String = ""
var title: String = ""
var reward: int = 0
var effects: Dictionary = {}
var objectives: Array[Dictionary] = []


static func parse(data: Dictionary, known_mission_ids: Dictionary = {}) -> Dictionary:
	var mission_id := str(data.get("id", "")).strip_edges()
	if mission_id.is_empty():
		return _failure("missing_mission_id")
	if known_mission_ids.has(mission_id):
		return _failure("duplicate_mission_id")
	var raw_objectives: Variant = data.get("objectives", [])
	if not raw_objectives is Array or raw_objectives.is_empty():
		return _failure("no_objectives")
	var mission_reward := int(data.get("reward", 0))
	if mission_reward < 0:
		return _failure("negative_reward")

	var definition := MissionDefinition.new()
	definition.id = mission_id
	definition.title = str(data.get("title", mission_id))
	definition.reward = mission_reward
	var raw_effects: Variant = data.get("effects", {})
	if raw_effects is Dictionary:
		definition.effects = raw_effects.duplicate(true)

	var objective_ids: Dictionary = {}
	for raw_objective in raw_objectives:
		if not raw_objective is Dictionary:
			return _failure("malformed_objective")
		var objective: Dictionary = raw_objective.duplicate(true)
		var objective_id := str(objective.get("id", "")).strip_edges()
		if objective_id.is_empty():
			return _failure("missing_objective_id")
		if objective_ids.has(objective_id):
			return _failure("duplicate_objective_id")
		objective_ids[objective_id] = true
		if str(objective.get("text", "")).strip_edges().is_empty():
			return _failure("missing_objective_text")
		var type_name := str(objective.get("type", ""))
		if not TYPE_NAMES.has(type_name):
			return _failure("unsupported_objective_type")
		objective["objective_type"] = int(TYPE_NAMES[type_name])
		var validation_error := _validate_objective(objective)
		if not validation_error.is_empty():
			return _failure(validation_error)
		if int(objective.get("reward", 0)) < 0:
			return _failure("negative_reward")
		definition.objectives.append(objective)

	return {"definition": definition, "error": ""}


static func _validate_objective(objective: Dictionary) -> String:
	match int(objective["objective_type"]):
		ObjectiveType.REACH:
			if str(objective.get("target", "")).is_empty():
				return "missing_target"
			if float(objective.get("radius", 0.0)) <= 0.0:
				return "non_positive_reach_radius"
		ObjectiveType.INTERACT:
			if str(objective.get("target", "")).is_empty():
				return "missing_target"
		ObjectiveType.ENTER_VEHICLE:
			if str(objective.get("entity", "")).is_empty():
				return "missing_entity"
		ObjectiveType.DEFEAT_ENCOUNTER:
			if str(objective.get("encounter", "")).is_empty():
				return "missing_encounter"
		ObjectiveType.LOSE_HEAT:
			if int(objective.get("max_heat", 0)) < 0:
				return "negative_heat_target"
		ObjectiveType.SURVIVE:
			if float(objective.get("duration", 0.0)) <= 0.0:
				return "non_positive_survive_duration"
		ObjectiveType.DIALOGUE:
			if str(objective.get("dialogue", "")).is_empty():
				return "missing_dialogue"
	return ""


static func _failure(error_name: String) -> Dictionary:
	return {"definition": null, "error": error_name}
