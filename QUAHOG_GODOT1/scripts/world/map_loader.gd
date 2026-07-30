extends RefCounted
class_name MapLoader

const DistrictAuthoringScript := preload("res://scripts/world/district_authoring.gd")

# Builds the real New Bedford map (the same data the web build ships) into Godot.
# Data lives under res://data/map: slice-newbedford.json (roads), tiles/b_X_Y.json
# (building footprints), overlays/*.json (land use). Coordinates are meters with
# x = east, y = north in the 2D arrays; in 3D we use x = east, z = -north, y = up
# (matching the web build's convention).

const MAP_DIR: = "res://data/map"
const TILE_M: = 500.0
const Y_GROUND: = 0.0
const Y_ROAD: = 0.04
const Y_OVERLAY: = 0.02
# Façade window texture tiled onto building walls (one repeat per ~4 m wide /
# ~3.2 m floor) so the real map reads as a windowed city, not flat boxes.
# Per-material facades by height tier so the city reads with real materials,
# authored to NB/Fall River architecture (tools/mapgen/gen_facades.py): painted
# clapboard triple-deckers (short), red-brick mills & rowhouses (mid), downtown
# granite/glass (tall). Luminance-based so the per-building vertex tint still
# drives the hue.
const FACADE_PATH: = "res://assets/textures/walls/nb_clapboard.png"
const BRICK_PATH: = "res://assets/textures/walls/nb_brick.png"
const OFFICE_PATH: = "res://assets/textures/walls/nb_downtown.png"
const WALL_TILE_U: = 4.0
const WALL_TILE_V: = 3.2
const ASPHALT_PATH: = "res://assets/textures/floors/wet_asphalt.png"
const ROAD_TILE: = 8.0  # metres per asphalt texture repeat (planar UV)
const CURB_WIDTH: = 1.7  # concrete sidewalk apron width (m) flanking each road
const Y_SIDEWALK: = 0.12  # raised slightly above the asphalt

# Highway furniture (I-195 / RT18 corridor): steel guardrails flank limited-access
# roads and green guide-sign gantries span them at intervals, so motorways read as
# highways instead of plain asphalt. All visual only — driving uses the ground plane.
const HIGHWAY_CLASSES: = ["motorway", "trunk", "motorway_link", "trunk_link"]
const GUARDRAIL_OFFSET: = 0.6   # metres beyond the carriageway edge
const GUARDRAIL_Y0: = 0.45      # rail band bottom / top (m)
const GUARDRAIL_Y1: = 0.85
const GANTRY_MIN_LEN: = 140.0   # only long mainline runs get an overhead sign
const GANTRY_HEIGHT: = 6.2
const COL_GUARDRAIL: = Color(0.55, 0.56, 0.58)
const COL_GANTRY: = Color(0.30, 0.31, 0.33)
const COL_SIGN: = Color(0.04, 0.30, 0.16)  # MUTCD highway-guide green
# Lane markings on limited-access roads: solid white edge lines + a dashed white
# lane divider down each carriageway. Painted just above the asphalt.
const Y_LINE: = 0.06
const COL_LINE: = Color(0.82, 0.82, 0.78)
const DASH_ON: = 3.0    # metres of paint per dash
const DASH_GAP: = 6.0   # metres of gap between dashes
# Undivided city arterials get a double-yellow centreline (no-passing) instead.
const ARTERIAL_CLASSES: = ["primary", "secondary", "tertiary", "primary_link", "secondary_link"]
const COL_YELLOW: = Color(0.80, 0.66, 0.16)

# The Braga ("Verde") Bridge — Fall River's icon — carries I-195 over the Taunton
# beside Battleship Cove. In the OSM data it's just flat asphalt, so we frame the
# real deck span with a green through-truss anchored to the exact crossing. The
# asphalt underneath stays drivable; the truss is visual only.
const BRAGA_A: = Vector2(-20701.0, 8078.0)   # span ends in slice space (x_east, y_north)
const BRAGA_B: = Vector2(-20044.0, 7582.0)
const BRAGA_HALF: = 15.0      # half deck width framed by the trusses
const BRAGA_RISE: = 15.0      # arch peak above the deck at mid-span
const BRAGA_DECK_Y: = 0.6
const COL_BRAGA: = Color(0.13, 0.42, 0.24)   # Braga Bridge green

# Road half-widths and colors are derived from the OSM class.
const ROAD_COLORS: = {
    "motorway": Color(0.16, 0.16, 0.18), "trunk": Color(0.16, 0.16, 0.18),
    "primary": Color(0.20, 0.20, 0.22), "secondary": Color(0.22, 0.22, 0.24),
    "tertiary": Color(0.24, 0.24, 0.26), "residential": Color(0.26, 0.26, 0.28),
    "service": Color(0.28, 0.28, 0.30), "footway": Color(0.40, 0.37, 0.33),
}
const OVERLAY_COLORS: = {
    "water": Color(0.12, 0.28, 0.42),     # harbor / rivers / bays — drawn glossy blue
    "parks": Color(0.22, 0.40, 0.20), "wood": Color(0.18, 0.34, 0.18),
    "cemetery": Color(0.26, 0.40, 0.26), "parking": Color(0.30, 0.30, 0.32),
    "beach": Color(0.78, 0.72, 0.52), "pier": Color(0.45, 0.36, 0.27),
    "islands": Color(0.20, 0.36, 0.18),   # land in the harbour
    "rail": Color(0.20, 0.18, 0.16),      # railbed gravel/ties
    "barrier": Color(0.42, 0.42, 0.44),   # NB Hurricane Barrier (granite/concrete)
}

# Stats for verification/logging.
var buildings_built: int = 0
var roads_built: int = 0
var overlays_built: int = 0
var named_places: Array = []  # [{name, pos}] from footprints that carry a name
var district_manifest: Dictionary = {}
var _authored_core_built: bool = false

# Spawn scaffolding derived from the road network so game_world can drive the
# real map the same way it drove the procedural CityBuilder (drop-in fields).
var player_spawn: Vector3 = Vector3(0, 0.6, 0)
var mission_giver_pos: Vector3 = Vector3(6, 0, 6)
var mission_giver_rot: float = 0.0
var car_slots: Array = []                  # [[Vector3 pos, float rot_y_deg], ...]
var light_slots: Array[Vector3] = []
var npc_waypoints: = PackedVector3Array()
var npc_spawns: Array[Vector3] = []
var job_points: Array[Vector3] = []
var _road_samples: Array = []              # [[Vector3 pos, float rot_y_deg], ...]
var _facade_tex: Texture2D = null
var _brick_tex: Texture2D = null
var _office_tex: Texture2D = null
var _asphalt_tex: Texture2D = null

# Building-tile streaming: the whole South Coast lives in tiles/, but only the
# tiles within _stream_radius of the player are built at any time (built/freed as
# the player moves or fast-travels), so the full region is explorable at constant
# cost instead of loading ~67k buildings at once.
var _buildings_root: Node3D = null
var _tiles: Dictionary = {}                # Vector2i tile -> MeshInstance3D
var _stream_radius: int = 2
var _stream_budget: int = 5
var _base_lod: int = 2
var _pending_tiles: Array = []          # [{key: Vector2i, lod: int}]
func set_stream_quality(radius: int, budget: int, base_lod: int) -> void :
    _stream_radius = clampi(radius, 1, 4)
    _stream_budget = clampi(budget, 1, 20)
    _base_lod = clampi(base_lod, 0, 2)


func _tile_lod(tile_dist: int) -> int:
    # Outer ring drops one LOD tier; impostor boxes at the far edge on Low/Medium.
    var lod: int = _base_lod
    if tile_dist >= _stream_radius:
        lod -= 1
    elif tile_dist == _stream_radius - 1 and _base_lod <= 1:
        lod = 0
    return clampi(lod, 0, 2)


func _pending_has(key: Vector2i) -> bool:
    for item in _pending_tiles:
        if item["key"] == key:
            return true
    return false

# Roads stream per-tile too (tiles/r_X_Y.json), so the ~38k-road network isn't
# all built at load. _junctions (arterial intersections) is computed once up front
# for stop-bar/crosswalk placement inside the streamed tiles.
var _roads_root: Node3D = null
var _road_tiles: Dictionary = {}           # Vector2i tile -> Node3D
var _junctions: Dictionary = {}
var _distant_world_built: bool = false

