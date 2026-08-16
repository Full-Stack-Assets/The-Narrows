extends CanvasLayer







const VirtualJoystick: = preload("res://scripts/ui/virtual_joystick.gd")
const TouchButton: = preload("res://scripts/ui/touch_button.gd")
const TouchCamera: = preload("res://scripts/ui/touch_camera.gd")
const MinimapScript: = preload("res://scripts/ui/minimap.gd")
const LayoutProfileScript := preload("res://scripts/ui/layout_profile.gd")

const DESIGN: = Vector2(1920, 1080)
const LAYOUT_PATH: = "user://controls_layout.json"

var _player: CharacterBody3D = null
var _root: Control
var _cash_label: Label
var _scrimshaw_label: Label = null
var _fronts_label: Label = null
var _buy_prompt: Label = null
var _prompt_label: Label
var _toast_label: Label
var _radio_label: Label = null
var _clock_label: Label = null
var _debug_label: Label = null
var _debug_t: float = 0.0
var _speed_label: Label = null
var _driving_now: bool = false
var _pause_panel: Control
var _settings_panel: Control
var _controls_panel: Control
var _quality_option: OptionButton
var _pause_stats_label: Label
var _edit_banner: Control
var _font: Font


var _minimap: Control = null
var _big_map: Control = null
var _objective_label: Label = null
var _objective_panel: Control = null
var _tutorial_label: Label = null
var _subtitle_label: Label = null
var _activity_label: Label = null
var _obj_active: bool = false
var _obj_text: String = ""
var _obj_target: Vector3 = Vector3.ZERO
var _wanted_label: Label = null
var _pursuit_label: Label = null
var _pursuit_clear_timer: float = 0.0
var _faction_label: Label = null
var _ammo_label: Label = null
var _health_bar: ProgressBar = null
var _armor_bar: ProgressBar = null
var _job_manager: Node = null
var _wanted_system: Node = null
var _story_mission: Node = null
var _layout_profile: Dictionary = {}
var _utility_controls: Dictionary = {}
var _action_controls: Array[Control] = []
var _pause_scroll: ScrollContainer = null
var _settings_scroll: ScrollContainer = null
var _controls_help_label: Label = null

var _joystick
var _look_area
var _buttons: = {}
var _editables: Array = []
var _defaults: = {}
var _toast_tween: Tween = null


var _edit_mode: bool = false
var _drag_target: Control = null
var _drag_resize: bool = false
var _drag_last: Vector2 = Vector2.ZERO


func _ready() -> void :
    layer = 10
    process_mode = Node.PROCESS_MODE_ALWAYS
    _font = load("res://assets/fonts/noto_serif.ttf")

    _root = Control.new()
    _root.name = "HUDRoot"
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var theme: = load("res://assets/ui/theme.tres") as Theme
    if theme:
        _root.theme = theme
    add_child(_root)
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _build_look_area()
    _build_top_bar()
    _build_prompt()
    _build_toast()
    _build_touch_controls()
    _build_gameplay_panels()
    _build_pause()
    _build_radio()
    _build_edit_banner()
    _build_debug()

    _apply_layout_profile(false)
    _load_layout()
    get_viewport().size_changed.connect(_on_viewport_size_changed)

    if GameManager:
        GameManager.cash_changed.connect(_on_cash_changed)
        GameManager.notify.connect(show_toast)
        GameManager.wanted_changed.connect(_on_wanted_changed)
        GameManager.faction_changed.connect(_on_faction_changed)
        GameManager.scrimshaw_changed.connect(_on_scrimshaw_changed)
        GameManager.businesses_changed.connect(_on_businesses_changed)
        _on_cash_changed(GameManager.cash)
        _on_wanted_changed(GameManager.wanted_level)
        _on_faction_changed(GameManager.faction_level)
        _on_scrimshaw_changed(GameManager.scrimshaw_found())
        _on_businesses_changed(GameManager.businesses_owned())
    if BusinessManager:
        BusinessManager.near_buy_changed.connect(_on_near_buy_changed)


func bind_player(player: CharacterBody3D) -> void :
    _player = player
    if _joystick:
        _joystick.joystick_input.connect(_player.set_move_input)
    if _look_area:
        _look_area.look_delta.connect(_player.add_camera_look)

    if _player.has_signal("interactable_changed"):
        _player.interactable_changed.connect(_on_interactable_changed)
    if _player.has_signal("weapon_changed"):
        _player.weapon_changed.connect(_on_weapon_changed)
    if _player.has_signal("driving_changed"):
        _player.driving_changed.connect(_on_driving_changed)
    if _player.has_signal("health_changed"):
        _player.health_changed.connect(_on_health_changed)
    if _minimap and _minimap.has_method("bind"):
        _minimap.bind(_player, _job_manager, _wanted_system)
    if _big_map and _big_map.has_method("bind"):
        _big_map.bind(_player, _job_manager)


func bind_systems(job_manager: Node, wanted_system: Node) -> void :
    _job_manager = job_manager
    _wanted_system = wanted_system
    if _job_manager and _job_manager.has_signal("job_changed"):
        _job_manager.job_changed.connect(_on_job_changed)
    if _wanted_system and _wanted_system.has_signal("pursuit_state_changed"):
        _wanted_system.pursuit_state_changed.connect(_on_pursuit_state_changed)
    if _minimap and _minimap.has_method("bind"):
        _minimap.bind(_player, _job_manager, _wanted_system)
    if _big_map and _big_map.has_method("bind"):
        _big_map.bind(_player, _job_manager)


func bind_story(story: Node) -> void :
    _story_mission = story
    if _story_mission and _story_mission.has_signal("mission_changed"):
        _story_mission.mission_changed.connect(_on_story_changed)
    if _story_mission and _story_mission.has_signal("subtitle_changed"):
        _story_mission.subtitle_changed.connect(_on_subtitle_changed)
    if _story_mission and _story_mission.has_signal("tutorial_prompt_changed"):
        _story_mission.tutorial_prompt_changed.connect(_on_tutorial_prompt_changed)


func bind_activities(activities: Array) -> void:
    for activity in activities:
        if activity and activity.has_signal("activity_changed"):
            activity.activity_changed.connect(_on_activity_changed)
        if activity and activity.has_signal("start_confirmation_requested"):
            activity.start_confirmation_requested.connect(_on_activity_confirmation)


func _wire_tap(id: String, cb: Callable) -> void :
    if _buttons.has(id):
        _buttons[id].pressed.connect(cb)

func _wire_hold(id: String, setter: Callable) -> void :
    if _buttons.has(id):
        _buttons[id].pressed.connect( func(): setter.call(true))
        _buttons[id].released.connect( func(): setter.call(false))



