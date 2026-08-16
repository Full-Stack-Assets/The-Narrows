extends CharacterBody3D




signal interactable_changed(prompt: String)
signal interacted(entity_id: String)
signal vehicle_entered(entity_id: String)
signal wasted
signal tutorial_action(action: String)
signal weapon_changed(weapon_name: String, clip: int, reserve: int, melee: bool)
signal driving_changed(driving: bool)
signal shots_fired(at: Vector3)
signal health_changed(health: int, max_health: int, armor: int)

@export var speed: float = 2.6
@export var sprint_speed: float = 6.2
@export var jump_velocity: float = 5.6
@export var gravity: float = 20.0
@export var camera_distance: float = 5.5
@export var camera_height: float = 2.0
@export var look_sensitivity: float = 0.006

const ACCEL: float = 16.0
const FRICTION: float = 16.0
const TURN_RATE: float = 12.0

var _move_input: Vector2 = Vector2.ZERO
var _look_delta: Vector2 = Vector2.ZERO
var _camera_rotation: Vector2 = Vector2(0.0, -0.25)
var _sprint_held: bool = false
var _aiming: bool = false
var _crouching: bool = false

var camera_pivot: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D
var mesh_root: Node3D
var anim_player: AnimationPlayer
var anim_tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback

var _interact_zone: Area3D
var _current_interactable: Node = null
var _footstep_stream: AudioStream = null
var _footstep_timer: float = 0.0


var _weapons: Dictionary = {}
var _weapon_order: Array = []
var _current_weapon: String = "fists"
var _fire_cooldown: float = 0.0
var _fire_held: bool = false
var _held_model: Node3D = null
var _muzzle_marker: Marker3D = null


var max_health: int = 100
var health: int = 100
var armor: int = 0
var dead: bool = false
var _regen_delay: float = 0.0
var _hurt_sfx_cd: float = 0.0
var _invuln: float = 0.0
var _autosave_t: float = 0.0


var _driving: bool = false
var current_car: Node = null
var _boating: bool = false
var current_boat: Node = null
var _boats: Array = []
# Free-look orbit while driving — accumulates look input, eases back to centre.
# Yaw is clamped so the chase cam never swings to the side/front (profile view
# makes car-local throttle read as sideways on screen and feels inverted).
const CAR_CAM_YAW_MAX: float = 0.85
var _car_cam_yaw: float = 0.0
var _car_cam_pitch: float = 0.0
var _cars: Array = []
var _traffic_cars: Array = []


var wanted_system: Node = null
var home_spawn: Vector3 = Vector3.ZERO
var _tutorial_actions: Dictionary = {}


func _ready() -> void :
    collision_layer = 2
    collision_mask = 1


    var col: = CollisionShape3D.new()
    var capsule: = CapsuleShape3D.new()
    capsule.height = 1.8
    capsule.radius = 0.34
    col.shape = capsule
    col.position.y = 0.9
    add_child(col)


    camera_pivot = Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position.y = camera_height
    add_child(camera_pivot)

    spring_arm = SpringArm3D.new()
    spring_arm.spring_length = camera_distance
    spring_arm.collision_mask = 1
    spring_arm.shape = SphereShape3D.new()
    (spring_arm.shape as SphereShape3D).radius = 0.3
    camera_pivot.add_child(spring_arm)

    camera = Camera3D.new()
    camera.fov = 62.0
    spring_arm.add_child(camera)
    camera.make_current()
    # A restrained camera-side fill keeps the protagonist readable against wet
    # asphalt and midnight streets without flattening the authored world light.
    var character_fill := OmniLight3D.new()
    character_fill.name = "CharacterFill"
    character_fill.light_color = Color(0.52, 0.64, 0.78)
    character_fill.light_energy = 0.72
    character_fill.omni_range = 9.0
    character_fill.shadow_enabled = false
    camera.add_child(character_fill)


    mesh_root = Node3D.new()
    mesh_root.name = "CharacterMesh"
    add_child(mesh_root)
    _load_character()


    _interact_zone = Area3D.new()
    _interact_zone.collision_layer = 0
    _interact_zone.collision_mask = 32
    var iz_col: = CollisionShape3D.new()
    var iz_shape: = SphereShape3D.new()
    iz_shape.radius = 3.2
    iz_col.shape = iz_shape
    iz_col.position.y = 1.0
    _interact_zone.add_child(iz_col)
    add_child(_interact_zone)

    _footstep_stream = load("res://assets/audio/sfx/player/player_footstep_concrete.mp3")


    _weapons["fists"] = {"clip": 0, "reserve": 0}
    _weapon_order.append("fists")
    # Cheat: start with the whole arsenal loaded.
    if GameManager and GameManager.cheat_all_weapons:
        for wid: String in WeaponDB.ORDER:
            if wid != "fists":
                give_weapon(wid, 999)
        _current_weapon = "fists"
    call_deferred("_emit_weapon")
    call_deferred("_emit_health")