# Full data extent (slice x = east, y = north) with margin, for the ground plane,
# road network, and land-use overlays (all built once up front). Extends ~82 km
# north of New Bedford up the RT-140 / RT-24 / I-93 corridor through Brockton and
# Stoughton to the Boston-area towns (Randolph / Canton / Braintree / Quincy).
const FULL_BBOX: = Rect2(-23500.0, -8500.0, 36000.0, 92000.0)


static func to_world(x_east: float, y_north: float, y_up: float = 0.0) -> Vector3:
    return Vector3(x_east, y_up, -y_north)


# Map data (tiles + the road slice) is stored gzip-compressed (e.g.
# b_X_Y.json.gz) to keep the web download small — JSON of footprint coords
# compresses ~85%. Reads the plain file if present, else falls back to the .gz
# beside it and inflates. Static so big_map/minimap can share it for the slice.
static func read_json_any(path: String) -> Variant:
    if FileAccess.file_exists(path):
        var f: = FileAccess.open(path, FileAccess.READ)
        if f == null:
            return null
        return JSON.parse_string(f.get_as_text())
    var gz: = path + ".gz"
    if not FileAccess.file_exists(gz):
        return null
    var gf: = FileAccess.open(gz, FileAccess.READ)
    if gf == null:
        return null
    var raw: PackedByteArray = gf.get_buffer(gf.get_length())
    var out: PackedByteArray = raw.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
    if out.is_empty():
        return null
    return JSON.parse_string(out.get_string_from_utf8())


func _read_json(path: String) -> Variant:
    return read_json_any(path)


# Build the map for a square block of tiles around center_tile (in tile indices).
# radius_tiles = 3 → a 7x7 = up to 49-tile core around New Bedford's center.
func build_region(parent: Node3D, center_tile: Vector2i = Vector2i.ZERO, radius_tiles: int = 2) -> void :
    _stream_radius = max(radius_tiles, 2)
    if _facade_tex == null and ResourceLoader.exists(FACADE_PATH):
        _facade_tex = load(FACADE_PATH)
    if _brick_tex == null and ResourceLoader.exists(BRICK_PATH):
        _brick_tex = load(BRICK_PATH)
    if _office_tex == null and ResourceLoader.exists(OFFICE_PATH):
        _office_tex = load(OFFICE_PATH)
    if _asphalt_tex == null and ResourceLoader.exists(ASPHALT_PATH):
        _asphalt_tex = load(ASPHALT_PATH)
    _buildings_root = Node3D.new()
    _buildings_root.name = "Buildings"
    parent.add_child(_buildings_root)
    _roads_root = Node3D.new()
    _roads_root.name = "Roads"
    parent.add_child(_roads_root)
    # Scan the slice once (no meshes) for spawn points + arterial junctions, and
    # build the sparse overhead sign gantries up front. Road surfaces themselves
    # stream per-tile in stream_buildings().
    _scan_slice(parent)
    _derive_spawns()
    district_manifest = DistrictAuthoringScript.load_manifest()
    var core_center := Vector2(player_spawn.x, -player_spawn.z)
    var core_bbox := Rect2(core_center - Vector2(750.0, 750.0), Vector2(1500.0, 1500.0))
    _build_ground(parent, core_bbox)
    prime_core(player_spawn)


func build_authored_core(parent: Node3D) -> Node3D:
    if _authored_core_built:
        return parent.get_node_or_null("NewBedfordAuthoredCore")
    _authored_core_built = true
    return DistrictAuthoringScript.build_core(parent, district_manifest)


func populate_authored_dressing(parent: Node3D) -> Node3D:
    var core := parent.get_node_or_null("NewBedfordAuthoredCore") as Node3D
    if core == null:
        return null
    return DistrictAuthoringScript.populate_dressing(core, district_manifest, false)


func populate_deferred_district_models(parent: Node3D) -> Node3D:
    var core := parent.get_node_or_null("NewBedfordAuthoredCore") as Node3D
    if core == null:
        return null
    return DistrictAuthoringScript.populate_deferred_models(core, district_manifest)


func prime_core(center: Vector3) -> void:
    if _buildings_root == null or _roads_root == null:
        return
    var key := Vector2i(int(floor(center.x / TILE_M)), int(floor(-center.z / TILE_M)))
    if not _road_tiles.has(key):
        _build_road_tile(key)
    if not _tiles.has(key):
        _build_streamed_tile(key, _base_lod)


func build_distant_world(parent: Node3D) -> void:
    if _distant_world_built:
        return
    _distant_world_built = true
    _build_ground(parent, FULL_BBOX)
    _build_overlays(parent, FULL_BBOX)
    _build_trees(parent)
    _build_braga_bridge(parent)
    _build_battleship(parent)
    _build_bridge_decks(parent)
    _build_traffic_props(parent)


# Build the building tiles within _stream_radius of center and free those that
# have moved out of range. New tiles are budgeted per call so fast-travel spikes
# don't hitch the frame.
func stream_buildings(center: Vector3) -> void :
    if _buildings_root == null:
        return
    var ctx: int = int(floor(center.x / TILE_M))
    var cty: int = int(floor(-center.z / TILE_M))   # world z = -north
    var r: int = _stream_radius
    for dx in range(-r, r + 1):
        for dy in range(-r, r + 1):
            var key: = Vector2i(ctx + dx, cty + dy)
            var dist: int = maxi(absi(dx), absi(dy))
            var lod: int = _tile_lod(dist)
            if not _tiles.has(key) and not _pending_has(key):
                _pending_tiles.append({"key": key, "lod": lod})
            if not _road_tiles.has(key):
                _build_road_tile(key)
    _pending_tiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        var ak: Vector2i = a["key"]
        var bk: Vector2i = b["key"]
        var ad: int = maxi(absi(ak.x - ctx), absi(ak.y - cty))
        var bd: int = maxi(absi(bk.x - ctx), absi(bk.y - cty))
        return ad < bd
    )
    var budget: int = _stream_budget
    while budget > 0 and _pending_tiles.size() > 0:
        var item: Dictionary = _pending_tiles.pop_front()
        var pkey: Vector2i = item["key"]
        if _tiles.has(pkey):
            continue
        _build_streamed_tile(pkey, int(item["lod"]))
        budget -= 1
    # Free tiles beyond the radius (with one tile of hysteresis).
    for key in _tiles.keys():
        if absi(key.x - ctx) > r + 1 or absi(key.y - cty) > r + 1:
            var node: Node = _tiles[key]
            if is_instance_valid(node):
                node.queue_free()
            _tiles.erase(key)
    for rkey in _road_tiles.keys():
        if absi(rkey.x - ctx) > r + 1 or absi(rkey.y - cty) > r + 1:
            var rnode: Node = _road_tiles[rkey]
            if is_instance_valid(rnode):
                rnode.queue_free()
            _road_tiles.erase(rkey)


# Road sample points ([Vector3 pos, float yaw_deg]) within `radius` of center —
# used to spawn / re-stream parked cars near the player on the big map.
func road_points_near(center: Vector3, radius: float, cap: int = 800) -> Array:
    var out: Array = []
    var r2: float = radius * radius
    for s in _road_samples:
        var p: Vector3 = s[0]
        var dx: float = p.x - center.x
        var dz: float = p.z - center.z
        if dx * dx + dz * dz <= r2:
            out.append(s)
            if out.size() >= cap:
                break
    return out


func _build_streamed_tile(key: Vector2i, lod: int = 2) -> void :
    _tiles[key] = null   # reserve so we don't re-attempt a missing tile every pass
    var path: = "%s/tiles/b_%d_%d.json" % [MAP_DIR, key.x, key.y]
    var data: Variant = _read_json(path)
    if data == null or not (data is Array):
        return
    var mi: = _build_tile(_buildings_root, data, key.x, key.y, lod)
    if mi != null:
        _tiles[key] = mi


