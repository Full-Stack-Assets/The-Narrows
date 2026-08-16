extends Control



signal joystick_input(direction: Vector2)

@export var max_radius: float = 78.0
@export var dead_zone: float = 0.12
@export var control_id: String = "move"

var edit_mode: bool = false
var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob: Vector2 = Vector2.ZERO
var _active: bool = false

func _ready() -> void :
    custom_minimum_size = Vector2(220, 220)
    size = custom_minimum_size
    pivot_offset = Vector2.ZERO
    mouse_filter = Control.MOUSE_FILTER_STOP
    _center = size / 2.0
    _knob = _center


func apply_layout(rect: Rect2) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    position = rect.position
    custom_minimum_size = rect.size
    size = rect.size
    max_radius = minf(rect.size.x, rect.size.y) * 0.36


func set_edit_mode(on: bool) -> void :
    edit_mode = on
    if on and _active:
        _reset()
    queue_redraw()

func _notification(what: int) -> void :
    if what == NOTIFICATION_RESIZED:
        _center = size / 2.0
        if not _active:
            _knob = _center
            queue_redraw()

func _gui_input(event: InputEvent) -> void :
    if edit_mode:
        return
    if event is InputEventScreenTouch or event is InputEventMouseButton:
        var pressed: bool = event.pressed
        var idx: int = event.index if event is InputEventScreenTouch else 0
        var local: Vector2 = event.position
        if pressed and not _active:
            _active = true
            _touch_index = idx
            _center = local
            _update_knob(local)
        elif not pressed and (idx == _touch_index or event is InputEventMouseButton):
            _reset()
    elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and _active:
        var idx2: int = event.index if event is InputEventScreenDrag else 0
        if event is InputEventMouseMotion or idx2 == _touch_index:
            _update_knob(event.position)

func _update_knob(local: Vector2) -> void :
    var offset: = local - _center
    if offset.length() > max_radius:
        offset = offset.normalized() * max_radius
    _knob = _center + offset
    var dir: = offset / max_radius
    if dir.length() < dead_zone:
        dir = Vector2.ZERO
    joystick_input.emit(dir)
    queue_redraw()

func _reset() -> void :
    _active = false
    _touch_index = -1
    _center = size / 2.0
    _knob = _center
    joystick_input.emit(Vector2.ZERO)
    queue_redraw()

func _draw() -> void :
    var base: = _center if _active else size / 2.0
    draw_circle(base, max_radius, Color(0.05, 0.07, 0.09, 0.38))
    draw_arc(base, max_radius, 0.0, TAU, 48, Color(0.79, 0.52, 0.16, 0.55), 3.0, true)
    draw_circle(_knob, 34.0, Color(0.79, 0.52, 0.16, 0.75))
    draw_circle(_knob, 34.0, Color(0.9, 0.65, 0.3, 0.0))
    if edit_mode:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.95, 0.78, 0.45, 0.9), false, 2.0)
        var grip: = Rect2(size - Vector2(24, 24), Vector2(22, 22))
        draw_rect(grip, Color(0.95, 0.78, 0.45, 0.85), true)
        draw_line(grip.position + Vector2(5, 17), grip.position + Vector2(17, 5), Color(0.1, 0.1, 0.1, 0.9), 2.0)
