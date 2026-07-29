extends Node3D





const PLAYER_SCENE: = preload("res://scenes/player.tscn")
const NPC_SCRIPT: = preload("res://scripts/npc.gd")
const MISSION_GIVER_SCRIPT: = preload("res://scripts/mission_giver.gd")
const HUD_SCRIPT: = preload("res://scripts/ui/hud.gd")
const CityBuilderScript: = preload("res://scripts/world/city_builder.gd")
const MapLoaderScript: = preload("res://scripts/world/map_loader.gd")
const CarScript: = preload("res://scripts/vehicles/car.gd")
const TrafficCarScript: = preload("res://scripts/vehicles/traffic_car.gd")
const JobManagerScript: = preload("res://scripts/systems/job_manager.gd")
const WantedSystemScript: = preload("res://scripts/systems/wanted_system.gd")
const WeaponPickupScript: = preload("res://scripts/weapons/weapon_pickup.gd")
const ShopScript: = preload("res://scripts/world/shop.gd")
const ShopMenuScript: = preload("res://scripts/ui/shop_menu.gd")
const StoryMissionScript: = preload("res://scripts/systems/story_mission.gd")
const WaterHazardScript: = preload("res://scripts/systems/water_hazard.gd")
const ResprayZoneScript: = preload("res://scripts/world/respray_zone.gd")
const SafehouseZoneScript: = preload("res://scripts/world/safehouse_zone.gd")
const ScrimshawCollectibleScript: = preload("res://scripts/world/scrimshaw_collectible.gd")
const BusinessFrontsScript: = preload("res://scripts/world/business_fronts.gd")
const DinerInteriorScript: = preload("res://scripts/world/diner_interior.gd")
const DinerMenuScript: = preload("res://scripts/ui/diner_menu.gd")
const NeonSignsScript: = preload("res://scripts/world/neon_signs.gd")
const HeroHubsScript: = preload("res://scripts/world/hero_hubs.gd")

# Cars everywhere: every parked car is a real, takeable drivable car (parked
# cars are frozen/dormant in car.gd, so a full map costs almost nothing until you
# get in one). TRAFFIC_CARS are the moving ambient cars.
# Parked cars stream around the player: a pool of CAR_POOL takeable cars is kept
# within CAR_NEAR of you, and any that drift past CAR_FAR are relocated to a fresh
# road point nearby — so there are always cars wherever you are on the big map.
# ~200 cars/km^2: CAR_NEAR is a 560 m radius (~0.98 km^2), so a 200-car pool
# fills it at roughly that density. Parked cars are dormant (see car.gd), so the
# cost of a couple hundred of them is near-zero until one is entered.
const CAR_POOL: = 200
const CAR_NEAR: = 560.0
const CAR_FAR: = 900.0
const TRAFFIC_CARS: = 16
# How many 500 m tiles out from the New Bedford core to build at once. The web
# build streams tiles; here we load a fixed core radius (P2 = streaming).
const MAP_RADIUS: = 2

# Curated South Coast hero landmarks (real OSM coords, world XZ where z = -north).
# Each gets an emissive dusk beacon + a billboard name so the corridor towns are
# recognizable the moment you fast-travel in — not anonymous streamed blocks.
const HERO_LANDMARKS: Array = [
    {"name": "Whaling Museum", "pos": Vector2(-219, 107), "tag": "museum", "h": 18.0},
    {"name": "Seamen's Bethel", "pos": Vector2(-272, 106)},
    {"name": "New Bedford City Hall", "pos": Vector2(-582, 60)},
    {"name": "Fort Taber", "pos": Vector2(1495, 4560)},
    {"name": "Clark's Point Light", "pos": Vector2(1598, 4764)},
    {"name": "Fairhaven", "pos": Vector2(1539, 32)},
    {"name": "Dartmouth Mall", "pos": Vector2(-3921, -378), "tag": "mall", "h": 16.0},
    {"name": "Cape Cod Canal", "pos": Vector2(-11050, -47600), "tag": "cape", "h": 20.0},
    {"name": "Heritage Marina", "pos": Vector2(-10520, -47420), "tag": "marina", "h": 16.0},
    {"name": "UMass Dartmouth", "pos": Vector2(-7190, 767)},
    {"name": "Westport", "pos": Vector2(-11897, 1521)},
    {"name": "Fall River City Hall", "pos": Vector2(-19475, -7216)},
    {"name": "Battleship Cove", "pos": Vector2(-20180, -7882), "tag": "battleship", "h": 22.0},
    {"name": "Lizzie Borden House", "pos": Vector2(-19599, -7080), "tag": "borden", "h": 14.0},
    {"name": "St. Mary's Cathedral", "pos": Vector2(-19696, -6969)},
    {"name": "Notre Dame Cathedral", "pos": Vector2(-17596, -6054)},
    {"name": "Narrows Center", "pos": Vector2(-20164, -7470)},
    {"name": "Green Monstah Mural", "pos": Vector2(-19570, -9192)},
    {"name": "Middleborough", "pos": Vector2(791, -28609)},
    {"name": "Taunton Green", "pos": Vector2(-14085, -29389)},
    {"name": "Bridgewater", "pos": Vector2(-4113, -39407)},
    {"name": "Brockton", "pos": Vector2(-8100, -49768)},
    {"name": "Stoughton", "pos": Vector2(-14916, -54435)},
    {"name": "Braintree", "pos": Vector2(-6951, -63664)},
    {"name": "Quincy", "pos": Vector2(-6809, -68672)},
]

var _tex_asphalt: Texture2D
var _tex_concrete: Texture2D