func _build_ground(parent: Node3D, bbox: Rect2) -> void :
    var plane: = PlaneMesh.new()
    plane.size = Vector2(bbox.size.x, bbox.size.y)
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.13, 0.14, 0.13)
    mat.roughness = 1.0
    plane.material = mat
    var mi: = MeshInstance3D.new()
    mi.name = "Ground"
    mi.mesh = plane
    var center: = to_world(bbox.position.x + bbox.size.x * 0.5, bbox.position.y + bbox.size.y * 0.5, Y_GROUND)
    mi.position = center
    parent.add_child(mi)
    # Flat collider so the player/cars stand on the world.
    var body: = StaticBody3D.new()
    body.name = "GroundBody"
    var col: = CollisionShape3D.new()
    var shape: = WorldBoundaryShape3D.new()
    shape.plane = Plane(Vector3.UP, Y_GROUND)
    col.shape = shape
    body.add_child(col)
    parent.add_child(body)


func _build_tile(root: Node3D, buildings: Array, tx: int, ty: int, lod: int = 2) -> Node3D:
    # Three façade materials by height tier (clapboard/windows · brick · concrete).
    var st_w: = SurfaceTool.new()
    st_w.begin(Mesh.PRIMITIVE_TRIANGLES)
    var st_b: = SurfaceTool.new()
    st_b.begin(Mesh.PRIMITIVE_TRIANGLES)
    var st_o: = SurfaceTool.new()
    st_o.begin(Mesh.PRIMITIVE_TRIANGLES)
    var any_w: = false
    var any_b: = false
    var any_o: = false
    var faces: = PackedVector3Array()
    var any: = false
    for b in buildings:
        if not (b is Dictionary):
            continue
        var fp: Variant = b.get("footprint")
        if not (fp is Array) or fp.size() < 3:
            continue
        var h: float = float(b.get("height", 8.0))
        var mill: bool = float(fp[0][0]) < -16000.0   # Fall River / Westport belt
        var st: SurfaceTool
        if h >= 24.0:
            st = st_o
            any_o = true
        elif h >= 13.0 or (mill and h >= 11.0):
            st = st_b
            any_b = true
        else:
            st = st_w
            any_w = true
        _emit_building(st, faces, fp, h, lod)
        if h >= 24.0:
            _emit_roof_detail(st, fp, h)   # rooftop AC unit on flat-topped towers
        buildings_built += 1
        any = true
        if b.has("name"):
            var c: = _centroid(fp)
            named_places.append({"name": b["name"], "pos": to_world(c.x, c.y, h)})
    if not any:
        return null
    var tile_root: = Node3D.new()
    tile_root.name = "Tile_%d_%d" % [tx, ty]
    if any_w:
        _commit_facade(tile_root, st_w, _facade_tex if lod >= 1 else null)
    if any_b:
        _commit_facade(tile_root, st_b, _brick_tex if lod >= 1 else null)
    if any_o:
        _commit_facade(tile_root, st_o, _office_tex if lod >= 1 else null)
    # One trimesh collider for the whole tile's walls/roofs.
    var body: = StaticBody3D.new()
    var col: = CollisionShape3D.new()
    var shape: = ConcavePolygonShape3D.new()
    shape.set_faces(faces)
    col.shape = shape
    body.add_child(col)
    tile_root.add_child(body)
    root.add_child(tile_root)
    return tile_root


func _commit_facade(parent: Node3D, st: SurfaceTool, tex: Texture2D) -> void :
    st.generate_normals()
    var mat: = StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.roughness = 0.92
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    if tex:
        mat.albedo_texture = tex
        mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    mat.emission_enabled = true
    mat.emission = Color(1.0, 0.78, 0.45)
    mat.emission_energy_multiplier = 0.0
    st.set_material(mat)
    var mi: = MeshInstance3D.new()
    mi.mesh = st.commit()
    var glow: = mat.duplicate() as StandardMaterial3D
    mi.material_override = glow
    mi.add_to_group("facade_emissive")
    parent.add_child(mi)


# A small rooftop box (HVAC unit) on a flat-topped tower so the skyline isn't a
# field of clean prisms. Visual only (no collision); winding is irrelevant since
# the facade material is double-sided. Seeded from the footprint for stable variety.
func _emit_roof_detail(st: SurfaceTool, fp: Array, h: float) -> void :
    var cx: = 0.0
    var cy: = 0.0
    for p in fp:
        cx += float(p[0])
        cy += float(p[1])
    cx /= float(fp.size())
    cy /= float(fp.size())
    var seed_i: int = int(absf(float(fp[0][0]) * 73856.0 + float(fp[0][1]) * 19349.0))
    var s: float = 1.6 + float(seed_i % 4) * 0.5
    var bh: float = 1.6 + float(seed_i % 3) * 0.7
    cx += float((seed_i % 7) - 3)
    cy += float((int(seed_i / 7.0) % 7) - 3)
    var col: = Color(0.38, 0.39, 0.41)
    var base: = h
    var top: = h + bh
    var a0: = to_world(cx - s, cy - s, base)
    var b0: = to_world(cx + s, cy - s, base)
    var c0: = to_world(cx + s, cy + s, base)
    var d0: = to_world(cx - s, cy + s, base)
    var a1: = to_world(cx - s, cy - s, top)
    var b1: = to_world(cx + s, cy - s, top)
    var c1: = to_world(cx + s, cy + s, top)
    var d1: = to_world(cx - s, cy + s, top)
    for quad in [[a1, b1, c1, d1], [a0, b0, b1, a1], [b0, c0, c1, b1], [c0, d0, d1, c1], [d0, a0, a1, d1]]:
        for idx in [0, 1, 2, 0, 2, 3]:
            st.set_color(col)
            st.set_uv(Vector2(0.05, 0.05))
            st.add_vertex(quad[idx])


func _emit_building(st: SurfaceTool, faces: PackedVector3Array, fp: Array, h: float, lod: int = 2) -> void :
    # Per-building tint by height tier, with deterministic variety inside each tier
    # so the streetscape reads as mixed eras (granite civic / brick mills / painted
    # triple-deckers) instead of three flat tones. Seed from the footprint so a
    # given building always paints the same colour (no flicker).
    var seed_i: int = int(absf(float(fp[0][0]) * 73856.0 + float(fp[0][1]) * 19349.0))
    var palette: Array
    # Fall River / Westport mill belt (west of x ≈ −16 km): bias the larger
    # buildings to deep mill brick + granite so the old textile-mill city reads
    # differently from New Bedford's painted waterfront.
    var mill_belt: bool = float(fp[0][0]) < -16000.0
    if mill_belt and h >= 11.0:
        palette = [Color(0.46, 0.23, 0.18), Color(0.41, 0.21, 0.17), Color(0.52, 0.29, 0.21), Color(0.44, 0.42, 0.40), Color(0.37, 0.36, 0.35), Color(0.49, 0.27, 0.22)]
    elif h >= 24.0:
        palette = [Color(0.52, 0.53, 0.55), Color(0.49, 0.50, 0.52), Color(0.56, 0.56, 0.55), Color(0.47, 0.48, 0.50)]
    elif h >= 13.0:
        palette = [Color(0.45, 0.27, 0.22), Color(0.50, 0.26, 0.20), Color(0.39, 0.28, 0.25), Color(0.55, 0.43, 0.33), Color(0.44, 0.40, 0.40)]
    else:
        palette = [Color(0.58, 0.50, 0.42), Color(0.80, 0.78, 0.72), Color(0.55, 0.60, 0.62), Color(0.46, 0.53, 0.44), Color(0.74, 0.68, 0.47), Color(0.57, 0.34, 0.30), Color(0.60, 0.60, 0.58)]
    var col: Color = palette[seed_i % palette.size()]

    var n: = fp.size()
    var poly2: = PackedVector2Array()
    for p in fp:
        poly2.append(Vector2(float(p[0]), float(p[1])))

    # Roof. UV pinned to a single texel so the roof reads as a flat tone (no
    # window grid up top). Short footprints (houses / triple-deckers) get a
    # peaked hip roof — a fan from each footprint edge up to an apex over the
    # centroid — so they aren't flat-topped boxes. Tall granite/mills stay flat.
    var roof_col: = col.lightened(0.08)
    var use_pitch: bool = h < 14.0 and lod >= 2
    if use_pitch:
        var cx: = 0.0
        var cy: = 0.0
        for p2 in poly2:
            cx += p2.x
            cy += p2.y
        cx /= float(poly2.size())
        cy /= float(poly2.size())
        var peak: = clampf(h * 0.45, 1.8, 4.5)
        var apex: = to_world(cx, cy, h + peak)
        for i in range(poly2.size()):
            var ea: = poly2[i]
            var eb: = poly2[(i + 1) % poly2.size()]
            var va: = to_world(ea.x, ea.y, h)
            var vb: = to_world(eb.x, eb.y, h)
            for v in [va, vb, apex]:
                st.set_color(roof_col)
                st.set_uv(Vector2(0.05, 0.05))
                st.add_vertex(v)
                faces.append(v)
    else:
        var tri: = Geometry2D.triangulate_polygon(poly2)
        for i in range(0, tri.size(), 3):
            for k in range(3):
                var v2: = poly2[tri[i + k]]
                var v: = to_world(v2.x, v2.y, h)
                st.set_color(roof_col)
                st.set_uv(Vector2(0.05, 0.05))
                st.add_vertex(v)
                faces.append(v)

    # Walls (extrude each edge from ground to roof) with window-grid UVs that
    # tile by wall length and floor height. Impostor LOD uses flat UVs.
    var vmax: = h / WALL_TILE_V
    var flat_uv: bool = lod <= 0
    for i in range(n):
        var a2: = poly2[i]
        var b2: = poly2[(i + 1) % n]
        var umax: = a2.distance_to(b2) / WALL_TILE_U
        var a0: = to_world(a2.x, a2.y, Y_GROUND)
        var b0: = to_world(b2.x, b2.y, Y_GROUND)
        var a1: = to_world(a2.x, a2.y, h)
        var b1: = to_world(b2.x, b2.y, h)
        # Two triangles: a0,b0,b1 and a0,b1,a1
        var verts: = [a0, b0, b1, a0, b1, a1]
        var uvs: = [
            Vector2(0.0, vmax), Vector2(umax, vmax), Vector2(umax, 0.0),
            Vector2(0.0, vmax), Vector2(umax, 0.0), Vector2(0.0, 0.0),
        ]
        for j in verts.size():
            st.set_color(col)
            st.set_uv(Vector2(0.05, 0.05) if flat_uv else uvs[j])
            st.add_vertex(verts[j])
            faces.append(verts[j])


