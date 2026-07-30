extends Node3D

# Maplecroft safehouse: bleed off police + faction heat on foot, autosave, sleep (T).

const RADIUS: float = 9.0
const SLEEP_PHASE: float = 0.52  # ~07:00 on the world clock

var _save_timer: float = 0.0
var _inside: bool = false
var _hinted: bool = false


func _ready() -> void :
    _build_visuals()


func _build_visuals() -> void :
    var wall: = StandardMaterial3D.new()
    wall.albedo_color = Color(0.48, 0.56, 0.58)
    wall.roughness = 0.88
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color(0.24, 0.16, 0.1)
    floor_mat.roughness = 0.94
    _add_room_piece("Floor", Vector3(8.0, 0.2, 8.0), Vector3(0.0, 0.1, 0.0), floor_mat, true)
    _add_room_piece("BackWall", Vector3(8.0, 4.0, 0.25), Vector3(0.0, 2.0, -4.0), wall, true)
    _add_room_piece("LeftWall", Vector3(0.25, 4.0, 8.0), Vector3(-4.0, 2.0, 0.0), wall, true)
    _add_room_piece("RightWall", Vector3(0.25, 4.0, 8.0), Vector3(4.0, 2.0, 0.0), wall, true)
    _add_room_piece("FrontLeft", Vector3(2.5, 4.0, 0.25), Vector3(-2.75, 2.0, 4.0), wall, true)
    _add_room_piece("FrontRight", Vector3(2.5, 4.0, 0.25), Vector3(2.75, 2.0, 4.0), wall, true)
    _add_room_piece("DoorHeader", Vector3(3.0, 0.8, 0.25), Vector3(0.0, 3.6, 4.0), wall, true)

    var roof: = MeshInstance3D.new()
    roof.name = "GableRoof"
    var cone: = PrismMesh.new()
    cone.size = Vector3(9.2, 2.8, 9.2)
    roof.mesh = cone
    roof.position = Vector3(0.0, 5.35, 0.0)
    var roof_mat: = StandardMaterial3D.new()
    roof_mat.albedo_color = Color(0.42, 0.28, 0.22)
    roof.material_override = roof_mat
    add_child(roof)

    var trim := StandardMaterial3D.new()
    trim.albedo_color = Color(0.84, 0.82, 0.7)
    trim.roughness = 0.82
    var door := StandardMaterial3D.new()
    door.albedo_color = Color(0.16, 0.31, 0.34)
    door.roughness = 0.7
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color(0.12, 0.24, 0.31)
    glass.emission_enabled = true
    glass.emission = Color(0.3, 0.48, 0.48)
    glass.emission_energy_multiplier = 0.18
    _add_room_piece("DoorTrim", Vector3(2.7, 3.4, 0.28), Vector3(0.0, 1.8, 4.12), trim)
    _add_room_piece("FrontDoor", Vector3(2.15, 2.9, 0.34), Vector3(0.0, 1.55, 4.3), door, true)
    for x in [-2.7, 2.7]:
        _add_room_piece("WindowTrim", Vector3(1.75, 1.9, 0.28), Vector3(x, 2.2, 4.12), trim)
        _add_room_piece("WindowGlass", Vector3(1.35, 1.5, 0.34), Vector3(x, 2.2, 4.3), glass)
        _add_room_piece("WindowMullion", Vector3(0.1, 1.5, 0.4), Vector3(x, 2.2, 4.5), trim)
        _add_room_piece("WindowMullion", Vector3(1.35, 0.1, 0.4), Vector3(x, 2.2, 4.5), trim)
    for step in range(2):
        _add_room_piece(
            "EntryStep",
            Vector3(3.5 + float(step) * 0.7, 0.24, 0.9),
            Vector3(0.0, 0.12 + float(step) * 0.2, 4.8 + float(step) * 0.5),
            trim,
            true
        )

    var bed_mat := StandardMaterial3D.new()
    bed_mat.albedo_color = Color(0.2, 0.34, 0.46)
    _add_room_piece("Bed", Vector3(2.0, 0.7, 3.4), Vector3(-2.2, 0.55, -1.8), bed_mat)
    var table_mat := StandardMaterial3D.new()
    table_mat.albedo_color = Color(0.34, 0.2, 0.1)
    _add_room_piece("SaveTable", Vector3(1.4, 0.9, 1.0), Vector3(2.5, 0.55, -2.6), table_mat)

    var lamp := OmniLight3D.new()
    lamp.light_color = Color(1.0, 0.7, 0.42)
    lamp.light_energy = 1.2
    lamp.omni_range = 8.0
    lamp.position = Vector3(0.0, 3.2, 0.0)
    lamp.add_to_group("authored_lantern")
    add_child(lamp)

    var ring: = MeshInstance3D.new()
    ring.name = "SafehouseGroundRing"
    var torus: = TorusMesh.new()
    torus.inner_radius = 2.15
    torus.outer_radius = 2.42
    ring.mesh = torus
    ring.position = Vector3(0.0, 0.11, 5.15)
    var mat: = StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color = Color(0.35, 0.92, 0.55, 0.42)
    ring.material_override = mat
    add_child(ring)

    var lbl: = Label3D.new()
    lbl.text = "SAFEHOUSE"
    lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lbl.modulate = Color(0.72, 0.98, 0.78)
    lbl.font_size = 44
    lbl.pixel_size = 0.014
    lbl.position = Vector3(0.0, 4.55, 4.35)
    lbl.outline_modulate = Color(0.03, 0.05, 0.06)
    lbl.outline_size = 7
    add_child(lbl)


