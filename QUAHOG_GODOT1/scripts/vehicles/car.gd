extends Node3D
class_name Car

signal destroyed

var mission_entity_id: String = ""
var _destroyed_emitted: bool = false





var model_path: String = "res://assets/props/vehicles/sedan.glb"
var model_height: float = 1.5
var display_name: String = "Sedan"

# GLB exports don't share one forward axis: sedan length is on +X, taxi faces -Z.
const MODEL_YAW_DEG: = {
    "res://assets/props/vehicles/sedan.glb": -90.0,
    "res://assets/props/vehicles/taxi.glb": 180.0,
    "res://assets/props/vehicles/suv.glb": 0.0,
}


var sphere: RigidBody3D
var raycast: RayCast3D
var vehicle_model: Node3D
var camera: Camera3D
var engine_ambient: AudioStreamPlayer3D
var screech_sound: AudioStreamPlayer3D
var _head_l: SpotLight3D
var _head_r: SpotLight3D
var _tail_l: OmniLight3D
var _tail_r: OmniLight3D
var _light_meshes: Array[MeshInstance3D] = []


var active: bool = false
var _steer: float = 0.0
var _throttle: float = 0.0
var handbrake_on: bool = false


func set_handbrake(on: bool) -> void :
    handbrake_on = on


func honk() -> void :
    if AudioManager:
        AudioManager.play_horn()

var input: Vector3 = Vector3.ZERO
var normal: Vector3 = Vector3.UP
var acceleration: float = 0.0
var angular_speed: float = 0.0
var linear_speed: float = 0.0
var colliding: bool = false
var linear_velocity: Vector3 = Vector3.ZERO
var prev_position: Vector3 = Vector3.ZERO


var max_throttle: float = 65.0
var torque: float = 220.0
var mass: float = 1000.0
var body_damage: float = 0.0

const MAX_BODY_DAMAGE: float = 100.0
var _impact_cd: float = 0.0
var _smoke_t: float = 0.0
var _near_miss_cd: float = 0.0
var _skid_t: float = 0.0
var _last_skid_l: Vector3 = Vector3.ZERO
var _last_skid_r: Vector3 = Vector3.ZERO
var _skid_marks: Array = []


func _ready() -> void :

    raycast = RayCast3D.new()
    raycast.name = "Ground"
    raycast.target_position = Vector3(0, -1.0, 0)
    raycast.position = Vector3(0, 0.5, 0)
    add_child(raycast)


    vehicle_model = Node3D.new()
    vehicle_model.name = "Container"
    add_child(vehicle_model)

    var scene: = load(model_path) as PackedScene
    if scene:
        var model: = scene.instantiate()
        model.name = "Model"
        vehicle_model.add_child(model)
        ModelUtils.scale_to_height(model, model_height)
        ModelUtils.ground_model(model, 0.0)
        if MODEL_YAW_DEG.has(model_path):
            model.rotation_degrees.y = MODEL_YAW_DEG[model_path]


    sphere = RigidBody3D.new()
    sphere.name = "Sphere"
    sphere.mass = mass
    sphere.gravity_scale = 1.5
    sphere.linear_damp = 0.2
    sphere.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
    sphere.angular_damp = 4.0
    sphere.continuous_cd = true
    sphere.contact_monitor = true
    sphere.max_contacts_reported = 2
    sphere.collision_layer = 1
    sphere.collision_mask = 1 | 4   # world geometry + ambient traffic
    var pm: = PhysicsMaterial.new()
    pm.friction = 4.0
    pm.rough = true
    sphere.physics_material_override = pm
    sphere.position = Vector3(0, 0.5, 0)
    var scol: = CollisionShape3D.new()
    var ssh: = SphereShape3D.new()
    ssh.radius = 0.5
    scol.shape = ssh
    sphere.add_child(scol)
    add_child(sphere)
    sphere.body_entered.connect(_on_body_entered)

    prev_position = vehicle_model.position

    set_physics_process(true)
    _set_dormant(true)   # parked cars are frozen + skip _drive until entered, so
                         # the map can be full of takeable cars at near-zero cost