# Scan the slice once WITHOUT building road surfaces: derive spawn samples +
# arterial junctions, and build the sparse overhead sign gantries (these need the
# whole road length, so they can't come from the clipped per-tile pieces). The
# asphalt / sidewalks / lane paint stream per-tile in _build_road_tile().
func _scan_slice(parent: Node3D) -> void :
    var slice: Variant = _read_json("%s/slice-newbedford.json" % MAP_DIR)
    if slice == null or not (slice is Dictionary):
        return
    var roads: Variant = slice.get("roads", [])
    if not (roads is Array):
        return
    _junctions = _collect_arterial_junctions(roads)
    var hf: = SurfaceTool.new()
    hf.begin(Mesh.PRIMITIVE_TRIANGLES)
    var hf_any: = false
    for r in roads:
        if not (r is Dictionary):
            continue
        var pts: Variant = r.get("points")
        if not (pts is Array) or pts.size() < 2:
            continue
        var hw: String = str(r.get("highway", "residential"))
        var width: float = float(r.get("width", 6.0))
        roads_built += 1
        var a0: = Vector2(float(pts[0][0]), float(pts[0][1]))
        var b0: = Vector2(float(pts[1][0]), float(pts[1][1]))
        var mid: = (a0 + b0) * 0.5
        var wdir: = Vector3(b0.x - a0.x, 0.0, -(b0.y - a0.y))
        var roty: = 0.0
        if wdir.length_squared() > 0.0001:
            roty = rad_to_deg(atan2(wdir.x, wdir.z))
        _road_samples.append([to_world(mid.x, mid.y, 0.0), roty, width])
        if hw in HIGHWAY_CLASSES and _emit_gantry(hf, pts, width * 0.5, hw):
            hf_any = true
    if hf_any:
        hf.generate_normals()
        var hmat: = StandardMaterial3D.new()
        hmat.vertex_color_use_as_albedo = true
        hmat.roughness = 0.6
        hmat.metallic = 0.2
        hmat.cull_mode = BaseMaterial3D.CULL_DISABLED
        hf.set_material(hmat)
        var hmi: = MeshInstance3D.new()
        hmi.name = "SignGantries"
        hmi.mesh = hf.commit()
        parent.add_child(hmi)


# Build the road surfaces for one 500 m tile from tiles/r_X_Y.json: asphalt into
# one (textured) mesh, and sidewalks / guardrails / lane paint / stop bars /
# crosswalks into a second (vertex-coloured) mesh. Visual only — driving uses the
# ground plane. Returns nothing; result is parented under _roads_root.
func _build_road_tile(key: Vector2i) -> void :
    _road_tiles[key] = null
    var path: = "%s/tiles/r_%d_%d.json" % [MAP_DIR, key.x, key.y]
    var data: Variant = _read_json(path)
    if data == null or not (data is Array):
        return
    var asp: = SurfaceTool.new()
    asp.begin(Mesh.PRIMITIVE_TRIANGLES)
    var dec: = SurfaceTool.new()
    dec.begin(Mesh.PRIMITIVE_TRIANGLES)
    var any: = false
    var dec_any: = false
    for piece in data:
        if not (piece is Dictionary):
            continue
        var pts: Variant = piece.get("points")
        if not (pts is Array) or pts.size() < 2:
            continue
        var hw: String = str(piece.get("highway", "residential"))
        var width: float = float(piece.get("width", 6.0))
        var rcol: Color = ROAD_COLORS.get(hw, Color(0.27, 0.27, 0.29))
        _emit_road(asp, pts, width * 0.5, rcol)
        any = true
        if hw in HIGHWAY_CLASSES:
            _emit_guardrail(dec, pts, width * 0.5)
            _emit_lane_lines(dec, pts, width * 0.5)
            _emit_dashes(dec, pts)
            dec_any = true
        elif hw != "footway" and hw != "service":
            _emit_sidewalk(dec, pts, width * 0.5)
            dec_any = true
        if hw in ARTERIAL_CLASSES:
            _emit_center_double(dec, pts)
            _emit_stop_bars(dec, pts, width * 0.5, _junctions)
            _emit_crosswalks(dec, pts, width * 0.5, _junctions)
            dec_any = true
    if not any:
        return
    var root: = Node3D.new()
    root.name = "RoadTile_%d_%d" % [key.x, key.y]
    asp.generate_normals()
    var amat: = StandardMaterial3D.new()
    amat.vertex_color_use_as_albedo = true
    amat.roughness = 0.95
    if _asphalt_tex:
        amat.albedo_texture = _asphalt_tex
        amat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    asp.set_material(amat)
    var ami: = MeshInstance3D.new()
    ami.name = "Asphalt"
    ami.mesh = asp.commit()
    root.add_child(ami)
    if dec_any:
        dec.generate_normals()
        var dmat: = StandardMaterial3D.new()
        dmat.vertex_color_use_as_albedo = true
        dmat.roughness = 0.9
        dmat.cull_mode = BaseMaterial3D.CULL_DISABLED
        dec.set_material(dmat)
        var dmi: = MeshInstance3D.new()
        dmi.name = "Detail"
        dmi.mesh = dec.commit()
        root.add_child(dmi)
    _roads_root.add_child(root)
    _road_tiles[key] = root


# Concrete apron strips flanking a road (visual only; the ground plane carries
# collision). Two quads per segment — one each side, inner edge at the kerb.
func _emit_sidewalk(st: SurfaceTool, pts: Array, half: float) -> void :
    var col: = Color(0.62, 0.62, 0.60)
    for i in range(pts.size() - 1):
        var a: = Vector2(float(pts[i][0]), float(pts[i][1]))
        var b: = Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
        var dir: = (b - a)
        if dir.length_squared() < 0.0001:
            continue
        dir = dir.normalized()
        var perp: = Vector2(-dir.y, dir.x)
        for s: float in [1.0, -1.0]:
            var ai: = a + perp * (half * s)
            var ao: = a + perp * ((half + CURB_WIDTH) * s)
            var bi: = b + perp * (half * s)
            var bo: = b + perp * ((half + CURB_WIDTH) * s)
            var vai: = to_world(ai.x, ai.y, Y_SIDEWALK)
            var vao: = to_world(ao.x, ao.y, Y_SIDEWALK)
            var vbi: = to_world(bi.x, bi.y, Y_SIDEWALK)
            var vbo: = to_world(bo.x, bo.y, Y_SIDEWALK)
            for v in [vai, vao, vbo, vai, vbo, vbi]:
                st.set_color(col)
                st.set_uv(Vector2(v.x * 0.25, v.z * 0.25))
                st.add_vertex(v)


