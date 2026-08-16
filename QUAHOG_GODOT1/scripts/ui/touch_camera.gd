extends Control



signal look_delta(delta: Vector2)

var _touch_index: int = -1
var _last_pos: Vector2 = Vector2.ZERO
var _active: bool = false
var _safe_area: Rect2 = Rect2()

func _ready() -> void :
    mouse_filter = Control.MOUSE_FILTER_STOP


func set_safe_area(area: Rect2) -> void:
    _safe_area = area


func _gui_input(event: InputEvent) -> void :
    if event is InputEventScreenTouch:
        if event.pressed and _safe_area.has_area() and not _safe_area.has_point(event.position):
            return
        if event.pressed and not _active:
            _active = true
            _touch_index = event.index
            _last_pos = event.position
        elif not event.pressed and event.index == _touch_index:
            _active = false
            _touch_index = -1
    elif event is InputEventScreenDrag and _active and event.index == _touch_index:
        var delta: Vector2 = event.position - _last_pos
        _last_pos = event.position
        look_delta.emit(Vector2( - delta.x, - delta.y))