# Camera + quiet cabin audio are created lazily on first entry.
func _ensure_cabin() -> void :
    if camera == null:
        camera = Camera3D.new()
        camera.name = "CarCamera"
        camera.fov = 64.0
        camera.far = 400.0
        add_child(camera)
        camera.top_level = true
    if engine_ambient == null:
        engine_ambient = AudioStreamPlayer3D.new()
        engine_ambient.name = "EngineAmbient"
        engine_ambient.stream = load("res://assets/audio/sfx/vehicle/vehicle_engine_ambient.mp3")
        engine_ambient.unit_size = 12.0
        engine_ambient.max_db = -6.0
        engine_ambient.volume_db = -42.0
        engine_ambient.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
        if engine_ambient.stream is AudioStreamMP3:
            (engine_ambient.stream as AudioStreamMP3).loop = true
        vehicle_model.add_child(engine_ambient)
    if screech_sound == null:
        screech_sound = AudioStreamPlayer3D.new()
        screech_sound.name = "ScreechSound"
        screech_sound.stream = load("res://assets/audio/sfx/vehicle/vehicle_tire_screech.mp3")
        screech_sound.volume_db = -4.0
        screech_sound.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
        if screech_sound.stream is AudioStreamMP3:
            (screech_sound.stream as AudioStreamMP3).loop = true
        vehicle_model.add_child(screech_sound)
    _ensure_lights()


func _ensure_lights() -> void :
    if _head_l != null:
        return
    for side in [-1.0, 1.0]:
        var spot: = SpotLight3D.new()
        spot.light_color = Color(1.0, 0.94, 0.78)
        spot.spot_range = 28.0
        spot.spot_angle = 38.0
        spot.light_energy = 0.0
        spot.shadow_enabled = false
        spot.position = Vector3(0.55 * side, 0.35, 1.05)
        spot.rotation.y = PI
        vehicle_model.add_child(spot)
        if side < 0.0:
            _head_l = spot
        else:
            _head_r = spot
        var hm: = MeshInstance3D.new()
        var hb: = BoxMesh.new()
        hb.size = Vector3(0.22, 0.1, 0.04)
        hm.mesh = hb
        var m: = StandardMaterial3D.new()
        m.albedo_color = Color(0.98, 0.94, 0.78)
        m.emission_enabled = true
        m.emission = Color(1.0, 0.92, 0.65)
        m.emission_energy_multiplier = 0.2
        hm.material_override = m
        hm.position = Vector3(0.55 * side, 0.35, 1.08)
        vehicle_model.add_child(hm)
        _light_meshes.append(hm)
    for side in [-1.0, 1.0]:
        var tail: = OmniLight3D.new()
        tail.light_color = Color(1.0, 0.15, 0.1)
        tail.omni_range = 4.5
        tail.light_energy = 0.0
        tail.position = Vector3(0.5 * side, 0.32, -1.05)
        vehicle_model.add_child(tail)
        if side < 0.0:
            _tail_l = tail
        else:
            _tail_r = tail
        var tm: = MeshInstance3D.new()
        var tb: = BoxMesh.new()
        tb.size = Vector3(0.2, 0.08, 0.04)
        tm.mesh = tb
        var tmat: = StandardMaterial3D.new()
        tmat.albedo_color = Color(0.65, 0.08, 0.08)
        tmat.emission_enabled = true
        tmat.emission = Color(0.9, 0.12, 0.1)
        tmat.emission_energy_multiplier = 0.2
        tm.material_override = tmat
        tm.position = Vector3(0.5 * side, 0.32, -1.08)
        vehicle_model.add_child(tm)
        _light_meshes.append(tm)


# Head/taillight energy from day_phase (0=day, 1=night). Braking flares tails.
func update_vehicle_lights(night: float, braking: bool = false) -> void :
    _ensure_lights()
    var head_e: float = 0.15 + night * 2.4
    var tail_e: float = 0.1 + night * 0.9 + (1.8 if braking else 0.0)
    if _head_l:
        _head_l.light_energy = head_e
    if _head_r:
        _head_r.light_energy = head_e
    if _tail_l:
        _tail_l.light_energy = tail_e
    if _tail_r:
        _tail_r.light_energy = tail_e
    var mesh_e: float = 0.2 + night * 1.4 + (0.8 if braking else 0.0)
    for mi in _light_meshes:
        if is_instance_valid(mi) and mi.material_override is StandardMaterial3D:
            (mi.material_override as StandardMaterial3D).emission_energy_multiplier = mesh_e


# A parked car freezes its physics body and stops per-frame driving; entering
# wakes it. Lets us scatter many drivable cars without paying for them all.
func _set_dormant(d: bool) -> void :
    if sphere:
        sphere.freeze = d
    set_physics_process(not d)