# Steel guardrail band flanking a limited-access road (visual only). One vertical
# strip each side, just outside the carriageway, between GUARDRAIL_Y0 and _Y1.
func _emit_guardrail(st: SurfaceTool, pts: Array, half: float) -> void :
    var off: float = half + GUARDRAIL_OFFSET
    for i in range(pts.size() - 1):
        var a: = Vector2(float(pts[i][0]), float(pts[i][1]))
        var b: = Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
        var dir: = (b - a)
        if dir.length_squared() < 0.0001:
            continue
        dir = dir.normalized()
        var perp: = Vector2(-dir.y, dir.x)
        for s: float in [1.0, -1.0]:
            var ea: = a + perp * (off * s)
            var eb: = b + perp * (off * s)
            var a0: = to_world(ea.x, ea.y, GUARDRAIL_Y0)
            var b0: = to_world(eb.x, eb.y, GUARDRAIL_Y0)
            var a1: = to_world(ea.x, ea.y, GUARDRAIL_Y1)
            var b1: = to_world(eb.x, eb.y, GUARDRAIL_Y1)
            for v in [a0, b0, b1, a0, b1, a1]:
                st.set_color(COL_GUARDRAIL)
                st.set_uv(Vector2.ZERO)
                st.add_vertex(v)


# A flat paint strip (one quad in the XZ plane at Y_LINE) running from ca to cb,
# `hw` metres to each side of that centreline. Used for lane paint.
func _strip(st: SurfaceTool, ca: Vector2, cb: Vector2, perp: Vector2, hw: float, col: Color) -> void :
    var a0: = to_world(ca.x + perp.x * hw, ca.y + perp.y * hw, Y_LINE)
    var a1: = to_world(ca.x - perp.x * hw, ca.y - perp.y * hw, Y_LINE)
    var b0: = to_world(cb.x + perp.x * hw, cb.y + perp.y * hw, Y_LINE)
    var b1: = to_world(cb.x - perp.x * hw, cb.y - perp.y * hw, Y_LINE)
    for v in [a0, b0, b1, a0, b1, a1]:
        st.set_color(col)
        st.set_uv(Vector2.ZERO)
        st.add_vertex(v)


# Solid white edge lines just inside both carriageway edges.
func _emit_lane_lines(st: SurfaceTool, pts: Array, half: float) -> void :
    var eo: float = maxf(half - 0.4, 0.4)
    for i in range(pts.size() - 1):
        var a: = Vector2(float(pts[i][0]), float(pts[i][1]))
        var b: = Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
        var dir: = (b - a)
        if dir.length_squared() < 0.0001:
            continue
        dir = dir.normalized()
        var perp: = Vector2(-dir.y, dir.x)
        for s: float in [1.0, -1.0]:
            _strip(st, a + perp * (eo * s), b + perp * (eo * s), perp, 0.12, COL_LINE)


# Solid double-yellow centreline for an undivided arterial.
# Count how many arterial ways share each endpoint. OSM splits ways at
# intersections, so a node shared by 3+ arterial endpoints is a real junction.
func _collect_arterial_junctions(roads: Array) -> Dictionary:
    var counts: Dictionary = {}
    for r in roads:
        if not (r is Dictionary):
            continue
        var hw: String = str(r.get("highway", "residential"))
        if not (hw in ARTERIAL_CLASSES):
            continue
        var pts: Variant = r.get("points")
        if not (pts is Array) or pts.size() < 2:
            continue
        for idx: int in [0, pts.size() - 1]:
            var p: Variant = pts[idx]
            var key: = Vector2i(roundi(float(p[0])), roundi(float(p[1])))
            counts[key] = int(counts.get(key, 0)) + 1
    return counts


# White stop bar across each arterial approach to a multi-arterial junction,
# set back a little from the node along the road's end segment.
func _emit_stop_bars(st: SurfaceTool, pts: Array, half: float, junctions: Dictionary) -> void :
    var ends: Array = [PackedInt32Array([0, 1]), PackedInt32Array([pts.size() - 1, pts.size() - 2])]
    for ei: int in range(ends.size()):
        var e: PackedInt32Array = ends[ei]
        var node: = Vector2(float(pts[e[0]][0]), float(pts[e[0]][1]))
        var key: = Vector2i(roundi(node.x), roundi(node.y))
        if int(junctions.get(key, 0)) < 3:
            continue
        var nxt: = Vector2(float(pts[e[1]][0]), float(pts[e[1]][1]))
        var d: = (nxt - node)
        if d.length_squared() < 0.0001:
            continue
        d = d.normalized()
        var perp: = Vector2(-d.y, d.x)
        var center: = node + d * 2.5
        var bw: float = half * 0.9
        _strip(st, center - perp * bw, center + perp * bw, d, 0.3, COL_LINE)


# Continental ("zebra") crosswalk on each arterial approach to a junction:
# stripes oriented along the travel direction, spaced across the carriageway,
# sitting just inside the stop bar.
func _emit_crosswalks(st: SurfaceTool, pts: Array, half: float, junctions: Dictionary) -> void :
    var ends: Array = [PackedInt32Array([0, 1]), PackedInt32Array([pts.size() - 1, pts.size() - 2])]
    for ei: int in range(ends.size()):
        var e: PackedInt32Array = ends[ei]
        var node: = Vector2(float(pts[e[0]][0]), float(pts[e[0]][1]))
        var key: = Vector2i(roundi(node.x), roundi(node.y))
        if int(junctions.get(key, 0)) < 3:
            continue
        var nxt: = Vector2(float(pts[e[1]][0]), float(pts[e[1]][1]))
        var d: = (nxt - node)
        if d.length_squared() < 0.0001:
            continue
        d = d.normalized()
        var perp: = Vector2(-d.y, d.x)
        var reach: float = half * 0.85
        var a_near: = node + d * 0.6
        var a_far: = node + d * 2.1
        var off: float = -reach
        while off <= reach + 0.001:
            _strip(st, a_near + perp * off, a_far + perp * off, perp, 0.22, COL_LINE)
            off += 0.9


func _emit_center_double(st: SurfaceTool, pts: Array) -> void :
    for i in range(pts.size() - 1):
        var a: = Vector2(float(pts[i][0]), float(pts[i][1]))
        var b: = Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
        var dir: = (b - a)
        if dir.length_squared() < 0.0001:
            continue
        dir = dir.normalized()
        var perp: = Vector2(-dir.y, dir.x)
        for off: float in [0.18, -0.18]:
            _strip(st, a + perp * off, b + perp * off, perp, 0.08, COL_YELLOW)


# Dashed white lane divider down the centreline, with the dash phase carried
# across segments so the pattern stays continuous along the whole road.
func _emit_dashes(st: SurfaceTool, pts: Array) -> void :
    var cycle: float = DASH_ON + DASH_GAP
    var traveled: float = 0.0
    for i in range(pts.size() - 1):
        var a: = Vector2(float(pts[i][0]), float(pts[i][1]))
        var b: = Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
        var seg: = (b - a)
        var seg_len: float = seg.length()
        if seg_len < 0.0001:
            continue
        var dir: = seg / seg_len
        var perp: = Vector2(-dir.y, dir.x)
        var s: float = 0.0
        while s < seg_len:
            var ph: float = fmod(traveled + s, cycle)
            if ph < DASH_ON:
                var dash_end: float = minf(s + (DASH_ON - ph), seg_len)
                _strip(st, a + dir * s, a + dir * dash_end, perp, 0.1, COL_LINE)
                s = dash_end
            else:
                s += (cycle - ph)
        traveled += seg_len


