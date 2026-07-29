extends CharacterBody3D

enum PedestrianState {
    IDLE,
    WALK,
    FLEE,
    COWER,
    CONVERSE,
    VEHICLE_DODGE,
}

@export var walk_speed: float = 1.5
@export var gravity: float = 20.0

var model_path: String = ""
var lib_path: String = ""
var waypoints: PackedVector3Array = PackedVector3Array()

var mesh_root: Node3D
var anim_player: AnimationPlayer
var anim_tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback

const FAR_DIST: float = 200.0       # respawn near the player past this range

const RUN_SPEED: float = 4.6        # flee speed when panicking
const PANIC_RADIUS: float = 26.0    # hear gunfire within this range

var player: Node3D = null
var _target: Vector3 = Vector3.ZERO
var _idle_timer: float = 0.0
var _has_target: bool = false
var _flee_timer: float = 0.0
var _flee_dir: Vector3 = Vector3.ZERO
var _state: PedestrianState = PedestrianState.IDLE
var _state_timer: float = 0.0
var _behavior_timer: float = 0.0
var _dodge_dir: Vector3 = Vector3.ZERO


# Called when the player fires nearby: bolt away from the shot for a few seconds.
func panic(from: Vector3) -> void :
    if global_position.distance_to(from) > PANIC_RADIUS:
        return
    var away: Vector3 = global_position - from
    away.y = 0.0
    if away.length() < 0.1:
        away = Vector3(randf() - 0.5, 0.0, randf() - 0.5)
    _flee_dir = away.normalized()
    _flee_timer = randf_range(2.5, 4.5)
    if global_position.distance_to(from) < 9.0:
        _set_state(PedestrianState.COWER, 1.0)
    else:
        _set_state(PedestrianState.FLEE, _flee_timer)


func state_name() -> String:
    return PedestrianState.keys()[_state].to_lower()


func begin_conversation(duration: float = 2.6) -> void:
    if _state in [PedestrianState.FLEE, PedestrianState.COWER, PedestrianState.VEHICLE_DODGE]:
        return
    _set_state(PedestrianState.CONVERSE, duration)


func setup(p_model: String, p_lib: String, p_waypoints: PackedVector3Array) -> void :
    model_path = p_model
    lib_path = p_lib
    waypoints = p_waypoints


func _ready() -> void :
    add_to_group("civic_pedestrian")
    collision_layer = 4
    collision_mask = 1

    var col: = CollisionShape3D.new()
    var capsule: = CapsuleShape3D.new()
    capsule.height = 1.7
    capsule.radius = 0.32
    col.shape = capsule
    col.position.y = 0.85
    add_child(col)

    mesh_root = Node3D.new()
    mesh_root.name = "CharacterMesh"
    add_child(mesh_root)

    if model_path != "":
        var scene: = load(model_path) as PackedScene
        if scene:
            var model: = scene.instantiate()
            mesh_root.add_child(model)
            ModelUtils.setup_character_for_movement(model, 1.72)
            var meshes: Array = model.find_children("*", "MeshInstance3D", true)
            if meshes.size() > 0:
                var first: = meshes[0] as MeshInstance3D
                if first and not ModelUtils.has_vertex_normals(first):
                    ModelUtils.generate_normals_for_all(model)
            anim_player = AnimationPlayer.new()
            anim_player.name = "AnimationPlayer"
            model.add_child(anim_player)
            var lib: = load(lib_path) as AnimationLibrary
            if lib:
                anim_player.add_animation_library("", lib)
                ModelUtils.set_animation_loops(anim_player)
                _setup_anim_tree()
            var clamp: = GroundClampNode.new()
            clamp.target_node = self
            clamp.character_mesh = mesh_root
            add_child(clamp)

    _idle_timer = randf_range(0.5, 2.0)
    _pick_target()


func _setup_anim_tree() -> void :
    var sm: = AnimationNodeStateMachine.new()
    for state in [["idle", "ual1_Idle"], ["walk", "ual1_Walk"]]:
        var node: = AnimationNodeAnimation.new()
        node.animation = state[1]
        sm.add_node(state[0], node)
    for pair in [["idle", "walk"], ["walk", "idle"]]:
        var t: = AnimationNodeStateMachineTransition.new()
        t.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
        t.xfade_time = 0.2
        sm.add_transition(pair[0], pair[1], t)
    anim_tree = AnimationTree.new()
    anim_tree.anim_player = anim_player.get_path()
    anim_tree.tree_root = sm
    add_child(anim_tree)
    anim_tree.active = true
    _playback = anim_tree["parameters/playback"]


func _pick_target() -> void :
    if waypoints.size() == 0:
        _has_target = false
        return
    if player != null and is_instance_valid(player):
        var here: = player.global_position
        for _i in range(8):
            var cand: Vector3 = waypoints[randi() % waypoints.size()]
            var d: float = here.distance_to(cand)
            if d > 10.0 and d < 160.0:
                _target = cand
                _has_target = true
                return
    _target = waypoints[randi() % waypoints.size()]
    _has_target = true