func place_at(pos: Vector3, yaw_deg: float) -> void :

    global_position = pos
    if sphere:
        sphere.global_position = pos + Vector3(0, 0.5, 0)
        sphere.linear_velocity = Vector3.ZERO
        sphere.angular_velocity = Vector3.ZERO
    if vehicle_model:
        vehicle_model.global_position = pos
        vehicle_model.rotation.y = deg_to_rad(yaw_deg)
        prev_position = vehicle_model.position
    linear_velocity = Vector3.ZERO
    # Park it: clear the drive integrator too, or _drive() keeps applying the
    # retained speed/turn and the car rolls away from where it was placed.
    linear_speed = 0.0
    angular_speed = 0.0
    acceleration = 0.0
    _throttle = 0.0
    _steer = 0.0
    body_damage = 0.0
    _destroyed_emitted = false
    if active:
        _snap_camera()


func enter(_driver: Node) -> void :
    active = true
    _ensure_cabin()       # build camera + audio on first entry
    _set_dormant(false)   # wake the physics body
    _snap_camera()
    if camera:
        camera.make_current()
    if engine_ambient and not engine_ambient.playing:
        engine_ambient.play()
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/vehicle/vehicle_car_enter.mp3")
        if snd:
            AudioManager.play_sfx(snd, -6.0)


func exit() -> Vector3:
    active = false
    _steer = 0.0
    _throttle = 0.0
    if engine_ambient:
        engine_ambient.stop()
    if screech_sound:
        screech_sound.stop()

    var right: Vector3 = vehicle_model.global_basis.x.normalized()
    var out_pos: = vehicle_model.global_position + right * 2.4 + Vector3(0, 0.6, 0)
    _set_dormant(true)   # re-park: stop paying physics for the car we just left
    return out_pos


func set_drive_input(steer: float, throttle: float) -> void :
    _steer = clampf(steer, -1.0, 1.0)
    _throttle = clampf(throttle, -1.0, 1.0)


func get_speed_kmh() -> float:
    return linear_velocity.length() * 3.6   # m/s -> km/h


func get_damage_percent() -> float:
    return clampf(body_damage / MAX_BODY_DAMAGE, 0.0, 1.0)


# Seconds the car has been on its side/roof; used to auto-right it.
var _flip_t: float = 0.0


func _physics_process(delta: float) -> void :
    _impact_cd = maxf(0.0, _impact_cd - delta)
    _drive(delta)
    _recover_if_flipped(delta)
    _update_skid_marks(delta)
    if active:
        _update_camera(delta)


# If the car ends up on its roof/side for more than a moment, flip it upright in
# place so the player is never stranded (keeps yaw, clears spin).
func _recover_if_flipped(delta: float) -> void :
    if not is_instance_valid(vehicle_model) or not is_instance_valid(sphere):
        return
    if vehicle_model.global_basis.y.dot(Vector3.UP) < 0.25:
        _flip_t += delta
    else:
        _flip_t = 0.0
    if _flip_t > 1.5:
        _flip_t = 0.0
        var yaw: float = vehicle_model.rotation.y
        vehicle_model.global_position += Vector3(0, 1.0, 0)
        vehicle_model.rotation = Vector3(0, yaw, 0)
        sphere.global_position = vehicle_model.global_position + Vector3(0, 0.5, 0)
        sphere.linear_velocity = Vector3.ZERO
        sphere.angular_velocity = Vector3.ZERO
        linear_speed = 0.0
        angular_speed = 0.0