func _emit_health() -> void :
    health_changed.emit(health, max_health, armor)


func _load_character() -> void :
    var scene: = load("res://assets/characters/protagonist/protagonist.glb") as PackedScene
    if scene == null:
        return
    var model: = scene.instantiate()
    mesh_root.add_child(model)
    ModelUtils.setup_character_for_movement(model, 1.82)


    var meshes: Array = model.find_children("*", "MeshInstance3D", true)
    if meshes.size() > 0:
        var first: = meshes[0] as MeshInstance3D
        if first and not ModelUtils.has_vertex_normals(first):
            ModelUtils.generate_normals_for_all(model)
    for mesh_node in meshes:
        var mesh_instance := mesh_node as MeshInstance3D
        var source := mesh_instance.get_active_material(0) as StandardMaterial3D
        if source == null:
            continue
        var visible := source.duplicate() as StandardMaterial3D
        visible.albedo_color = Color(1.28, 1.28, 1.28, 1.0)
        visible.emission_enabled = true
        visible.emission = Color(0.34, 0.39, 0.48)
        visible.emission_texture = source.albedo_texture
        visible.emission_energy_multiplier = 0.26
        mesh_instance.material_override = visible

    anim_player = AnimationPlayer.new()
    anim_player.name = "AnimationPlayer"
    model.add_child(anim_player)
    var lib: = load("res://assets/characters/protagonist/protagonist_animations.tres") as AnimationLibrary
    if lib:
        anim_player.add_animation_library("", lib)
        ModelUtils.set_animation_loops(anim_player)
        _setup_animation_tree()


    var clamp: = GroundClampNode.new()
    clamp.name = "GroundClamp"
    clamp.target_node = self
    clamp.character_mesh = mesh_root
    add_child(clamp)


func _setup_animation_tree() -> void :
    var sm: = AnimationNodeStateMachine.new()
    for state in [["idle", "ual1_Idle"], ["walk", "ual1_Walk"], ["sprint", "ual1_Sprint"], ["jump", "ual1_Jump"]]:
        var node: = AnimationNodeAnimation.new()
        node.animation = state[1]
        sm.add_node(state[0], node)

    var states: = ["idle", "walk", "sprint", "jump"]
    for from_s in states:
        for to_s in states:
            if from_s == to_s:
                continue
            var t: = AnimationNodeStateMachineTransition.new()
            t.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
            t.xfade_time = 0.12 if (from_s == "jump" or to_s == "jump") else 0.16
            sm.add_transition(from_s, to_s, t)

    anim_tree = AnimationTree.new()
    anim_tree.anim_player = anim_player.get_path()
    anim_tree.tree_root = sm
    add_child(anim_tree)
    anim_tree.active = true
    _playback = anim_tree["parameters/playback"]



func set_move_input(dir: Vector2) -> void :
    _move_input = dir
    if dir.length() > 0.1:
        _emit_tutorial_action("move_look")

func add_camera_look(delta: Vector2) -> void :
    _look_delta += delta
    if delta.length() > 0.1:
        _emit_tutorial_action("move_look")

func set_sprint(active: bool) -> void :
    _sprint_held = active

func do_jump() -> void :
    if is_on_floor():
        velocity.y = jump_velocity
        if GameManager and GameManager.cheat_super_jump:
            velocity.y = jump_velocity * 2.2

func do_interact() -> void :
    if _current_interactable and is_instance_valid(_current_interactable) and _current_interactable.has_method("interact"):
        _current_interactable.interact(self)
        var entity_id := str(_current_interactable.name)
        if "mission_entity_id" in _current_interactable:
            entity_id = str(_current_interactable.mission_entity_id)
        interacted.emit(entity_id)

func set_aim(active: bool) -> void :
    _aiming = active
    if active:
        _emit_tutorial_action("attack_aim")

func set_crouch(active: bool) -> void :
    _crouching = active