# Overhead green guide-sign gantry at the midpoint of a long mainline run. Two
# posts straddling the carriageway, a cross beam, and a green sign panel. Returns
# true when one was placed. Links never get a gantry (handled by the caller).
func _emit_gantry(st: SurfaceTool, pts: Array, half: float, hw: String) -> bool:
    if hw.ends_with("_link"):
        return false
    var total: float = 0.0
    for i in range(pts.size() - 1):
        total += Vector2(float(pts[i][0]), float(pts[i][1])).distance_to(Vector2(float(pts[i + 1][0]), float(pts[i + 1][1])))
    if total < GANTRY_MIN_LEN:
        return false
    # Walk to the halfway point along the polyline for the gantry centre + heading.
    var target: float = total * 0.5
    var run: float = 0.0
    var mid: = Vector2.ZERO
    var dir: = Vector2(1, 0)
    for i in range(pts.size() - 1):
        var a: = Vector2(float(pts[i][0]), float(pts[i][1]))
        var b: = Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
        var seg: float = a.distance_to(b)
        if seg < 0.0001:
            continue
        if run + seg >= target:
            var t: float = (target - run) / seg
            mid = a.lerp(b, t)
            dir = (b - a).normalized()
            break
        run += seg
    var perp: = Vector2(-dir.y, dir.x)
    var span: float = half + GUARDRAIL_OFFSET + 0.6
    var left: = mid + perp * span
    var right: = mid - perp * span
    # Posts (square columns) at each edge.
    _emit_box(st, to_world(left.x, left.y, GANTRY_HEIGHT * 0.5), Vector3(0.5, GANTRY_HEIGHT, 0.5), COL_GANTRY)
    _emit_box(st, to_world(right.x, right.y, GANTRY_HEIGHT * 0.5), Vector3(0.5, GANTRY_HEIGHT, 0.5), COL_GANTRY)
    # Cross beam spanning the carriageway near the top.
    var beam_c: = (left + right) * 0.5
    var beam_len: float = left.distance_to(right) + 0.5
    var ang: float = atan2(perp.y, perp.x)
    _emit_box_rot(st, to_world(beam_c.x, beam_c.y, GANTRY_HEIGHT - 0.4), Vector3(beam_len, 0.4, 0.4), -ang, COL_GANTRY)
    # Green sign panel hung under the beam.
    _emit_box_rot(st, to_world(beam_c.x, beam_c.y, GANTRY_HEIGHT - 1.6), Vector3(beam_len * 0.8, 1.7, 0.18), -ang, COL_SIGN)
    return true


# Axis-aligned box (12 tris) centred at c with the given full-extent size.
func _emit_box(st: SurfaceTool, c: Vector3, sz: Vector3, col: Color) -> void :
    _emit_box_rot(st, c, sz, 0.0, col)


# Box centred at c, sized sz (x=length, y=height, z=depth), yawed by yaw radians
# about the world Y axis. Visual only — appended to the furniture surface.
func _emit_box_rot(st: SurfaceTool, c: Vector3, sz: Vector3, yaw: float, col: Color) -> void :
    var hx: float = sz.x * 0.5
    var hy: float = sz.y * 0.5
    var hz: float = sz.z * 0.5
    var cs: float = cos(yaw)
    var sn: float = sin(yaw)
    var corners: Array = []
    for sxp: float in [-1.0, 1.0]:
        for syp: float in [-1.0, 1.0]:
            for szp: float in [-1.0, 1.0]:
                var lx: float = sxp * hx
                var lz: float = szp * hz
                var wx: float = lx * cs - lz * sn
                var wz: float = lx * sn + lz * cs
                corners.append(c + Vector3(wx, syp * hy, wz))
    # corner index = (sx?4)+(sy?2)+(sz?1) with -1->0,+1->1
    var idx: Array = [
        PackedInt32Array([0, 1, 3, 0, 3, 2]),  # x-
        PackedInt32Array([4, 6, 7, 4, 7, 5]),  # x+
        PackedInt32Array([0, 4, 5, 0, 5, 1]),  # y-
        PackedInt32Array([2, 3, 7, 2, 7, 6]),  # y+
        PackedInt32Array([0, 2, 6, 0, 6, 4]),  # z-
        PackedInt32Array([1, 5, 7, 1, 7, 3]),  # z+
    ]
    for fi: int in range(idx.size()):
        var face: PackedInt32Array = idx[fi]
        for k: int in face:
            var v: Vector3 = corners[k]
            st.set_color(col)
            st.set_uv(Vector2.ZERO)
            st.add_vertex(v)


# A box-section beam between two arbitrary 3D points (square cross-section of side
# `thick`), oriented along the segment. Used to weld the Braga truss from chords,
# verticals, and diagonals.
func _emit_beam(st: SurfaceTool, p0: Vector3, p1: Vector3, thick: float, col: Color) -> void :
    var axis: = p1 - p0
    var length: float = axis.length()
    if length < 0.001:
        return
    axis = axis / length
    var up: = Vector3.UP
    if absf(axis.dot(up)) > 0.99:
        up = Vector3.RIGHT
    var right: = axis.cross(up).normalized()
    var up2: = right.cross(axis).normalized()
    var hr: = right * (thick * 0.5)
    var hu: = up2 * (thick * 0.5)
    var center: = (p0 + p1) * 0.5
    var corners: = PackedVector3Array()
    for sl: float in [-1.0, 1.0]:
        for sr: float in [-1.0, 1.0]:
            for su: float in [-1.0, 1.0]:
                corners.append(center + axis * (length * 0.5 * sl) + hr * sr + hu * su)
    var idx: Array = [
        PackedInt32Array([0, 1, 3, 0, 3, 2]),
        PackedInt32Array([4, 6, 7, 4, 7, 5]),
        PackedInt32Array([0, 4, 5, 0, 5, 1]),
        PackedInt32Array([2, 3, 7, 2, 7, 6]),
        PackedInt32Array([0, 2, 6, 0, 6, 4]),
        PackedInt32Array([1, 5, 7, 1, 7, 3]),
    ]
    for fi: int in range(idx.size()):
        var face: PackedInt32Array = idx[fi]
        for k: int in face:
            var v: Vector3 = corners[k]
            st.set_color(col)
            st.set_uv(Vector2.ZERO)
            st.add_vertex(v)


# Green through-truss framing the I-195 deck over the Taunton (the Braga Bridge).
# Built once over the real crossing; the asphalt deck below stays drivable.
func _build_bridge_decks(parent: Node3D) -> void :
    var root: = Node3D.new()
    root.name = "BridgeDecks"
    parent.add_child(root)
    _add_bridge_deck(root, BRAGA_A, BRAGA_B, BRAGA_HALF * 2.0, BRAGA_DECK_Y + 0.15)
    # New Bedford hurricane barrier crossing (world fast-travel ~860, 2000).
    _add_bridge_deck(root, Vector2(380.0, 2000.0), Vector2(1520.0, 2000.0), 14.0, 0.75)
    # New Bedford ↔ Fairhaven span.
    _add_bridge_deck(root, Vector2(1080.0, -8.0), Vector2(2120.0, -52.0), 12.0, 0.7)


func _add_bridge_deck(root: Node3D, a_slice: Vector2, b_slice: Vector2, width: float, y_up: float) -> void :
    var aw: = to_world(a_slice.x, a_slice.y, y_up)
    var bw: = to_world(b_slice.x, b_slice.y, y_up)
    var mid: Vector3 = (aw + bw) * 0.5
    var d: Vector3 = bw - aw
    var length: float = d.length()
    if length < 1.0:
        return
    var yaw: float = atan2(d.z, d.x)
    var body: = StaticBody3D.new()
    body.collision_layer = 1
    body.collision_mask = 0
    var col: = CollisionShape3D.new()
    var box: = BoxShape3D.new()
    box.size = Vector3(length, 0.35, width)
    col.shape = box
    body.add_child(col)
    body.position = mid
    body.rotation.y = yaw
    root.add_child(body)
    var mesh: = MeshInstance3D.new()
    var bm: = BoxMesh.new()
    bm.size = box.size
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.22, 0.22, 0.24)
    mat.roughness = 0.88
    mesh.mesh = bm
    mesh.material_override = mat
    mesh.position = mid
    mesh.rotation.y = yaw
    root.add_child(mesh)


# Stop signs + traffic lights at major arterial junctions near downtown.
func _build_traffic_props(parent: Node3D) -> void :
    var root: = Node3D.new()
    root.name = "TrafficProps"
    parent.add_child(root)
    var core: Vector3 = player_spawn
    var placed: int = 0
    for key in _junctions:
        if int(_junctions[key]) < 3:
            continue
        var wp: = to_world(float(key.x), float(key.y), 0.0)
        if Vector2(wp.x - core.x, wp.z - core.z).length() > 720.0:
            continue
        _add_stop_sign(root, wp + Vector3(-2.5, 0.0, 1.8))
        _add_traffic_light(root, wp + Vector3(2.5, 0.0, -1.8))
        placed += 1
        if placed >= 36:
            break