# Day/night: a slow clock (phase 0..1 over DAY_LENGTH seconds) drives the sun
# angle + ambient/fog. Anchored so dusk — the game's signature look — sits at
# the start and recurs each cycle.
const DAY_LENGTH: float = 600.0     # seconds for a full day→night→day loop
var _sun: DirectionalLight3D = null
var _env: Environment = null
var _day_phase: float = 0.0

# Weather: rain drifts in and out. The emitter rides above the player; when it's
# raining the fog thickens a touch on top of the day/night base.
var _rain: CPUParticles3D = null
var _weather_t: float = 25.0
var _raining: bool = false
var _gloria_flood: MeshInstance3D = null
var _gloria_flood_y: float = -2.0
var _gloria_active: bool = false
var _rain_dir_calm: Vector3 = Vector3(0.05, -1.0, 0.0)
var _rain_box_calm: Vector3 = Vector3(26.0, 0.5, 26.0)
# Real-map builder (MapLoader). Untyped because it replaces the old CityBuilder
# but exposes the same spawn fields (player_spawn, car_slots, light_slots,
# npc_waypoints, npc_spawns, mission_giver_pos/rot, job_points).
var _city
var _player: CharacterBody3D
var _hud: CanvasLayer
var _drivable_cars: Array = []
var _traffic: Array = []
var _npcs: Array = []
var _street_lights: Array = []
var _last_stream_tile: Vector2i = Vector2i(999999, 999999)
var _car_restream_i: int = 0
var _road_cands: Array = []
var _road_cand_tile: Vector2i = Vector2i(999999, 999999)
var _road_cand_i: int = 0
var _contacts: Array = []
var _job_manager: Node = null
var _wanted_system: Node = null
var _story_mission: Node = null
var _water_hazard: Node = null
var _ambient_player: AudioStreamPlayer = null
var _tod_life_t: float = 0.0
var _day_phase_override_pending: bool = false


func get_wanted_system() -> Node:
    return _wanted_system


func set_gloria_storm(active: bool) -> void :
    if _gloria_active == active:
        return
    _gloria_active = active
    if GameManager:
        GameManager.gloria_storm_active = active
    if active:
        _raining = true
        if _rain:
            _rain.emitting = true
        _weather_t = 9999.0
        if _gloria_flood:
            _gloria_flood.visible = true
        GameManager.show_message("GLORIA — Hurricane Gloria coming ashore. Get to high ground!")
        if has_node("/root/RadioHooks"):
            get_node("/root/RadioHooks").call_deferred("on_gloria_started")
    else:
        _weather_t = 90.0
        if _gloria_flood:
            _gloria_flood.visible = false
            _gloria_flood_y = -2.0
            _gloria_flood.position.y = -2.0
        if _rain:
            _rain.direction = _rain_dir_calm
            _rain.emission_box_extents = _rain_box_calm
        GameManager.show_message("The storm's breaking — skies clearing over the bay.")


func _ready() -> void :
    add_to_group("game_world")
    # Cheat: global slow-mo / fast-forward (clamped to a sane range).
    if GameManager:
        Engine.time_scale = clampf(GameManager.cheat_time_scale, 0.1, 4.0)

    _tex_asphalt = load("res://assets/textures/floors/wet_asphalt.png")
    _tex_concrete = load("res://assets/textures/floors/concrete_sidewalk.png")

    _setup_environment()
    if GameManager:
        GameManager.graphics_quality_changed.connect(_apply_graphics_quality)
    _build_city()
    if StartupMetrics:
        StartupMetrics.mark("core_map_ready")
    _apply_graphics_quality()
    _spawn_player()
    if StartupMetrics:
        StartupMetrics.mark("player_ready")
    if _player.has_signal("shots_fired"):
        _player.shots_fired.connect(_on_shots_fired)
    _build_hud()
    _build_systems()
    if StartupMetrics:
        StartupMetrics.mark("world_interactive")
    call_deferred("_start_deferred_city")


func _start_deferred_city() -> void:
    await get_tree().process_frame
    if DeferredContent:
        await DeferredContent.ensure_loaded()
    if _city and _city.has_method("stream_buildings"):
        _city.stream_buildings(_player.global_position)
    await get_tree().process_frame
    _place_cars()
    await get_tree().process_frame
    _spawn_traffic()
    await get_tree().process_frame
    _place_streetlights()
    _place_landmark_beacons()
    await get_tree().process_frame
    _spawn_contacts()
    _spawn_npcs()
    for tc in _traffic:
        if is_instance_valid(tc):
            tc.player = _player
    for npc in _npcs:
        if is_instance_valid(npc):
            npc.player = _player
    for contact in _contacts:
        if is_instance_valid(contact):
            contact.job_manager = _job_manager
    await get_tree().process_frame
    _spawn_pickups()
    _spawn_scrimshaw()
    _spawn_shops()
    _build_shop_menu()
    _build_diner()
    NeonSignsScript.build(self)
    HeroHubsScript.build(self)
    _start_audio()
    _setup_weather()
    _setup_gloria_flood()
    if _city and _city.has_method("build_distant_world"):
        await get_tree().process_frame
        _city.build_distant_world(self)
    call_deferred("_apply_tod_life")


