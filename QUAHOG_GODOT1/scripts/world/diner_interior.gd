extends Node3D
class_name DinerInterior

# Linguiça Linq — enterable diner (interior menu overlay).

@export var interact_prompt: String = "Enter Linguiça Linq"


func setup(pos: Vector3) -> void :
    global_position = pos


func _ready() -> void :
    var area: = Area3D.new()
    area.collision_layer = 32
    area.collision_mask = 0
    var acol: = CollisionShape3D.new()
    var ashape: = SphereShape3D.new()
    ashape.radius = 3.2
    acol.shape = ashape
    acol.position.y = 1.0
    area.add_child(acol)
    add_child(area)

    var fm: = StandardMaterial3D.new()
    fm.albedo_color = Color(0.34, 0.12, 0.075)
    fm.roughness = 0.88
    var tile := StandardMaterial3D.new()
    tile.albedo_color = Color(0.66, 0.62, 0.48)
    tile.roughness = 0.82
    _add_piece("Floor", Vector3(8.0, 0.18, 6.0), Vector3(0.0, 0.09, 0.0), tile, true)
    _add_piece("BackWall", Vector3(8.0, 3.2, 0.2), Vector3(0.0, 1.6, -3.0), fm, true)
    _add_piece("LeftWall", Vector3(0.2, 3.2, 6.0), Vector3(-4.0, 1.6, 0.0), fm, true)
    _add_piece("RightWall", Vector3(0.2, 3.2, 6.0), Vector3(4.0, 1.6, 0.0), fm, true)
    _add_piece("FrontLeft", Vector3(2.8, 3.2, 0.2), Vector3(-2.6, 1.6, 3.0), fm, true)
    _add_piece("FrontRight", Vector3(2.8, 3.2, 0.2), Vector3(2.6, 1.6, 3.0), fm, true)
    _add_piece("DoorHeader", Vector3(2.4, 0.6, 0.2), Vector3(0.0, 2.9, 3.0), fm, true)

    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color(0.08, 0.25, 0.30)
    glass.roughness = 0.24
    glass.emission_enabled = true
    glass.emission = Color(0.2, 0.44, 0.42)
    glass.emission_energy_multiplier = 0.32
    var cream := StandardMaterial3D.new()
    cream.albedo_color = Color(0.86, 0.78, 0.58)
    cream.roughness = 0.78
    for x in [-2.65, 2.65]:
        _add_piece("FrontWindowTrim", Vector3(2.05, 2.1, 0.25), Vector3(x, 1.65, 3.08), cream)
        _add_piece("FrontWindow", Vector3(1.68, 1.72, 0.32), Vector3(x, 1.65, 3.25), glass)
        _add_piece("WindowMullion", Vector3(0.1, 1.72, 0.38), Vector3(x, 1.65, 3.44), cream)
        _add_piece("WindowMullion", Vector3(1.68, 0.1, 0.38), Vector3(x, 1.65, 3.44), cream)
    _add_piece("Awning", Vector3(8.7, 0.3, 1.2), Vector3(0.0, 3.15, 3.48), cream)
    _add_piece("Sidewalk", Vector3(10.0, 0.16, 4.0), Vector3(0.0, 0.08, 4.3), tile, true)
    var roof := MeshInstance3D.new()
    roof.name = "DinerRoof"
    var roof_mesh := PrismMesh.new()
    roof_mesh.size = Vector3(8.8, 1.8, 6.8)
    roof.mesh = roof_mesh
    roof.position = Vector3(0.0, 4.0, 0.0)
    roof.material_override = fm
    add_child(roof)

    var counter := StandardMaterial3D.new()
    counter.albedo_color = Color(0.1, 0.26, 0.28)
    counter.metallic = 0.12
    _add_piece("Counter", Vector3(5.5, 1.1, 0.9), Vector3(0.6, 0.65, -1.8), counter)
    var booth := StandardMaterial3D.new()
    booth.albedo_color = Color(0.5, 0.08, 0.07)
    for x in [-2.6, 2.6]:
        _add_piece("Booth", Vector3(1.5, 0.9, 1.8), Vector3(x, 0.55, 0.6), booth)

    var sign := Label3D.new()
    sign.text = "LINGUIÇA LINQ"
    sign.font_size = 42
    sign.pixel_size = 0.016
    sign.position = Vector3(0.0, 3.75, 3.62)
    sign.modulate = Color(1.0, 0.64, 0.24)
    sign.outline_modulate = Color(0.18, 0.035, 0.02)
    sign.outline_size = 8
    add_child(sign)

    var lamp := OmniLight3D.new()
    lamp.light_color = Color(1.0, 0.58, 0.3)
    lamp.light_energy = 1.4
    lamp.omni_range = 9.0
    lamp.position = Vector3(0.0, 2.7, 0.0)
    lamp.add_to_group("authored_lantern")
    add_child(lamp)


func _add_piece(
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


func interact(_player: Node) -> void :
    if GameManager:
        GameManager.open_diner_requested.emit()