func _respawn_near_player() -> void :
    if player == null or not is_instance_valid(player) or waypoints.size() == 0:
        return
    var here: = player.global_position
    for _i in range(12):
        var cand: Vector3 = waypoints[randi() % waypoints.size()]
        var d: float = here.distance_to(cand)
        if d > 40.0 and d < 160.0 and not _is_position_visible(cand):
            global_position = Vector3(cand.x, 0.6, cand.z)
            velocity = Vector3.ZERO
            _pick_target()
            return


func _is_position_visible(position: Vector3) -> bool:
    var camera := get_viewport().get_camera_3d()
    return camera != null and camera.is_position_in_frustum(position + Vector3.UP)


func _set_state(next: PedestrianState, duration: float = 0.0) -> void:
    _state = next
    _state_timer = maxf(duration, 0.0)


func _behavior_interval() -> float:
    var quality: int = GameManager.graphics_quality if GameManager else 1
    var quality_rate: float = [0.34, 0.2, 0.12][clampi(quality, 0, 2)]
    if player == null or not is_instance_valid(player):
        return quality_rate * 2.0
    var distance := global_position.distance_to(player.global_position)
    return quality_rate * clampf(distance / 35.0, 1.0, 4.0)


func _vehicle_dodge_direction() -> Vector3:
    for vehicle in get_tree().get_nodes_in_group("traffic_vehicle"):
        if not is_instance_valid(vehicle) or not vehicle is Node3D:
            continue
        var away: Vector3 = global_position - (vehicle as Node3D).global_position
        away.y = 0.0
        if away.length() > 7.0:
            continue
        var vehicle_velocity: Vector3 = vehicle.velocity if "velocity" in vehicle else Vector3.ZERO
        if vehicle_velocity.length() < 1.5:
            continue
        var side := Vector3(-vehicle_velocity.z, 0.0, vehicle_velocity.x).normalized()
        if side.dot(away) < 0.0:
            side = -side
        return side
    return Vector3.ZERO


func _consider_social_behavior() -> void:
    if _state != PedestrianState.IDLE or randf() > 0.08:
        return
    for other in get_tree().get_nodes_in_group("civic_pedestrian"):
        if other == self or not is_instance_valid(other) or not other is Node3D:
            continue
        if global_position.distance_to((other as Node3D).global_position) <= 3.0:
            begin_conversation()
            if other.has_method("begin_conversation"):
                other.begin_conversation()
            return


func _update_behavior(delta: float) -> void:
    _behavior_timer -= delta
    if _behavior_timer > 0.0:
        return
    _behavior_timer = _behavior_interval()
    if _state not in [PedestrianState.FLEE, PedestrianState.COWER]:
        var dodge := _vehicle_dodge_direction()
        if dodge != Vector3.ZERO:
            _dodge_dir = dodge
            _set_state(PedestrianState.VEHICLE_DODGE, 0.8)
            return
    _consider_social_behavior()


func _physics_process(delta: float) -> void :
    if player != null and is_instance_valid(player):
        if global_position.distance_to(player.global_position) > FAR_DIST:
            _respawn_near_player()

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    _update_behavior(delta)
    _state_timer = maxf(0.0, _state_timer - delta)

    var moving: = false
    if _state == PedestrianState.COWER:
        velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
        if _state_timer <= 0.0:
            _set_state(PedestrianState.FLEE, _flee_timer)
    elif _state == PedestrianState.FLEE:
        _flee_timer = maxf(0.0, _flee_timer - delta)
        velocity.x = _flee_dir.x * RUN_SPEED
        velocity.z = _flee_dir.z * RUN_SPEED
        if mesh_root:
            mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, atan2( - _flee_dir.x, - _flee_dir.z), 10.0 * delta)
        moving = true
        if _flee_timer <= 0.0:
            _idle_timer = randf_range(1.0, 2.5)
            _set_state(PedestrianState.IDLE)
    elif _state == PedestrianState.VEHICLE_DODGE:
        velocity.x = _dodge_dir.x * RUN_SPEED
        velocity.z = _dodge_dir.z * RUN_SPEED
        if mesh_root:
            mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, atan2( - _dodge_dir.x, - _dodge_dir.z), 12.0 * delta)
        moving = true
        if _state_timer <= 0.0:
            _set_state(PedestrianState.WALK)
    elif _state == PedestrianState.CONVERSE:
        velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
        if _state_timer <= 0.0:
            _idle_timer = randf_range(0.5, 1.5)
            _set_state(PedestrianState.IDLE)
    elif _idle_timer > 0.0:
        _set_state(PedestrianState.IDLE)
        _idle_timer -= delta
        velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
    elif _has_target:
        var to_target: = _target - global_position
        to_target.y = 0.0
        if to_target.length() < 1.0:
            _idle_timer = randf_range(1.5, 4.0)
            _pick_target()
        else:
            _set_state(PedestrianState.WALK)
            var dir: = to_target.normalized()
            velocity.x = dir.x * walk_speed
            velocity.z = dir.z * walk_speed
            mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, atan2( - dir.x, - dir.z), 8.0 * delta)
            moving = true
    else:
        _pick_target()
        _set_state(PedestrianState.WALK if _has_target else PedestrianState.IDLE)

    move_and_slide()

    if _playback:
        _playback.travel("walk" if moving and velocity.length() > 0.3 else "idle")