func _add_stop_sign(root: Node3D, pos: Vector3) -> void :
    var pole: = MeshInstance3D.new()
    var cyl: = CylinderMesh.new()
    cyl.top_radius = 0.06
    cyl.bottom_radius = 0.08
    cyl.height = 2.6
    pole.mesh = cyl
    var pm: = StandardMaterial3D.new()
    pm.albedo_color = Color(0.35, 0.36, 0.38)
    pole.material_override = pm
    pole.position = pos + Vector3(0, 1.3, 0)
    root.add_child(pole)
    var sign: = MeshInstance3D.new()
    var plate: = BoxMesh.new()
    plate.size = Vector3(0.04, 0.55, 0.55)
    sign.mesh = plate
    var sm: = StandardMaterial3D.new()
    sm.albedo_color = Color(0.72, 0.08, 0.08)
    sm.emission_enabled = true
    sm.emission = Color(0.9, 0.1, 0.1)
    sm.emission_energy_multiplier = 0.15
    sign.material_override = sm
    sign.position = pos + Vector3(0, 2.55, 0)
    root.add_child(sign)


func _add_traffic_light(root: Node3D, pos: Vector3) -> void :
    var pole: = MeshInstance3D.new()
    var cyl: = CylinderMesh.new()
    cyl.top_radius = 0.07
    cyl.bottom_radius = 0.09
    cyl.height = 4.8
    pole.mesh = cyl
    var pm: = StandardMaterial3D.new()
    pm.albedo_color = Color(0.32, 0.33, 0.35)
    pole.material_override = pm
    pole.position = pos + Vector3(0, 2.4, 0)
    root.add_child(pole)
    var housing: = MeshInstance3D.new()
    var box: = BoxMesh.new()
    box.size = Vector3(0.35, 0.9, 0.28)
    housing.mesh = box
    var hm: = StandardMaterial3D.new()
    hm.albedo_color = Color(0.12, 0.12, 0.14)
    housing.material_override = hm
    housing.position = pos + Vector3(0, 4.9, 0)
    root.add_child(housing)
    var colors: Array = [Color(0.9, 0.1, 0.1), Color(0.9, 0.75, 0.1), Color(0.2, 0.85, 0.25)]
    for i in 3:
        var lens: = MeshInstance3D.new()
        var lm: = BoxMesh.new()
        lm.size = Vector3(0.08, 0.18, 0.18)
        lens.mesh = lm
        var m: = StandardMaterial3D.new()
        m.albedo_color = colors[i]
        m.emission_enabled = true
        m.emission = colors[i]
        m.emission_energy_multiplier = 0.35 if i == 2 else 0.12
        lens.material_override = m
        lens.position = pos + Vector3(0.2, 4.55 + float(i) * 0.28, 0)
        root.add_child(lens)


func _build_braga_bridge(parent: Node3D) -> void :
    var a: = BRAGA_A
    var b: = BRAGA_B
    var total: float = a.distance_to(b)
    if total < 1.0:
        return
    var dir2: = (b - a) / total
    var perp2: = Vector2(-dir2.y, dir2.x)
    var bays: int = maxi(10, int(total / 26.0))
    var top_l: = PackedVector3Array()
    var top_r: = PackedVector3Array()
    var bot_l: = PackedVector3Array()
    var bot_r: = PackedVector3Array()
    for i in range(bays + 1):
        var frac: float = float(i) / float(bays)
        var t: float = total * frac
        var arch: float = BRAGA_RISE * sin(PI * frac)
        for s: float in [1.0, -1.0]:
            var planar: = a + dir2 * t + perp2 * (BRAGA_HALF * s)
            var bn: = to_world(planar.x, planar.y, BRAGA_DECK_Y + 0.8)
            var tn: = to_world(planar.x, planar.y, BRAGA_DECK_Y + 5.0 + arch)
            if s > 0.0:
                bot_l.append(bn)
                top_l.append(tn)
            else:
                bot_r.append(bn)
                top_r.append(tn)
    var st: = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(bays + 1):
        _emit_beam(st, bot_l[i], top_l[i], 0.6, COL_BRAGA)   # verticals
        _emit_beam(st, bot_r[i], top_r[i], 0.6, COL_BRAGA)
        if i % 4 == 0:
            _emit_beam(st, top_l[i], top_r[i], 0.6, COL_BRAGA)   # portal bracing across the top
    for i in range(bays):
        _emit_beam(st, top_l[i], top_l[i + 1], 0.7, COL_BRAGA)   # top chords
        _emit_beam(st, top_r[i], top_r[i + 1], 0.7, COL_BRAGA)
        _emit_beam(st, bot_l[i], bot_l[i + 1], 0.7, COL_BRAGA)   # bottom chords
        _emit_beam(st, bot_r[i], bot_r[i + 1], 0.7, COL_BRAGA)
        _emit_beam(st, bot_l[i], top_l[i + 1], 0.4, COL_BRAGA)   # web diagonals
        _emit_beam(st, bot_r[i], top_r[i + 1], 0.4, COL_BRAGA)
    st.generate_normals()
    var mat: = StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.roughness = 0.7
    mat.metallic = 0.25
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    st.set_material(mat)
    var mi: = MeshInstance3D.new()
    mi.name = "BragaBridge"
    mi.mesh = st.commit()
    parent.add_child(mi)


# USS Massachusetts ("Big Mamie") moored at Battleship Cove beside the Braga
# Bridge — a stylized grey battleship silhouette (hull, deck, superstructure,
# conning tower, funnel, mast, fore/aft turrets with twin barrels). Visual only;
# built once over the real cove coords and aligned to the bridge axis.
func _build_battleship(parent: Node3D) -> void :
    var base: = to_world(-20180.0, 7882.0, 0.0)
    var aw: = to_world(BRAGA_A.x, BRAGA_A.y, 0.0)
    var bw: = to_world(BRAGA_B.x, BRAGA_B.y, 0.0)
    var d: = bw - aw
    var yaw: float = atan2(d.z, d.x)
    var lx: = Vector3(cos(yaw), 0.0, sin(yaw))           # length axis (bow↔stern)
    var px: = Vector3(-lx.z, 0.0, lx.x)                   # beam axis (port↔starboard)
    var hull: = Color(0.40, 0.43, 0.46)
    var deck: = Color(0.34, 0.30, 0.24)
    var ssup: = Color(0.47, 0.49, 0.51)
    var dark: = Color(0.20, 0.21, 0.23)
    var st: = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    _emit_box_rot(st, base + Vector3(0, 4.0, 0), Vector3(208, 8, 27), yaw, hull)        # hull
    _emit_box_rot(st, base + Vector3(0, 8.3, 0), Vector3(198, 0.7, 23), yaw, deck)      # deck
    _emit_box_rot(st, base + Vector3(0, 12.5, 0), Vector3(66, 8, 16), yaw, ssup)        # superstructure
    _emit_box_rot(st, base + Vector3(0, 18.5, 0), Vector3(32, 6, 12), yaw, ssup)
    _emit_box_rot(st, base - lx * 6.0 + Vector3(0, 23.0, 0), Vector3(13, 13, 11), yaw, ssup)  # conning tower
    _emit_box_rot(st, base + lx * 10.0 + Vector3(0, 24.0, 0), Vector3(11, 9, 10), yaw, dark)  # funnel
    _emit_beam(st, base - lx * 6.0 + Vector3(0, 29.0, 0), base - lx * 6.0 + Vector3(0, 46.0, 0), 1.0, dark)  # mast
    # Main-battery turrets: two forward, two aft (superfiring pairs), twin barrels.
    for slot: float in [58.0, 40.0, -40.0, -58.0]:
        var sgn: float = 1.0 if slot > 0.0 else -1.0
        var tc: = base + lx * slot
        _emit_box_rot(st, tc + Vector3(0, 10.0, 0), Vector3(16, 5, 18), yaw, ssup)
        for off: float in [-3.2, 3.2]:
            var b0: = tc + px * off + Vector3(0, 11.0, 0) + lx * (sgn * 8.0)
            var b1: = b0 + lx * (sgn * 15.0)
            _emit_beam(st, b0, b1, 1.2, dark)
    st.generate_normals()
    var mat: = StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.roughness = 0.8
    mat.metallic = 0.3
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    st.set_material(mat)
    var mi: = MeshInstance3D.new()
    mi.name = "Battleship"
    mi.mesh = st.commit()
    parent.add_child(mi)
    # Mooring lights + nameplate so Battleship Cove reads from the Braga approach.
    for off: Vector3 in [lx * 95.0, -lx * 95.0]:
        var lamp: = OmniLight3D.new()
        lamp.light_color = Color(1.0, 0.72, 0.42)
        lamp.light_energy = 0.0
        lamp.omni_range = 22.0
        lamp.position = base + off + Vector3(0, 14.0, 0)
        lamp.add_to_group("mooring_light")
        parent.add_child(lamp)
    var lbl: = Label3D.new()
    lbl.text = "USS Massachusetts"
    lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    lbl.modulate = Color(0.88, 0.9, 0.92)
    lbl.font_size = 48
    lbl.pixel_size = 0.028
    lbl.position = base + Vector3(0, 32.0, 0)
    parent.add_child(lbl)