func _drive(delta: float) -> void :
    if not is_instance_valid(sphere):
        return
    var grounded: bool = raycast.is_colliding()

    input.x = _steer if (active and grounded) else 0.0
    input.z = (_throttle * max_throttle) if (active and grounded) else 0.0
    var dmg_factor: float = 1.0 - get_damage_percent() * 0.35
    input.z *= dmg_factor
    if GameManager and GameManager.cheat_car_turbo:
        input.z *= 2.0   # turbo: double top speed / acceleration

    var direction: float = sign(linear_speed)
    if direction == 0.0:
        direction = sign(input.z) if absf(input.z) > 0.1 else 1.0

    var speed_frac: float = clampf(absf(linear_speed) / maxf(max_throttle, 0.1), 0.0, 1.0)
    var wetness: float = 0.0
    if GameManager and (GameManager.raining or GameManager.gloria_storm_active):
        wetness = 1.0
    if sphere and sphere.physics_material_override is PhysicsMaterial:
        (sphere.physics_material_override as PhysicsMaterial).friction = lerpf(4.0, 2.7, wetness)
    var steering_grip: float = clampf(0.48 + speed_frac * 0.52, 0.48, 1.0)
    steering_grip *= lerpf(1.0, 0.82, wetness)
    # High-speed stability: turn rate tapers so triple-digit runs stay controllable.
    var turn_gain: float = lerpf(6.8, 3.6, speed_frac)
    if handbrake_on and active:
        turn_gain = 7.2
    var target_angular: float = - input.x * steering_grip * turn_gain * direction
    angular_speed = lerpf(angular_speed, target_angular, delta * 9.0)
    vehicle_model.rotate_y(angular_speed * delta)

    if grounded:
        normal = raycast.get_collision_normal()
        if normal.dot(vehicle_model.global_basis.y) > 0.5:
            var xform: = _align_with_y(vehicle_model.global_transform, normal)
            vehicle_model.global_transform = vehicle_model.global_transform.interpolate_with(xform, 0.2).orthonormalized()
    colliding = grounded

    var target_speed: float = input.z
    if handbrake_on and active:
        linear_speed = lerpf(linear_speed, 0.0, delta * lerpf(6.0, 4.4, wetness))   # wet roads lengthen stops
    elif target_speed < 0.0 and linear_speed > 0.01:
        linear_speed = lerpf(linear_speed, 0.0, delta * lerpf(8.0, 5.8, wetness))   # brake before reversing
    elif target_speed < 0.0:
        linear_speed = lerpf(linear_speed, target_speed * 0.5, delta * 3.0)  # reverse, slower
    else:
        linear_speed = lerpf(linear_speed, target_speed, delta * lerpf(16.0, 13.0, wetness))

    acceleration = lerpf(acceleration, linear_speed, delta)

    sphere.angular_velocity += vehicle_model.get_global_transform().basis.x * (linear_speed * torque / max_throttle) * delta

    vehicle_model.position = sphere.position - Vector3(0, 0.5, 0)
    raycast.position = sphere.position
    linear_velocity = (vehicle_model.position - prev_position) / delta
    prev_position = vehicle_model.position

    _effect_ambient_engine(delta)
    _effect_skid(delta)
    _effect_damage_smoke(delta)
    _check_near_miss(delta)
    if active and GameManager:
        var ang: float = GameManager.day_phase * TAU
        var daylight: float = clampf(sin(ang + PI), 0.0, 1.0)
        var night: float = clampf(1.0 - daylight, 0.0, 1.0)
        var braking: bool = handbrake_on or (_throttle < -0.05 and linear_speed > 0.5)
        update_vehicle_lights(night, braking)


func _effect_ambient_engine(delta: float) -> void :
    if engine_ambient == null:
        return
    if not active:
        engine_ambient.volume_db = lerpf(engine_ambient.volume_db, -50.0, delta * 8.0)
        return
    var speed_factor: float = clampf(absf(linear_speed) / maxf(max_throttle, 0.1), 0.0, 1.0)
    var throttle_factor: float = clampf(absf(_throttle), 0.0, 1.0)
    # Subtle cabin rumble — present but never loud or buzzy.
    var target_db: float = remap(speed_factor * 0.65 + throttle_factor * 0.35, 0.0, 1.0, -40.0, -30.0)
    engine_ambient.volume_db = lerpf(engine_ambient.volume_db, target_db, delta * 3.5)
    var target_pitch: float = 0.96 + speed_factor * 0.1 + throttle_factor * 0.04
    engine_ambient.pitch_scale = lerpf(engine_ambient.pitch_scale, target_pitch, delta * 2.5)


func _effect_skid(delta: float) -> void :
    if screech_sound == null:
        return
    var drift: float = absf(angular_speed) * clampf(absf(linear_speed) / maxf(max_throttle, 0.1), 0.0, 1.0)
    var handbrake_skid: float = 1.6 if (handbrake_on and absf(linear_speed) > 8.0) else 0.0
    drift += handbrake_skid
    var skidding: bool = active and drift > 1.05
    if skidding:
        if not screech_sound.playing:
            screech_sound.play()
        var loud: float = remap(clampf(drift, 1.05, 2.8), 1.05, 2.8, -14.0, 0.0)
        screech_sound.volume_db = lerpf(screech_sound.volume_db, loud, delta * 12.0)
        screech_sound.pitch_scale = lerpf(screech_sound.pitch_scale, 0.92 + clampf(drift * 0.12, 0.0, 0.4), delta * 8.0)
        _spawn_skid_marks(delta, drift)
    else:
        screech_sound.volume_db = lerpf(screech_sound.volume_db, -40.0, delta * 14.0)
        if screech_sound.volume_db < -28.0 and screech_sound.playing:
            screech_sound.stop()
        _skid_t = 0.0
        _last_skid_l = Vector3.ZERO
        _last_skid_r = Vector3.ZERO