# Emissive dusk beacon + billboard name at each curated hero landmark, so the
# corridor towns read as recognizable places from a distance. Cheap (one mesh +
# one Label3D each); placed once at load over the whole region.
func _place_landmark_beacons() -> void :
    var root: = Node3D.new()
    root.name = "Landmarks"
    add_child(root)
    var font: Font = load("res://assets/fonts/noto_serif.ttf")
    for lm in HERO_LANDMARKS:
        var p: Vector2 = lm["pos"]
        var nm: String = str(lm["name"])
        var tag: String = str(lm.get("tag", ""))
        var tower_h: float = float(lm.get("h", 12.0))
        var beacon: = MeshInstance3D.new()
        var cyl: = CylinderMesh.new()
        cyl.top_radius = 0.25 if tag == "" else 0.35
        cyl.bottom_radius = 0.7 if tag == "" else 1.0
        cyl.height = tower_h
        beacon.mesh = cyl
        var m: = StandardMaterial3D.new()
        if tag == "museum":
            m.albedo_color = Color(0.72, 0.58, 0.38)
            m.emission = Color(1.0, 0.82, 0.45)
        elif tag == "battleship":
            m.albedo_color = Color(0.55, 0.58, 0.62)
            m.emission = Color(0.75, 0.8, 0.9)
        elif tag == "borden":
            m.albedo_color = Color(0.62, 0.48, 0.42)
            m.emission = Color(1.0, 0.55, 0.35)
        elif tag == "mall":
            m.albedo_color = Color(0.55, 0.62, 0.78)
            m.emission = Color(0.45, 0.72, 1.0)
        elif tag == "cape":
            m.albedo_color = Color(0.38, 0.55, 0.68)
            m.emission = Color(0.55, 0.82, 0.95)
        elif tag == "marina":
            m.albedo_color = Color(0.42, 0.52, 0.62)
            m.emission = Color(0.55, 0.75, 0.88)
        else:
            m.albedo_color = Color(0.95, 0.72, 0.36)
            m.emission = Color(1.0, 0.74, 0.34)
        m.emission_enabled = true
        m.emission_energy_multiplier = 2.4
        beacon.material_override = m
        beacon.position = Vector3(p.x, tower_h * 0.5, p.y)
        root.add_child(beacon)
        var lbl: = Label3D.new()
        lbl.text = nm
        lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        lbl.modulate = Color(1.0, 0.91, 0.68)
        lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
        lbl.font_size = 64 if tag == "" else 72
        lbl.outline_size = 14
        lbl.pixel_size = 0.03
        lbl.position = Vector3(p.x, tower_h + 7.0, p.y)
        if font:
            lbl.font = font
        root.add_child(lbl)
        if tag == "museum":
            var sub: = Label3D.new()
            sub.text = "Johnny Cake Hill"
            sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
            sub.modulate = Color(0.9, 0.86, 0.72)
            sub.font_size = 36
            sub.pixel_size = 0.022
            sub.position = Vector3(p.x, tower_h + 3.5, p.y)
            if font:
                sub.font = font
            root.add_child(sub)
        elif tag == "borden":
            var sub: = Label3D.new()
            sub.text = "92 Second St"
            sub.billboard = BaseMaterial3D.BILLBOARD_ENABLED
            sub.modulate = Color(0.92, 0.78, 0.7)
            sub.font_size = 36
            sub.pixel_size = 0.022
            sub.position = Vector3(p.x, tower_h + 3.5, p.y)
            if font:
                sub.font = font
            root.add_child(sub)


func _setup_weather() -> void :
    var rain: = CPUParticles3D.new()
    rain.name = "Rain"
    rain.amount = GameManager.rain_particle_count() if GameManager else 280
    rain.lifetime = 1.1
    rain.local_coords = false
    rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    rain.emission_box_extents = Vector3(26.0, 0.5, 26.0)
    rain.direction = Vector3(0.05, -1.0, 0.0)
    rain.spread = 2.0
    rain.gravity = Vector3(0.0, -32.0, 0.0)
    rain.initial_velocity_min = 16.0
    rain.initial_velocity_max = 22.0
    var streak: = BoxMesh.new()
    streak.size = Vector3(0.015, 0.5, 0.015)
    rain.mesh = streak
    var mat: = StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color = Color(0.7, 0.78, 0.9, 0.5)
    rain.material_override = mat
    rain.emitting = false
    add_child(rain)
    _rain = rain


func _setup_gloria_flood() -> void :
    var flood: = MeshInstance3D.new()
    flood.name = "GloriaFlood"
    var plane: = PlaneMesh.new()
    plane.size = Vector2(420.0, 420.0)
    flood.mesh = plane
    flood.rotation.x = -PI * 0.5
    flood.position.y = -2.0
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.08, 0.22, 0.38, 0.62)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.roughness = 0.06
    mat.metallic = 0.08
    flood.material_override = mat
    flood.visible = false
    add_child(flood)
    _gloria_flood = flood



func _setup_environment() -> void :
    var env: = Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky: = load("res://assets/textures/skyboxes/south_coast_dusk_sky.tres") as Sky
    if sky:
        env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
    env.ambient_light_energy = 0.55
    env.background_energy_multiplier = 0.9

    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = 1.0

    env.glow_enabled = true
    env.glow_intensity = 0.4
    env.glow_bloom = 0.1

    # Cheap colour grade (works in the GL Compatibility web renderer, unlike
    # SSAO/SDFGI): a little more contrast + saturation lifts the flat dusk look.
    env.adjustment_enabled = true
    env.adjustment_brightness = 1.12
    env.adjustment_contrast = 1.06
    env.adjustment_saturation = 1.12

    # Lighter depth haze: the previous density (0.011) washed the whole city to
    # flat grey. Pull it well back so streets/buildings read with contrast, keep
    # just enough aerial perspective for distance.
    env.fog_enabled = true
    env.fog_light_color = Color(0.55, 0.60, 0.64)
    env.fog_density = 0.0018
    env.fog_sky_affect = 0.25
    env.fog_aerial_perspective = 0.25

    var we: = WorldEnvironment.new()
    we.name = "WorldEnvironment"
    we.environment = env
    add_child(we)
    _env = env

    var sun: = DirectionalLight3D.new()
    sun.name = "Sun"
    sun.light_color = Color(1.0, 0.86, 0.72)
    sun.light_energy = 0.8
    sun.shadow_enabled = true
    sun.shadow_bias = 0.03
    sun.shadow_normal_bias = 1.2
    # Cascaded shadows with a bounded distance so near buildings/cars cast crisp
    # shadows without trying to shadow the whole 80 km map.
    sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
    sun.directional_shadow_max_distance = 220.0
    sun.directional_shadow_split_1 = 0.06
    sun.directional_shadow_split_2 = 0.16
    sun.directional_shadow_split_3 = 0.45
    sun.directional_shadow_blend_splits = true
    sun.rotation_degrees = Vector3(-26.0, 52.0, 0.0)
    add_child(sun)
    _sun = sun
    _apply_day_night()


