extends Control















const TESANA_QUIT_URL: = "https://tesana.ai/quit"



const PLAY_TARGET_SCENE: = "res://scenes/game_world.tscn"




const BUTTON_IDS: PackedStringArray = ["play"]
const BUTTON_STYLEBOXES: PackedStringArray = ["res://assets/ui/btn_play.tres"]


const BG_CANDIDATES: PackedStringArray = [
    "res://assets/ui/title_poster.webp", 
    "res://assets/ui/title_poster.png", 
    "res://assets/textures/backgrounds/menu_background.png", 
    "res://assets/textures/backgrounds/menu_bg.png", 
    "res://assets/ui/menu_background.png", 
]
const CLICK_SFX_CANDIDATES: PackedStringArray = [
    "res://assets/audio/sfx/ui/ui_menu_click.mp3", 
    "res://assets/audio/sfx/ui/ui_button_click.mp3", 
    "res://assets/audio/sfx/ui/ui_click.mp3", 
    "res://assets/audio/sfx/ui/ui_ui_click.mp3", 
]
const SETTINGS_SCENE_CANDIDATES: PackedStringArray = [
    "res://scenes/ui/settings.tscn", 
    "res://scenes/settings.tscn", 
]
const CREDITS_SCENE_CANDIDATES: PackedStringArray = [
    "res://scenes/ui/credits.tscn", 
    "res://scenes/credits.tscn", 
]

const TIPS: PackedStringArray = [
    "WASD to move · Shift to sprint · F to grab a car.",
    "Heat climbs when you cause trouble. Lay low to cool off.",
    "Tap MAP for the city — tap a place name to fast-travel.",
    "Tap RADIO to cycle the stations: WHALE · The Rage · The Anvil · Maré Alta.",
    "Ram a car to stop it, then jack it on foot.",
    "Take jobs from the contact downtown to earn your first dollars.",
]
const FONT_PATH: = "res://assets/fonts/noto_serif.ttf"

var _click_sfx_stream: AudioStream = null
var _wordmark: TextureRect = null
var _font: Font = null
var _cheats_overlay: Control = null
var _new_game_dialog: ConfirmationDialog = null

# Quick-start spawn presets for testing (world XZ; y lifted so you drop onto the
# street). Lets you jump straight into any corner of the South Coast.
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


func _ready() -> void :
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    Engine.time_scale = 1.0   # menus always run at normal speed (slow-mo is in-game)
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    if ResourceLoader.exists("res://assets/ui/theme.tres"):
        theme = load("res://assets/ui/theme.tres") as Theme

    var sfx_path: = _first_existing(CLICK_SFX_CANDIDATES)
    if sfx_path != "":
        _click_sfx_stream = load(sfx_path) as AudioStream

    if ResourceLoader.exists(FONT_PATH):
        _font = load(FONT_PATH)

    _build_background()
    _build_wordmark()
    _build_buttons()
    _build_text_overlay()
    call_deferred("_mark_menu_visible")


func _mark_menu_visible() -> void:
    if StartupMetrics:
        StartupMetrics.mark("menu_visible")


# Web StartMenu parity: era tag, subtitle, a rotating tip, and the OSM
# attribution footer.
func _build_text_overlay() -> void :
    var era: = _make_label("SOUTH COAST · NOW", 22, Color(1.0, 0.48, 0.85, 0.9))
    era.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(era)
    era.anchor_left = 0.0
    era.anchor_right = 1.0
    era.anchor_top = 0.0
    era.offset_top = 36
    era.offset_bottom = 70

    var subtitle: = _make_label("New Bedford · Fall River · the Narrows", 26, Color(0.9, 0.86, 0.78, 0.85))
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(subtitle)
    subtitle.anchor_left = 0.0
    subtitle.anchor_right = 1.0
    subtitle.anchor_top = 0.0
    subtitle.offset_top = 396
    subtitle.offset_bottom = 436

    var tip_i: int = int(Time.get_unix_time_from_system()) % TIPS.size()
    var tip: = _make_label("TIP: " + TIPS[tip_i], 22, Color(0.82, 0.82, 0.86, 0.8))
    tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(tip)
    tip.anchor_left = 0.0
    tip.anchor_right = 1.0
    tip.anchor_bottom = 1.0
    tip.anchor_top = 1.0
    tip.offset_top = -110
    tip.offset_bottom = -64

    var build: = _make_label("BUILD " + BuildInfo.display_string(), 14, Color(0.72, 0.72, 0.76, 0.72))
    build.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(build)
    build.anchor_left = 0.0
    build.anchor_right = 1.0
    build.anchor_bottom = 1.0
    build.anchor_top = 1.0
    build.offset_top = -58
    build.offset_bottom = -36

    var attrib: = _make_label("Map data © OpenStreetMap contributors, ODbL · An original work", 16, Color(0.7, 0.7, 0.74, 0.6))
    attrib.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(attrib)
    attrib.anchor_left = 0.0
    attrib.anchor_right = 1.0
    attrib.anchor_bottom = 1.0
    attrib.anchor_top = 1.0
    attrib.offset_top = -34
    attrib.offset_bottom = -10