func _emit_road(st: SurfaceTool, pts: Array, half: float, col: Color) -> void :
    for i in range(pts.size() - 1):
        var a: = Vector2(float(pts[i][0]), float(pts[i][1]))
        var b: = Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
        var dir: = (b - a)
        if dir.length_squared() < 0.0001:
            continue
        dir = dir.normalized()
        var perp: = Vector2(-dir.y, dir.x) * half
        var a_l: = a + perp
        var a_r: = a - perp
        var b_l: = b + perp
        var b_r: = b - perp
        var va_l: = to_world(a_l.x, a_l.y, Y_ROAD)
        var va_r: = to_world(a_r.x, a_r.y, Y_ROAD)
        var vb_l: = to_world(b_l.x, b_l.y, Y_ROAD)
        var vb_r: = to_world(b_r.x, b_r.y, Y_ROAD)
        for v in [va_l, va_r, vb_r, va_l, vb_r, vb_l]:
            st.set_color(col)
            st.set_uv(Vector2(v.x / ROAD_TILE, v.z / ROAD_TILE))
            st.add_vertex(v)


func _build_overlays(parent: Node3D, bbox: Rect2) -> void :
    var root: = Node3D.new()
    root.name = "LandUse"
    parent.add_child(root)
    for key in OVERLAY_COLORS.keys():
        var path: = "%s/overlays/%s.json" % [MAP_DIR, key]
        var data: Variant = _read_json(path)
        if data == null or not (data is Array):
            continue
        var st: = SurfaceTool.new()
        st.begin(Mesh.PRIMITIVE_TRIANGLES)
        var col: Color = OVERLAY_COLORS[key]
        var any: = false
        for ring in data:
            if not (ring is Array) or ring.size() < 3:
                continue
            var poly2: = PackedVector2Array()
            for p in ring:
                poly2.append(Vector2(float(p[0]), float(p[1])))
            if not bbox.has_point(poly2[0]):
                continue
            var tri: = Geometry2D.triangulate_polygon(poly2)
            if tri.is_empty():
                continue
            for i in tri:
                st.set_color(col)
                st.add_vertex(to_world(poly2[i].x, poly2[i].y, Y_OVERLAY))
            any = true
            overlays_built += 1
        if not any:
            continue
        st.generate_normals()
        var mat: = StandardMaterial3D.new()
        mat.vertex_color_use_as_albedo = true
        if key == "water":
            mat.roughness = 0.12          # glossy so the sky/sun reflect off it
            mat.metallic = 0.25
            mat.albedo_color = Color(0.55, 0.7, 0.85)   # multiplies the blue vertex tint
        else:
            mat.roughness = 1.0
        st.set_material(mat)
        var mi: = MeshInstance3D.new()
        mi.name = "Overlay_%s" % key
        mi.mesh = st.commit()
        root.add_child(mi)


# Scatter low-poly conifers across the green overlays (parks / woods / cemeteries)
# with one cheap MultiMesh, so those areas read as planted instead of flat green.
func _build_trees(parent: Node3D) -> void :
    var positions: Array = []
    for key in ["parks", "wood", "cemetery"]:
        var data: Variant = _read_json("%s/overlays/%s.json" % [MAP_DIR, key])
        if data == null or not (data is Array):
            continue
        for ring in data:
            if not (ring is Array) or ring.size() < 3:
                continue
            var poly2: = PackedVector2Array()
            for p in ring:
                poly2.append(Vector2(float(p[0]), float(p[1])))
            if not FULL_BBOX.has_point(poly2[0]):
                continue
            var tri: = Geometry2D.triangulate_polygon(poly2)
            for i in range(0, tri.size() - 2, 3):
                var a: = poly2[tri[i]]
                var b: = poly2[tri[i + 1]]
                var c: = poly2[tri[i + 2]]
                positions.append((a + b + c) / 3.0)
                if positions.size() >= 5000:
                    break
            if positions.size() >= 5000:
                break
        if positions.size() >= 5000:
            break
    if positions.is_empty():
        return
    var cone: = CylinderMesh.new()
    cone.top_radius = 0.0
    cone.bottom_radius = 1.7
    cone.height = 4.8
    cone.radial_segments = 6
    var mat: = StandardMaterial3D.new()
    mat.albedo_color = Color(0.17, 0.33, 0.16)
    mat.roughness = 1.0
    cone.material = mat
    var mm: = MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = cone
    mm.instance_count = positions.size()
    for idx in positions.size():
        var pos: Vector3 = to_world(positions[idx].x, positions[idx].y, Y_OVERLAY)
        mm.set_instance_transform(idx, Transform3D(Basis(), pos + Vector3(0, 2.4, 0)))
    var mmi: = MultiMeshInstance3D.new()
    mmi.name = "Trees"
    mmi.multimesh = mm
    parent.add_child(mmi)


# Derive player/NPC/car/light spawn points from the sampled road network so the
# real map is a drop-in for the procedural CityBuilder's spawn fields.
func _derive_spawns() -> void :
    if _road_samples.is_empty():
        return
    # Player spawns on the street nearest downtown New Bedford (by the Whaling
    # Museum / historic district) rather than the bare map origin, so a new game
    # starts somewhere recognizable instead of an arbitrary waterfront edge.
    var anchor: = Vector2(-219.0, 107.0)   # world (x, z) of the downtown core
    var best: = 0
    var best_d: = INF
    for i in _road_samples.size():
        var p: Vector3 = _road_samples[i][0]
        var dx: float = p.x - anchor.x
        var dz: float = p.z - anchor.y
        var d: = dx * dx + dz * dz
        if d < best_d:
            best_d = d
            best = i
    var sp: Vector3 = _road_samples[best][0]
    player_spawn = Vector3(sp.x, 0.6, sp.z)
    mission_giver_pos = player_spawn + Vector3(6, 0, 6)
    mission_giver_rot = _road_samples[best][1]

    var n: = _road_samples.size()
    var step: int = max(1, int(n / 240.0))
    var i2: = 0
    while i2 < n:
        var s: Array = _road_samples[i2]
        var pos: Vector3 = s[0]
        npc_waypoints.append(pos)
        if car_slots.size() < 120:
            car_slots.append([Vector3(pos.x, 0.0, pos.z), float(s[1])])
        if light_slots.size() < 60:
            light_slots.append(Vector3(pos.x, 0.0, pos.z))
        if npc_spawns.size() < 30:
            npc_spawns.append(Vector3(pos.x, 0.6, pos.z))
        i2 += step

    for pl in named_places:
        if job_points.size() >= 30:
            break
        var pp: Vector3 = pl["pos"]
        job_points.append(Vector3(pp.x, 0.5, pp.z))
    if job_points.is_empty():
        for s2 in _road_samples:
            if job_points.size() >= 20:
                break
            var p3: Vector3 = s2[0]
            job_points.append(Vector3(p3.x, 0.5, p3.z))


func _centroid(fp: Array) -> Vector2:
    var c: = Vector2.ZERO
    for p in fp:
        c += Vector2(float(p[0]), float(p[1]))
    return c / float(fp.size())
