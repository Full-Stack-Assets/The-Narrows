extends CharacterBody3D
class_name TrafficCar

# Lightweight ambient traffic: a kinematic car that cruises between road-derived
# waypoints, orienting to its travel direction. Not drivable (that's car.gd) —
# this exists purely to make the streets feel alive, mirroring the web build's
# ambient traffic. Collides with buildings/player via move_and_slide.

const MODEL_YAW_DEG: = {
    "res://assets/props/vehicles/sedan.glb": -90.0,
    "res://assets/props/vehicles/taxi.glb": 180.0,
    "res://assets/props/vehicles/suv.glb": 0.0,
}

const GRAVITY: float = 18.0
const ARRIVE_DIST: float = 3.0
const TURN_RATE: float = 6.0       # rad/s yaw smoothing toward travel heading

var model_path: String = "res://assets/props/vehicles/sedan.glb"
var model_height: float = 1.5
var speed: float = 8.0
var base_speed: float = 8.0
var waypoints: PackedVector3Array = PackedVector3Array()

const FAR_DIST: float = 240.0       # respawn near the player past this range

var player: Node3D = null
var mesh_root: Node3D
var _target: Vector3 = Vector3.ZERO
var _has_target: bool = false
var _yaw: float = 0.0
var _light_meshes: Array[MeshInstance3D] = []
var stop_timer: float = 0.0
var carjacked: bool = false
var _stall_timer: float = 0.0
var _last_progress_position: Vector3 = Vector3.ZERO
var _replanned_for_stall: bool = false

const BLOCKER_LOOKAHEAD: float = 8.0
const STALL_REPLAN_TIME: float = 3.0
const STALL_RELOCATE_TIME: float = 7.0


func setup(p_path: String, p_height: float, p_speed: float, p_waypoints: PackedVector3Array) -> void :
    model_path = p_path
    model_height = p_height
    speed = p_speed
    base_speed = p_speed
    waypoints = p_waypoints


func _ready() -> void :
    add_to_group("traffic_vehicle")
    collision_layer = 4
    collision_mask = 1

    var col: = CollisionShape3D.new()
    var box: = BoxShape3D.new()
    box.size = Vector3(2.0, 1.4, 4.4)
    col.shape = box
    col.position.y = 0.7
    add_child(col)

    mesh_root = Node3D.new()
    mesh_root.name = "CarMesh"
    add_child(mesh_root)

    if model_path != "":
        var scene: = load(model_path) as PackedScene
        if scene:
            var model: = scene.instantiate()
            mesh_root.add_child(model)
            ModelUtils.scale_to_height(model, model_height)
            ModelUtils.ground_model(model, 0.0)
            if MODEL_YAW_DEG.has(model_path):
                model.rotation_degrees.y = MODEL_YAW_DEG[model_path]
            _add_running_lights(model)

    _pick_target()
    _last_progress_position = global_position


func _add_running_lights(model: Node3D) -> void :
    for side in [-1.0, 1.0]:
        var hm: = MeshInstance3D.new()
        var hb: = BoxMesh.new()
        hb.size = Vector3(0.18, 0.08, 0.03)
        hm.mesh = hb
        var m: = StandardMaterial3D.new()
        m.albedo_color = Color(0.98, 0.94, 0.78)
        m.emission_enabled = true
        m.emission = Color(1.0, 0.92, 0.65)
        m.emission_energy_multiplier = 0.15
        hm.material_override = m
        hm.position = Vector3(0.45 * side, model_height * 0.42, model_height * 0.28)
        model.add_child(hm)
        _light_meshes.append(hm)
    for side in [-1.0, 1.0]:
        var tm: = MeshInstance3D.new()
        var tb: = BoxMesh.new()
        tb.size = Vector3(0.16, 0.07, 0.03)
        tm.mesh = tb
        var tmat: = StandardMaterial3D.new()
        tmat.albedo_color = Color(0.65, 0.08, 0.08)
        tmat.emission_enabled = true
        tmat.emission = Color(0.9, 0.12, 0.1)
        tmat.emission_energy_multiplier = 0.12
        tm.material_override = tmat
        tm.position = Vector3(0.42 * side, model_height * 0.4, -model_height * 0.28)
        model.add_child(tm)
        _light_meshes.append(tm)


func update_running_lights(night: float) -> void :
    var e: float = 0.12 + night * 1.1
    for mi in _light_meshes:
        if is_instance_valid(mi) and mi.material_override is StandardMaterial3D:
            (mi.material_override as StandardMaterial3D).emission_energy_multiplier = e


func halt(duration: float = 1.6) -> void :
    stop_timer = maxf(stop_timer, duration)