func _make_label(text: String, font_size: int, color: Color) -> Label:
    var lbl: = Label.new()
    lbl.text = text
    lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    lbl.add_theme_color_override("font_color", color)
    lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    lbl.add_theme_constant_override("outline_size", 5)
    lbl.add_theme_font_size_override("font_size", font_size)
    if _font:
        lbl.add_theme_font_override("font", _font)
    return lbl


func _first_existing(paths: PackedStringArray) -> String:
    for p in paths:
        if ResourceLoader.exists(p):
            return p
    return ""


func _build_background() -> void :
    var bg_path: = _first_existing(BG_CANDIDATES)
    if bg_path != "":
        var bg: = TextureRect.new()
        bg.texture = load(bg_path)
        bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(bg)
        bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    else:
        var solid: = ColorRect.new()
        solid.color = Color(0.08, 0.08, 0.1, 1.0)
        solid.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(solid)
        solid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


    var vignette: = ColorRect.new()
    vignette.color = Color(0, 0, 0, 0.35)
    vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(vignette)
    vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_wordmark() -> void :
    # Text stays authoritative and accessible over the text-free key art.
    var title: = _make_label("THE NARROWS", 88, Color(1.0, 1.0, 1.0, 0.98))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_constant_override("outline_size", 8)
    add_child(title)
    title.anchor_left = 0.0
    title.anchor_right = 1.0
    title.anchor_top = 0.0
    title.offset_top = 88
    title.offset_bottom = 200
    _wordmark = null


func _build_buttons() -> void :




    var center: = CenterContainer.new()
    add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_PASS

    var vbox: = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 18)
    center.add_child(vbox)


    if _wordmark != null:
        var spacer: = Control.new()
        spacer.custom_minimum_size = Vector2(0, 240)
        spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vbox.add_child(spacer)
    else:
        var spacer: = Control.new()
        spacer.custom_minimum_size = Vector2(0, 200)
        spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        vbox.add_child(spacer)

    # Continue (resume the saved spot) appears only when a save exists. The
    # image PLAY button below it starts a fresh game.
    var gm: = get_node_or_null("/root/GameManager")
    if gm and gm.has_method("has_save") and gm.has_save():
        vbox.add_child(_make_text_button("▶ CONTINUE", _on_continue_pressed))
    elif gm and gm.has_method("has_backup_save") and gm.has_backup_save():
        vbox.add_child(_make_text_button("↻ RECOVER SAVE", _on_continue_pressed))

    var n: = BUTTON_IDS.size()
    for i in n:
        var btn: = _make_button(BUTTON_IDS[i], BUTTON_STYLEBOXES[i])
        vbox.add_child(btn)

    vbox.add_child(_make_text_button("⚙ CHEATS", _open_cheats))


func _make_text_button(text: String, cb: Callable) -> Button:
    var b: = Button.new()
    b.text = text
    b.focus_mode = Control.FOCUS_NONE
    b.custom_minimum_size = Vector2(360, 64)
    if _font:
        b.add_theme_font_override("font", _font)
    b.add_theme_font_size_override("font_size", 30)
    b.add_theme_color_override("font_color", Color(1.0, 0.81, 0.28))
    b.pressed.connect(cb)
    return b


func _on_continue_pressed() -> void :
    _play_click_sfx()
    var gm: = get_node_or_null("/root/GameManager")
    if gm and gm.has_method("has_save") and not gm.has_save():
        if not gm.has_method("recover_backup_save") or gm.recover_backup_save() != OK:
            _show_notice("Save recovery failed", "The backup could not be validated. Start a New Game to continue.")
            return
    if gm and "has_saved_pos" in gm and gm.has_saved_pos:
        gm.player_spawn_override = gm.saved_pos
        gm.has_spawn_override = true
    _go_to_play()


