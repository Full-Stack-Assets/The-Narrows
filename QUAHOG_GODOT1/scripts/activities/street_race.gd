extends Node
class_name StreetRace

signal activity_changed(activity_id: String, active: bool, text: String)
signal start_confirmation_requested(activity_id: String, title: String)

const ActivityRuntimeScript := preload("res://scripts/activities/activity_runtime.gd")
const JobMarkerScript := preload("res://scripts/world/job_marker.gd")

var player: Node3D = null
var world: Node3D = null
var boat: Node3D = null
var definition: Dictionary = {}
var runtime: ActivityRuntime = null
var _marker: JobMarker = null
var _pending_confirmation: bool = false
var _status_second: int = -1
var _initialized: bool = false


func setup(definition_path: String, p_player: Node3D, p_world: Node3D, p_boat: Node3D = null) -> Error:
	player = p_player
	world = p_world
	boat = p_boat
	definition = _read_definition(definition_path)
	if definition.is_empty():
		return ERR_FILE_CORRUPT
	runtime = ActivityRuntimeScript.new()
	runtime.checkpoint_changed.connect(_on_checkpoint_changed)
	runtime.completed.connect(_on_completed)
	runtime.failed.connect(_on_failed)
	var saved: Dictionary = {}
	if GameManager and GameManager.activity_state.has(str(definition["id"])):
		var candidate: Variant = GameManager.activity_state[str(definition["id"])]
		if candidate is Dictionary:
			saved = candidate
	var result := runtime.start(definition, saved)
	if result != OK:
		return result
	_initialized = true
	if saved.is_empty():
		runtime.active = false
	if runtime.active:
		_spawn_checkpoint_marker()
	else:
		_spawn_start_marker()
	return OK


func confirm_start() -> Error:
	if not _pending_confirmation:
		return ERR_UNAVAILABLE
	var vehicle := _activity_vehicle()
	if vehicle == null:
		GameManager.show_message(
			"Board a boat first." if str(definition["mode"]) == "boat" else "Enter a car first."
		)
		_pending_confirmation = false
		_spawn_start_marker()
		return ERR_UNAVAILABLE
	_pending_confirmation = false
	runtime.restart()
	_place_vehicle_at_start(vehicle)
	if str(definition["mode"]) == "boat":
		_add_heat(int(definition.get("heat_on_start", 0)))
	GameManager.show_message("%s started — hit every checkpoint." % definition["title"])
	return OK


func cancel() -> void:
	if runtime and runtime.active:
		runtime.abandon()
	elif _pending_confirmation:
		_pending_confirmation = false
		_spawn_start_marker()


func _process(delta: float) -> void:
	if runtime == null or not runtime.active:
		return
	runtime.tick(delta)
	var seconds := int(ceil(runtime.elapsed))
	if seconds != _status_second:
		_status_second = seconds
		_emit_status()


func _unhandled_input(event: InputEvent) -> void:
	if _pending_confirmation and (
		event.is_action_pressed("interact") or event.is_action_pressed("dialogue_advance")
	):
		confirm_start()
		get_viewport().set_input_as_handled()
	elif _pending_confirmation and event.is_action_pressed("dialogue_skip"):
		cancel()
		get_viewport().set_input_as_handled()
	elif runtime and runtime.active and event.is_action_pressed("dialogue_skip"):
		cancel()
		get_viewport().set_input_as_handled()


func _spawn_start_marker() -> void:
	_clear_marker()
	if player == null:
		return
	_marker = JobMarkerScript.new()
	world.add_child(_marker)
	_marker.setup(
		_array_to_vector(definition.get("start_position", [0.0, 0.0, 0.0])),
		float(definition.get("start_radius", 10.0)),
		Color(0.3, 0.75, 1.0) if str(definition["mode"]) == "boat" else Color(0.8, 0.45, 1.0),
		player
	)
	_marker.reached.connect(_request_start_confirmation)
	activity_changed.emit(str(definition["id"]), false, "%s start" % definition["title"])