# Drive the sun + ambient/fog from _day_phase (0=dusk → night → dawn → day →
# back to dusk). Kept warm and gentle so the city keeps its dusk character.
func _process(delta: float) -> void :
    if GameManager and absf(GameManager.day_phase - _day_phase) > 0.08:
        _day_phase = GameManager.day_phase
        _day_phase_override_pending = true
    # Cheat: a forced time of day pins the clock; otherwise it advances normally.
    if GameManager and GameManager.cheat_time_phase >= 0.0:
        _day_phase = GameManager.cheat_time_phase
    elif _day_phase_override_pending:
        _day_phase_override_pending = false
    else:
        _day_phase = fposmod(_day_phase + delta / DAY_LENGTH, 1.0)
    _apply_day_night()
    _update_weather(delta)
    _update_streaming()
    _tod_life_t += delta
    if _tod_life_t >= 2.0:
        _tod_life_t = 0.0
        _apply_tod_life()
    if GameManager:
        GameManager.day_phase = _day_phase
        GameManager.raining = _raining


# Stream building tiles around the player. Tile builds are budgeted per frame;
# parked cars re-stream in small batches so a 200-car pool stays cheap.
func _update_streaming() -> void :
    if _city == null or _player == null or not is_instance_valid(_player):
        return
    var p: Vector3 = _player.global_position
    if _city.has_method("stream_buildings"):
        _city.stream_buildings(p)
    var tile: = Vector2i(int(floor(p.x / 500.0)), int(floor(-p.z / 500.0)))
    if tile != _road_cand_tile:
        _road_cand_tile = tile
        if _city.has_method("road_points_near"):
            _road_cands = _city.road_points_near(p, CAR_NEAR, 800)
            _road_cands.shuffle()
            _road_cand_i = 0
    _restream_cars_staggered(p)
    _last_stream_tile = tile


func _apply_graphics_quality() -> void :
    if _city == null or GameManager == null:
        return
    if _city.has_method("set_stream_quality"):
        _city.set_stream_quality(
            GameManager.stream_radius(),
            GameManager.stream_tile_budget(),
            GameManager.building_lod()
        )
    if _rain:
        _rain.amount = GameManager.rain_particle_count()


func _update_weather(delta: float) -> void :
    if _rain == null:
        return
    # Keep the emitter riding above the player.
    if _player != null and is_instance_valid(_player):
        _rain.global_position = _player.global_position + Vector3(0.0, 22.0, 0.0)
    # Scripted Gloria hurricane overrides the normal rain cycle.
    if GameManager and GameManager.gloria_storm_active:
        _raining = true
        _rain.emitting = true
        _rain.amount = maxi(420, GameManager.rain_particle_count())
        _rain.direction = Vector3(0.38, -1.0, 0.14).normalized()
        _rain.emission_box_extents = Vector3(44.0, 0.5, 44.0)
        if _env != null:
            _env.fog_density += 0.0048
        _update_gloria_flood(delta)
        return
    if _rain:
        _rain.direction = _rain_dir_calm
        _rain.emission_box_extents = _rain_box_calm
    # Cheat: a forced weather state overrides the timer.
    if GameManager and GameManager.cheat_force_rain >= 0:
        var want: bool = GameManager.cheat_force_rain == 1
        if _raining != want:
            _raining = want
            _rain.emitting = want
    else:
        # Flip weather on a long-ish timer (rain spells ~40s, dry ~90s).
        _weather_t -= delta
        if _weather_t <= 0.0:
            _raining = not _raining
            _rain.emitting = _raining
            _weather_t = 18.0 if _raining else 180.0
    # Rain thickens the haze slightly on top of the day/night base.
    if _raining and _env != null:
        _env.fog_density += 0.0012


func _update_gloria_flood(delta: float) -> void :
    if not _gloria_active or _gloria_flood == null or _player == null:
        return
    _gloria_flood.global_position = Vector3(_player.global_position.x, 0.0, _player.global_position.z)
    _gloria_flood_y = move_toward(_gloria_flood_y, 1.75, delta * 0.32)
    _gloria_flood.position.y = _gloria_flood_y