func register_systems(p_wanted: Node, p_spawn: Vector3) -> void :
    wanted_system = p_wanted
    home_spawn = p_spawn

func register_cars(cars: Array) -> void :
    _cars = cars


func register_boats(boats: Array) -> void:
    _boats = boats


func register_traffic(cars: Array) -> void :
    _traffic_cars = cars

func owns_weapon(id: String) -> bool:
    return _weapons.has(id)

func give_weapon(id: String, ammo: int = 0) -> void :
    var def: = WeaponDB.get_def(id)
    if not _weapons.has(id):
        _weapons[id] = {"clip": 0, "reserve": 0}
        _weapon_order.append(id)
    if not def.get("melee", false):
        _weapons[id]["reserve"] += ammo
        if _weapons[id]["clip"] <= 0:
            _reload_from_reserve(id)
    _current_weapon = id
    _build_held_model()
    if GameManager:
        GameManager.show_message("Got the %s." % def["name"])
    _emit_weapon()

func add_ammo(id: String, amount: int) -> bool:
    if not _weapons.has(id):
        return false
    if WeaponDB.is_melee(id):
        return false
    _weapons[id]["reserve"] += amount
    if id == _current_weapon:
        _emit_weapon()
    return true

func switch_weapon() -> void :
    if _driving or _boating or _weapon_order.size() <= 1:
        return
    var idx: = _weapon_order.find(_current_weapon)
    idx = (idx + 1) % _weapon_order.size()
    _current_weapon = _weapon_order[idx]
    _build_held_model()
    _emit_weapon()

func _emit_weapon() -> void :
    var def: = WeaponDB.get_def(_current_weapon)
    var clip: = 0
    var reserve: = 0
    if _weapons.has(_current_weapon):
        clip = _weapons[_current_weapon]["clip"]
        reserve = _weapons[_current_weapon]["reserve"]
    weapon_changed.emit(def["name"], clip, reserve, def.get("melee", false))

func _reload_from_reserve(id: String) -> void :
    var def: = WeaponDB.get_def(id)
    var clip_size: int = int(def.get("clip", 0))
    var need: int = clip_size - _weapons[id]["clip"]
    var take: int = min(need, _weapons[id]["reserve"])
    _weapons[id]["clip"] += take
    _weapons[id]["reserve"] -= take

func _build_held_model() -> void :
    if mesh_root == null:
        return
    if _held_model and is_instance_valid(_held_model):
        _held_model.queue_free()
        _held_model = null
    if _muzzle_marker == null:
        _muzzle_marker = Marker3D.new()
        mesh_root.add_child(_muzzle_marker)
        _muzzle_marker.position = Vector3(0.28, 1.05, -0.7)
    var def: = WeaponDB.get_def(_current_weapon)
    var path: String = def.get("model", "")
    if path == "":
        return
    var scene: = load(path) as PackedScene
    if scene == null:
        return
    _held_model = scene.instantiate() as Node3D
    mesh_root.add_child(_held_model)
    _scale_to_longest(_held_model, float(def.get("len", 0.4)))
    _held_model.position = Vector3(0.28, 1.0, -0.34)
    _held_model.rotation_degrees = Vector3(0, 180, 0)

func _scale_to_longest(model: Node3D, target: float) -> void :
    var aabb: = ModelUtils._get_combined_aabb(model)
    var longest: float = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
    if longest > 0.001:
        model.scale = Vector3.ONE * (target / longest)

func set_fire_held(active: bool) -> void :
    _fire_held = active
    if active:
        _emit_tutorial_action("attack_aim")
    if active:
        do_fire()