func _build_gameplay_panels() -> void :

    var big_map_script: Variant = load("res://scripts/ui/big_map.gd")
    if big_map_script:
        _big_map = big_map_script.new()
        _root.add_child(_big_map)

    _minimap = MinimapScript.new()
    _root.add_child(_minimap)
    _minimap.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    _minimap.position = Vector2(24, 116)


    _wanted_label = Label.new()
    _wanted_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _apply_font(_wanted_label, 34, Color(0.98, 0.82, 0.2))
    _wanted_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    _wanted_label.add_theme_constant_override("outline_size", 5)
    _root.add_child(_wanted_label)
    _wanted_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    _wanted_label.position = Vector2(-260, 92)
    _wanted_label.custom_minimum_size = Vector2(236, 40)
    _wanted_label.visible = false

    _pursuit_label = Label.new()
    _pursuit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _pursuit_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    _pursuit_label.add_theme_constant_override("outline_size", 6)
    _apply_font(_pursuit_label, 22, Color(1.0, 0.36, 0.25))
    _root.add_child(_pursuit_label)
    _pursuit_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    _pursuit_label.position = Vector2(-260, 132)
    _pursuit_label.custom_minimum_size = Vector2(236, 34)
    _pursuit_label.visible = false

    _faction_label = Label.new()
    _faction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _apply_font(_faction_label, 34, Color(1.0, 0.45, 0.42))
    _faction_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    _faction_label.add_theme_constant_override("outline_size", 5)
    _root.add_child(_faction_label)
    _faction_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    _faction_label.position = Vector2(-260, 166)
    _faction_label.custom_minimum_size = Vector2(236, 40)
    _faction_label.visible = false


    _objective_panel = PanelContainer.new()
    _objective_panel.theme_type_variation = "HudPanel"
    _objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(_objective_panel)
    _objective_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    _objective_panel.position = Vector2(-230, 22)
    _objective_panel.custom_minimum_size = Vector2(460, 52)
    _objective_panel.visible = false
    var omargin: = MarginContainer.new()
    for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        omargin.add_theme_constant_override(m, 10)
    _objective_panel.add_child(omargin)
    _objective_label = Label.new()
    _objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(_objective_label, 26, Color(0.96, 0.86, 0.6))
    omargin.add_child(_objective_label)

    _tutorial_label = Label.new()
    _tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _tutorial_label.visible = false
    _apply_font(_tutorial_label, 22, Color(0.82, 0.92, 1.0))
    _root.add_child(_tutorial_label)
    _tutorial_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    _tutorial_label.position = Vector2(-340, 88)
    _tutorial_label.custom_minimum_size = Vector2(680, 58)

    _activity_label = Label.new()
    _activity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _activity_label.visible = false
    _apply_font(_activity_label, 24, Color(0.45, 0.9, 1.0))
    _activity_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    _activity_label.add_theme_constant_override("outline_size", 5)
    _root.add_child(_activity_label)
    _activity_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    _activity_label.position = Vector2(-340, 150)
    _activity_label.custom_minimum_size = Vector2(680, 44)

    _subtitle_label = Label.new()
    _subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _subtitle_label.visible = false
    _subtitle_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
    _subtitle_label.add_theme_constant_override("outline_size", 7)
    _apply_font(_subtitle_label, 30, Color(1.0, 0.96, 0.84))
    _root.add_child(_subtitle_label)
    _subtitle_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    _subtitle_label.position = Vector2(-540, -210)
    _subtitle_label.custom_minimum_size = Vector2(1080, 100)


    _ammo_label = Label.new()
    _ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(_ammo_label, 30, Color(0.95, 0.92, 0.85))
    _ammo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    _ammo_label.add_theme_constant_override("outline_size", 5)
    _root.add_child(_ammo_label)
    _ammo_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    _ammo_label.position = Vector2(1410, 690)
    _ammo_label.custom_minimum_size = Vector2(220, 76)
    _ammo_label.visible = false


    var hp_holder: = VBoxContainer.new()
    hp_holder.add_theme_constant_override("separation", 6)
    hp_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(hp_holder)
    hp_holder.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    hp_holder.position = Vector2(40, -150)

    _health_bar = _make_stat_bar(Color(0.28, 0.78, 0.32), Color(0.5, 1.0, 0.55))
    hp_holder.add_child(_health_bar)
    _armor_bar = _make_stat_bar(Color(0.3, 0.55, 0.85), Color(0.5, 0.75, 1.0))
    _armor_bar.value = 0
    hp_holder.add_child(_armor_bar)


func _make_stat_bar(bg: Color, fill: Color) -> ProgressBar:
    var bar: = ProgressBar.new()
    bar.custom_minimum_size = Vector2(360, 26)
    bar.min_value = 0
    bar.max_value = 100
    bar.value = 100
    bar.show_percentage = false
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var sb_bg: = StyleBoxFlat.new()
    sb_bg.bg_color = Color(0.05, 0.06, 0.07, 0.8)
    sb_bg.set_corner_radius_all(6)
    sb_bg.set_border_width_all(2)
    sb_bg.border_color = Color(0, 0, 0, 0.6)
    bar.add_theme_stylebox_override("background", sb_bg)
    var sb_fill: = StyleBoxFlat.new()
    sb_fill.bg_color = fill
    sb_fill.set_corner_radius_all(6)
    bar.add_theme_stylebox_override("fill", sb_fill)
    return bar


func _on_health_changed(health: int, max_health: int, armor: int) -> void :
    if _health_bar:
        _health_bar.max_value = max_health
        _health_bar.value = health
    if _armor_bar:
        _armor_bar.value = armor
        _armor_bar.visible = armor > 0


func _on_wanted_changed(level: int) -> void :
    if _wanted_label == null:
        return
    if level <= 0:
        _wanted_label.visible = false
        return
    _wanted_label.visible = true
    _wanted_label.text = "★".repeat(level)


func _on_pursuit_state_changed(label: String, _last_known: Vector3) -> void:
    if _pursuit_label == null:
        return
    _pursuit_label.text = label
    _pursuit_label.visible = label != ""
    _pursuit_clear_timer = 2.8 if label == "ESCAPED" else 0.0
    match label:
        "SPOTTED":
            _pursuit_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
        "SEARCHING":
            _pursuit_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.24))
        "ESCAPED":
            _pursuit_label.add_theme_color_override("font_color", Color(0.4, 0.92, 0.78))


func _on_faction_changed(level: int) -> void :
    if _faction_label == null:
        return
    if level <= 0:
        _faction_label.visible = false
        return
    _faction_label.visible = true
    _faction_label.text = "🔪".repeat(level)


