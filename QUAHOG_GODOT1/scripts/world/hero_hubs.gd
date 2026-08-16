extends RefCounted
class_name HeroHubs

# Hero district hubs — Dartmouth Mall, Champion City Gym (Brockton), Cape Cod Canal,
# Chip Worthington's Heritage Marina (Act III).

const DARTMOUTH_MALL: = Vector3(-3921.0, 0.0, -378.0)
const CHAMPION_GYM: = Vector3(-8350.0, 0.0, -49620.0)
const CAPE_CANAL: = Vector3(-11050.0, 0.0, -47600.0)
const HERITAGE_MARINA: = Vector3(-10520.0, 0.0, -47420.0)
const DETAIL_RADIUS: float = 1400.0


static func build(parent: Node3D, detail_origin: Vector3 = Vector3.ZERO) -> void :
    var root: = Node3D.new()
    root.name = "HeroHubs"
    parent.add_child(root)
    var hubs := [
        ["Dartmouth Mall", DARTMOUTH_MALL, Callable(HeroHubs, "_dartmouth_mall")],
        ["Champion City Gym", CHAMPION_GYM, Callable(HeroHubs, "_champion_gym")],
        ["Cape Cod Canal", CAPE_CANAL, Callable(HeroHubs, "_cape_canal")],
        ["Heritage Marina", HERITAGE_MARINA, Callable(HeroHubs, "_heritage_marina")],
    ]
    for hub in hubs:
        if detail_origin.distance_to(hub[1]) <= DETAIL_RADIUS:
            hub[2].call(root)
        else:
            _navigation_marker(root, hub[0], hub[1])


static func _navigation_marker(root: Node3D, title: String, position: Vector3) -> void:
    var marker := Node3D.new()
    marker.name = title.to_pascal_case()
    marker.position = position
    root.add_child(marker)
    var label := Label3D.new()
    label.text = title.to_upper()
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.visibility_range_end = 650.0
    label.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
    label.modulate = Color(0.74, 0.82, 0.84)
    label.font_size = 36
    label.pixel_size = 0.022
    label.position = Vector3(0.0, 10.0, 0.0)
    marker.add_child(label)


