extends Node
class_name EncounterDirector

signal encounter_completed(encounter_id: String)
signal encounter_failed(encounter_id: String, reason: String)

const EncounterEnemyScript := preload("res://scripts/missions/encounter_enemy.gd")
const PIER_AMBUSH_SPECS: Array[Dictionary] = [
	{"role": "melee", "offset": Vector3(-7.0, 0.6, -4.0)},
	{"role": "melee", "offset": Vector3(6.0, 0.6, -5.0)},
	{"role": "ranged", "offset": Vector3(0.0, 0.6, -13.0)},
]

var player: Node3D = null
var assigned_car: Node = null
var encounter_center: Vector3 = Vector3.ZERO
var boundary_radius: float = 42.0
var boundary_timeout: float = 15.0
var _outside_time: float = 0.0
var _active_id: String = ""
var _actors: Array[Node] = []
var _completed: Dictionary = {}
var _actor_factory: Callable


func configure(
	p_player: Node3D = null,
	p_assigned_car: Node = null,
	p_actor_factory: Callable = Callable()
) -> void:
	player = p_player
	assigned_car = p_assigned_car
	_actor_factory = p_actor_factory
	if (
		assigned_car
		and assigned_car.has_signal("destroyed")
		and not assigned_car.destroyed.is_connected(_on_assigned_car_destroyed)
	):
		assigned_car.destroyed.connect(_on_assigned_car_destroyed)


func start(encounter_id: String) -> bool:
	if encounter_id != "pier_ambush" or _completed.has(encounter_id) or _active_id == encounter_id:
		return false
	_remove_active_actors()
	_active_id = encounter_id
	_outside_time = 0.0
	for spec in PIER_AMBUSH_SPECS:
		var actor: Node = _actor_factory.call(spec) if _actor_factory.is_valid() else EncounterEnemyScript.new()
		if actor == null:
			continue
		if actor.has_method("configure"):
			actor.configure(encounter_id, str(spec["role"]), player)
		elif "role" in actor:
			actor.role = str(spec["role"])
		if "encounter_id" in actor:
			actor.encounter_id = encounter_id
		add_child(actor)
		if actor is Node3D:
			if is_inside_tree():
				(actor as Node3D).global_position = encounter_center + Vector3(spec["offset"])
			else:
				(actor as Node3D).position = encounter_center + Vector3(spec["offset"])
		if actor.has_signal("defeated"):
			actor.defeated.connect(_on_actor_defeated)
		_actors.append(actor)
	return _actors.size() == PIER_AMBUSH_SPECS.size()


func reset(encounter_id: String) -> bool:
	if encounter_id != "pier_ambush":
		return false
	_remove_active_actors()
	_restore_failure_state()
	_completed.erase(encounter_id)
	_active_id = ""
	return start(encounter_id)


func active_actor_count() -> int:
	return _actors.size()


func active_roles() -> Array[String]:
	var roles: Array[String] = []
	for actor in _actors:
		roles.append(str(actor.role) if "role" in actor else "")
	return roles


func defeat_all_for_test() -> void:
	for actor in _actors.duplicate():
		if is_instance_valid(actor) and actor.has_method("defeat_for_test"):
			actor.defeat_for_test()


func _process(delta: float) -> void:
	if _active_id.is_empty() or player == null or not is_instance_valid(player):
		return
	var planar := player.global_position - encounter_center
	planar.y = 0.0
	if planar.length() <= boundary_radius:
		_outside_time = 0.0
		return
	_outside_time += delta
	if _outside_time >= boundary_timeout:
		_fail("left_ambush_boundary")


func _on_actor_defeated(actor: Node) -> void:
	_actors.erase(actor)
	if _actors.is_empty() and not _active_id.is_empty():
		var completed_id := _active_id
		_completed[completed_id] = true
		_active_id = ""
		encounter_completed.emit(completed_id)


func _on_assigned_car_destroyed() -> void:
	if not _active_id.is_empty():
		_fail("assigned_car_destroyed")


func notify_player_wasted() -> void:
	if not _active_id.is_empty():
		_fail("wasted")


func _fail(reason: String) -> void:
	var failed_id := _active_id
	_remove_active_actors()
	_restore_failure_state()
	_active_id = ""
	encounter_failed.emit(failed_id, reason)


func _restore_failure_state() -> void:
	if player and player.has_method("heal_full"):
		player.heal_full()
	if assigned_car and "body_damage" in assigned_car:
		assigned_car.body_damage = 0.0
	if assigned_car and "_destroyed_emitted" in assigned_car:
		assigned_car._destroyed_emitted = false
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.set_wanted(0)
		game_manager.set_faction(0)


func _remove_active_actors() -> void:
	for actor in _actors:
		if is_instance_valid(actor):
			actor.free()
	_actors.clear()