func _make_button(id: String, stylebox_path: String) -> Button:
    var btn: = Button.new()
    btn.custom_minimum_size = Vector2(360, 110)
    btn.text = ""
    btn.focus_mode = Control.FOCUS_NONE
    if ResourceLoader.exists(stylebox_path):
        var sb: = load(stylebox_path) as StyleBox
        if sb:
            btn.add_theme_stylebox_override("normal", sb)
            btn.add_theme_stylebox_override("hover", sb)
            btn.add_theme_stylebox_override("pressed", sb)
            btn.add_theme_stylebox_override("focus", sb)
            btn.add_theme_stylebox_override("disabled", sb)
    btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
    btn.mouse_exited.connect(_on_button_hover.bind(btn, false))
    btn.pressed.connect(_on_button_pressed.bind(id))
    return btn


func _on_button_hover(btn: Button, entering: bool) -> void :
    var target: = Color(1.1, 1.1, 1.1, 1.0) if entering else Color(1.0, 1.0, 1.0, 1.0)
    var tween: = create_tween()
    tween.tween_property(btn, "modulate", target, 0.08)


func _on_button_pressed(id: String) -> void :
    _play_click_sfx()
    match id:
        "play", "new_game":
            _on_new_game()
        "continue":
            _on_continue_pressed()
        "settings", "options":
            _open_settings_or_noop()
        "credits":
            _open_credits_or_noop()
        "back":
            pass
        "quit", "exit":
            _quit_to_tesana()
        _:



            push_warning("Main menu: unknown button id '" + id + "' (no action wired).")


func _on_new_game() -> void :
    var gm: = get_node_or_null("/root/GameManager")
    if gm and (
        (gm.has_method("has_save") and gm.has_save())
        or (gm.has_method("has_backup_save") and gm.has_backup_save())
    ):
        _confirm_new_game()
        return
    _start_new_game()


func _confirm_new_game() -> void:
    if _new_game_dialog and is_instance_valid(_new_game_dialog):
        _new_game_dialog.popup_centered()
        return
    _new_game_dialog = ConfirmationDialog.new()
    _new_game_dialog.title = "Start New Game?"
    _new_game_dialog.dialog_text = "This resets story progress, cash, collectibles, activities, and vehicles. Your settings are preserved."
    _new_game_dialog.ok_button_text = "Start New Game"
    _new_game_dialog.cancel_button_text = "Keep Save"
    _new_game_dialog.confirmed.connect(_start_new_game)
    add_child(_new_game_dialog)
    _new_game_dialog.popup_centered(Vector2i(620, 220))


func _start_new_game() -> void:
    var gm: = get_node_or_null("/root/GameManager")
    if gm:
        gm.has_spawn_override = false
        if gm.has_method("reset_save"):
            gm.reset_save()
    _go_to_play()


func _show_notice(title: String, message: String) -> void:
    var dialog := AcceptDialog.new()
    dialog.title = title
    dialog.dialog_text = message
    dialog.confirmed.connect(dialog.queue_free)
    dialog.canceled.connect(dialog.queue_free)
    add_child(dialog)
    dialog.popup_centered(Vector2i(580, 180))


# --- Cheats / test panel ----------------------------------------------------

func _open_cheats() -> void :
    _play_click_sfx()
    if _cheats_overlay != null and is_instance_valid(_cheats_overlay):
        return
    var panel: = CheatsPanel.new()
    panel.menu_mode = true
    add_child(panel)
    _cheats_overlay = panel


func _go_to_play() -> void :
    if StartupMetrics:
        StartupMetrics.mark("play_pressed")
    var loader: = get_node_or_null("/root/LoadingScreen")
    if loader and loader.has_method("preload_and_change_scene"):
        loader.preload_and_change_scene(PLAY_TARGET_SCENE)
    else:
        get_tree().change_scene_to_file(PLAY_TARGET_SCENE)


func _open_settings_or_noop() -> void :
    var path: = _first_existing(SETTINGS_SCENE_CANDIDATES)
    if path != "":
        get_tree().change_scene_to_file(path)


func _open_credits_or_noop() -> void :
    var path: = _first_existing(CREDITS_SCENE_CANDIDATES)
    if path != "":
        get_tree().change_scene_to_file(path)


func _quit_to_tesana() -> void :








    if OS.has_feature("web"):
        var js: = "try { window.top.location.href = \"" + TESANA_QUIT_URL + "\"; }"\
+ " catch (e) { window.location.href = \"" + TESANA_QUIT_URL + "\"; }"
        JavaScriptBridge.eval(js)
    else:
        get_tree().quit()


func _play_click_sfx() -> void :




    if _click_sfx_stream == null:
        return
    var p: = AudioStreamPlayer.new()
    p.stream = _click_sfx_stream
    p.volume_db = -4.0
    add_child(p)
    p.play()
    p.finished.connect(p.queue_free)