func do_fire() -> void :
    if _driving or _boating or dead:
        return
    if _fire_cooldown > 0.0:
        return
    var def: = WeaponDB.get_def(_current_weapon)
    _fire_cooldown = float(def.get("rate", 0.3))
    if GameManager and GameManager.cheat_rapidfire:
        _fire_cooldown = 0.05

    if def.get("melee", false):
        _melee_attack(def)
        return

    var inf_ammo: bool = GameManager != null and GameManager.cheat_infinite_ammo
    if not inf_ammo:
        if not _weapons.has(_current_weapon) or _weapons[_current_weapon]["clip"] <= 0:
            if GameManager:
                GameManager.show_message("Empty — tap RLD to reload, or SWAP weapon.")
            return
        _weapons[_current_weapon]["clip"] -= 1
    _emit_weapon()
    shots_fired.emit(global_position)
    _camera_rotation.y = clamp(_camera_rotation.y + 0.035, -1.1, 0.45)

    var origin: Vector3 = camera.global_position if camera else global_position + Vector3(0, 1.4, 0)
    var base_dir: Vector3 = ( - camera.global_transform.basis.z).normalized() if camera else - global_transform.basis.z
    var muzzle_pos: Vector3 = _muzzle_marker.global_position if _muzzle_marker else global_position + Vector3(0, 1.2, 0)

    if AudioManager and def.has("shot"):
        var snd: = load(def["shot"])
        if snd:
            AudioManager.play_sfx(snd, -4.0, 0.08)
    if VFX:
        VFX.spawn_muzzle(muzzle_pos, base_dir, 0.45)

    var pellets: int = int(def.get("pellets", 1))
    var spread: float = float(def.get("spread", 0.01))
    var rng: float = float(def.get("range", 80.0))
    var dmg: int = int(def.get("damage", 1))
    if GameManager and GameManager.cheat_oneshot:
        dmg = 999
    for i in pellets:
        var dir: = base_dir
        if spread > 0.0:
            dir = (base_dir + Vector3(randf_range( - spread, spread), randf_range( - spread, spread), randf_range( - spread, spread))).normalized()
        _fire_ray(origin, dir, rng, dmg, def)

    if wanted_system and wanted_system.has_method("add_heat"):
        wanted_system.add_heat(int(def.get("heat", 1)))
    if wanted_system and wanted_system.has_method("add_faction_heat"):
        wanted_system.add_faction_heat(1)

func _fire_ray(origin: Vector3, dir: Vector3, rng: float, dmg: int, def: Dictionary) -> void :
    var space: = get_world_3d().direct_space_state
    var query: = PhysicsRayQueryParameters3D.create(origin, origin + dir * rng)
    query.collision_mask = 1 | 4
    query.exclude = [get_rid()]
    var hit: = space.intersect_ray(query)
    if not hit:
        return
    if VFX:
        VFX.spawn_impact(hit.position, 0.35)
    if AudioManager and def.has("impact"):
        var isnd: = load(def["impact"])
        if isnd:
            AudioManager.play_sfx(isnd, -12.0)
    var collider: Object = hit.collider
    if collider and collider.has_method("take_damage"):
        collider.take_damage(dmg)

func _melee_attack(def: Dictionary) -> void :
    if AudioManager and def.has("swing"):
        var snd: = load(def["swing"])
        if snd:
            AudioManager.play_sfx(snd, -6.0)
    var origin: Vector3 = global_position + Vector3(0, 1.2, 0)
    var dir: Vector3 = ( - camera.global_transform.basis.z).normalized() if camera else - mesh_root.global_transform.basis.z
    dir.y = 0.0
    dir = dir.normalized()
    var space: = get_world_3d().direct_space_state
    var query: = PhysicsRayQueryParameters3D.create(origin, origin + dir * float(def.get("range", 2.5)))
    query.collision_mask = 4
    query.exclude = [get_rid()]
    var hit: = space.intersect_ray(query)
    if hit:
        var collider: Object = hit.collider
        if collider and collider.has_method("take_damage"):
            collider.take_damage(int(def.get("damage", 1)))
            if AudioManager and def.has("hit"):
                var hsnd: = load(def["hit"])
                if hsnd:
                    AudioManager.play_sfx(hsnd, -4.0)
            if VFX:
                VFX.spawn_impact(hit.position, 0.3)
            if wanted_system and wanted_system.has_method("add_heat"):
                wanted_system.add_heat(int(def.get("heat", 1)))
            if wanted_system and wanted_system.has_method("add_faction_heat"):
                wanted_system.add_faction_heat(1)

func do_reload() -> void :
    if _driving or _boating or dead:
        return
    var def: = WeaponDB.get_def(_current_weapon)
    if def.get("melee", false) or not _weapons.has(_current_weapon):
        return
    var entry: Dictionary = _weapons[_current_weapon]
    if entry["clip"] >= int(def.get("clip", 0)) or entry["reserve"] <= 0:
        return
    _reload_from_reserve(_current_weapon)
    if AudioManager and def.has("reload"):
        var snd: = load(def["reload"])
        if snd:
            AudioManager.play_sfx(snd, -8.0)
    _emit_weapon()