func _on_weapon_changed(weapon_name: String, clip: int, reserve: int, melee: bool) -> void :
    if _ammo_label == null:
        return
    _ammo_label.visible = true
    if melee:
        _ammo_label.text = weapon_name
    else:
        _ammo_label.text = "%s\n%d / %d" % [weapon_name, clip, reserve]


func _on_driving_changed(driving: bool) -> void :
    if _buttons.has("vehicle"):
        _buttons["vehicle"].label_text = "EXIT" if driving else "CAR"
        _buttons["vehicle"].queue_redraw()
    _driving_now = driving
    if _speed_label:
        _speed_label.visible = driving


func _on_job_changed(active: bool, text: String, target: Vector3) -> void :
    if _story_mission and _story_mission.has_method("has_active_mission") and _story_mission.has_active_mission():
        return
    _set_objective(active, text, target)


func _on_story_changed(active: bool, text: String, target: Vector3) -> void :
    _set_objective(active, text, target)


func _on_subtitle_changed(speaker: String, text: String) -> void:
    if _subtitle_label == null:
        return
    _subtitle_label.visible = not text.is_empty()
    _subtitle_label.text = ("%s: %s" % [speaker, text]) if not speaker.is_empty() else text


func _on_tutorial_prompt_changed(text: String) -> void:
    if _tutorial_label == null:
        return
    _tutorial_label.visible = not text.is_empty()
    _tutorial_label.text = text


func _on_activity_changed(_activity_id: String, active: bool, text: String) -> void:
    if _activity_label:
        _activity_label.visible = active
        _activity_label.text = text
    if active and _tutorial_label and _tutorial_label.text.begins_with("Press USE to start"):
        _tutorial_label.visible = false


func _on_activity_confirmation(_activity_id: String, title: String) -> void:
    if _tutorial_label:
        _tutorial_label.visible = true
        _tutorial_label.text = "Press USE to start %s · X / east button to cancel" % title


func _set_objective(active: bool, text: String, target: Vector3) -> void :
    _obj_active = active
    _obj_text = text
    _obj_target = target
    if _objective_panel == null:
        return
    _objective_panel.visible = active
    if active and _objective_label:
        _objective_label.text = "● " + text


func _process(_delta: float) -> void :
    _update_debug(_delta)
    if _pursuit_clear_timer > 0.0:
        _pursuit_clear_timer = maxf(0.0, _pursuit_clear_timer - _delta)
        if _pursuit_clear_timer <= 0.0 and _pursuit_label:
            _pursuit_label.visible = false
    # World clock + weather readout.
    if _clock_label:
        var gm: = get_node_or_null("/root/GameManager")
        if gm and gm.has_method("time_string"):
            var storm: bool = gm.gloria_storm_active if "gloria_storm_active" in gm else false
            if storm:
                _clock_label.text = "%s  🌪" % gm.time_string()
            elif gm.raining:
                _clock_label.text = ("%s  ☔" % gm.time_string())
            else:
                _clock_label.text = gm.time_string()

    # Speedometer while driving.
    if _driving_now and _speed_label and _player != null and is_instance_valid(_player):
        var car: Variant = _player.current_car
        if car != null and is_instance_valid(car) and car.has_method("get_speed_kmh"):
            var mph: int = int(round(float(car.get_speed_kmh()) * 0.621371))
            _speed_label.text = "%d MPH" % mph

    # Live distance to the objective, like the web HUD ("… — 636 m").
    if not _obj_active or _objective_label == null:
        return
    if _player == null or not is_instance_valid(_player):
        return
    var target: Vector3 = _obj_target
    if _story_mission and _story_mission.has_method("has_active_mission") and _story_mission.has_active_mission():
        if _story_mission.has_method("get_objective_position"):
            target = _story_mission.get_objective_position()
    var d: float = _player.global_position.distance_to(target)
    var dist_str: String = ""
    if d < 1000.0:
        dist_str = "%d m" % int(d)
    else:
        dist_str = "%.1f km" % (d / 1000.0)
    _objective_label.text = "● %s — %s" % [_obj_text, dist_str]



func _build_look_area() -> void :
    _look_area = TouchCamera.new()
    _root.add_child(_look_area)
    _look_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_top_bar() -> void :
    var panel: = PanelContainer.new()
    panel.theme_type_variation = "HudPanel"
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(panel)
    panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    panel.position = Vector2(-260, 24)
    panel.custom_minimum_size = Vector2(236, 88)

    var margin: = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 22)
    margin.add_theme_constant_override("margin_right", 22)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    panel.add_child(margin)

    var stack: = VBoxContainer.new()
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    margin.add_child(stack)

    _cash_label = Label.new()
    _cash_label.text = "$0"
    _cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(_cash_label, 34, Color(0.96, 0.81, 0.45))
    stack.add_child(_cash_label)

    _scrimshaw_label = Label.new()
    _scrimshaw_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(_scrimshaw_label, 20, Color(0.92, 0.86, 0.68))
    _scrimshaw_label.visible = false
    stack.add_child(_scrimshaw_label)

    _fronts_label = Label.new()
    _fronts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(_fronts_label, 20, Color(0.78, 0.92, 0.72))
    _fronts_label.visible = false
    stack.add_child(_fronts_label)


func _build_prompt() -> void :
    _prompt_label = Label.new()
    _prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(_prompt_label, 28, Color(0.98, 0.96, 0.92))
    _prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    _prompt_label.add_theme_constant_override("outline_size", 6)
    _root.add_child(_prompt_label)
    _prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    _prompt_label.position = Vector2(-260, -300)
    _prompt_label.custom_minimum_size = Vector2(520, 40)
    _prompt_label.visible = false

    _buy_prompt = Label.new()
    _buy_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(_buy_prompt, 24, Color(0.06, 0.13, 0.08))
    _buy_prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
    _buy_prompt.add_theme_constant_override("outline_size", 4)
    _root.add_child(_buy_prompt)
    _buy_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    _buy_prompt.position = Vector2(-320, -360)
    _buy_prompt.custom_minimum_size = Vector2(640, 72)
    _buy_prompt.visible = false


func _build_toast() -> void :
    _toast_label = Label.new()
    _toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(_toast_label, 30, Color(0.98, 0.93, 0.8))
    _toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    _toast_label.add_theme_constant_override("outline_size", 6)
    _root.add_child(_toast_label)
    _toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    _toast_label.position = Vector2(-360, 110)
    _toast_label.custom_minimum_size = Vector2(720, 44)
    _toast_label.modulate.a = 0.0