func _apply_day_night() -> void :
    if _sun == null or _env == null:
        return
    # Sun elevation: high at midday, below horizon at night. phase 0 = dusk.
    var ang: float = _day_phase * TAU
    var elevation: float = sin(ang + PI)        # +1 midday, -1 midnight; 0 at dusk/dawn
    _sun.rotation_degrees = Vector3(lerp(-2.0, -62.0, clampf((elevation + 1.0) * 0.5, 0.0, 1.0)), 52.0, 0.0)
    var daylight: float = clampf(elevation, 0.0, 1.0)        # 0 at/below horizon, 1 midday
    var night: float = clampf( - elevation, 0.0, 1.0)
    # Warm low sun, cooler bright midday; sun fades out at night.
    var warm: = Color(1.0, 0.66, 0.42)
    var noon: = Color(1.0, 0.93, 0.82)
    _sun.light_color = warm.lerp(noon, daylight)
    # Much brighter floors so dusk/night reads clearly instead of near-black.
    _sun.light_energy = lerp(0.6, 1.4, daylight)
    _env.ambient_light_energy = lerp(0.85, 1.15, daylight)
    _env.background_energy_multiplier = lerp(0.75, 1.1, daylight)
    # Lighter haze overall (it was crushing the foreground to black).
    _env.fog_light_color = Color(0.34, 0.38, 0.46).lerp(Color(0.58, 0.63, 0.67), daylight)
    _env.fog_density = lerp(0.0014, 0.0009, daylight)
    _env.glow_intensity = lerp(0.7, 0.35, daylight) + night * 0.2
    # Time-of-day colour grade: richer, moodier at dusk/night; flatter by day.
    _env.adjustment_saturation = lerp(1.22, 1.10, daylight)
    _env.adjustment_contrast = lerp(1.12, 1.05, daylight)
    # Streetlights warm up at dusk and glow through the night.
    var lamp_e: float = clampf(1.0 - daylight, 0.0, 1.0) * 3.0
    for lamp in _street_lights:
        if is_instance_valid(lamp):
            lamp.light_energy = lamp_e
    var window_glow: float = clampf(1.0 - daylight, 0.0, 1.0) * 0.42
    for node in get_tree().get_nodes_in_group("facade_emissive"):
        if node is MeshInstance3D and node.material_override is StandardMaterial3D:
            (node.material_override as StandardMaterial3D).emission_energy_multiplier = window_glow
    for lamp in get_tree().get_nodes_in_group("mooring_light"):
        if lamp is OmniLight3D:
            (lamp as OmniLight3D).light_energy = lamp_e * 0.55
    var neon_e: float = clampf(1.0 - daylight, 0.0, 1.0) * 1.6
    for lamp in get_tree().get_nodes_in_group("neon_light"):
        if lamp is OmniLight3D:
            (lamp as OmniLight3D).light_energy = neon_e
    for sign in get_tree().get_nodes_in_group("neon_sign"):
        if sign is MeshInstance3D and sign.material_override is StandardMaterial3D:
            (sign.material_override as StandardMaterial3D).emission_energy_multiplier = 0.1 + neon_e * 0.3
    for tc in _traffic:
        if is_instance_valid(tc) and tc.has_method("update_running_lights"):
            tc.update_running_lights(night)
    if _player and "current_car" in _player and _player.current_car and is_instance_valid(_player.current_car):
        var car = _player.current_car
        if car.has_method("update_vehicle_lights"):
            var braking: bool = false
            if "handbrake_on" in car:
                braking = car.handbrake_on
            car.update_vehicle_lights(night, braking)


func _apply_tod_life() -> void :
    if _sun == null:
        return
    var ang: float = _day_phase * TAU
    var daylight: float = clampf(sin(ang + PI), 0.0, 1.0)
    var night: float = clampf(1.0 - daylight, 0.0, 1.0)
    # Rush-hour bump around late afternoon; thin out peds/traffic deep at night.
    var rush: float = 1.0 if daylight > 0.35 and daylight < 0.85 else 0.72
    var traffic_keep: float = clampf(lerp(0.38, 1.0, daylight) * rush, 0.25, 1.0)
    var ped_keep: float = clampf(lerp(0.3, 1.0, daylight) * rush, 0.2, 1.0)
    for i in _traffic.size():
        var tc = _traffic[i]
        if not is_instance_valid(tc):
            continue
        var on: bool = float(i) / maxf(float(_traffic.size()), 1.0) < traffic_keep
        tc.visible = on
        tc.set_physics_process(on)
        if "base_speed" in tc:
            tc.speed = float(tc.base_speed) * lerp(0.75, 1.05, daylight) * rush
    for i in _npcs.size():
        var npc = _npcs[i]
        if not is_instance_valid(npc):
            continue
        var show: bool = float(i) / maxf(float(_npcs.size()), 1.0) < ped_keep
        npc.visible = show
        npc.set_physics_process(show)
        if "walk_speed" in npc:
            npc.walk_speed = lerp(1.1, 1.65, daylight) * (0.85 if night > 0.55 else 1.0)


func _make_ground() -> void :
    var body: = StaticBody3D.new()
    body.name = "Ground"
    body.collision_layer = 1
    body.collision_mask = 0
    add_child(body)

    var col: = CollisionShape3D.new()
    var box: = BoxShape3D.new()
    box.size = Vector3(900, 1.0, 900)
    col.shape = box
    col.position.y = -0.5
    body.add_child(col)

    var mesh: = MeshInstance3D.new()
    var plane: = PlaneMesh.new()
    plane.size = Vector2(900, 900)
    mesh.mesh = plane
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.15, 0.16, 0.17)
    if _tex_concrete:
        mat.albedo_texture = _tex_concrete
        mat.uv1_scale = Vector3(150, 150, 1)
    mat.roughness = 0.95
    mesh.set_surface_override_material(0, mat)
    body.add_child(mesh)



func _build_city() -> void :
    # Build the real New Bedford map (OSM footprints + roads + land use) instead
    # of the procedural grid. MapLoader also lays a ground plane + collider and
    # derives all the spawn fields game_world relies on.
    _city = MapLoaderScript.new()
    var radius: int = GameManager.stream_radius() if GameManager else MAP_RADIUS
    _city.build_region(self, Vector2i.ZERO, radius)