func take_damage(amount: int) -> void :
    if GameManager and GameManager.cheat_godmode:
        return
    if dead or _invuln > 0.0:
        return
    _regen_delay = 5.0
    var dmg: = amount
    if armor > 0:
        var absorbed: int = min(armor, dmg)
        armor -= absorbed
        dmg -= absorbed
    health = max(0, health - dmg)
    if _hurt_sfx_cd <= 0.0 and AudioManager:
        _hurt_sfx_cd = 0.4
        var snd: = load("res://assets/audio/sfx/player/player_player_hurt.mp3")
        if snd:
            AudioManager.play_sfx(snd, -4.0, 0.1)
    health_changed.emit(health, max_health, armor)
    if health <= 0:
        _die()

func heal(amount: int) -> void :
    health = min(max_health, health + amount)
    health_changed.emit(health, max_health, armor)


func heal_full() -> void :
    health = max_health
    health_changed.emit(health, max_health, armor)

func add_armor(amount: int) -> void :
    armor = min(100, armor + amount)
    health_changed.emit(health, max_health, armor)

func _die() -> void :
    if dead:
        return
    if ConsequenceManager and ConsequenceManager.is_active():
        return
    dead = true
    wasted.emit()
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/player/player_player_wasted.mp3")
        if snd:
            AudioManager.play_sfx(snd, -2.0)
    if ConsequenceManager and ConsequenceManager.has_method("start"):
        ConsequenceManager.start("wasted")
        return
    # Fallback if autoload missing.
    var lost: int = int(GameManager.cash * 0.4) + 30 if GameManager else 0
    if GameManager:
        GameManager.add_cash( - lost)
        GameManager.show_message("WASTED — you woke up at the clinic. Lost $%d." % lost)
        GameManager.set_wanted(0)
        GameManager.set_faction(0)
    _respawn()
    dead = false

func _respawn() -> void :
    if _boating:
        exit_boat()
    if _driving:
        exit_car()
    if home_spawn != Vector3.ZERO:
        global_position = home_spawn
    velocity = Vector3.ZERO
    health = max_health
    armor = 0
    health_changed.emit(health, max_health, armor)


func fast_travel_to(target: Vector3) -> void :
    # Map-tap teleport. Raycast down from high above the target to land on the
    # street/terrain instead of clipping into a building or floating. If you're
    # driving, your car comes with you (it's your ride across the South Coast).
    var space: = get_world_3d().direct_space_state
    var from: = Vector3(target.x, 400.0, target.z)
    var to: = Vector3(target.x, -200.0, target.z)
    var q: = PhysicsRayQueryParameters3D.create(from, to)
    q.exclude = [get_rid()]
    var hit: Dictionary = space.intersect_ray(q)
    # No ground below the target (open water / void) — refuse rather than fling
    # the player into the sky over the harbor.
    if not hit.has("position"):
        if GameManager and GameManager.has_method("show_message"):
            GameManager.show_message("Can't fast-travel there.")
        return
    var ground: float = (hit["position"] as Vector3).y
    if _boating and current_boat != null and is_instance_valid(current_boat) and current_boat.has_method("place_at"):
        current_boat.place_at(Vector3(target.x, maxf(ground, 0.8), target.z), rad_to_deg(get_map_heading()))
        velocity = Vector3.ZERO
        if GameManager:
            GameManager.show_message("Fast travelled (with boat).")
        return
    if _driving and current_car != null and is_instance_valid(current_car) and current_car.has_method("place_at"):
        # The car-follow in _physics_process slaves the player to the car, so we
        # only need to move the car; it parks stationary at the destination.
        current_car.place_at(Vector3(target.x, ground + 0.5, target.z), rad_to_deg(get_map_heading()))
        velocity = Vector3.ZERO
        if GameManager and GameManager.has_method("show_message"):
            GameManager.show_message("Fast travelled (with car).")
        return
    global_position = Vector3(target.x, ground + 1.2, target.z)
    velocity = Vector3.ZERO
    if GameManager and GameManager.has_method("show_message"):
        GameManager.show_message("Fast travelled.")


