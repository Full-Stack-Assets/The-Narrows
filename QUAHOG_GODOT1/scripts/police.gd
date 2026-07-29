extends CharacterBody3D
class_name Police





const PoliceStateRuntime = preload("res://scripts/ai/police_state.gd")
const MODEL: = "res://assets/characters/cop/cop.glb"
const ANIMS: = "res://assets/characters/cop/cop_animations.tres"

var run_speed: float = 5.2
var gravity: float = 20.0
var health: int = 3
var dead: bool = false

var target: Node3D = null
var wanted_system: Node = null

const FIRE_RANGE: float = 22.0
const FIRE_DAMAGE: int = 6
const FIRE_INTERVAL: float = 1.1

var mesh_root: Node3D
var anim_player: AnimationPlayer
var anim_tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback
var _arrest_cooldown: float = 0.0
var _hit_timer: float = 0.0
var _fire_cooldown: float = 0.0
var _state_runtime := PoliceStateRuntime.new()
var _disengage_timer: float = 0.0

const SIGHT_RANGE: float = 58.0


func setup(p_target: Node3D, p_wanted: Node) -> void :
    target = p_target
    wanted_system = p_wanted


func _ready() -> void :
    collision_layer = 4
    collision_mask = 1

    var col: = CollisionShape3D.new()
    var capsule: = CapsuleShape3D.new()
    capsule.height = 1.8
    capsule.radius = 0.34
    col.shape = capsule
    col.position.y = 0.9
    add_child(col)

    mesh_root = Node3D.new()
    mesh_root.name = "CharacterMesh"
    add_child(mesh_root)

    var scene: = load(MODEL) as PackedScene
    if scene:
        var model: = scene.instantiate()
        mesh_root.add_child(model)
        ModelUtils.setup_character_for_movement(model, 1.82)
        var meshes: Array = model.find_children("*", "MeshInstance3D", true)
        if meshes.size() > 0:
            var first: = meshes[0] as MeshInstance3D
            if first and not ModelUtils.has_vertex_normals(first):
                ModelUtils.generate_normals_for_all(model)
        anim_player = AnimationPlayer.new()
        anim_player.name = "AnimationPlayer"
        model.add_child(anim_player)
        var lib: = load(ANIMS) as AnimationLibrary
        if lib:
            anim_player.add_animation_library("", lib)
            ModelUtils.set_animation_loops(anim_player)
            _setup_anim_tree()
        var clamp: = GroundClampNode.new()
        clamp.target_node = self
        clamp.character_mesh = mesh_root
        add_child(clamp)


func _setup_anim_tree() -> void :
    var sm: = AnimationNodeStateMachine.new()
    for state in [["idle", "ual1_Idle"], ["run", "ual1_Sprint"], ["hit", "ual1_Hit_Chest"], ["death", "ual1_Death01"]]:
        var node: = AnimationNodeAnimation.new()
        node.animation = state[1]
        sm.add_node(state[0], node)
    var states: = ["idle", "run", "hit", "death"]
    for a in states:
        for b in states:
            if a == b:
                continue
            var t: = AnimationNodeStateMachineTransition.new()
            t.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
            t.xfade_time = 0.15
            sm.add_transition(a, b, t)
    anim_tree = AnimationTree.new()
    anim_tree.anim_player = anim_player.get_path()
    anim_tree.tree_root = sm
    add_child(anim_tree)
    anim_tree.active = true
    _playback = anim_tree["parameters/playback"]
    _playback.travel("idle")


func take_damage(amount: int) -> void :
    if dead:
        return
    health -= amount
    _hit_timer = 0.4
    if _playback:
        _playback.travel("hit")
    if health <= 0:
        _die()


func _die() -> void :
    dead = true
    collision_layer = 0
    if _playback:
        _playback.travel("death")
    if wanted_system and wanted_system.has_method("on_cop_killed"):
        wanted_system.on_cop_killed()
    var tw: = create_tween()
    tw.tween_interval(2.5)
    tw.tween_callback(queue_free)