func _place_cars() -> void :
    if _city == null:
        return

    var models: = [
        {"path": "res://assets/props/vehicles/sedan.glb", "h": 1.5, "name": "Sedan", "spd": 68.0, "trq": 280.0, "mass": 1000.0},
        {"path": "res://assets/props/vehicles/taxi.glb", "h": 1.5, "name": "Cab", "spd": 76.0, "trq": 310.0, "mass": 1100.0},
        {"path": "res://assets/props/vehicles/suv.glb", "h": 1.85, "name": "SUV", "spd": 62.0, "trq": 340.0, "mass": 1500.0},
    ]
    # Spawn the pool on road points near where the player starts (dense), not
    # smeared across the whole 80 km region. _restream_cars keeps them near you.
    var slots: Array = _city.car_slots
    if _city.has_method("road_points_near"):
        slots = _city.road_points_near(_city.player_spawn, CAR_NEAR, 800)
    slots.shuffle()
    var pool: int = GameManager.car_pool_size() if GameManager else CAR_POOL
    var count: int = mini(pool, slots.size())
    for i in count:
        var slot = slots[i]
        var m: Dictionary = models[i % models.size()]
        var park: Array = _parked_xform(slot)
        _spawn_drivable_car(m, park[0], park[1])


# Park a car at the curb: offset the road-centerline sample sideways by half the
# road width + a margin, aligned to the road heading, so cars line the streets
# instead of sitting in the travel lanes. Side is deterministic per location so a
# car re-streamed to the same spot lands on the same curb.
func _parked_xform(slot: Array) -> Array:
    var pos: Vector3 = slot[0]
    var yaw: float = slot[1]
    var width: float = (float(slot[2]) if slot.size() > 2 else 6.0)
    var rad: float = deg_to_rad(yaw)
    var right: Vector3 = Vector3(cos(rad), 0.0, - sin(rad))
    var side: float = 1.0 if (int(absf(pos.x) + absf(pos.z)) % 2 == 0) else -1.0
    var offset: Vector3 = right * side * (width * 0.5 + 1.5)
    return [pos + offset, yaw]


# Relocate far parked cars onto road points near the player in small batches.
func _restream_cars_staggered(center: Vector3) -> void :
    if _city == null or _drivable_cars.is_empty():
        return
    var batch: int = GameManager.car_restream_batch() if GameManager else 12
    if _road_cands.is_empty() and _city.has_method("road_points_near"):
        _road_cands = _city.road_points_near(center, CAR_NEAR, 800)
        _road_cands.shuffle()
        _road_cand_i = 0
    if _road_cands.is_empty():
        return
    for _i in batch:
        if _drivable_cars.is_empty():
            break
        _car_restream_i = (_car_restream_i + 1) % _drivable_cars.size()
        var car = _drivable_cars[_car_restream_i]
        if not is_instance_valid(car):
            continue
        if _player != null and _player.current_car == car:
            continue
        var cp: Vector3 = car.global_position
        if Vector2(cp.x - center.x, cp.z - center.z).length() <= CAR_FAR:
            continue
        while _road_cand_i < _road_cands.size():
            var slot = _road_cands[_road_cand_i]
            _road_cand_i += 1
            var sp: Vector3 = slot[0]
            if Vector2(sp.x - center.x, sp.z - center.z).length() > 40.0:
                var park: Array = _parked_xform(slot)
                car.place_at(park[0], park[1])
                break


func _spawn_drivable_car(m: Dictionary, pos: Vector3, rot_y: float) -> void :
    var car: = Node3D.new()
    car.set_script(CarScript)
    car.model_path = m["path"]
    car.model_height = m["h"]
    car.display_name = m["name"]
    car.max_throttle = m["spd"]
    car.torque = m["trq"]
    car.mass = m.get("mass", 1000.0)
    add_child(car)
    car.place_at(pos, rot_y)
    _drivable_cars.append(car)


func _place_car(path: String, pos: Vector3, rot_y: float, height: float) -> void :
    var scene: = load(path) as PackedScene
    if scene == null:
        return
    var inst: = scene.instantiate()
    add_child(inst)
    inst.position = pos
    inst.rotation_degrees.y = rot_y
    ModelUtils.scale_to_height(inst, height)
    ModelUtils.ground_model(inst, 0.0)
    ModelUtils.add_per_part_convex_collision(inst, 1)


# Ambient moving traffic — kinematic cars cruising the road-derived waypoints.
func _spawn_traffic() -> void :
    if _city == null:
        return
    var waypoints: PackedVector3Array = _city.npc_waypoints
    if waypoints.size() < 2:
        return
    var models: = [
        ["res://assets/props/vehicles/sedan.glb", 1.5, 8.5],
        ["res://assets/props/vehicles/taxi.glb", 1.5, 9.5],
        ["res://assets/props/vehicles/suv.glb", 1.85, 7.5],
    ]
    var want_traffic: int = GameManager.traffic_car_count() if GameManager else TRAFFIC_CARS
    if GameManager:
        want_traffic = int(round(float(want_traffic) * GameManager.cheat_traffic_mult))
    var n: int = mini(want_traffic, waypoints.size())
    for i in n:
        var m: Array = models[i % models.size()]
        var tc: = CharacterBody3D.new()
        tc.set_script(TrafficCarScript)
        tc.setup(m[0], m[1], m[2], waypoints)
        add_child(tc)
        var wp: Vector3 = waypoints[(i * 7) % waypoints.size()]
        tc.global_position = Vector3(wp.x, 0.6, wp.z)
        _traffic.append(tc)


func _place_streetlights() -> void :
    if _city == null:
        return
    var light_path: = "res://assets/props/decorations/streetlight.glb"
    var scene: = load(light_path) as PackedScene
    for pos in _city.light_slots:
        if scene:
            var inst: = scene.instantiate() as Node3D
            add_child(inst)
            inst.position = pos
            ModelUtils.scale_to_height(inst, 6.0)
            ModelUtils.ground_model(inst, 0.0)
            ModelUtils.add_per_part_convex_collision(inst, 1)
        var light: = OmniLight3D.new()
        light.light_color = Color(1.0, 0.74, 0.42)
        light.light_energy = 0.0      # day/night drives this (on at night)
        light.omni_range = 18.0
        light.shadow_enabled = false
        light.position = pos + Vector3(0, 5.4, 0)
        add_child(light)
        _street_lights.append(light)