func _spawn_skid_marks(delta: float, drift: float) -> void :
    if vehicle_model == null:
        return
    _skid_t -= delta
    if _skid_t > 0.0:
        return
    _skid_t = 0.07
    var basis: Basis = vehicle_model.global_basis
    var left: Vector3 = vehicle_model.global_position - basis.x.normalized() * 0.72
    var right: Vector3 = vehicle_model.global_position + basis.x.normalized() * 0.72
    left.y = 0.03
    right.y = 0.03
    if _last_skid_l != Vector3.ZERO:
        _add_skid_segment(_last_skid_l, left, 0.24 + clampf(drift * 0.05, 0.0, 0.12))
    if _last_skid_r != Vector3.ZERO:
        _add_skid_segment(_last_skid_r, right, 0.24 + clampf(drift * 0.05, 0.0, 0.12))
    _last_skid_l = left
    _last_skid_r = right


func _add_skid_segment(a: Vector3, b: Vector3, width: float) -> void :
    var mid: Vector3 = (a + b) * 0.5
    var delta: Vector3 = b - a
    var len: float = delta.length()
    if len < 0.18:
        return
    var mark: = MeshInstance3D.new()
    var quad: = QuadMesh.new()
    quad.size = Vector2(width, len)
    mark.mesh = quad
    mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.02, 0.02, 0.02, 0.5)
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.no_depth_test = false
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mark.material_override = mat
    mark.global_position = mid
    mark.rotation.x = -PI * 0.5
    mark.rotation.y = atan2(delta.x, delta.z)
    get_tree().current_scene.add_child(mark)
    _skid_marks.append({"node": mark, "life": 8.0})


func _update_skid_marks(delta: float) -> void :
    for i in range(_skid_marks.size() - 1, -1, -1):
        var data: Dictionary = _skid_marks[i]
        var node: MeshInstance3D = data.get("node")
        var life: float = float(data.get("life", 0.0)) - delta
        if not is_instance_valid(node) or life <= 0.0:
            if is_instance_valid(node):
                node.queue_free()
            _skid_marks.remove_at(i)
            continue
        data["life"] = life
        if node.material_override is StandardMaterial3D:
            var mat: StandardMaterial3D = node.material_override as StandardMaterial3D
            mat.albedo_color.a = minf(0.5, life / 8.0 * 0.5)
        _skid_marks[i] = data


func _effect_damage_smoke(delta: float) -> void :
    if not active or body_damage < 45.0 or vehicle_model == null:
        return
    _smoke_t -= delta
    if _smoke_t > 0.0:
        return
    _smoke_t = 0.22 if body_damage < 75.0 else 0.12
    if VFX:
        var fwd: Vector3 = vehicle_model.global_basis.z.normalized()
        var pos: Vector3 = vehicle_model.global_position + fwd * 1.6 + Vector3(0, 0.9, 0)
        VFX.spawn_impact(pos, 0.35 if body_damage < 80.0 else 0.55)


func _on_body_entered(body: Node) -> void :
    if not active or _impact_cd > 0.0 or not is_instance_valid(vehicle_model):
        return
    var impact: float = linear_velocity.length()
    if impact < 5.0:
        return
    var other: Node = body
    if body is CollisionShape3D and body.get_parent():
        other = body.get_parent()
    var building: bool = other is StaticBody3D
    var traffic: bool = other is CharacterBody3D
    if not building and not traffic:
        return
    var dmg: float = clampf((impact - 4.0) * (3.0 if building else 2.2), 3.0, 38.0)
    body_damage = minf(MAX_BODY_DAMAGE, body_damage + dmg)
    _impact_cd = 0.4
    linear_speed *= 0.5
    angular_speed *= 0.65
    if traffic:
        if other.has_method("halt"):
            other.halt(1.6)
        else:
            other.global_position += vehicle_model.global_basis.z.normalized() * 1.2
            if "speed" in other:
                other.speed = 0.0
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/vehicle/vehicle_impact.mp3")
        if snd:
            AudioManager.play_sfx(snd, -2.0)
    if VFX:
        VFX.spawn_impact(vehicle_model.global_position + Vector3(0, 0.8, 0), 0.45)
    if GameManager and dmg >= 12.0:
        GameManager.show_message("Vehicle damage — body at %d%%" % int(get_damage_percent() * 100.0))
    if body_damage >= MAX_BODY_DAMAGE and GameManager:
        GameManager.show_message("Ride's totaled — grab another car.")
        if not _destroyed_emitted:
            _destroyed_emitted = true
            destroyed.emit()