func can_carjack() -> bool:
    return stop_timer > 0.0 and not carjacked


func _pick_target() -> void :
    if waypoints.size() == 0:
        _has_target = false
        return
    # Prefer a waypoint reasonably near the player so traffic stays where the
    # action is; fall back to a random one.
    if player != null and is_instance_valid(player):
        var here: = player.global_position
        for _i in range(8):
            var cand: Vector3 = waypoints[randi() % waypoints.size()]
            var d: float = here.distance_to(cand)
            if d > 30.0 and d < 200.0:
                _target = cand
                _has_target = true
                return
    _target = waypoints[randi() % waypoints.size()]
    _has_target = true


func _respawn_near_player() -> void :
    if player == null or not is_instance_valid(player) or waypoints.size() == 0:
        return
    if _is_position_visible(global_position):
        _pick_target()
        return
    var here: = player.global_position
    for _i in range(18):
        var cand: Vector3 = waypoints[randi() % waypoints.size()]
        var d: float = here.distance_to(cand)
        if d > 60.0 and d < 200.0 and not _is_position_visible(cand):
            global_position = Vector3(cand.x, 0.6, cand.z)
            velocity = Vector3.ZERO
            _stall_timer = 0.0
            _replanned_for_stall = false
            _last_progress_position = global_position
            _pick_target()
            return


func _is_position_visible(position: Vector3) -> bool:
    var camera := get_viewport().get_camera_3d()
    return camera != null and camera.is_position_in_frustum(position + Vector3.UP)


func _at_red_light(direction: Vector3) -> bool:
    var nearest_x := roundf(global_position.x / 80.0) * 80.0
    var nearest_z := roundf(global_position.z / 80.0) * 80.0
    var approaching_intersection := (
        absf(global_position.x - nearest_x) < 8.0
        and absf(global_position.z - nearest_z) < 8.0
    )
    if not approaching_intersection:
        return false
    var phase := int(Time.get_ticks_msec() / 6000) % 2
    var east_west := absf(direction.x) > absf(direction.z)
    return (east_west and phase == 0) or (not east_west and phase == 1)


func _blocker_ahead(direction: Vector3) -> bool:
    if direction.length_squared() < 0.01:
        return false
    if player and is_instance_valid(player):
        var to_player := player.global_position - global_position
        to_player.y = 0.0
        if to_player.length() < 9.0 and direction.dot(to_player.normalized()) > 0.25:
            return true
    var origin := global_position + Vector3(0.0, 0.8, 0.0)
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * BLOCKER_LOOKAHEAD)
    query.collision_mask = 1 | 2 | 4
    query.exclude = [get_rid()]
    return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _update_stall_recovery(delta: float, wants_motion: bool) -> void:
    var moved := global_position.distance_to(_last_progress_position)
    if not wants_motion or moved > 0.8:
        _stall_timer = 0.0
        _replanned_for_stall = false
        _last_progress_position = global_position
        return
    _stall_timer += delta
    if _stall_timer >= STALL_RELOCATE_TIME and not _is_position_visible(global_position):
        _respawn_near_player()
    elif _stall_timer >= STALL_REPLAN_TIME and not _replanned_for_stall:
        _pick_target()
        _replanned_for_stall = true


func _physics_process(delta: float) -> void :
    if carjacked:
        return
    stop_timer = maxf(0.0, stop_timer - delta)
    # Keep traffic near the player: if it drifts too far, hop to a road near you.
    if player != null and is_instance_valid(player):
        if global_position.distance_to(player.global_position) > FAR_DIST:
            _respawn_near_player()

    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = 0.0

    var wants_motion := false
    if _has_target:
        var to_target: Vector3 = _target - global_position
        to_target.y = 0.0
        var dist: float = to_target.length()
        var dir := to_target / dist if dist > 0.001 else Vector3.ZERO
        var red_light := _at_red_light(dir)
        var blocked := _blocker_ahead(dir)
        var yielding := red_light or blocked
        wants_motion = dist >= ARRIVE_DIST and stop_timer <= 0.0 and not red_light
        if stop_timer > 0.0 or yielding:
            velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
        elif dist < ARRIVE_DIST:
            _pick_target()
        else:
            velocity.x = dir.x * speed
            velocity.z = dir.z * speed
            var desired_yaw: float = atan2(dir.x, dir.z)
            _yaw = lerp_angle(_yaw, desired_yaw, clampf(TURN_RATE * delta, 0.0, 1.0))
            if mesh_root:
                mesh_root.rotation.y = _yaw
    else:
        velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

    move_and_slide()
    _update_stall_recovery(delta, wants_motion)
