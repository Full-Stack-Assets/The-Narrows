extends RefCounted

const LayoutProfile = preload("res://scripts/ui/layout_profile.gd")
const CRITICAL := ["pause", "mission", "minimap", "radio", "actions"]


static func run(t: SceneTree) -> void:
	var cases := [
		{"name": "desktop", "size": Vector2(1920, 1080), "safe": Rect2()},
		{"name": "compact", "size": Vector2(1280, 720), "safe": Rect2()},
		{"name": "phone", "size": Vector2(844, 390), "safe": Rect2()},
		{
			"name": "phone-safe-area",
			"size": Vector2(844, 390),
			"safe": Rect2(Vector2(24, 0), Vector2(796, 390)),
		},
	]
	for test_case in cases:
		var profile := LayoutProfile.for_viewport(test_case["size"], test_case["safe"])
		var usable: Rect2 = profile["usable"]
		t.assert_true(usable.has_area(), "%s has a usable rectangle" % test_case["name"])
		for key in CRITICAL:
			var rect: Rect2 = profile[key]
			t.assert_true(_contains_rect(usable, rect), "%s keeps %s inside the safe area" % [test_case["name"], key])
		for i in CRITICAL.size():
			for j in range(i + 1, CRITICAL.size()):
				var a: Rect2 = profile[CRITICAL[i]]
				var b: Rect2 = profile[CRITICAL[j]]
				t.assert_true(
					not a.intersects(b),
					"%s keeps %s clear of %s" % [test_case["name"], CRITICAL[i], CRITICAL[j]]
				)
	t.assert_eq(
		LayoutProfile.for_viewport(Vector2(1920, 1080), Rect2())["mode"],
		"desktop",
		"1080p uses the desktop profile"
	)
	t.assert_eq(
		LayoutProfile.for_viewport(Vector2(844, 390), Rect2())["mode"],
		"touch",
		"landscape phone uses the touch profile"
	)
	t.assert_true(
		LayoutProfile.for_viewport(Vector2(844, 390), Rect2())["scroll_pause"],
		"short landscape screens scroll pause content"
	)
	for action in [
		"move_forward", "move_back", "move_left", "move_right",
		"look_left", "look_right", "look_up", "look_down",
		"interact", "enter_vehicle", "fire", "aim", "reload", "weapon_next",
		"map", "pause", "dialogue_advance", "dialogue_skip", "restart_checkpoint",
	]:
		t.assert_true(InputMap.has_action(action), "%s input action exists" % action)
		t.assert_true(not InputMap.action_get_events(action).is_empty(), "%s has a binding" % action)
		t.assert_true(_has_gamepad_event(action), "%s has a standard gamepad binding" % action)
	var phone_usable := Rect2(Vector2(24, 0), Vector2(796, 390))
	var recovered := LayoutProfile.clamp_rect(
		Rect2(Vector2(-900, 700), Vector2(124, 124)),
		phone_usable
	)
	t.assert_true(_contains_rect(phone_usable, recovered), "off-screen saved controls are recovered into the safe area")


static func _contains_rect(outer: Rect2, inner: Rect2) -> bool:
	return (
		outer.has_point(inner.position)
		and inner.end.x <= outer.end.x
		and inner.end.y <= outer.end.y
	)


static func _has_gamepad_event(action: String) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return true
	return false