static func _dartmouth_mall(root: Node3D) -> void :
    var hub: = Node3D.new()
    hub.name = "DartmouthMall"
    hub.position = DARTMOUTH_MALL
    root.add_child(hub)

    var lot: = MeshInstance3D.new()
    var lot_mesh: = PlaneMesh.new()
    lot_mesh.size = Vector2(160.0, 120.0)
    lot.mesh = lot_mesh
    lot.rotation.x = -PI * 0.5
    lot.position = Vector3(0.0, 0.05, 40.0)
    var lot_mat: = StandardMaterial3D.new()
    lot_mat.albedo_color = Color(0.24, 0.25, 0.28)
    lot_mat.roughness = 0.95
    lot.material_override = lot_mat
    hub.add_child(lot)

    var mall: = MeshInstance3D.new()
    var mall_box: = BoxMesh.new()
    mall_box.size = Vector3(150.0, 12.0, 70.0)
    mall.mesh = mall_box
    mall.position = Vector3(0.0, 6.0, -20.0)
    var mall_mat: = StandardMaterial3D.new()
    mall_mat.albedo_color = Color(0.72, 0.66, 0.56)
    mall_mat.roughness = 0.88
    mall.material_override = mall_mat
    hub.add_child(mall)

    var canopy: = MeshInstance3D.new()
    var canopy_box: = BoxMesh.new()
    canopy_box.size = Vector3(24.0, 8.0, 8.0)
    canopy.mesh = canopy_box
    canopy.position = Vector3(0.0, 4.0, 16.0)
    canopy.material_override = mall_mat
    hub.add_child(canopy)

    var sign_pole: = MeshInstance3D.new()
    var pole: = BoxMesh.new()
    pole.size = Vector3(1.2, 16.0, 1.2)
    sign_pole.mesh = pole
    sign_pole.position = Vector3(60.0, 8.0, 70.0)
    var pole_mat: = StandardMaterial3D.new()
    pole_mat.albedo_color = Color(0.2, 0.22, 0.24)
    sign_pole.material_override = pole_mat
    hub.add_child(sign_pole)

    var sign: = MeshInstance3D.new()
    var sign_box: = BoxMesh.new()
    sign_box.size = Vector3(10.0, 5.0, 0.6)
    sign.mesh = sign_box
    sign.position = Vector3(60.0, 14.0, 70.0)
    var sign_mat: = StandardMaterial3D.new()
    sign_mat.albedo_color = Color(0.12, 0.31, 0.47)
    sign_mat.emission_enabled = true
    sign_mat.emission = Color(0.15, 0.38, 0.58)
    sign_mat.emission_energy_multiplier = 0.5
    sign.material_override = sign_mat
    sign.add_to_group("neon_sign")
    hub.add_child(sign)

    var lamp: = OmniLight3D.new()
    lamp.light_color = Color(0.35, 0.65, 1.0)
    lamp.light_energy = 0.0
    lamp.omni_range = 28.0
    lamp.position = Vector3(0.0, 8.0, 10.0)
    lamp.add_to_group("neon_light")
    hub.add_child(lamp)

    var lbl: = Label3D.new()
    lbl.text = "DARTMOUTH MALL"
    lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lbl.modulate = Color(0.95, 0.9, 0.82)
    lbl.font_size = 52
    lbl.pixel_size = 0.028
    lbl.position = Vector3(0.0, 16.0, 8.0)
    hub.add_child(lbl)

    var shop: = Area3D.new()
    shop.collision_layer = 32
    shop.collision_mask = 0
    var scol: = CollisionShape3D.new()
    var sshape: = BoxShape3D.new()
    sshape.size = Vector3(80.0, 8.0, 60.0)
    scol.shape = sshape
    scol.position = Vector3(0.0, 4.0, 0.0)
    shop.add_child(scol)
    hub.add_child(shop)


static func _champion_gym(root: Node3D) -> void :
    var hub: = Node3D.new()
    hub.name = "ChampionCityGym"
    hub.position = CHAMPION_GYM
    root.add_child(hub)

    var gym: = MeshInstance3D.new()
    var gym_box: = BoxMesh.new()
    gym_box.size = Vector3(22.0, 8.0, 18.0)
    gym.mesh = gym_box
    gym.position = Vector3(0.0, 4.0, 0.0)
    var brick: = StandardMaterial3D.new()
    brick.albedo_color = Color(0.48, 0.26, 0.2)
    brick.roughness = 0.9
    gym.material_override = brick
    hub.add_child(gym)

    var ring: = MeshInstance3D.new()
    var ring_cyl: = CylinderMesh.new()
    ring_cyl.top_radius = 5.5
    ring_cyl.bottom_radius = 5.5
    ring_cyl.height = 0.25
    ring.mesh = ring_cyl
    ring.position = Vector3(0.0, 0.15, 0.0)
    var rope: = StandardMaterial3D.new()
    rope.albedo_color = Color(0.85, 0.2, 0.18)
    rope.emission_enabled = true
    rope.emission = Color(0.9, 0.25, 0.2)
    rope.emission_energy_multiplier = 0.35
    ring.material_override = rope
    hub.add_child(ring)

    var lamp: = OmniLight3D.new()
    lamp.light_color = Color(1.0, 0.45, 0.25)
    lamp.light_energy = 0.0
    lamp.omni_range = 24.0
    lamp.position = Vector3(0.0, 6.0, 0.0)
    lamp.add_to_group("neon_light")
    hub.add_child(lamp)

    var lbl: = Label3D.new()
    lbl.text = "CHAMPION CITY GYM"
    lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lbl.modulate = Color(1.0, 0.78, 0.45)
    lbl.font_size = 48
    lbl.pixel_size = 0.026
    lbl.position = Vector3(0.0, 12.0, 0.0)
    hub.add_child(lbl)


