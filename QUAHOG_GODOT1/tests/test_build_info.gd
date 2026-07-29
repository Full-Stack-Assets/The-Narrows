extends RefCounted


static func run(t: Variant) -> void:
	var path := "res://scripts/autoloads/build_info.gd"
	t.assert_true(ResourceLoader.exists(path), "BuildInfo script exists")
	if not ResourceLoader.exists(path):
		return

	var build_info_script: Script = load(path)
	var build_info: Node = build_info_script.new()
	t.assert_true(
		not build_info.display_string().is_empty(),
		"BuildInfo display string is non-empty",
	)
	t.assert_eq(build_info.COMMIT_SHA, "local", "fallback SHA is local")
	t.assert_eq(
		build_info_script.format_display(
			"0123456789abcdef0123456789abcdef01234567",
			"2026-07-29T15:00:00Z",
		),
		"0123456 · 2026-07-29T15:00:00Z",
		"full SHA renders as seven characters",
	)
	build_info.free()
