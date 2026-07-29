extends Control
class_name Minimap





const WORLD_VIEW: = 240.0
const SLICE: = "res://data/map/slice-newbedford.json"
const CELL: = 200.0  # spatial bin size so we only draw nearby road segments

var player: Node3D = null
var job_manager: Node = null
var wanted_system: Node = null
var _font: Font

# Real road network binned into CELL-sized cells of [Vector2 a, Vector2 b]
# segments in world XZ (x=east, z=-north), so _draw only iterates nearby roads.
var _road_cells: Dictionary = {}
var _landmarks: Array = []          # [{name:String, pos:Vector2(x,z)}]
var _roads_loaded: bool = false

var _scale: float = 1.0
var _center_px: Vector2 = Vector2.ZERO
var _pulse: float = 0.0


func bind(p_player: Node3D, p_jobs: Node, p_wanted: Node) -> void :
    player = p_player
    job_manager = p_jobs
    wanted_system = p_wanted


func _ready() -> void :
    custom_minimum_size = Vector2(240, 240)
    size = custom_minimum_size
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _font = load("res://assets/fonts/noto_serif.ttf")


func apply_layout(rect: Rect2) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    position = rect.position
    custom_minimum_size = rect.size
    size = rect.size
    queue_redraw()


func _process(delta: float) -> void :
    _pulse = fmod(_pulse + delta * 3.0, TAU)
    queue_redraw()


func _load_roads() -> void :
    _roads_loaded = true
    var data: Variant = MapLoader.read_json_any(SLICE)
    if not (data is Dictionary):
        return
    var roads: Variant = data.get("roads", [])
    if not (roads is Array):
        return
    for r in roads:
        if not (r is Dictionary):
            continue
        var pts: Variant = r.get("points")
        if not (pts is Array) or pts.size() < 2:
            continue
        for i in range(pts.size() - 1):
            # world XZ: x = east, z = -north. Stored flat (a, b, a, b, ...).
            var a: = Vector2(float(pts[i][0]), - float(pts[i][1]))
            var b: = Vector2(float(pts[i + 1][0]), - float(pts[i + 1][1]))
            var key: = Vector2i(int(floor(((a.x + b.x) * 0.5) / CELL)), int(floor(((a.y + b.y) * 0.5) / CELL)))
            if not _road_cells.has(key):
                _road_cells[key] = []
            var arr: Array = _road_cells[key]
            arr.append(a)
            arr.append(b)

    var lms: Variant = data.get("landmarks", [])
    if lms is Array:
        for l in lms:
            if not (l is Dictionary):
                continue
            var lp: Variant = l.get("pos")
            if not (lp is Array) or lp.size() < 2:
                continue
            _landmarks.append({"name": str(l.get("name", "")), "pos": Vector2(float(lp[0]), - float(lp[1]))})


# Nearest real landmark within range, else the synthetic district name.
func _location_name(p: Vector3) -> String:
    var here: = Vector2(p.x, p.z)
    var best: String = ""
    var best_d: float = 220.0
    for lm in _landmarks:
        var d: float = here.distance_to(lm["pos"])
        if d < best_d:
            best_d = d
            best = str(lm["name"])
    if best != "":
        return best
    return _district_name(p)


func _world_to_map(w: Vector3, center: Vector3) -> Vector2:
    var rel: = w - center
    return _center_px + Vector2(rel.x, rel.z) * _scale


func _district_name(p: Vector3) -> String:
    if p.length() < 36.0:
        return "Mill Plaza"
    var ns: = "North" if p.z < -20.0 else ("South" if p.z > 20.0 else "")
    var ew: = "West" if p.x < -20.0 else ("East" if p.x > 20.0 else "")
    if ns == "" and ew == "":
        return "Downtown"
    var label: = (ns + " " + ew).strip_edges()
    return label + " End"