func _build_touch_controls() -> void :

    _joystick = VirtualJoystick.new()
    _joystick.control_id = "move"
    _root.add_child(_joystick)
    _joystick.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    _joystick.position = Vector2(60, 800)
    _register_editable(_joystick, "move")


    var amber: = Color(0.79, 0.52, 0.16)
    var specs: = [
        {"id": "jump", "label": "JUMP", "accent": amber, "hold": false, "action": "jump", "pos": Vector2(1772, 904)},
        {"id": "sprint", "label": "RUN", "accent": Color(0.6, 0.4, 0.18), "hold": true, "action": "sprint", "pos": Vector2(1772, 764)},
        {"id": "interact", "label": "USE", "accent": Color(0.36, 0.55, 0.5), "hold": false, "action": "interact", "pos": Vector2(1632, 904)},
        {"id": "fire", "label": "FIRE", "accent": Color(0.72, 0.27, 0.22), "hold": false, "action": "fire", "pos": Vector2(1632, 764)},
        {"id": "vehicle", "label": "CAR", "accent": Color(0.3, 0.46, 0.6), "hold": false, "action": "enter_vehicle", "pos": Vector2(1492, 904)},
        {"id": "aim", "label": "AIM", "accent": Color(0.42, 0.46, 0.5), "hold": true, "action": "aim", "pos": Vector2(1492, 764)},
        {"id": "reload", "label": "RLD", "accent": Color(0.46, 0.46, 0.48), "hold": false, "action": "reload", "pos": Vector2(1352, 904)},
        {"id": "crouch", "label": "DUCK", "accent": Color(0.35, 0.5, 0.32), "hold": true, "action": "crouch", "pos": Vector2(1352, 764)},
        {"id": "swap", "label": "SWAP", "accent": Color(0.55, 0.4, 0.6), "hold": false, "action": "weapon_next", "pos": Vector2(1212, 904)},
        {"id": "handbrake", "label": "BRAKE", "accent": Color(0.7, 0.5, 0.2), "hold": true, "action": "handbrake", "pos": Vector2(1212, 764)},
        {"id": "horn", "label": "HORN", "accent": Color(0.35, 0.48, 0.62), "hold": false, "action": "horn", "pos": Vector2(1072, 764)},
    ]
    for s in specs:
        var b: = TouchButton.new()
        b.control_id = s["id"]
        b.label_text = s["label"]
        b.accent = s["accent"]
        b.hold_mode = s["hold"]
        b.action_name = s["action"]
        _root.add_child(b)
        b.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
        b.position = s["pos"]
        _buttons[s["id"]] = b
        _action_controls.append(b)
        _register_editable(b, s["id"])


func _register_editable(ctrl: Control, id: String) -> void :
    _editables.append(ctrl)
    _defaults[id] = {"pos": ctrl.position, "scale": 1.0}


func _build_pause() -> void :

    var pause_btn: = TouchButton.new()
    pause_btn.label_text = "II"
    pause_btn.custom_minimum_size = Vector2(96, 96)
    pause_btn.size = pause_btn.custom_minimum_size
    pause_btn.accent = Color(0.3, 0.37, 0.42)
    _root.add_child(pause_btn)
    pause_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    pause_btn.position = Vector2(28, 28)
    pause_btn.pressed.connect(_toggle_pause)
    _utility_controls["pause"] = pause_btn


    var edit_btn: = TouchButton.new()
    edit_btn.label_text = "EDIT"
    edit_btn.custom_minimum_size = Vector2(108, 96)
    edit_btn.size = edit_btn.custom_minimum_size
    edit_btn.accent = Color(0.5, 0.42, 0.2)
    _root.add_child(edit_btn)
    edit_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    edit_btn.position = Vector2(140, 28)
    edit_btn.pressed.connect(_toggle_edit)
    _utility_controls["edit"] = edit_btn

    _pause_panel = Control.new()
    _pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    _pause_panel.visible = false
    _root.add_child(_pause_panel)
    _pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var dim: = ColorRect.new()
    dim.color = Color(0.02, 0.03, 0.04, 0.78)
    _pause_panel.add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var center: = CenterContainer.new()
    _pause_panel.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _pause_scroll = ScrollContainer.new()
    _pause_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _pause_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    center.add_child(_pause_scroll)

    var vbox: = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 22)
    _pause_scroll.add_child(vbox)

    var title: = Label.new()
    title.text = "PAUSED"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(title, 64, Color(0.96, 0.81, 0.45))
    vbox.add_child(title)

    _pause_stats_label = Label.new()
    _pause_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _pause_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _pause_stats_label.custom_minimum_size = Vector2(520, 120)
    _apply_font(_pause_stats_label, 22, Color(0.9, 0.9, 0.84))
    vbox.add_child(_pause_stats_label)

    var legal: = Label.new()
    legal.text = "THE NARROWS · Map data © OpenStreetMap contributors, ODbL\nBUILD " + BuildInfo.display_string()
    legal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(legal, 16, Color(0.72, 0.72, 0.74))
    vbox.add_child(legal)

    vbox.add_child(_menu_button("Resume", _toggle_pause))
    vbox.add_child(_menu_button("Restart Checkpoint", _restart_checkpoint))
    vbox.add_child(_menu_button("Save & Quit", _save_and_quit))
    vbox.add_child(_menu_button("Settings", _open_settings))
    vbox.add_child(_menu_button("Controls", _open_controls))
    vbox.add_child(_menu_button("Edit Controls", func(): _toggle_pause();_toggle_edit()))
    vbox.add_child(_menu_button("Main Menu", _go_to_menu))

    _build_settings()
    _build_controls()


# Audio settings overlay (web parity): Master / Music / SFX volume sliders,
# persisted to user://settings.cfg and re-applied on launch.
func _build_settings() -> void :
    _settings_panel = Control.new()
    _settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    _settings_panel.visible = false
    _root.add_child(_settings_panel)
    _settings_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var dim: = ColorRect.new()
    dim.color = Color(0.02, 0.03, 0.04, 0.88)
    _settings_panel.add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var center: = CenterContainer.new()
    _settings_panel.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _settings_scroll = ScrollContainer.new()
    _settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _settings_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    center.add_child(_settings_scroll)

    var vbox: = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 18)
    vbox.custom_minimum_size = Vector2(540, 0)
    _settings_scroll.add_child(vbox)

    var title: = Label.new()
    title.text = "SETTINGS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(title, 56, Color(0.96, 0.81, 0.45))
    vbox.add_child(title)

    vbox.add_child(_volume_row("Master", "Master"))
    vbox.add_child(_volume_row("Music", "Music"))
    vbox.add_child(_volume_row("Sound FX", "SFX"))

    var qual_row: = VBoxContainer.new()
    qual_row.add_theme_constant_override("separation", 4)
    var qual_lbl: = Label.new()
    qual_lbl.text = "Graphics"
    _apply_font(qual_lbl, 26, Color(0.92, 0.9, 0.86))
    qual_row.add_child(qual_lbl)
    _quality_option = OptionButton.new()
    _quality_option.custom_minimum_size = Vector2(500, 44)
    for i in GameManager.QUALITY_NAMES.size():
        _quality_option.add_item(GameManager.QUALITY_NAMES[i], i)
    if GameManager:
        _quality_option.select(GameManager.graphics_quality)
    _quality_option.item_selected.connect(_on_quality_selected)
    qual_row.add_child(_quality_option)
    vbox.add_child(qual_row)

    var back: = _menu_button("Back", _close_settings)
    vbox.add_child(back)


