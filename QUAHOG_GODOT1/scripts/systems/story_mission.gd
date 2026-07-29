extends Node
class_name StoryMission

signal mission_changed(active: bool, text: String, target: Vector3)
signal mission_completed(title: String)
signal mission_failed(reason: String)

const DEFINITION_PATH := "res://data/missions/off_the_boat.json"
const JobMarkerScript := preload("res://scripts/world/job_marker.gd")
const MissionDefinitionScript := preload("res://scripts/missions/mission_definition.gd")
const MissionEventScript := preload("res://scripts/missions/mission_event.gd")
const MissionRuntimeScript := preload("res://scripts/missions/mission_runtime.gd")

var player: Node3D = null
var world: Node3D = null
var runtime: MissionRuntime = null
var definition: MissionDefinition = null
var _marker: JobMarker = null
var _survive_elapsed: float = 0.0


func setup(p_player: Node3D, p_world: Node3D) -> void:
	player = p_player
	world = p_world
	_connect_world_events()


func try_start_opener() -> void:
	if GameManager == null or GameManager.campaign_done:
		return
	var parsed := _load_definition(DEFINITION_PATH)
	if not str(parsed.get("error", "")).is_empty():
		push_error("Mission definition rejected: %s" % parsed["error"])
		mission_changed.emit(false, "Mission unavailable", Vector3.ZERO)
		return
	definition = parsed["definition"]
	runtime = MissionRuntimeScript.new()
	runtime.objective_changed.connect(_on_objective_changed)
	runtime.mission_completed.connect(_on_runtime_completed)
	runtime.mission_failed.connect(_on_runtime_failed)
	runtime.start(definition)
	if GameManager.campaign_step > 0:
		var saved := runtime.snapshot()
		saved["objective_index"] = mini(GameManager.campaign_step, definition.objectives.size() - 1)
		saved["objective_id"] = str(definition.objectives[int(saved["objective_index"])]["id"])
		runtime.restore(saved)
	GameManager.show_message("Off the Boat: head to Seamen's Bethel.")
	_sync_objective()


func try_resume_campaign() -> void:
	try_start_opener()


func has_active_mission() -> bool:
	return runtime != null and not runtime.is_completed()


func current_title() -> String:
	return definition.title if definition else "Free roam"


func current_objective_text() -> String:
	return str(runtime.current_objective().get("text", "")) if runtime else ""


func get_objective_position() -> Vector3:
	if runtime == null:
		return Vector3.ZERO
	var raw_position: Variant = runtime.current_objective().get("position", [])
	if raw_position is Array and raw_position.size() == 3:
		return Vector3(float(raw_position[0]), float(raw_position[1]), float(raw_position[2]))
	return Vector3.ZERO


func dispatch_event(event: MissionEvent) -> void:
	if runtime:
		runtime.dispatch(event)


func notify_encounter_defeated(encounter_id: String) -> void:
	dispatch_event(MissionEventScript.create("defeat_encounter", encounter_id))


func notify_dialogue_completed(dialogue_id: String) -> void:
	dispatch_event(MissionEventScript.create("dialogue", dialogue_id))


func restart_checkpoint() -> void:
	if runtime:
		runtime.restart_checkpoint()
		_sync_objective()


func snapshot() -> Dictionary:
	return runtime.snapshot() if runtime else {}


func restore(saved: Dictionary) -> Error:
	if runtime == null:
		return ERR_UNCONFIGURED
	var result := runtime.restore(saved)
	if result == OK:
		_sync_objective()
	return result


func _process(delta: float) -> void:
	if runtime == null:
		return
	var objective := runtime.current_objective()
	if int(objective.get("objective_type", -1)) != MissionDefinition.ObjectiveType.SURVIVE:
		_survive_elapsed = 0.0
		return
	_survive_elapsed += delta
	dispatch_event(MissionEventScript.create("survived", "", _survive_elapsed))


func _connect_world_events() -> void:
	if player and player.has_signal("driving_changed"):
		player.driving_changed.connect(_on_driving_changed)
	if player and player.has_signal("interacted"):
		player.interacted.connect(_on_interacted)
	if GameManager and not GameManager.wanted_changed.is_connected(_on_wanted_changed):
		GameManager.wanted_changed.connect(_on_wanted_changed)


func _on_driving_changed(driving: bool) -> void:
	if driving:
		dispatch_event(MissionEventScript.create("enter_vehicle", "any_vehicle"))


func _on_interacted(entity_id: String) -> void:
	dispatch_event(MissionEventScript.create("interact", entity_id))


func _on_wanted_changed(level: int) -> void:
	dispatch_event(MissionEventScript.create("heat_changed", "", level))


func _on_marker_reached(target_id: String) -> void:
	dispatch_event(MissionEventScript.create("reach", target_id, 0.0))


func _on_objective_changed(_objective_id: String) -> void:
	if runtime == null:
		return
	GameManager.campaign_step = runtime.progress.objective_index
	GameManager.save_game()
	_sync_objective()


func _sync_objective() -> void:
	if runtime == null or runtime.is_completed():
		_clear_marker()
		mission_changed.emit(false, "", Vector3.ZERO)
		return
	var objective := runtime.current_objective()
	var position := get_objective_position()
	if position != Vector3.ZERO:
		_spawn_marker(
			position,
			float(objective.get("radius", 5.0)),
			str(objective.get("target", ""))
		)
	else:
		_clear_marker()
	mission_changed.emit(true, str(objective.get("text", "")), position)


func _spawn_marker(pos: Vector3, radius: float, target_id: String) -> void:
	_clear_marker()
	_marker = JobMarkerScript.new()
	world.add_child(_marker)
	_marker.setup(pos, radius, Color(0.95, 0.78, 0.25), player)
	_marker.reached.connect(func() -> void: _on_marker_reached(target_id))


func _clear_marker() -> void:
	if _marker and is_instance_valid(_marker):
		_marker.queue_free()
	_marker = null


func _on_runtime_completed(reward: int, effects: Dictionary) -> void:
	if reward > 0:
		GameManager.add_cash_silent(reward)
	if bool(effects.get("opener_complete", false)):
		GameManager.opener_complete = true
	GameManager.campaign_step = definition.objectives.size()
	GameManager.campaign_done = true
	GameManager.record_mission_complete()
	GameManager.save_game()
	_clear_marker()
	mission_changed.emit(false, "Mission complete", Vector3.ZERO)
	mission_completed.emit(definition.title)
	GameManager.show_message("Safehouse reached. Welcome to the Narrows. +$%d" % reward)


func _on_runtime_failed(reason: String) -> void:
	GameManager.save_game()
	mission_failed.emit(reason)
	GameManager.show_message("Mission failed: %s" % reason)


func _load_definition(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"definition": null, "error": "definition_not_found"}
	var source := FileAccess.open(path, FileAccess.READ)
	if source == null:
		return {"definition": null, "error": "definition_unreadable"}
	var data: Variant = JSON.parse_string(source.get_as_text())
	if not data is Dictionary:
		return {"definition": null, "error": "definition_invalid_json"}
	return MissionDefinitionScript.parse(data)
