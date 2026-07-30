extends RefCounted

const CheatsPanelRuntime = preload("res://scripts/ui/cheats_panel.gd")


static func run(t: SceneTree) -> void:
	var panel := CheatsPanelRuntime.new()
	var passive := panel._text_button("Passive", Callable())
	t.assert_eq(
		passive.pressed.get_connections().size(),
		0,
		"buttons created for later binding do not connect a null callable"
	)
	var active := panel._text_button("Close", panel._close)
	t.assert_eq(
		active.pressed.get_connections().size(),
		1,
		"buttons with callbacks connect exactly once"
	)
	passive.free()
	active.free()
	panel.free()
