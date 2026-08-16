extends RefCounted
class_name LayoutProfile


static func for_viewport(size: Vector2, safe_area: Rect2) -> Dictionary:
	var viewport := Rect2(Vector2.ZERO, size)
	var usable := safe_area.intersection(viewport) if safe_area.has_area() else viewport
	if not usable.has_area():
		usable = viewport
	if size.x < 1000.0 or size.y < 500.0:
		return _touch(usable)
	if size.x < 1500.0 or size.y < 800.0:
		return _compact(usable)
	return _desktop(usable)


static func clamp_rect(rect: Rect2, usable: Rect2) -> Rect2:
	var size := Vector2(
		minf(rect.size.x, usable.size.x),
		minf(rect.size.y, usable.size.y)
	)
	var position := Vector2(
		clampf(rect.position.x, usable.position.x, usable.end.x - size.x),
		clampf(rect.position.y, usable.position.y, usable.end.y - size.y)
	)
	return Rect2(position, size)


static func _desktop(usable: Rect2) -> Dictionary:
	return {
		"mode": "desktop",
		"usable": usable,
		"pause": Rect2(usable.position + Vector2(28, 28), Vector2(96, 96)),
		"radio": Rect2(usable.position + Vector2(264, 28), Vector2(140, 96)),
		"map": Rect2(usable.position + Vector2(416, 28), Vector2(124, 96)),
		"camera": Rect2(usable.position + Vector2(556, 28), Vector2(124, 96)),
		"mission": Rect2(
			Vector2(usable.get_center().x - 230, usable.position.y + 22),
			Vector2(460, 64)
		),
		"minimap": Rect2(usable.position + Vector2(24, 136), Vector2(240, 240)),
		"actions": Rect2(usable.end - Vector2(748, 328), Vector2(720, 300)),
		"joystick": Rect2(
			Vector2(usable.position.x + 60, usable.end.y - 280),
			Vector2(220, 220)
		),
		"touch_scale": 1.0,
		"touch_controls_visible": false,
		"keyboard_help_visible": true,
		"scroll_pause": false,
	}


static func _compact(usable: Rect2) -> Dictionary:
	return {
		"mode": "compact",
		"usable": usable,
		"pause": Rect2(usable.position + Vector2(20, 20), Vector2(72, 72)),
		"radio": Rect2(usable.position + Vector2(112, 20), Vector2(96, 72)),
		"map": Rect2(usable.position + Vector2(220, 20), Vector2(88, 72)),
		"camera": Rect2(usable.position + Vector2(320, 20), Vector2(88, 72)),
		"mission": Rect2(
			Vector2(usable.end.x - 640, usable.position.y + 20),
			Vector2(600, 60)
		),
		"minimap": Rect2(usable.position + Vector2(20, 108), Vector2(180, 180)),
		"actions": Rect2(usable.end - Vector2(520, 240), Vector2(500, 220)),
		"joystick": Rect2(
			Vector2(usable.position.x + 28, usable.end.y - 208),
			Vector2(180, 180)
		),
		"touch_scale": 0.76,
		"touch_controls_visible": false,
		"keyboard_help_visible": true,
		"scroll_pause": false,
	}


static func _touch(usable: Rect2) -> Dictionary:
	var action_size := Vector2(minf(320.0, usable.size.x * 0.42), minf(156.0, usable.size.y * 0.4))
	return {
		"mode": "touch",
		"usable": usable,
		"pause": Rect2(usable.position + Vector2(12, 12), Vector2(52, 52)),
		"radio": Rect2(usable.position + Vector2(72, 12), Vector2(68, 52)),
		"map": Rect2(usable.position + Vector2(148, 12), Vector2(60, 52)),
		"camera": Rect2(usable.position + Vector2(216, 12), Vector2(60, 52)),
		"mission": Rect2(
			Vector2(usable.position.x + 288, usable.position.y + 12),
			Vector2(maxf(220.0, usable.size.x - 300), 52)
		),
		"minimap": Rect2(usable.position + Vector2(12, 76), Vector2(128, 128)),
		"actions": Rect2(usable.end - action_size - Vector2(12, 12), action_size),
		"joystick": Rect2(
			Vector2(usable.position.x + 12, usable.end.y - 156),
			Vector2(144, 144)
		),
		"touch_scale": 0.5,
		"touch_controls_visible": true,
		"keyboard_help_visible": false,
		"scroll_pause": true,
	}
