extends Node
class_name StoryMission

signal mission_changed(active: bool, text: String, target: Vector3)
signal mission_completed(title: String)
signal mission_failed(reason: String)
signal subtitle_changed(speaker: String, text: String)
signal tutorial_prompt_changed(text: String)

const DEFINITION_PATH := "res://data/missions/off_the_boat.json"
const JobMarkerScript := preload("res://scripts/world/job_marker.gd")
const MissionDefinitionScript := preload("res://scripts/missions/mission_definition.gd")
const MissionEventScript := preload("res://scripts/missions/mission_event.gd")
const MissionRuntimeScript := preload("res://scripts/missions/mission_runtime.gd")
const EncounterDirectorScript := preload("res://scripts/missions/encounter_director.gd")
const DialogueRunnerScript := preload("res://scripts/dialogue/dialogue_runner.gd")

var player: Node3D = null
var world: Node3D = null
var runtime: MissionRuntime = null
var definition: MissionDefinition = null
var _marker: JobMarker = null
var _survive_elapsed: float = 0.0
var _encounter: EncounterDirector = null
var _dialogue: DialogueRunner = null
var _input_device: String = "keyboard"
var _tutorial_seen: Dictionary = {}
var _assigned_car: Node = null


func setup(p_player: Node3D, p_world: Node3D) -> void:
	player = p_player
	world = p_world
	_dialogue = DialogueRunnerScript.new()
	add_child(_dialogue)
	_dialogue.load_file("res://data/dialogue/off_the_boat.json")
	_dialogue.line_changed.connect(_on_dialogue_line)
	_dialogue.conversation_completed.connect(notify_dialogue_completed)
	_encounter = EncounterDirectorScript.new()
	add_child(_encounter)
	_encounter.encounter_center = Vector3(-310.0, 0.0, -88.0)
	_encounter.encounter_completed.connect(notify_encounter_defeated)
	_encounter.encounter_failed.connect(_on_encounter_failed)
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
	subtitle_changed.emit("", "")
	dispatch_event(MissionEventScript.create("dialogue", dialogue_id))


func restart_checkpoint() -> void:
	if runtime:
		runtime.restart_checkpoint()
		_sync_objective()


func set_input_device(device: String) -> void:
	if device == _input_device:
		return
	_input_device = device
	_emit_tutorial_prompt()


func mark_tutorial_action(action: String) -> void:
	_tutorial_seen[action] = true
	_emit_tutorial_prompt()


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
	if player and player.has_signal("vehicle_entered"):
		player.vehicle_entered.connect(_on_vehicle_entered)
	if player and player.has_signal("interacted"):
		player.interacted.connect(_on_interacted)
	if player and player.has_signal("wasted"):
		player.wasted.connect(_on_player_wasted)
	if player and player.has_signal("tutorial_action"):
		player.tutorial_action.connect(mark_tutorial_action)
	if GameManager and not GameManager.wanted_changed.is_connected(_on_wanted_changed):
		GameManager.wanted_changed.connect(_on_wanted_changed)


func _on_driving_changed(driving: bool) -> void:
	if driving and not player.has_signal("vehicle_entered"):
		dispatch_event(MissionEventScript.create("enter_vehicle", "any_vehicle"))


func _on_vehicle_entered(entity_id: String) -> void:
	mark_tutorial_action("enter_drive")
	dispatch_event(MissionEventScript.create("enter_vehicle", entity_id))


func _on_interacted(entity_id: String) -> void:
	mark_tutorial_action("interact")
	dispatch_event(MissionEventScript.create("interact", entity_id))


func _on_wanted_changed(level: int) -> void:
	if level == 0:
		mark_tutorial_action("lose_heat")
	dispatch_event(MissionEventScript.create("heat_changed", "", level))


func _on_marker_reached(target_id: String) -> void:
	dispatch_event(MissionEventScript.create("reach", target_id, 0.0))


