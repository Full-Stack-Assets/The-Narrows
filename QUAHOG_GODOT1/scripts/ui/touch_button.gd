extends Control




signal pressed
signal released

@export var label_text: String = "A"
@export var action_name: String = ""
@export var accent: Color = Color(0.79, 0.52, 0.16)
@export var hold_mode: bool = false
@export var control_id: String = ""

var edit_mode: bool = false
var _down: bool = false
var _touch_index: int = -1
var _font: Font = null

func _ready() -> void :
    custom_minimum_size = Vector2(124, 124)
    size = custom_minimum_size
    pivot_offset = Vector2.ZERO
    mouse_filter = Control.MOUSE_FILTER_STOP
    _font = load("res://assets/fonts/noto_serif.ttf")


func apply_layout(rect: Rect2) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    position = rect.position
    custom_minimum_size = rect.size
    size = rect.size


func set_edit_mode(on: bool) -> void :
    edit_mode = on
    if on and _down:
        _down = false
        _release()
    queue_redraw()

func _gui_input(event: InputEvent) -> void :
    if edit_mode:
        return
    if event is InputEventScreenTouch or event is InputEventMouseButton:
        var idx: int = event.index if event is InputEventScreenTouch else 0
        if event.pressed and not _down:
            _down = true
            _touch_index = idx
            _press()
        elif not event.pressed and (idx == _touch_index or event is InputEventMouseButton):
            _down = false
            _touch_index = -1
            _release()

func _press() -> void :
    queue_redraw()
    pressed.emit()
    if action_name != "" and InputMap.has_action(action_name):
        Input.action_press(action_name)

func _release() -> void :
    queue_redraw()
    released.emit()
    if action_name != "" and InputMap.has_action(action_name):
        Input.action_release(action_name)

func _draw() -> void :
    var c: = size / 2.0
    var r: float = min(size.x, size.y) / 2.0 - 2.0
    var fill: = accent
    fill.a = 0.85 if _down else 0.55
    draw_circle(c, r, Color(0.05, 0.07, 0.09, 0.55))
    draw_circle(c, r - 4.0, fill)
    draw_arc(c, r, 0.0, TAU, 40, Color(0.95, 0.78, 0.45, 0.9), 2.5, true)
    if _font:
        var fs: = 30
        var ts: = _font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
        draw_string(_font, c - ts / 2.0 + Vector2(0, ts.y * 0.32), label_text, 
            HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(0.98, 0.96, 0.92))
    if edit_mode:
        _draw_edit_decor()

func _draw_edit_decor() -> void :
    var rect: = Rect2(Vector2.ZERO, size)

    draw_rect(rect, Color(0.95, 0.78, 0.45, 0.9), false, 2.0)

    var grip: = Rect2(size - Vector2(22, 22), Vector2(20, 20))
    draw_rect(grip, Color(0.95, 0.78, 0.45, 0.85), true)
    draw_line(grip.position + Vector2(4, 16), grip.position + Vector2(16, 4), Color(0.1, 0.1, 0.1, 0.9), 2.0)