func _build_controls() -> void :
    _controls_panel = Control.new()
    _controls_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    _controls_panel.visible = false
    _root.add_child(_controls_panel)
    _controls_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var dim: = ColorRect.new()
    dim.color = Color(0.02, 0.03, 0.04, 0.9)
    _controls_panel.add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var center: = CenterContainer.new()
    _controls_panel.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var panel: = VBoxContainer.new()
    panel.add_theme_constant_override("separation", 14)
    panel.custom_minimum_size = Vector2(760, 0)
    center.add_child(panel)

    var title: = Label.new()
    title.text = "CONTROLS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_font(title, 56, Color(0.96, 0.81, 0.45))
    panel.add_child(title)

    _controls_help_label = Label.new()
    _controls_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    _controls_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _controls_help_label.custom_minimum_size = Vector2(760, 0)
    _controls_help_label.text = "\n".join([
        "Move  WASD / left stick",
        "Jump  SPACE",
        "Sprint  SHIFT",
        "Use  E",
        "Enter / exit car  F",
        "Buy business  B",
        "Fire / aim  Mouse buttons",
        "Reload  R",
        "Swap weapon  Q",
        "Crouch  C",
        "Horn  H",
        "Handbrake  SPACE while driving",
        "Sleep at safehouse  T",
        "Pause  ESC",
    ])
    _apply_font(_controls_help_label, 24, Color(0.92, 0.9, 0.86))
    panel.add_child(_controls_help_label)

    panel.add_child(_menu_button("Back", _close_controls))


func _volume_row(label_text: String, bus_name: String) -> Control:
    var row: = VBoxContainer.new()
    row.add_theme_constant_override("separation", 4)
    var lbl: = Label.new()
    lbl.text = label_text
    _apply_font(lbl, 26, Color(0.92, 0.9, 0.86))
    row.add_child(lbl)
    var slider: = HSlider.new()
    slider.min_value = 0.0
    slider.max_value = 1.0
    slider.step = 0.01
    slider.custom_minimum_size = Vector2(500, 36)
    var idx: int = AudioServer.get_bus_index(bus_name)
    slider.value = db_to_linear(AudioServer.get_bus_volume_db(idx)) if idx >= 0 else 1.0
    slider.value_changed.connect(_on_volume_changed.bind(bus_name))
    row.add_child(slider)
    return row


func _on_quality_selected(index: int) -> void :
    if GameManager:
        GameManager.set_graphics_quality(index)
    _save_settings()


func _on_volume_changed(value: float, bus_name: String) -> void :
    var idx: int = AudioServer.get_bus_index(bus_name)
    if idx >= 0:
        AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))
    _save_settings()


func _open_settings() -> void :
    if _pause_panel:
        _pause_panel.visible = false
    if _settings_panel:
        _settings_panel.visible = true
        _settings_panel.move_to_front()


func _close_settings() -> void :
    if _settings_panel:
        _settings_panel.visible = false
    if _pause_panel:
        _pause_panel.visible = true


func _open_controls() -> void :
    if _pause_panel:
        _pause_panel.visible = false
    if _controls_panel:
        _controls_panel.visible = true
        _controls_panel.move_to_front()


func _close_controls() -> void :
    if _controls_panel:
        _controls_panel.visible = false
    if _pause_panel:
        _pause_panel.visible = true


func _save_settings() -> void :
    var cfg: = ConfigFile.new()
    cfg.load("user://settings.cfg")
    for bus_name in ["Master", "Music", "SFX"]:
        var idx: int = AudioServer.get_bus_index(bus_name)
        if idx >= 0:
            cfg.set_value("audio", bus_name, AudioServer.get_bus_volume_db(idx))
    if GameManager:
        cfg.set_value("graphics", "quality", GameManager.graphics_quality)
    cfg.save("user://settings.cfg")


func _build_radio() -> void :
    # Tap to cycle OFF -> WHALE -> The Rage -> The Anvil -> Maré Alta -> OFF.
    var radio_btn: = TouchButton.new()
    radio_btn.control_id = "radio"
    radio_btn.label_text = "RADIO"
    radio_btn.custom_minimum_size = Vector2(140, 96)
    radio_btn.size = radio_btn.custom_minimum_size
    radio_btn.accent = Color(0.42, 0.3, 0.5)
    _root.add_child(radio_btn)
    radio_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    radio_btn.position = Vector2(264, 28)
    radio_btn.pressed.connect(_on_radio_pressed)
    _utility_controls["radio"] = radio_btn

    var map_btn: = TouchButton.new()
    map_btn.control_id = "map"
    map_btn.label_text = "MAP"
    map_btn.custom_minimum_size = Vector2(124, 96)
    map_btn.size = map_btn.custom_minimum_size
    map_btn.accent = Color(0.3, 0.46, 0.5)
    _root.add_child(map_btn)
    map_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    map_btn.position = Vector2(416, 28)
    map_btn.pressed.connect(_on_map_pressed)
    _utility_controls["map"] = map_btn

    var cam_btn: = TouchButton.new()
    cam_btn.control_id = "cam"
    cam_btn.label_text = "CAM"
    cam_btn.custom_minimum_size = Vector2(124, 96)
    cam_btn.size = cam_btn.custom_minimum_size
    cam_btn.accent = Color(0.45, 0.4, 0.3)
    _root.add_child(cam_btn)
    cam_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    cam_btn.position = Vector2(556, 28)
    cam_btn.pressed.connect(_on_cam_pressed)
    _utility_controls["camera"] = cam_btn

    _clock_label = Label.new()
    _apply_font(_clock_label, 26, Color(0.96, 0.92, 0.78))
    _clock_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    _clock_label.add_theme_constant_override("outline_size", 5)
    _clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _root.add_child(_clock_label)
    _clock_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    _clock_label.offset_left = -180
    _clock_label.offset_right = -28
    _clock_label.offset_top = 28
    _clock_label.text = "18:00"

    _speed_label = Label.new()
    _apply_font(_speed_label, 40, Color(0.96, 0.92, 0.78))
    _speed_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    _speed_label.add_theme_constant_override("outline_size", 6)
    _speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _speed_label.visible = false
    _root.add_child(_speed_label)
    _speed_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    _speed_label.offset_left = -320
    _speed_label.offset_right = -40
    _speed_label.offset_top = -210
    _speed_label.offset_bottom = -150

    _radio_label = Label.new()
    _apply_font(_radio_label, 24, Color(0.86, 0.80, 0.94))
    _radio_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
    _radio_label.add_theme_constant_override("outline_size", 5)
    _root.add_child(_radio_label)
    _radio_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    _radio_label.position = Vector2(28, 136)
    _radio_label.custom_minimum_size = Vector2(520, 30)
    _radio_label.text = "RADIO: OFF"

    var radio: = get_node_or_null("/root/Radio")
    if radio:
        radio.station_changed.connect(_on_radio_station)
        radio.now_playing.connect(_on_radio_track)