func try_enter_vehicle() -> void :
    if _boating:
        exit_boat()
        return
    if _driving:
        exit_car()
        return
    var nearest_boat: Node = null
    var nearest_boat_distance := 8.5
    for candidate in _boats:
        if is_instance_valid(candidate):
            var boat_distance := global_position.distance_to(candidate.global_position)
            if boat_distance < nearest_boat_distance:
                nearest_boat_distance = boat_distance
                nearest_boat = candidate
    if nearest_boat:
        enter_boat(nearest_boat)
        return
    var world: = get_tree().get_first_node_in_group("game_world")
    if world and world.has_method("find_carjackable_traffic"):
        var tc: Variant = world.find_carjackable_traffic(global_position, 6.5)
        if tc and world.has_method("carjack_traffic"):
            var jacked: Variant = world.carjack_traffic(tc)
            if jacked:
                enter_car(jacked)
                return
    var nearest: Node = null
    var best: = 7.5
    for c in _cars:
        if is_instance_valid(c):
            var d: float = global_position.distance_to(c.global_position)
            if d < best:
                best = d
                nearest = c
    if nearest:
        enter_car(nearest)
    elif GameManager:
        GameManager.show_message("No car nearby — walk up to one and tap CAR.")

func snap_drive_camera() -> void :
    if _driving and current_car != null and is_instance_valid(current_car) and current_car.has_method("_snap_camera"):
        current_car._snap_camera()


func enter_boat(boat: Node) -> void:
    _boating = true
    current_boat = boat
    set_collision_layer_value(2, false)
    _set_capsule(true)
    visible = false
    velocity = Vector3.ZERO
    if boat.has_method("enter"):
        boat.enter(self)
    driving_changed.emit(true)
    vehicle_entered.emit(str(boat.get("mission_entity_id")))


func exit_boat() -> void:
    if not _boating or current_boat == null:
        return
    var position := global_position + Vector3(2.5, 0.6, 0)
    if current_boat.has_method("exit"):
        position = current_boat.exit()
    _boating = false
    current_boat = null
    global_position = position
    visible = true
    set_collision_layer_value(2, true)
    _set_capsule(false)
    if camera:
        camera.make_current()
    driving_changed.emit(false)


func enter_car(car: Node) -> void :
    _driving = true
    current_car = car
    _car_cam_yaw = 0.0
    _car_cam_pitch = 0.0
    if car.has_method("set_cam_orbit"):
        car.set_cam_orbit(0.0, 0.0)
    set_collision_layer_value(2, false)
    _set_capsule(true)
    visible = false
    velocity = Vector3.ZERO
    if car.has_method("enter"):
        car.enter(self)
    driving_changed.emit(true)
    var entity_id := "any_vehicle"
    if "mission_entity_id" in car and not str(car.mission_entity_id).is_empty():
        entity_id = str(car.mission_entity_id)
    vehicle_entered.emit(entity_id)

func exit_car() -> void :
    if not _driving or current_car == null:
        return
    var pos: Vector3 = global_position + Vector3(2.5, 0.6, 0)
    if current_car.has_method("exit"):
        pos = current_car.exit()
    _driving = false
    current_car = null
    global_position = pos
    visible = true
    set_collision_layer_value(2, true)
    _set_capsule(false)
    if camera:
        camera.make_current()
    driving_changed.emit(false)

func _set_capsule(disabled: bool) -> void :
    for c in get_children():
        if c is CollisionShape3D:
            c.set_deferred("disabled", disabled)

func on_busted() -> void :
    if _boating:
        exit_boat()
    if _driving:
        exit_car()
    global_position = home_spawn if home_spawn != Vector3.ZERO else global_position
    velocity = Vector3.ZERO


func recover_from_water(pos: Vector3, in_car: bool) -> void :
    if _boating and current_boat and is_instance_valid(current_boat):
        if current_boat.has_method("recover_safe"):
            current_boat.recover_safe()
        return
    if in_car and current_car != null and is_instance_valid(current_car) and current_car.has_method("place_at"):
        current_car.place_at(pos, get_map_heading())
    global_position = pos
    velocity = Vector3.ZERO

func set_heading(yaw: float) -> void :
    if mesh_root:
        mesh_root.rotation.y = yaw


func get_map_heading() -> float:
    if _boating and current_boat and is_instance_valid(current_boat) and current_boat.has_method("get_heading"):
        return current_boat.get_heading()
    if _driving and current_car and is_instance_valid(current_car) and "vehicle_model" in current_car and current_car.vehicle_model:
        return current_car.vehicle_model.rotation.y
    return mesh_root.rotation.y if mesh_root else 0.0