func _spawn_contacts() -> void :

    var spots: = [
        [_city.mission_giver_pos if _city else Vector3(12, 0, 14), _city.mission_giver_rot if _city else 200.0], 
        [Vector3(58.0, 0, 50.0), 220.0], 
        [Vector3(-54.0, 0, -46.0), 30.0], 
    ]
    for s in spots:
        var contact: = Node3D.new()
        contact.set_script(MISSION_GIVER_SCRIPT)
        add_child(contact)
        contact.global_position = s[0]
        contact.rotation_degrees.y = s[1]
        _contacts.append(contact)


func _build_systems() -> void :
    if _player == null:
        return
    _wanted_system = Node.new()
    _wanted_system.set_script(WantedSystemScript)
    add_child(_wanted_system)
    _wanted_system.setup(_player, self)

    _job_manager = Node.new()
    _job_manager.set_script(JobManagerScript)
    add_child(_job_manager)
    _job_manager.setup(_player, self, _job_locations())

    _story_mission = Node.new()
    _story_mission.set_script(StoryMissionScript)
    add_child(_story_mission)
    _story_mission.setup(_player, self)
    if _story_mission.has_method("try_start_opener"):
        _story_mission.call_deferred("try_start_opener")

    _water_hazard = Node.new()
    _water_hazard.set_script(WaterHazardScript)
    add_child(_water_hazard)
    var spawn: Vector3 = _city.player_spawn if _city else Vector3(8, 0.6, 8)
    _water_hazard.setup(_player, spawn)

    var respray: = Node3D.new()
    respray.set_script(ResprayZoneScript)
    add_child(respray)
    respray.global_position = Vector3(48.0, 0.0, -12.0)

    var safehouse: = Node3D.new()
    safehouse.set_script(SafehouseZoneScript)
    add_child(safehouse)
    safehouse.global_position = Vector3(-188.0, 0.0, -40.0)

    var fronts: = Node3D.new()
    fronts.set_script(BusinessFrontsScript)
    add_child(fronts)
    fronts.setup(_player)
    if GameManager:
        GameManager.businesses_changed.connect(fronts.on_owned_changed)
    if BusinessManager:
        BusinessManager.set_active(true)


    for c in _contacts:
        if is_instance_valid(c):
            c.job_manager = _job_manager

    if _player.has_method("register_systems"):
        _player.register_systems(_wanted_system, spawn)
    if _player.has_method("register_cars"):
        _player.register_cars(_drivable_cars)
    if _player.has_method("register_traffic"):
        _player.register_traffic(_traffic)
    if _hud and _hud.has_method("bind_systems"):
        _hud.bind_systems(_job_manager, _wanted_system)
    if _hud and _hud.has_method("bind_story") and _story_mission:
        _hud.bind_story(_story_mission)
    if _story_mission and _story_mission.has_signal("mission_completed"):
        _story_mission.mission_completed.connect(_on_mission_completed)


func _job_locations() -> Array[Vector3]:
    var pts: Array[Vector3] = []
    if _city:
        for p in _city.job_points:
            pts.append(p)
    return pts


func _spawn_pickups() -> void :
    if _player == null:
        return
    var spawn: Vector3 = _city.player_spawn if _city else Vector3(8, 0.6, 8)

    var specs: = [
        ["weapon", "pistol", spawn + Vector3(6.0, 0, -8.0)],
        ["weapon", "bat", Vector3(68.0, 0.5, 10.0)],
        ["weapon", "shotgun", Vector3(-48.0, 0.5, 66.0)],
        ["weapon", "rifle", Vector3(-100.0, 0.5, -98.0)],
        ["ammo", "pistol", spawn + Vector3(10.0, 0, -6.0)],
        ["ammo", "shotgun", Vector3(-44.0, 0.5, 72.0)],
        ["ammo", "rifle", Vector3(-92.0, 0.5, -90.0)],
        ["medkit", "", Vector3(12.0, 0.5, 64.0)],
        ["medkit", "", Vector3(64.0, 0.5, -64.0)],
        ["armor", "", Vector3(-64.0, 0.5, -8.0)],
        ["armor", "", Vector3(104.0, 0.5, 100.0)],
    ]
    for s in specs:
        var pickup: = Node3D.new()
        pickup.set_script(WeaponPickupScript)
        add_child(pickup)
        pickup.setup(s[2], _player, s[0], s[1], 0)


func _spawn_scrimshaw() -> void :
    if _player == null:
        return
    # World XZ (z = -north) — mirrors web Collectibles.tsx spots.
    var spots: Array[Vector3] = [
        Vector3(-272.0, 0.0, -106.0), Vector3(-244.0, 0.0, -70.0), Vector3(-300.0, 0.0, -130.0),
        Vector3(-210.0, 0.0, -100.0), Vector3(-330.0, 0.0, -80.0), Vector3(-256.0, 0.0, -150.0),
        Vector3(-225.0, 0.0, -60.0), Vector3(-290.0, 0.0, -175.0),
    ]
    for i in spots.size():
        if GameManager and GameManager.is_scrimshaw_collected(i):
            continue
        var c: = Node3D.new()
        c.set_script(ScrimshawCollectibleScript)
        add_child(c)
        c.setup(i, spots[i], _player)


func find_carjackable_traffic(near: Vector3, radius: float) -> Node:
    var best: Node = null
    var best_d: float = radius
    for tc in _traffic:
        if not is_instance_valid(tc):
            continue
        if not tc.has_method("can_carjack") or not tc.can_carjack():
            continue
        var d: float = near.distance_to(tc.global_position)
        if d < best_d:
            best_d = d
            best = tc
    return best