func _on_radio_pressed() -> void :
    var radio: = get_node_or_null("/root/Radio")
    if radio:
        radio.cycle()


func _on_map_pressed() -> void :
    if _big_map and _big_map.has_method("toggle"):
        _big_map.toggle()
    if _story_mission and _story_mission.has_method("mark_tutorial_action"):
        _story_mission.mark_tutorial_action("map")


func _on_cam_pressed() -> void :
    var gm: = get_node_or_null("/root/GameManager")
    if gm and gm.has_method("toggle_cam_flip"):
        gm.toggle_cam_flip()
    if _player and _player.has_method("snap_drive_camera"):
        _player.snap_drive_camera()


# On-screen telemetry overlay (toggled via the Debug Overlay cheat). Pure
# read-out of engine Performance monitors + player/world state for diagnosing
# the web build without a console.
func _build_debug() -> void :
    _debug_label = Label.new()
    _apply_font(_debug_label, 22, Color(0.6, 1.0, 0.7))
    _debug_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    _debug_label.add_theme_constant_override("outline_size", 5)
    _debug_label.visible = false
    _root.add_child(_debug_label)
    _debug_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    _debug_label.position = Vector2(28, 280)


func _update_debug(delta: float) -> void :
    if _debug_label == null:
        return
    var on: bool = GameManager != null and GameManager.cheat_show_debug
    if on != _debug_label.visible:
        _debug_label.visible = on
    if not on:
        return
    _debug_t += delta
    if _debug_t < 0.25:        # refresh 4x/sec, not every frame
        return
    _debug_t = 0.0
    var fps: float = Engine.get_frames_per_second()
    var draw: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    var prims: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
    var vmem: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
    var objs: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
    var lines: = ["FPS %d   draw %d   prim %dk" % [int(fps), draw, int(prims / 1000.0)],
                  "vram %.0f MB   nodes %d" % [vmem, objs],
                  "build " + BuildInfo.display_string()]
    if _player != null and is_instance_valid(_player):
        var p: Vector3 = _player.global_position
        lines.append("pos %.0f, %.0f   tile %d_%d" % [p.x, -p.z, int(floor(p.x / 500.0)), int(floor(-p.z / 500.0))])
    _debug_label.text = "\n".join(lines)


func _on_radio_station(_index: int, station_name: String) -> void :
    if _radio_label:
        _radio_label.text = "RADIO: " + station_name


func _on_radio_track(title: String) -> void :
    if _radio_label and title != "":
        _radio_label.text = "♪ " + title


func _menu_button(text: String, cb: Callable) -> Button:
    var b: = Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(320, 70)
    _apply_font(b, 28, Color(0.98, 0.96, 0.92))
    b.pressed.connect(cb)
    return b


func _build_edit_banner() -> void :
    _edit_banner = PanelContainer.new()
    _edit_banner.theme_type_variation = "HudPanel"
    _edit_banner.visible = false
    _root.add_child(_edit_banner)
    _edit_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    _edit_banner.position = Vector2(-430, 26)
    _edit_banner.custom_minimum_size = Vector2(860, 76)

    var hb: = HBoxContainer.new()
    hb.add_theme_constant_override("separation", 18)
    hb.alignment = BoxContainer.ALIGNMENT_CENTER
    var mc: = MarginContainer.new()
    for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        mc.add_theme_constant_override(m, 10)
    mc.add_child(hb)
    _edit_banner.add_child(mc)

    var lbl: = Label.new()
    lbl.text = "Drag to move  •  drag corner to resize"
    lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _apply_font(lbl, 26, Color(0.96, 0.86, 0.6))
    hb.add_child(lbl)

    var reset_b: = Button.new()
    reset_b.text = "Reset"
    reset_b.custom_minimum_size = Vector2(150, 56)
    _apply_font(reset_b, 24, Color(0.98, 0.92, 0.85))
    reset_b.pressed.connect(_reset_layout)
    hb.add_child(reset_b)

    var done_b: = Button.new()
    done_b.text = "Done"
    done_b.custom_minimum_size = Vector2(150, 56)
    _apply_font(done_b, 24, Color(0.98, 0.96, 0.92))
    done_b.pressed.connect(_toggle_edit)
    hb.add_child(done_b)



func _toggle_edit() -> void :
    if _edit_mode:
        _exit_edit()
    else:
        _enter_edit()


func _enter_edit() -> void :
    _edit_mode = true
    get_tree().paused = true
    if _look_area:
        _look_area.visible = false
    for e in _editables:
        if e.has_method("set_edit_mode"):
            e.set_edit_mode(true)
    _edit_banner.visible = true


func _exit_edit() -> void :
    _edit_mode = false
    _drag_target = null
    get_tree().paused = false
    if _look_area:
        _look_area.visible = true
    for e in _editables:
        if e.has_method("set_edit_mode"):
            e.set_edit_mode(false)
    _edit_banner.visible = false
    _save_layout()


