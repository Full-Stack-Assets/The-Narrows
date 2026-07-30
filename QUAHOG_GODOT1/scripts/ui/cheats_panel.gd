extends Control
class_name CheatsPanel

# Reusable CHEATS / test-tools overlay. Used from the main menu (menu_mode = true,
# shows fresh-game quick-start spawns) and in-game from the Big Map (menu_mode =
# false, toggles apply live). All state lives on GameManager and is persisted.

const FONT_PATH: = "res://assets/fonts/noto_serif.ttf"
const PLAY_SCENE: = "res://scenes/game_world.tscn"

const BOOL_CHEATS: Array = [
    ["No Police (no heat)", "cheat_no_police"],
    ["God Mode", "cheat_godmode"],
    ["Infinite Ammo", "cheat_infinite_ammo"],
    ["All Weapons (next start)", "cheat_all_weapons"],
    ["One-Shot Kills", "cheat_oneshot"],
    ["Rapid Fire", "cheat_rapidfire"],
    ["Super Speed", "cheat_super_speed"],
    ["Super Jump", "cheat_super_jump"],
    ["Infinite Cash", "cheat_infinite_cash"],
    ["Car Turbo", "cheat_car_turbo"],
    ["Teleport Anywhere (map)", "cheat_teleport_anywhere"],
    ["Debug Overlay (FPS/mem)", "cheat_show_debug"],
]
const SPAWN_PRESETS: Array = [
    {"name": "Downtown New Bedford", "pos": Vector3(-219, 1.5, 107)},
    {"name": "Seamen's Bethel", "pos": Vector3(-272, 1.5, -72)},
    {"name": "Fish Pier", "pos": Vector3(-310, 1.5, -70)},
    {"name": "Opening Safehouse", "pos": Vector3(-240, 1.5, -116)},
    {"name": "Linguiça Linq Diner", "pos": Vector3(-300, 1.5, -58)},
    {"name": "Fort Taber", "pos": Vector3(1495, 1.5, 4560)},
    {"name": "Fall River (City Hall)", "pos": Vector3(-19475, 1.5, -7216)},
    {"name": "Battleship Cove", "pos": Vector3(-20180, 1.5, -7790)},
    {"name": "Brockton", "pos": Vector3(-8100, 1.5, -49768)},
    {"name": "Stoughton", "pos": Vector3(-14916, 1.5, -54435)},
]
const TIME_OPTS: Array = [["Normal", -1.0], ["Dusk", 0.0], ["Day", 0.75], ["Night", 0.25], ["Dawn", 0.5]]
const RAIN_OPTS: Array = [["Auto", -1], ["Rain", 1], ["Dry", 0]]
const TRAFFIC_OPTS: Array = [["Light", 0.5], ["Normal", 1.0], ["Heavy", 2.0], ["Insane", 4.0]]
const SPEED_OPTS: Array = [["0.5x", 0.5], ["1x", 1.0], ["2x", 2.0], ["4x", 4.0]]

var menu_mode: bool = true
var _font: Font = null


func _ready() -> void :
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    move_to_front()
    if ResourceLoader.exists(FONT_PATH):
        _font = load(FONT_PATH)

    var dim: = ColorRect.new()
    dim.color = Color(0, 0, 0, 0.82)
    dim.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var scroll: = ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.offset_left = 120
    scroll.offset_right = -120
    scroll.offset_top = 56
    scroll.offset_bottom = -48
    add_child(scroll)

    var box: = VBoxContainer.new()
    box.add_theme_constant_override("separation", 9)
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(box)

    box.add_child(_label("CHEATS · TEST TOOLS", 34, Color(1.0, 0.81, 0.28)))
    box.add_child(_label("Toggles (saved):", 19, Color(0.8, 0.8, 0.84)))
    for c in BOOL_CHEATS:
        _bool_cheat(box, str(c[0]), str(c[1]))
    box.add_child(_label("Settings:", 19, Color(0.8, 0.8, 0.84)))
    _cycle_cheat(box, "Time", "cheat_time_phase", TIME_OPTS)
    _cycle_cheat(box, "Weather", "cheat_force_rain", RAIN_OPTS)
    _cycle_cheat(box, "Traffic (next start)", "cheat_traffic_mult", TRAFFIC_OPTS)
    _cycle_cheat(box, "Game Speed", "cheat_time_scale", SPEED_OPTS)
    box.add_child(_text_button("+ ADD $10,000", _add_cash))
    if menu_mode:
        box.add_child(_label("Quick start (fresh game):", 19, Color(0.8, 0.8, 0.84)))
        for preset in SPAWN_PRESETS:
            var p: Dictionary = preset
            var pos: Vector3 = p["pos"]
            box.add_child(_text_button("▶ " + str(p["name"]), _spawn.bind(pos)))
    box.add_child(_text_button("✕ CLOSE", _close))


