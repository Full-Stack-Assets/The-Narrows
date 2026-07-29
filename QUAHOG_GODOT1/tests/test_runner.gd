extends SceneTree

const SUITES: Array[Script] = [
	preload("res://tests/test_smoke.gd"),
	preload("res://tests/test_build_info.gd"),
	preload("res://tests/test_startup_manifest.gd"),
	preload("res://tests/test_mission_runtime.gd"),
	preload("res://tests/test_off_the_boat.gd"),
]

var assertions: int = 0
var failures: int = 0


func _initialize() -> void:
	for suite in SUITES:
		suite.run(self)

	if failures > 0:
		print("Godot tests failed: %d of %d assertions" % [failures, assertions])
		quit(1)
		return

	print("Godot tests passed: %d assertions" % assertions)
	quit(0)


func assert_true(condition: bool, message: String) -> void:
	assertions += 1
	if condition:
		return
	failures += 1
	push_error("FAIL: %s" % message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	assertions += 1
	if actual == expected:
		return
	failures += 1
	push_error("FAIL: %s (expected %s, received %s)" % [message, expected, actual])