func _unhandled_input(event: InputEvent) -> void :

    if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
        add_camera_look(Vector2( - event.relative.x, - event.relative.y))
    if (
        event.is_action_pressed("move_forward")
        or event.is_action_pressed("move_back")
        or event.is_action_pressed("move_left")
        or event.is_action_pressed("move_right")
    ):
        _emit_tutorial_action("move_look")
    if event.is_action_pressed("fire"):
        set_fire_held(true)
    elif event.is_action_released("fire"):
        set_fire_held(false)
    if event.is_action_pressed("aim"):
        set_aim(true)
    elif event.is_action_released("aim"):
        set_aim(false)
    if event.is_action_pressed("interact"):
        do_interact()
    if event.is_action_pressed("enter_vehicle"):
        try_enter_vehicle()
    if event.is_action_pressed("reload"):
        do_reload()
    if event.is_action_pressed("weapon_next"):
        switch_weapon()
    if event.is_action_pressed("crouch"):
        set_crouch(true)
    elif event.is_action_released("crouch"):
        set_crouch(false)


func _emit_tutorial_action(action: String) -> void:
    if _tutorial_actions.has(action):
        return
    _tutorial_actions[action] = true
    tutorial_action.emit(action)


func _physics_process(delta: float) -> void :
    _fire_cooldown = max(0.0, _fire_cooldown - delta)
    _hurt_sfx_cd = max(0.0, _hurt_sfx_cd - delta)
    _invuln = max(0.0, _invuln - delta)
    var stick_look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
    if stick_look.length() > 0.15:
        add_camera_look(stick_look * 180.0 * delta)

    # Light autosave so the menu's Continue resumes where you left off.
    _autosave_t += delta
    if _autosave_t >= 5.0:
        _autosave_t = 0.0
        if not dead and GameManager and GameManager.has_method("save_player_state"):
            var vehicle := {}
            if _boating and current_boat and is_instance_valid(current_boat):
                vehicle = {"identity": "boat", "condition": 1.0}
            elif _driving and current_car and is_instance_valid(current_car):
                vehicle = {
                    "identity": str(current_car.get("model_path")),
                    "condition": 1.0 - float(current_car.get_damage_percent()),
                }
            GameManager.save_player_state(global_position, get_map_heading(), health, armor, vehicle)


    if not dead and health < max_health:
        if _regen_delay > 0.0:
            _regen_delay = max(0.0, _regen_delay - delta)
        elif health < max_health:
            var before: = health
            health = min(max_health, health + int(ceil(12.0 * delta)))
            if health != before:
                health_changed.emit(health, max_health, armor)


    if _fire_held and not _driving and not _boating and not dead:
        var adef: = WeaponDB.get_def(_current_weapon)
        if adef.get("auto", false):
            do_fire()


    if _boating:
        if current_boat == null or not is_instance_valid(current_boat):
            _boating = false
            current_boat = null
        else:
            global_position = current_boat.global_position
            return

    if _driving:
        if current_car == null or not is_instance_valid(current_car):
            _driving = false
        else:
            var kb_drive: = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
            # Stick up (negative y) = gas; stick down = reverse/brake. Keyboard unchanged.
            var raw: = Vector2(_move_input.x + kb_drive.x, -_move_input.y + kb_drive.y)
            if raw.length() > 1.0:
                raw = raw.normalized()
            var steer: float = raw.x
            var throttle: float = raw.y
            # If the chase cam slipped in front of the car, gas would drive toward
            # the lens — flip so push-up always means "away from camera".
            if current_car.has_method("drive_view_flip"):
                var flip: float = current_car.drive_view_flip()
                steer *= flip
                throttle *= flip
            steer = clampf(steer, -1.0, 1.0)
            throttle = clampf(throttle, -1.0, 1.0)
            if current_car.has_method("set_drive_input"):
                current_car.set_drive_input(steer, throttle)
            if current_car.has_method("set_handbrake"):
                current_car.set_handbrake(Input.is_action_pressed("handbrake"))
            if Input.is_action_just_pressed("horn") and current_car.has_method("honk"):
                current_car.honk()
            if "vehicle_model" in current_car and current_car.vehicle_model:
                global_position = current_car.vehicle_model.global_position
            # Pan the chase cam with look input; when released, ease back so the
            # camera settles behind the car again.
            if _look_delta.length_squared() > 0.0:
                _car_cam_yaw += _look_delta.x * look_sensitivity
                _car_cam_pitch += _look_delta.y * look_sensitivity
                _look_delta = Vector2.ZERO
            else:
                _car_cam_yaw = lerpf(_car_cam_yaw, 0.0, clampf(delta * 5.0, 0.0, 1.0))
                _car_cam_pitch = lerpf(_car_cam_pitch, 0.0, clampf(delta * 5.0, 0.0, 1.0))
            _car_cam_yaw = clampf(_car_cam_yaw, -CAR_CAM_YAW_MAX, CAR_CAM_YAW_MAX)
            _car_cam_pitch = clampf(_car_cam_pitch, -0.35, 0.9)
            if current_car.has_method("set_cam_orbit"):
                current_car.set_cam_orbit(_car_cam_yaw, _car_cam_pitch)
            return


    if _look_delta.length_squared() > 0.0:
        _camera_rotation.x += _look_delta.x * look_sensitivity
        _camera_rotation.y += _look_delta.y * look_sensitivity
        _camera_rotation.y = clamp(_camera_rotation.y, -1.1, 0.45)
        _look_delta = Vector2.ZERO
    camera_pivot.rotation.y = _camera_rotation.x
    camera_pivot.rotation.x = _camera_rotation.y


    if camera:
        var want_fov: float = 48.0 if _aiming else 62.0
        camera.fov = lerp(camera.fov, want_fov, 8.0 * delta)
    if spring_arm:
        var want_dist: float = 3.2 if _aiming else camera_distance
        spring_arm.spring_length = lerp(spring_arm.spring_length, want_dist, 8.0 * delta)
    var want_h: float = (camera_height - 0.6) if _crouching else camera_height
    camera_pivot.position.y = lerp(camera_pivot.position.y, want_h, 8.0 * delta)


    if not is_on_floor():
        velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump"):
        do_jump()


    var kb: = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var raw: = _move_input + kb
    if raw.length() > 1.0:
        raw = raw.normalized()

    var cam_basis: = camera_pivot.global_basis
    var direction: Vector3 = cam_basis * Vector3(raw.x, 0.0, raw.y)
    direction.y = 0.0
    var input_strength: = raw.length()
    if direction.length_squared() > 0.0001:
        direction = direction.normalized()

    var sprinting: = (_sprint_held or Input.is_action_pressed("sprint")) and not _crouching
    var target_speed: float = sprint_speed if sprinting else speed
    if _crouching:
        target_speed = speed * 0.55
    if GameManager and GameManager.cheat_super_speed:
        target_speed *= 2.4
    var desired: Vector3 = direction * target_speed * clamp(input_strength, 0.0, 1.0)

    if input_strength > 0.05:
        velocity.x = move_toward(velocity.x, desired.x, ACCEL * delta)
        velocity.z = move_toward(velocity.z, desired.z, ACCEL * delta)
        var target_yaw: = atan2( - direction.x, - direction.z)
        mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_yaw, TURN_RATE * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
        velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)

    move_and_slide()
    _update_animation()
    _update_footsteps(delta)
    _update_interactable()


