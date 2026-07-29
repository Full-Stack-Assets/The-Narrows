extends Node3D
class_name Boat

signal boarded
signal exited

const MAX_SPEED := 18.0
const ACCELERATION := 8.0
const TURN_RATE := 1.25

var mission_entity_id := "activity_boat"
var active: bool = false
var driver: Node = null
var speed: float = 0.0
var _heading: float = 0.0
var _visual: Node3D = null
var _camera: Camera3D = null
var _wake: GPUParticles3D = null
var _last_safe_water: Vector3
var _has_water_channel: bool = false


func _ready() -> void:
	_last_safe_water = global_position
	_build_visuals()


func enter(p_driver: Node) -> void:
	driver = p_driver
	active = true
	if _camera:
		_camera.make_current()
	boarded.emit()


func exit() -> Vector3:
	active = false
	driver = null
	speed = 0.0
	if _wake:
		_wake.emitting = false
	exited.emit()
	return global_position + global_basis.x * 2.8 + Vector3.UP * 0.6


func place_at(position: Vector3, heading_degrees: float = 0.0) -> void:
	global_position = position
	_heading = deg_to_rad(heading_degrees)
	rotation.y = _heading
	speed = 0.0
	_last_safe_water = position
	_has_water_channel = WaterZones.is_blocked(position.x, position.z)


func recover_safe() -> void:
	global_position = _last_safe_water
	speed = 0.0


func get_heading() -> float:
	return _heading


func _physics_process(delta: float) -> void:
	if active:
		var throttle := Input.get_axis("move_back", "move_forward")
		var steer := Input.get_axis("move_left", "move_right")
		speed = move_toward(speed, throttle * MAX_SPEED, ACCELERATION * delta)
		var steer_strength := clampf(absf(speed) / MAX_SPEED, 0.25, 1.0)
		_heading -= steer * TURN_RATE * steer_strength * delta
		rotation.y = _heading
		var forward := -global_basis.z
		global_position += forward * speed * delta
		if WaterZones.is_blocked(global_position.x, global_position.z):
			_last_safe_water = global_position
			_has_water_channel = true
		elif _has_water_channel and global_position.distance_to(_last_safe_water) > 80.0:
			recover_safe()
			if GameManager:
				GameManager.show_message("Boat returned to the marked channel.")
	else:
		speed = move_toward(speed, 0.0, ACCELERATION * 0.35 * delta)
	if _visual:
		_visual.position.y = sin(Time.get_ticks_msec() * 0.0025) * 0.14
		_visual.rotation.z = sin(Time.get_ticks_msec() * 0.0017) * 0.025
	if _wake:
		_wake.emitting = active and absf(speed) > 1.5


func _build_visuals() -> void:
	_visual = Node3D.new()
	_visual.name = "BoatVisual"
	add_child(_visual)

	var hull := MeshInstance3D.new()
	var hull_mesh := BoxMesh.new()
	hull_mesh.size = Vector3(2.6, 0.8, 6.4)
	hull.mesh = hull_mesh
	hull.position.y = 0.35
	var hull_material := StandardMaterial3D.new()
	hull_material.albedo_color = Color(0.82, 0.84, 0.8)
	hull_material.metallic = 0.15
	hull_material.roughness = 0.42
	hull.material_override = hull_material
	_visual.add_child(hull)

	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.8, 1.1, 2.1)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 1.15, 0.4)
	var cabin_material := StandardMaterial3D.new()
	cabin_material.albedo_color = Color(0.15, 0.31, 0.38)
	cabin_material.metallic = 0.25
	cabin.material_override = cabin_material
	_visual.add_child(cabin)

	_camera = Camera3D.new()
	_camera.position = Vector3(0, 4.4, 9.0)
	_camera.rotation_degrees.x = -16.0
	add_child(_camera)

	_wake = GPUParticles3D.new()
	_wake.amount = 36
	_wake.lifetime = 1.4
	_wake.position = Vector3(0, 0.05, 3.0)
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0, 0.15, 1)
	process.spread = 24.0
	process.initial_velocity_min = 1.5
	process.initial_velocity_max = 3.5
	process.gravity = Vector3(0, -0.2, 0)
	process.scale_min = 0.15
	process.scale_max = 0.45
	_wake.process_material = process
	var foam := QuadMesh.new()
	foam.size = Vector2(0.55, 0.55)
	var foam_material := StandardMaterial3D.new()
	foam_material.albedo_color = Color(0.8, 0.92, 1.0, 0.55)
	foam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam.material = foam_material
	_wake.draw_pass_1 = foam
	add_child(_wake)