static func _cape_canal(root: Node3D) -> void :
    var hub: = Node3D.new()
    hub.name = "CapeCodCanal"
    hub.position = CAPE_CANAL
    root.add_child(hub)

    var water: = MeshInstance3D.new()
    var water_plane: = PlaneMesh.new()
    water_plane.size = Vector2(220.0, 80.0)
    water.mesh = water_plane
    water.rotation.x = -PI * 0.5
    water.position = Vector3(0.0, -0.2, 0.0)
    var wmat: = StandardMaterial3D.new()
    wmat.albedo_color = Color(0.1, 0.28, 0.42)
    wmat.roughness = 0.15
    wmat.metallic = 0.05
    water.material_override = wmat
    hub.add_child(water)

    for side in [-1.0, 1.0]:
        var span: = MeshInstance3D.new()
        var arch: = BoxMesh.new()
        arch.size = Vector3(8.0, 14.0, 90.0)
        span.mesh = arch
        span.position = Vector3(55.0 * side, 7.0, 0.0)
        var steel: = StandardMaterial3D.new()
        steel.albedo_color = Color(0.42, 0.44, 0.48)
        steel.metallic = 0.55
        steel.roughness = 0.45
        span.material_override = steel
        hub.add_child(span)

    var lbl: = Label3D.new()
    lbl.text = "CAPE COD CANAL"
    lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lbl.modulate = Color(0.75, 0.88, 0.95)
    lbl.font_size = 44
    lbl.pixel_size = 0.024
    lbl.position = Vector3(0.0, 18.0, 0.0)
    hub.add_child(lbl)


static func _heritage_marina(root: Node3D) -> void :
    var hub: = Node3D.new()
    hub.name = "HeritageMarina"
    hub.position = HERITAGE_MARINA
    root.add_child(hub)

    var dock: = MeshInstance3D.new()
    var dock_plane: = PlaneMesh.new()
    dock_plane.size = Vector2(90.0, 28.0)
    dock.mesh = dock_plane
    dock.rotation.x = -PI * 0.5
    dock.position = Vector3(0.0, 0.08, 8.0)
    var wood: = StandardMaterial3D.new()
    wood.albedo_color = Color(0.42, 0.34, 0.26)
    wood.roughness = 0.92
    dock.material_override = wood
    hub.add_child(dock)

    var yacht: = MeshInstance3D.new()
    var hull: = BoxMesh.new()
    hull.size = Vector3(18.0, 5.0, 6.0)
    yacht.mesh = hull
    yacht.position = Vector3(-12.0, 2.5, 0.0)
    var hull_mat: = StandardMaterial3D.new()
    hull_mat.albedo_color = Color(0.92, 0.94, 0.96)
    hull_mat.roughness = 0.35
    hull_mat.metallic = 0.15
    yacht.material_override = hull_mat
    hub.add_child(yacht)

    var clubhouse: = MeshInstance3D.new()
    var club_box: = BoxMesh.new()
    club_box.size = Vector3(22.0, 8.0, 14.0)
    clubhouse.mesh = club_box
    clubhouse.position = Vector3(28.0, 4.0, -10.0)
    var club_mat: = StandardMaterial3D.new()
    club_mat.albedo_color = Color(0.68, 0.62, 0.52)
    club_mat.roughness = 0.85
    clubhouse.material_override = club_mat
    hub.add_child(clubhouse)

    var sign: = Label3D.new()
    sign.text = "HERITAGE MARINA"
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.modulate = Color(0.82, 0.9, 0.95)
    sign.font_size = 44
    sign.pixel_size = 0.024
    sign.position = Vector3(0.0, 14.0, 18.0)
    hub.add_child(sign)