func _on_objective_changed(objective_id: String) -> void:
	if runtime == null:
		return
	GameManager.campaign_step = runtime.progress.objective_index
	GameManager.save_game()
	if objective_id == "reach_fish_pier" and _dialogue:
		_dialogue.start("deacon_intro")
	elif objective_id == "pier_ambush":
		_start_pier_ambush()
	elif objective_id == "safehouse_dialogue" and _dialogue:
		_dialogue.start("safehouse_wrap")
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
	_emit_tutorial_prompt()


func _start_pier_ambush() -> void:
	_assigned_car = null
	if world and world.has_method("prepare_mission_getaway_car"):
		_assigned_car = world.prepare_mission_getaway_car()
	if (
		_assigned_car
		and _assigned_car.has_signal("destroyed")
		and not _assigned_car.destroyed.is_connected(_on_getaway_destroyed)
	):
		_assigned_car.destroyed.connect(_on_getaway_destroyed)
	_encounter.configure(player, _assigned_car)
	_encounter.start("pier_ambush")
	if world and world.has_method("get_wanted_system"):
		var wanted: Node = world.get_wanted_system()
		if wanted and wanted.has_method("add_heat"):
			wanted.add_heat(2)


func _on_encounter_failed(_encounter_id: String, reason: String) -> void:
	dispatch_event(MissionEventScript.create("failed", reason))
	restart_checkpoint()
	_encounter.reset("pier_ambush")


func _on_getaway_destroyed() -> void:
	if runtime and runtime.current_objective_id() == "enter_getaway_car":
		dispatch_event(MissionEventScript.create("failed", "assigned_car_destroyed"))
		restart_checkpoint()
		_encounter.reset("pier_ambush")


func _on_player_wasted() -> void:
	if _encounter:
		_encounter.notify_player_wasted()


func _on_dialogue_line(speaker: String, text: String, _audio_path: String) -> void:
	subtitle_changed.emit(speaker, text)


func _emit_tutorial_prompt() -> void:
	if runtime == null:
		tutorial_prompt_changed.emit("")
		return
	var objective_id := runtime.current_objective_id()
	var action := ""
	var prompts := {}
	if _input_device == "touch":
		prompts = {
			"move_look": "Drag the left stick to move · swipe the screen to look",
			"interact": "Tap USE near Deacon",
			"attack_aim": "Hold AIM · tap FIRE",
			"enter_drive": "Tap CAR beside the marked getaway",
			"map": "Tap MAP to orient yourself",
			"lose_heat": "Break line of sight until the stars clear",
			"pause_save": "Tap II to pause and save",
		}
	elif _input_device == "gamepad":
		prompts = {
			"move_look": "Left stick to move · right stick to look",
			"interact": "Press the confirm button near Deacon",
			"attack_aim": "Hold left trigger · press right trigger",
			"enter_drive": "Press the vehicle button beside the marked getaway",
			"map": "Press the map button to orient yourself",
			"lose_heat": "Break line of sight until the stars clear",
			"pause_save": "Press Menu to pause and save",
		}
	else:
		prompts = {
			"move_look": "WASD to move · drag the mouse to look",
			"interact": "Press E near Deacon",
			"attack_aim": "Right mouse to aim · left mouse to attack",
			"enter_drive": "Press F beside the marked getaway",
			"map": "Press M to open the map",
			"lose_heat": "Break line of sight until the stars clear",
			"pause_save": "Press Esc to pause and save",
		}
	if objective_id == "reach_bethel":
		action = "move_look"
	elif objective_id == "interact_deacon":
		action = "interact"
	elif objective_id == "pier_ambush":
		action = "attack_aim"
	elif objective_id == "enter_getaway_car":
		action = "enter_drive"
	elif objective_id == "lose_police_heat":
		action = "lose_heat"
	elif objective_id == "reach_safehouse":
		action = "map"
	elif objective_id == "safehouse_dialogue":
		action = "pause_save"
	var text := "" if action.is_empty() or _tutorial_seen.has(action) else str(prompts[action])
	tutorial_prompt_changed.emit(text)


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
