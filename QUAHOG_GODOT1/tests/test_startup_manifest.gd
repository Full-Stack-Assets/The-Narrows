extends RefCounted

const StartupMetricsScript := preload("res://scripts/autoloads/startup_metrics.gd")


static func run(test: SceneTree) -> void:
	var metrics: Node = StartupMetricsScript.new()
	var expected: Array[String] = [
		"boot",
		"menu_visible",
		"play_pressed",
		"core_map_ready",
		"player_ready",
		"world_interactive",
	]

	for index in expected.size():
		test.assert_true(
			metrics.mark(expected[index], 1000 + index * 100),
			"startup phase %s is accepted in order" % expected[index]
		)

	test.assert_eq(
		metrics.elapsed_ms("play_pressed", "world_interactive"),
		300,
		"startup metrics calculate Play-to-control duration"
	)
	test.assert_eq(
		metrics.snapshot().get("order", []),
		expected,
		"startup snapshot is JSON-safe and retains ordered phases"
	)
	test.assert_true(
		not metrics.mark("world_interactive", 1700),
		"startup metrics reject a duplicate terminal phase"
	)

	metrics.reset()
	test.assert_true(metrics.mark("boot", 2000), "startup metrics accept boot after reset")
	test.assert_true(
		not metrics.mark("menu_visible", 1900),
		"startup metrics reject a negative phase duration"
	)