func _unhandled_key_input(event: InputEvent) -> void :
    if _edit_mode or get_tree().paused:
        return
    var k: = event as InputEventKey
    if k == null or not k.pressed or k.echo:
        return
    if k.keycode == KEY_M:
        _on_map_pressed()
        get_viewport().set_input_as_handled()
        return
    # Radio: number keys 1-9 pick a station, 0 turns it off (R stays reload).
    var radio: = get_node_or_null("/root/Radio")
    if radio == null:
        return
    if k.keycode == KEY_0:
        radio.set_station(-1)
        get_viewport().set_input_as_handled()
    elif k.keycode >= KEY_1 and k.keycode <= KEY_9:
        var idx: int = k.keycode - KEY_1
        if idx < radio.station_count():
            radio.set_station(idx)
            get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void :
    if _story_mission and _story_mission.has_method("set_input_device"):
        if event is InputEventScreenTouch or event is InputEventScreenDrag:
            _story_mission.set_input_device("touch")
        elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
            _story_mission.set_input_device("gamepad")
        elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
            _story_mission.set_input_device("keyboard")
    if not _edit_mode and event.is_action_pressed("pause"):
        _toggle_pause()
        get_viewport().set_input_as_handled()
        return
    if not _edit_mode and not get_tree().paused and event.is_action_pressed("map"):
        _on_map_pressed()
        get_viewport().set_input_as_handled()
        return
    if not _edit_mode and event.is_action_pressed("restart_checkpoint"):
        _restart_checkpoint()
        get_viewport().set_input_as_handled()
        return
    if not _edit_mode:
        return
    if event is InputEventScreenTouch or event is InputEventMouseButton:
        if event.pressed:
            if _begin_drag(event.position):
                get_viewport().set_input_as_handled()
        else:
            if _drag_target:
                get_viewport().set_input_as_handled()
            _drag_target = null
    elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and _drag_target:
        var p: Vector2 = event.position
        var d: Vector2 = p - _drag_last
        _drag_last = p
        if _drag_resize:
            var ns: float = clampf(_drag_target.scale.x + (d.x + d.y) * 0.0016, 0.6, 2.4)
            _drag_target.scale = Vector2(ns, ns)
        else:
            _drag_target.position += d
            _clamp_into_screen(_drag_target)
        _drag_target.queue_redraw()
        get_viewport().set_input_as_handled()


func _begin_drag(screen_pos: Vector2) -> bool:

    for i in range(_editables.size() - 1, -1, -1):
        var e: Control = _editables[i]
        var vis_size: Vector2 = e.size * e.scale
        var rect: = Rect2(e.position, vis_size)
        if rect.has_point(screen_pos):
            _drag_target = e
            _drag_last = screen_pos
            var grip: = Rect2(e.position + vis_size - Vector2(40, 40), Vector2(44, 44))
            _drag_resize = grip.has_point(screen_pos)
            return true
    _drag_target = null
    return false


func _clamp_into_screen(ctrl: Control) -> void :
    var vis_size: Vector2 = ctrl.size * ctrl.scale
    var usable: Rect2 = _layout_profile.get("usable", Rect2(Vector2.ZERO, DESIGN))
    var recovered := LayoutProfileScript.clamp_rect(Rect2(ctrl.position, vis_size), usable)
    ctrl.position = recovered.position


func _reset_layout() -> void :
    for e in _editables:
        var d = _defaults.get(e.control_id, null)
        if d:
            e.position = d["pos"]
            e.scale = Vector2(d["scale"], d["scale"])
            e.queue_redraw()
    _save_layout()


func _save_layout() -> void :
    var data: = {}
    for e in _editables:
        data[e.control_id] = {"x": e.position.x, "y": e.position.y, "s": e.scale.x}
    var f: = FileAccess.open(LAYOUT_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(data))
        f.close()


func _load_layout() -> void :
    if not FileAccess.file_exists(LAYOUT_PATH):
        return
    var f: = FileAccess.open(LAYOUT_PATH, FileAccess.READ)
    if not f:
        return
    var text: = f.get_as_text()
    f.close()
    var parsed: Variant = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    for e in _editables:
        if parsed.has(e.control_id):
            var c: Dictionary = parsed[e.control_id]
            e.position = Vector2(float(c.get("x", e.position.x)), float(c.get("y", e.position.y)))
            var s: float = clampf(float(c.get("s", 1.0)), 0.45, 1.75)
            e.scale = Vector2(s, s)
            _clamp_into_screen(e)
            e.queue_redraw()


func _on_viewport_size_changed() -> void:
    _apply_layout_profile(true)


func _apply_layout_profile(resized: bool) -> void:
    var viewport_size := get_viewport().get_visible_rect().size
    _layout_profile = LayoutProfileScript.for_viewport(viewport_size, _viewport_safe_area(viewport_size))
    for key in ["pause", "radio", "map", "camera"]:
        if _utility_controls.has(key):
            _apply_control_rect(_utility_controls[key], _layout_profile[key])
    if _utility_controls.has("edit"):
        var pause_rect: Rect2 = _layout_profile["pause"]
        var edit_control: Control = _utility_controls["edit"]
        edit_control.visible = str(_layout_profile["mode"]) != "touch"
        _apply_control_rect(
            edit_control,
            Rect2(pause_rect.end + Vector2(12, -pause_rect.size.y), Vector2(108, pause_rect.size.y))
        )
    if _minimap:
        if _minimap.has_method("apply_layout"):
            _minimap.apply_layout(_layout_profile["minimap"])
        else:
            _apply_control_rect(_minimap, _layout_profile["minimap"])
    if _objective_panel:
        _apply_control_rect(_objective_panel, _layout_profile["mission"])
    if _look_area and _look_area.has_method("set_safe_area"):
        _look_area.set_safe_area(_layout_profile["usable"])

    var show_touch := bool(_layout_profile["touch_controls_visible"]) or OS.has_feature("mobile")
    _joystick.visible = show_touch
    for control in _action_controls:
        control.visible = show_touch
    if not resized:
        _place_touch_controls(_layout_profile["actions"], _layout_profile["joystick"])
    else:
        _clamp_into_screen(_joystick)
        for control in _action_controls:
            _clamp_into_screen(control)

    var usable: Rect2 = _layout_profile["usable"]
    var scroll_height := usable.size.y - 32.0 if bool(_layout_profile["scroll_pause"]) else minf(900.0, usable.size.y - 48.0)
    if _pause_scroll:
        _pause_scroll.custom_minimum_size = Vector2(minf(620.0, usable.size.x - 24.0), scroll_height)
    if _settings_scroll:
        _settings_scroll.custom_minimum_size = Vector2(minf(580.0, usable.size.x - 24.0), scroll_height)
    _update_controls_help()


func _update_controls_help() -> void:
    if _controls_help_label == null:
        return
    if bool(_layout_profile.get("keyboard_help_visible", true)):
        _controls_help_label.text = "\n".join([
            "Move  WASD / left stick",
            "Look  Mouse / right stick",
            "Jump  SPACE / south button",
            "Sprint  SHIFT / left stick",
            "Use / dialogue  E / south button",
            "Enter / exit car  F / west button",
            "Fire / aim  Mouse / triggers",
            "Reload  R / north button",
            "Swap weapon  Q / shoulder",
            "Map  M / Select",
            "Pause  ESC / Start",
            "Restart checkpoint  K / D-pad down",
        ])
    else:
        _controls_help_label.text = "\n".join([
            "Move with the left stick · swipe open space to look",
            "Use the labeled action buttons to jump, aim, fire, reload, and enter vehicles",
            "Open MAP, RADIO, and pause from the top row",
            "Choose Edit Controls to move or resize touch controls",
        ])