func _draw() -> void :
    var rect: = Rect2(Vector2.ZERO, size)
    draw_rect(rect, Color(0.06, 0.07, 0.09, 0.82), true)
    if player == null or not is_instance_valid(player):
        draw_rect(rect, Color(0.79, 0.52, 0.16, 0.7), false, 2.0)
        return

    _scale = size.x / WORLD_VIEW
    _center_px = size * 0.5
    var center: Vector3 = player.global_position


    if not _roads_loaded:
        _load_roads()
    var road_col: = Color(0.62, 0.64, 0.55, 0.95)
    var cx: = int(floor(center.x / CELL))
    var cz: = int(floor(center.z / CELL))
    for dx in range(-1, 2):
        for dz in range(-1, 2):
            var segs: Array = _road_cells.get(Vector2i(cx + dx, cz + dz), [])
            var i: = 0
            while i + 1 < segs.size():
                var aw: Vector2 = segs[i]
                var bw: Vector2 = segs[i + 1]
                draw_line(_world_to_map(Vector3(aw.x, 0, aw.y), center), _world_to_map(Vector3(bw.x, 0, bw.y), center), road_col, 2.0)
                i += 2


    if job_manager and job_manager.has_method("has_active_job") and job_manager.has_active_job():
        var obj: Vector3 = job_manager.get_objective_position()
        var col: = Color(0.4, 0.9, 0.5) if (job_manager.get("stage") == 2) else Color(0.97, 0.8, 0.3)
        _draw_blip(obj, center, col, 6.0 + sin(_pulse) * 2.0)


    if wanted_system and wanted_system.has_method("get_cops"):
        for cop in wanted_system.get_cops():
            if is_instance_valid(cop):
                _draw_blip(cop.global_position, center, Color(0.95, 0.3, 0.3), 4.0)
    if wanted_system and wanted_system.has_method("get_enforcers"):
        for goon in wanted_system.get_enforcers():
            if is_instance_valid(goon):
                _draw_blip(goon.global_position, center, Color(0.95, 0.45, 0.2), 4.0)

    if BusinessManager:
        for i in BusinessManager.BUSINESSES.size():
            var b: Dictionary = BusinessManager.BUSINESSES[i]
            var pos: Vector3 = b["pos"]
            var owned: bool = BusinessManager.is_owned(i)
            var col: Color = Color(0.29, 0.84, 0.43) if owned else Color(1.0, 0.81, 0.29)
            _draw_blip(pos, center, col, 3.5 if owned else 2.5)


    var yaw: float = 0.0
    if player.has_method("get_map_heading"):
        yaw = player.get_map_heading()
    _draw_player(yaw)


    draw_rect(rect, Color(0.79, 0.52, 0.16, 0.85), false, 2.0)
    if _font:
        # North indicator (the minimap is north-up, so N sits at the top edge).
        draw_string(_font, Vector2(size.x - 22, 20), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.95, 0.86, 0.6))
        var dn: = _location_name(center)
        draw_string(_font, Vector2(8, size.y - 10), dn, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.95, 0.86, 0.6))


func _draw_blip(world: Vector3, center: Vector3, color: Color, r: float) -> void :
    var p: = _world_to_map(world, center)
    var margin: = 10.0
    p.x = clampf(p.x, margin, size.x - margin)
    p.y = clampf(p.y, margin, size.y - margin)
    draw_circle(p, r + 2.0, Color(0, 0, 0, 0.5))
    draw_circle(p, r, color)


func _draw_player(yaw: float) -> void :
    var c: = _center_px

    var fwd: = Vector2(sin(yaw), - cos(yaw))
    var right: = Vector2( - fwd.y, fwd.x)
    var p1: = c + fwd * 9.0
    var p2: = c - fwd * 6.0 + right * 6.0
    var p3: = c - fwd * 6.0 - right * 6.0
    draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(0.45, 0.8, 1.0))
    draw_circle(c, 2.5, Color(1, 1, 1))