func _label(text: String, size: int, color: Color) -> Label:
    var l: = Label.new()
    l.text = text
    l.add_theme_color_override("font_color", color)
    l.add_theme_font_size_override("font_size", size)
    if _font:
        l.add_theme_font_override("font", _font)
    return l


func _text_button(text: String, cb: Callable) -> Button:
    var b: = Button.new()
    b.text = text
    b.focus_mode = Control.FOCUS_NONE
    b.custom_minimum_size = Vector2(380, 60)
    if _font:
        b.add_theme_font_override("font", _font)
    b.add_theme_font_size_override("font_size", 26)
    if cb.is_valid():
        b.pressed.connect(cb)
    return b


func _gm() -> Node:
    return get_node_or_null("/root/GameManager")


func _bool_cheat(box: VBoxContainer, label: String, flag: String) -> void :
    var b: = _text_button("", Callable())
    b.pressed.connect(_toggle_flag.bind(b, label, flag))
    _refresh_flag(b, label, flag)
    box.add_child(b)


func _refresh_flag(btn: Button, label: String, flag: String) -> void :
    var gm: = _gm()
    var on: bool = gm != null and bool(gm.get(flag))
    btn.text = label + ":  " + ("ON" if on else "OFF")
    btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.55) if on else Color(0.85, 0.72, 0.42))


func _toggle_flag(btn: Button, label: String, flag: String) -> void :
    var gm: = _gm()
    if gm:
        gm.set(flag, not bool(gm.get(flag)))
        if gm.has_method("save_game"):
            gm.save_game()
    _refresh_flag(btn, label, flag)


func _cycle_cheat(box: VBoxContainer, label: String, flag: String, options: Array) -> void :
    var b: = _text_button("", Callable())
    b.pressed.connect(_cycle_flag.bind(b, label, flag, options))
    _refresh_cycle(b, label, flag, options)
    box.add_child(b)


func _refresh_cycle(btn: Button, label: String, flag: String, options: Array) -> void :
    var gm: = _gm()
    var v: float = float(gm.get(flag)) if gm != null else 0.0
    var disp: String = str(options[0][0])
    for opt in options:
        if absf(float(opt[1]) - v) < 0.001:
            disp = str(opt[0])
            break
    btn.text = label + ":  " + disp


func _cycle_flag(btn: Button, label: String, flag: String, options: Array) -> void :
    var gm: = _gm()
    if gm == null:
        return
    var v: float = float(gm.get(flag))
    var cur: int = 0
    for i in options.size():
        if absf(float(options[i][1]) - v) < 0.001:
            cur = i
            break
    var nv: Variant = options[(cur + 1) % options.size()][1]
    gm.set(flag, nv)
    if gm.has_method("save_game"):
        gm.save_game()
    # Game speed applies live so you can slow/fast time without restarting.
    if flag == "cheat_time_scale":
        Engine.time_scale = clampf(float(nv), 0.1, 4.0)
    _refresh_cycle(btn, label, flag, options)


func _add_cash() -> void :
    var gm: = _gm()
    if gm and gm.has_method("add_cash"):
        gm.add_cash(10000)


func _spawn(pos: Vector3) -> void :
    var gm: = _gm()
    if gm:
        if gm.has_method("reset_save"):
            gm.reset_save()
        gm.player_spawn_override = pos
        gm.has_spawn_override = true
    var startup_metrics := get_node_or_null("/root/StartupMetrics")
    if startup_metrics:
        startup_metrics.mark("play_pressed")
    get_tree().change_scene_to_file(PLAY_SCENE)


func _close() -> void :
    queue_free()
