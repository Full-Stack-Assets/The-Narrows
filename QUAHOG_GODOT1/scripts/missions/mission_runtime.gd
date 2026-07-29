extends RefCounted
class_name MissionRuntime

signal objective_changed(objective_id: String)
signal mission_completed(reward: int, effects: Dictionary)
signal mission_failed(reason: String)

var definition: MissionDefinition = null
var progress := MissionProgress.new()


func start(p_definition: MissionDefinition) -> void:
	definition = p_definition
	progress.reset()
	_capture_checkpoint()
	objective_changed.emit(current_objective_id())


func dispatch(event: MissionEvent) -> void:
	if definition == null or progress.completed:
		return
	if event.kind == "failed":
		progress.failed = true
		mission_failed.emit(event.subject_id)
		return
	if progress.failed or not _event_completes_current_objective(event):
		return
	_advance()


func current_objective() -> Dictionary:
	if definition == null or progress.completed:
		return {}
	if progress.objective_index < 0 or progress.objective_index >= definition.objectives.size():
		return {}
	return definition.objectives[progress.objective_index]


func current_objective_id() -> String:
	return str(current_objective().get("id", ""))


func is_completed() -> bool:
	return progress.completed


func snapshot() -> Dictionary:
	var checkpoint_id := ""
	if definition != null and progress.checkpoint_index >= 0 and progress.checkpoint_index < definition.objectives.size():
		checkpoint_id = str(definition.objectives[progress.checkpoint_index].get("id", ""))
	return {
		"mission_id": definition.id if definition else "",
		"objective_id": current_objective_id(),
		"objective_index": progress.objective_index,
		"checkpoint_objective_id": checkpoint_id,
		"checkpoint_index": progress.checkpoint_index,
		"completed": progress.completed,
		"failed": progress.failed,
		"reward_emitted": progress.reward_emitted,
	}


func restore(saved: Dictionary) -> Error:
	if definition == null or str(saved.get("mission_id", "")) != definition.id:
		return ERR_INVALID_DATA
	var objective_index := int(saved.get("objective_index", -1))
	var checkpoint_index := int(saved.get("checkpoint_index", -1))
	var completed := bool(saved.get("completed", false))
	if objective_index < 0 or objective_index > definition.objectives.size():
		return ERR_INVALID_DATA
	if checkpoint_index < -1 or checkpoint_index >= definition.objectives.size():
		return ERR_INVALID_DATA
	if not completed and objective_index >= definition.objectives.size():
		return ERR_INVALID_DATA
	progress.objective_index = objective_index
	progress.checkpoint_index = checkpoint_index
	progress.completed = completed
	progress.failed = bool(saved.get("failed", false))
	progress.reward_emitted = bool(saved.get("reward_emitted", false))
	objective_changed.emit(current_objective_id())
	return OK


func restart_checkpoint() -> void:
	if definition == null:
		return
	progress.objective_index = maxi(progress.checkpoint_index, 0)
	progress.failed = false
	progress.completed = false
	objective_changed.emit(current_objective_id())


func _capture_checkpoint() -> void:
	var objective := current_objective()
	if bool(objective.get("checkpoint", false)):
		progress.checkpoint_index = progress.objective_index


func _advance() -> void:
	progress.objective_index += 1
	if progress.objective_index >= definition.objectives.size():
		progress.completed = true
		if not progress.reward_emitted:
			progress.reward_emitted = true
			mission_completed.emit(definition.reward, definition.effects.duplicate(true))
		return
	_capture_checkpoint()
	objective_changed.emit(current_objective_id())


func _event_completes_current_objective(event: MissionEvent) -> bool:
	var objective := current_objective()
	if objective.is_empty():
		return false
	match int(objective["objective_type"]):
		MissionDefinition.ObjectiveType.REACH:
			return (
				event.kind == "reach"
				and event.subject_id == str(objective["target"])
				and event.value <= float(objective["radius"])
			)
		MissionDefinition.ObjectiveType.INTERACT:
			return event.kind == "interact" and event.subject_id == str(objective["target"])
		MissionDefinition.ObjectiveType.ENTER_VEHICLE:
			return event.kind == "enter_vehicle" and event.subject_id == str(objective["entity"])
		MissionDefinition.ObjectiveType.DEFEAT_ENCOUNTER:
			return event.kind == "defeat_encounter" and event.subject_id == str(objective["encounter"])
		MissionDefinition.ObjectiveType.LOSE_HEAT:
			return event.kind == "heat_changed" and event.value <= float(objective.get("max_heat", 0))
		MissionDefinition.ObjectiveType.SURVIVE:
			return event.kind == "survived" and event.value >= float(objective["duration"])
		MissionDefinition.ObjectiveType.DIALOGUE:
			return event.kind == "dialogue" and event.subject_id == str(objective["dialogue"])
	return false