func _add_room_piece(
    piece_name: String,
    size: Vector3,
    position: Vector3,
    material: Material,
    collision: bool = false
) -> void:
    var piece := MeshInstance3D.new()
    piece.name = piece_name
    var mesh := BoxMesh.new()
    mesh.size = size
    piece.mesh = mesh
    piece.position = position
    piece.material_override = material
    add_child(piece)
    if collision:
        var body := StaticBody3D.new()
        body.collision_layer = 1
        var shape := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = size
        shape.shape = box
        body.position = position
        body.add_child(shape)
        add_child(body)


func _physics_process(delta: float) -> void :
    var world: = get_tree().get_first_node_in_group("game_world")
    if world == null:
        return
    var player: Variant = world.get("_player")
    if player == null or not is_instance_valid(player):
        return
    if "_driving" in player and player._driving:
        _inside = false
        _hinted = false
        return

    var pp: Vector3 = player.global_position
    var here: bool = Vector2(pp.x - global_position.x, pp.z - global_position.z).length() <= RADIUS
    if here and not _inside:
        GameManager.show_message("Safehouse — press T to sleep til morning.")
        _hinted = true
    _inside = here

    if not here:
        return

    if GameManager.wanted_level > 0:
        if randf() < delta * 0.35:
            GameManager.set_wanted(GameManager.wanted_level - 1)
    if GameManager.faction_level > 0:
        if randf() < delta * 0.35:
            GameManager.set_faction(GameManager.faction_level - 1)

    _save_timer += delta
    if _save_timer >= 3.0:
        _save_timer = 0.0
        GameManager.save_game()

    if Input.is_action_just_pressed("sleep"):
        _sleep(player)


func _sleep(player: Node) -> void :
    GameManager.set_wanted(0)
    GameManager.set_faction(0)
    GameManager.day_phase = SLEEP_PHASE
    GameManager.save_game()
    if player.has_method("heal_full"):
        player.heal_full()
    elif "health" in player and "max_health" in player:
        player.health = player.max_health
    GameManager.show_message("Slept til morning — heat cleared, game saved.")
    if AudioManager:
        var snd: = load("res://assets/audio/sfx/ui/ui_shop_buy.mp3")
        if snd:
            AudioManager.play_sfx(snd, -8.0)