func carjack_traffic(tc: Node) -> Node:
    if tc == null or not is_instance_valid(tc) or not tc.has_method("can_carjack"):
        return null
    if not tc.can_carjack():
        return null
    tc.carjacked = true
    tc.visible = false
    tc.set_physics_process(false)
    var pos: Vector3 = tc.global_position
    var yaw: float = 0.0
    if "mesh_root" in tc and tc.mesh_root:
        yaw = rad_to_deg(tc.mesh_root.rotation.y)
    var path: String = str(tc.model_path) if "model_path" in tc else "res://assets/props/vehicles/sedan.glb"
    var spec: Dictionary = {
        "res://assets/props/vehicles/taxi.glb": {"path": "res://assets/props/vehicles/taxi.glb", "h": 1.5, "name": "Cab", "spd": 76.0, "trq": 310.0, "mass": 1100.0},
        "res://assets/props/vehicles/suv.glb": {"path": "res://assets/props/vehicles/suv.glb", "h": 1.85, "name": "SUV", "spd": 62.0, "trq": 340.0, "mass": 1500.0},
    }.get(path, {"path": "res://assets/props/vehicles/sedan.glb", "h": 1.5, "name": "Sedan", "spd": 68.0, "trq": 280.0, "mass": 1000.0})
    _spawn_drivable_car(spec, pos, yaw)
    var car = _drivable_cars.back()
    if _player and _player.has_method("register_cars"):
        _player.register_cars(_drivable_cars)
    if _wanted_system and _wanted_system.has_method("add_heat"):
        _wanted_system.add_heat(1)
    if _wanted_system and _wanted_system.has_method("add_faction_heat"):
        _wanted_system.add_faction_heat(1)
    GameManager.show_message("Carjacked — lose the heat.")
    return car


func _spawn_shops() -> void :
    var spots: = [
        Vector3(50.0, 0.0, 6.0), 
        Vector3(-52.0, 0.0, -12.0), 
        Vector3(6.0, 0.0, -110.0),
        Vector3(-3921.0, 0.0, -378.0),  # Dartmouth Mall hub
    ]
    for p in spots:
        var shop: = Node3D.new()
        shop.set_script(ShopScript)
        add_child(shop)
        shop.setup(p, "gun")


func _build_shop_menu() -> void :
    var shop_menu: = CanvasLayer.new()
    shop_menu.set_script(ShopMenuScript)
    add_child(shop_menu)
    if _player:
        shop_menu.bind_player(_player)


func _build_diner() -> void :
    var diner: = Node3D.new()
    diner.set_script(DinerInteriorScript)
    add_child(diner)
    diner.setup(Vector3(-300.0, 0.0, -92.0))
    var diner_menu: = CanvasLayer.new()
    diner_menu.set_script(DinerMenuScript)
    add_child(diner_menu)
    if _player:
        diner_menu.bind_player(_player)


func _on_mission_completed(title: String) -> void :
    var hooks: = get_node_or_null("/root/RadioHooks")
    if hooks and hooks.has_method("on_mission_completed"):
        hooks.on_mission_completed(title)


# Gunfire scatters nearby pedestrians and draws police attention.
func _on_shots_fired(at: Vector3) -> void :
    for npc in _npcs:
        if is_instance_valid(npc) and npc.has_method("panic"):
            npc.panic(at)
    # Firing in public draws the law: first shot earns a star; cops escalate it.
    if _wanted_system and _wanted_system.has_method("add_heat") and GameManager and GameManager.wanted_level < 1:
        _wanted_system.add_heat(1)


func _spawn_npcs() -> void :
    if _city == null:
        return
    var waypoints: PackedVector3Array = _city.npc_waypoints
    var peds: = [
        ["res://assets/characters/pedestrian_male/pedestrian_male.glb", "res://assets/characters/pedestrian_male/pedestrian_male_animations.tres"], 
        ["res://assets/characters/pedestrian_female/pedestrian_female.glb", "res://assets/characters/pedestrian_female/pedestrian_female_animations.tres"], 
    ]
    for i in _city.npc_spawns.size():
        var npc: = CharacterBody3D.new()
        npc.set_script(NPC_SCRIPT)
        var ped = peds[i % peds.size()]
        npc.setup(ped[0], ped[1], waypoints)
        add_child(npc)
        npc.global_position = _city.npc_spawns[i]
        _npcs.append(npc)


func _spawn_player() -> void :
    _player = PLAYER_SCENE.instantiate()
    add_child(_player)
    _player.global_position = _city.player_spawn if _city else Vector3(8, 0.6, 8)
    if GameManager and GameManager.has_spawn_override:
        _player.global_position = GameManager.player_spawn_override
        if GameManager.has_saved_pos and _player.has_method("set_heading"):
            _player.set_heading(GameManager.saved_yaw)
        # Seed the building stream around the override (e.g. a cheat spawn far from
        # downtown) so you don't drop into an empty area before _process catches up.
        if _city and _city.has_method("stream_buildings"):
            _city.stream_buildings(_player.global_position)


func _build_hud() -> void :
    _hud = HUD_SCRIPT.new()
    add_child(_hud)
    if _player:
        _hud.bind_player(_player)


func _start_audio() -> void :
    # Quiet coastal ambience (gulls, harbor, distant traffic). Radio stays the
    # only music source — this loop sits on SFX so it doesn't fight stations.
    var amb: = load("res://assets/audio/ambient/ambient_coastal_city_coastal_city.mp3")
    if amb == null:
        return
    _ambient_player = AudioStreamPlayer.new()
    _ambient_player.bus = "SFX"
    _ambient_player.volume_db = -24.0
    if amb is AudioStreamMP3:
        (amb as AudioStreamMP3).loop = true
    _ambient_player.stream = amb
    add_child(_ambient_player)
    _ambient_player.play()