func _check_near_miss(delta: float) -> void :
    if not active:
        return
    _near_miss_cd = maxf(0.0, _near_miss_cd - delta)
    if _near_miss_cd > 0.0 or absf(linear_speed) < 24.0:
        return
    var world: = get_tree().get_first_node_in_group("game_world")
    if world == null or not ("_traffic" in world):
        return
    var missed: bool = false
    var cp: Vector3 = vehicle_model.global_position if vehicle_model else global_position
    for tc in world._traffic:
        if not is_instance_valid(tc) or ("carjacked" in tc and tc.carjacked):
            continue
        var d: float = Vector2(cp.x - tc.global_position.x, cp.z - tc.global_position.z).length()
        if d < 4.4 and absf(linear_speed) > 6.0:
            if tc.has_method("halt"):
                tc.halt(1.6)
        elif d < 6.6:
            missed = true
    if missed and GameManager:
        _near_miss_cd = 1.1
        GameManager.add_cash(15)
        GameManager.show_message("NEAR MISS +$15")


# Camera orbit offset (driver can pan the chase cam around the car).
var cam_yaw: float = 0.0
var cam_pitch: float = 0.0


func set_cam_orbit(yaw: float, pitch: float) -> void :
    cam_yaw = clampf(yaw, -0.85, 0.85)
    cam_pitch = clampf(pitch, -0.35, 0.9)


# +1 when the chase cam is behind the car, -1 when it has swung in front so
# throttle/steer stay "push up = away from the lens".
func drive_view_flip() -> float:
    if camera == null or vehicle_model == null:
        return 1.0
    var car_fwd: = vehicle_model.global_basis.z
    car_fwd.y = 0.0
    if car_fwd.length_squared() < 1e-6:
        return 1.0
    car_fwd = car_fwd.normalized()
    var to_cam: = camera.global_position - vehicle_model.global_position
    to_cam.y = 0.0
    if to_cam.length_squared() < 1e-6:
        return 1.0
    return -1.0 if to_cam.normalized().dot(car_fwd) > 0.25 else 1.0


func _chase_pos(car_pos: Vector3) -> Vector3:
    # Forward throttle rolls toward +basis.z; park the chase cam on the opposite
    # side so push-up on the stick drives the car into the screen, not at you.
    var forward: Vector3 = vehicle_model.global_basis.z.normalized().rotated(Vector3.UP, cam_yaw)
    var dist: float = 9.0
    var height: float = 4.6 + cam_pitch * 5.0
    var side: float = 1.0 if (GameManager and GameManager.cam_flip) else -1.0
    return car_pos + forward * dist * side + Vector3(0, height, 0)


# Pull the chase cam in if a building/ground is between it and the car, so it
# never clips through geometry.
func _cam_unobstructed(car_pos: Vector3, want: Vector3) -> Vector3:
    if not is_inside_tree():
        return want
    var space: = get_world_3d().direct_space_state
    if space == null:
        return want
    var eye: = car_pos + Vector3(0, 1.2, 0)
    var q: = PhysicsRayQueryParameters3D.create(eye, want)
    q.collision_mask = 1
    if is_instance_valid(sphere):
        q.exclude = [sphere.get_rid()]
    var hit: = space.intersect_ray(q)
    if hit.is_empty():
        return want
    return (hit.position as Vector3) + (eye - want).normalized() * 0.5


func _update_camera(delta: float) -> void :
    if camera == null:
        return
    var car_pos: Vector3 = vehicle_model.global_position
    var want: = _cam_unobstructed(car_pos, _chase_pos(car_pos))
    camera.global_position = camera.global_position.lerp(want, clampf(delta * 6.0, 0.0, 1.0))
    camera.look_at(car_pos + Vector3(0, 1.2, 0), Vector3.UP)


func _snap_camera() -> void :
    if camera == null or vehicle_model == null:
        return
    var car_pos: Vector3 = vehicle_model.global_position
    camera.global_position = _cam_unobstructed(car_pos, _chase_pos(car_pos))
    camera.look_at(car_pos + Vector3(0, 1.2, 0), Vector3.UP)


func _align_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:
    xform.basis.y = new_y
    xform.basis.x = - xform.basis.z.cross(new_y)
    xform.basis = xform.basis.orthonormalized()
    return xform