func _request_start_confirmation() -> void:
	_pending_confirmation = true
	_clear_marker()
	start_confirmation_requested.emit(str(definition["id"]), str(definition["title"]))
	GameManager.show_message("Press USE to start %s · X to cancel" % definition["title"])


func _spawn_checkpoint_marker() -> void:
	_clear_marker()
	if runtime == null or not runtime.active:
		return
	var checkpoint := runtime.current_checkpoint()
	_marker = JobMarkerScript.new()
	world.add_child(_marker)
	_marker.setup(
		_array_to_vector(checkpoint["position"]),
		float(checkpoint["radius"]),
		Color(0.25, 0.85, 1.0) if str(definition["mode"]) == "boat" else Color(0.85, 0.35, 1.0),
		player
	)
	_marker.reached.connect(_on_marker_reached)
	_emit_status()


func _on_marker_reached() -> void:
	if runtime == null or not runtime.active:
		return
	var checkpoint_id := runtime.current_checkpoint_id()
	if runtime.reach_checkpoint(checkpoint_id) == OK and str(definition["mode"]) == "boat":
		_add_heat(int(definition.get("heat_per_checkpoint", 0)))


func _on_checkpoint_changed(_activity_id: String, _checkpoint_id: String, _index: int) -> void:
	if not _initialized:
		return
	call_deferred("_spawn_checkpoint_marker")
	_save_activity()


func _on_completed(activity_id: String, finish_time: float, reward: int) -> void:
	_clear_marker()
	if reward > 0:
		GameManager.add_cash_silent(reward)
	_save_activity()
	GameManager.save_game()
	GameManager.show_message(
		"%s complete — %.1fs%s" % [
			definition["title"],
			finish_time,
			" · +$%d" % reward if reward > 0 else "",
		]
	)
	activity_changed.emit(activity_id, false, "Best %.1fs" % runtime.best_time)
	call_deferred("_spawn_start_marker")


func _on_failed(activity_id: String, reason: String) -> void:
	_clear_marker()
	_save_activity()
	GameManager.save_game()
	GameManager.show_message("%s failed: %s" % [definition["title"], reason])
	activity_changed.emit(activity_id, false, "%s failed" % definition["title"])
	call_deferred("_spawn_start_marker")


func _emit_status() -> void:
	if runtime == null or not runtime.active:
		return
	activity_changed.emit(
		str(definition["id"]),
		true,
		"%s · CP %d/%d · %.1fs" % [
			definition["title"],
			runtime.checkpoint_index + 1,
			definition["checkpoints"].size(),
			runtime.elapsed,
		]
	)


func _activity_vehicle() -> Node:
	if player == null:
		return null
	if str(definition["mode"]) == "boat":
		if bool(player.get("_boating")) and player.get("current_boat") != null:
			return player.get("current_boat")
		return null
	if bool(player.get("_driving")) and player.get("current_car") != null:
		return player.get("current_car")
	return null


func _place_vehicle_at_start(vehicle: Node) -> void:
	var start := _array_to_vector(definition["start_position"])
	var heading := float(definition.get("start_yaw", 0.0))
	if vehicle.has_method("place_at"):
		vehicle.place_at(start, heading)


func _add_heat(amount: int) -> void:
	if amount <= 0:
		return
	if world and world.has_method("get_wanted_system"):
		var wanted: Node = world.get_wanted_system()
		if wanted and wanted.has_method("add_heat"):
			wanted.add_heat(amount)
			return
	if GameManager:
		GameManager.set_wanted(GameManager.wanted_level + amount)


func _save_activity() -> void:
	if GameManager and runtime:
		GameManager.activity_state[str(definition["id"])] = runtime.snapshot()


func _clear_marker() -> void:
	if _marker and is_instance_valid(_marker):
		_marker.queue_free()
	_marker = null


func _read_definition(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return {}
	return parser.data


func _array_to_vector(raw: Variant) -> Vector3:
	if raw is Array and raw.size() == 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.ZERO