func _update_animation() -> void :
    if _playback == null:
        return
    var planar_speed: = Vector2(velocity.x, velocity.z).length()
    if not is_on_floor():
        _playback.travel("jump")
    elif planar_speed > 4.2:
        _playback.travel("sprint")
    elif planar_speed > 0.4:
        _playback.travel("walk")
    else:
        _playback.travel("idle")


func _update_footsteps(delta: float) -> void :
    if not is_on_floor():
        return
    var planar_speed: = Vector2(velocity.x, velocity.z).length()
    if planar_speed < 0.6:
        _footstep_timer = 0.0
        return
    _footstep_timer -= delta
    if _footstep_timer <= 0.0:
        var interval: = 0.34 if planar_speed > 4.2 else 0.5
        _footstep_timer = interval
        if AudioManager and _footstep_stream:
            AudioManager.play_sfx(_footstep_stream, -14.0, 0.12)


func _update_interactable() -> void :
    var nearest: Node = null
    var nearest_dist: = INF
    for area in _interact_zone.get_overlapping_areas():
        var owner_node: Node = area
        if not area.has_method("interact"):
            owner_node = area.get_parent()
        if owner_node and owner_node.has_method("interact"):
            var d: = global_position.distance_to((area as Node3D).global_position)
            if d < nearest_dist:
                nearest_dist = d
                nearest = owner_node
    if nearest != _current_interactable:
        _current_interactable = nearest
        var prompt: = ""
        if nearest and "interact_prompt" in nearest:
            prompt = str(nearest.interact_prompt)
        elif nearest:
            prompt = "Interact"
        interactable_changed.emit(prompt)
