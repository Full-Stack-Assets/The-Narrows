extends RefCounted


static func run(t: Variant) -> void:
	t.assert_true(
		ResourceLoader.exists("res://scenes/main.tscn"),
		"main scene exists",
	)
	t.assert_true(
		ResourceLoader.exists("res://scenes/game_world.tscn"),
		"world scene exists",
	)
	t.assert_eq(
		ProjectSettings.get_setting("application/config/name"),
		"The Narrows",
		"product name",
	)
	t.assert_eq(
		ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"gl_compatibility",
		"web renderer",
	)