func _place_touch_controls(action_bounds: Rect2, joystick_bounds: Rect2) -> void:
    var joystick_scale := joystick_bounds.size.x / maxf(_joystick.size.x, 1.0)
    _joystick.position = joystick_bounds.position
    _joystick.scale = Vector2.ONE * joystick_scale
    _defaults[_joystick.control_id] = {"pos": _joystick.position, "scale": joystick_scale}
    var columns := 5
    var cell := Vector2(action_bounds.size.x / columns, action_bounds.size.y / 3.0)
    for i in _action_controls.size():
        var control := _action_controls[i]
        var scale_factor := minf(
            (cell.x - 4.0) / maxf(control.size.x, 1.0),
            (cell.y - 4.0) / maxf(control.size.y, 1.0)
        )
        control.scale = Vector2.ONE * scale_factor
        control.position = action_bounds.position + Vector2(i % columns, i / columns) * cell
        _defaults[control.control_id] = {"pos": control.position, "scale": scale_factor}


func _apply_control_rect(control: Control, rect: Rect2) -> void:
    control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    control.position = rect.position
    control.custom_minimum_size = rect.size
    control.size = rect.size


func _viewport_safe_area(viewport_size: Vector2) -> Rect2:
    var display_size := Vector2(DisplayServer.screen_get_size())
    var safe := Rect2(DisplayServer.get_display_safe_area())
    if not safe.has_area() or display_size.x <= 0.0 or display_size.y <= 0.0:
        return Rect2()
    var factor := viewport_size / display_size
    return Rect2(safe.position * factor, safe.size * factor)



func _on_cash_changed(value: int) -> void :
    if _cash_label:
        _cash_label.text = "$" + str(value)


func _on_scrimshaw_changed(found: int) -> void :
    if _scrimshaw_label == null:
        return
    if found <= 0:
        _scrimshaw_label.visible = false
        return
    _scrimshaw_label.visible = true
    _scrimshaw_label.text = "🦴 %d/%d scrimshaw" % [found, GameManager.SCRIMSHAW_TOTAL]


func _on_businesses_changed(count: int) -> void :
    if _fronts_label == null or BusinessManager == null:
        return
    if count <= 0:
        _fronts_label.visible = false
        return
    _fronts_label.visible = true
    _fronts_label.text = "🏠 %d/%d fronts" % [count, BusinessManager.business_count()]


func _on_near_buy_changed(index: int) -> void :
    if _buy_prompt == null or BusinessManager == null:
        return
    if index < 0:
        _buy_prompt.visible = false
        return
    var b: Dictionary = BusinessManager.BUSINESSES[index]
    var cost: int = int(b["cost"])
    var affordable: bool = GameManager.can_afford(cost)
    var col: Color = Color(0.29, 0.84, 0.43) if affordable else Color(0.75, 0.75, 0.78)
    _buy_prompt.add_theme_color_override("font_color", col)
    _buy_prompt.text = "PRESS B — BUY %s ($%d)\n%s · +$%d/day" % [
        str(b["name"]).to_upper(), cost, str(b["blurb"]), int(b["per_day"])
    ]
    _buy_prompt.visible = true


func _refresh_pause_stats() -> void :
    if _pause_stats_label == null:
        return
    var mission_name: String = "Free roam"
    if _story_mission and _story_mission.has_method("current_title"):
        mission_name = str(_story_mission.current_title())
    var fronts: String = "0/0"
    if BusinessManager:
        fronts = "%d/%d" % [GameManager.businesses_owned(), BusinessManager.business_count()]
    _pause_stats_label.text = "Cash  $%d\nMission  %s\nCompleted jobs  %d\nFronts  %s   •   Scrimshaw  %d/%d" % [
        GameManager.cash,
        mission_name,
        GameManager.missions_completed,
        fronts,
        GameManager.scrimshaw_found(),
        GameManager.SCRIMSHAW_TOTAL,
    ]


func _on_interactable_changed(prompt: String) -> void :
    if not _prompt_label:
        return
    if prompt == "":
        _prompt_label.visible = false
    else:
        _prompt_label.text = prompt + "   [ USE ]"
        _prompt_label.visible = true


func show_toast(message: String) -> void :
    if not _toast_label:
        return
    _toast_label.text = message
    if _toast_tween and _toast_tween.is_valid():
        _toast_tween.kill()
    _toast_label.modulate.a = 0.0
    _toast_tween = create_tween()
    _toast_tween.tween_property(_toast_label, "modulate:a", 1.0, 0.25)
    _toast_tween.tween_interval(2.6)
    _toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.6)


func _toggle_pause() -> void :
    if _edit_mode:
        return
    var paused: = not get_tree().paused
    get_tree().paused = paused
    _pause_panel.visible = paused
    if paused:
        _refresh_pause_stats()
        if _story_mission and _story_mission.has_method("mark_tutorial_action"):
            _story_mission.mark_tutorial_action("pause_save")
    if not paused and _settings_panel:
        _settings_panel.visible = false
    if not paused and _controls_panel:
        _controls_panel.visible = false


func _go_to_menu() -> void :
    get_tree().paused = false
    var ls = get_node_or_null("/root/LoadingScreen")
    if ls and ls.has_method("change_scene"):
        ls.change_scene("res://scenes/main.tscn")
        return
    get_tree().change_scene_to_file("res://scenes/main.tscn")


func _restart_checkpoint() -> void:
    var was_paused := get_tree().paused
    if _story_mission and _story_mission.has_method("restart_checkpoint"):
        _story_mission.restart_checkpoint()
        GameManager.show_message("Checkpoint restarted.")
    if was_paused:
        _toggle_pause()


func _save_and_quit() -> void:
    if _player and is_instance_valid(_player) and GameManager:
        var vehicle := {}
        if _player.current_boat and is_instance_valid(_player.current_boat):
            vehicle = {"identity": "boat", "condition": 1.0}
        elif _player.current_car and is_instance_valid(_player.current_car):
            vehicle = {
                "identity": str(_player.current_car.get("model_path")),
                "condition": 1.0 - float(_player.current_car.get_damage_percent()),
            }
        GameManager.save_player_state(
            _player.global_position,
            _player.get_map_heading(),
            _player.health,
            _player.armor,
            vehicle
        )
    elif GameManager:
        GameManager.save_game()
    _go_to_menu()


func _apply_font(ctrl: Control, fsize: int, color: Color) -> void :
    if _font:
        ctrl.add_theme_font_override("font", _font)
    ctrl.add_theme_font_size_override("font_size", fsize)
    ctrl.add_theme_color_override("font_color", color)