func _shoot_at_player() -> void :
    if target == null or not is_instance_valid(target):
        return
    _fire_cooldown = FIRE_INTERVAL
    var muzzle: Vector3 = global_position + Vector3(0, 1.4, 0)
    var aim: Vector3 = (target.global_position + Vector3(0, 1.2, 0)) - muzzle
    var dir: = aim.normalized()

    var space: = get_world_3d().direct_space_state
    var query: = PhysicsRayQueryParameters3D.create(muzzle, muzzle + dir * FIRE_RANGE)
    query.collision_mask = 1 | 2
    query.exclude = [get_rid()]
    var hit: = space.intersect_ray(query)
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/weapon/weapon_pistol_shot.mp3")
        if snd:
            AudioManager.play_sfx(snd, -8.0, 0.12)
    if VFX:
        VFX.spawn_muzzle(muzzle + dir * 0.4, dir, 0.3)
    if hit:
        var collider: Object = hit.collider
        if collider == target and target.has_method("take_damage"):
            target.take_damage(FIRE_DAMAGE)
        elif VFX:
            VFX.spawn_impact(hit.position, 0.3)


func pursuit_state() -> int:
    return _state_runtime.state


func last_known_position() -> Vector3:
    return _state_runtime.last_known_position


func is_actively_seeing_player() -> bool:
    return _state_runtime.is_actively_seen()


func _can_see_target() -> bool:
    if target == null or not is_instance_valid(target):
        return false
    var eye := global_position + Vector3(0.0, 1.45, 0.0)
    var target_eye := target.global_position + Vector3(0.0, 1.1, 0.0)
    if eye.distance_to(target_eye) > SIGHT_RANGE:
        return false
    var query := PhysicsRayQueryParameters3D.create(eye, target_eye)
    query.collision_mask = 1 | 2
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return true
    var collider: Object = hit.get("collider")
    return collider == target or (collider is Node and target.is_ancestor_of(collider))


func _physics_process(delta: float) -> void :
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    if dead:
        velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
        move_and_slide()
        return

    _arrest_cooldown = max(0.0, _arrest_cooldown - delta)
    _hit_timer = max(0.0, _hit_timer - delta)
    _fire_cooldown = max(0.0, _fire_cooldown - delta)

    var moving: = false
    if target and is_instance_valid(target):
        var has_heat: bool = GameManager != null and GameManager.wanted_level > 0
        var has_sight := _can_see_target()
        var previous_state: int = _state_runtime.state
        var state: int = _state_runtime.update(has_heat, has_sight, target.global_position, delta)
        if state != previous_state and wanted_system and wanted_system.has_method("on_police_state_changed"):
            wanted_system.on_police_state_changed(self, state, _state_runtime.last_known_position)

        var destination: Vector3 = target.global_position
        if state == PoliceStateRuntime.State.SEARCHING:
            destination = _state_runtime.last_known_position
        elif state == PoliceStateRuntime.State.DISENGAGING:
            _disengage_timer += delta
            destination = global_position + (global_position - target.global_position).normalized() * 8.0

        var to_t: = destination - global_position
        to_t.y = 0.0
        var dist: = to_t.length()
        if state == PoliceStateRuntime.State.DISENGAGING and _disengage_timer >= 2.0:
            queue_free()
        elif dist > 2.0:
            var dir: = to_t.normalized()
            var approach_speed: float = run_speed if state == PoliceStateRuntime.State.PURSUING else run_speed * 0.55
            if state == PoliceStateRuntime.State.PURSUING and dist <= FIRE_RANGE * 0.6:
                approach_speed = run_speed * 0.4
            velocity.x = dir.x * approach_speed
            velocity.z = dir.z * approach_speed
            mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, atan2( - dir.x, - dir.z), 9.0 * delta)
            moving = approach_speed > run_speed * 0.5
            if state == PoliceStateRuntime.State.PURSUING and has_sight and dist <= FIRE_RANGE and _fire_cooldown <= 0.0:
                _shoot_at_player()
        else:
            velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
            if state == PoliceStateRuntime.State.PURSUING and _arrest_cooldown <= 0.0:
                _arrest_cooldown = 1.0
                if wanted_system and wanted_system.has_method("on_player_caught"):
                    wanted_system.on_player_caught()
    move_and_slide()

    if _playback and _hit_timer <= 0.0:
        _playback.travel("run" if moving else "idle")
