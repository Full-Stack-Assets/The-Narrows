extends Node3D
class_name JobMarker




signal reached

var radius: float = 4.0
var target: Node3D = null
var _done: bool = false
var _beam: MeshInstance3D
var _ring: MeshInstance3D


func setup(pos: Vector3, p_radius: float, color: Color, p_target: Node3D) -> void :
    radius = p_radius
    target = p_target
    global_position = pos
    _build(color)


func _build(color: Color) -> void :

    _beam = MeshInstance3D.new()
    var cyl: = CylinderMesh.new()
    # The interaction radius belongs on the ground ring. Using it for the
    # vertical beacon produced an opaque 18–25 m wall that hid the destination.
    var beacon_radius := clampf(radius * 0.08, 0.55, 1.15)
    cyl.top_radius = beacon_radius * 0.35
    cyl.bottom_radius = beacon_radius
    cyl.height = 9.0
    _beam.mesh = cyl
    _beam.position.y = 4.5
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(color.r, color.g, color.b, 0.08)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 0.45
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    _beam.material_override = mat
    _beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_beam)


    _ring = MeshInstance3D.new()
    var torus: = TorusMesh.new()
    torus.inner_radius = radius - 0.4
    torus.outer_radius = radius
    _ring.mesh = torus
    _ring.position.y = 0.1
    var rmat: = StandardMaterial3D.new()
    rmat.albedo_color = color
    rmat.emission_enabled = true
    rmat.emission = color
    rmat.emission_energy_multiplier = 2.4
    rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _ring.material_override = rmat
    _ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_ring)


func _process(delta: float) -> void :
    if _beam:
        _beam.rotation.y += delta * 0.8
    if _done or target == null or not is_instance_valid(target):
        return
    var to: = target.global_position - global_position
    to.y = 0.0
    if to.length() < radius:
        _done = true
        reached.emit()
