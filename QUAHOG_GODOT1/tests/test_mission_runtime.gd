extends RefCounted

const MissionDefinitionScript := preload("res://scripts/missions/mission_definition.gd")
const MissionEventScript := preload("res://scripts/missions/mission_event.gd")
const MissionRuntimeScript := preload("res://scripts/missions/mission_runtime.gd")


static func run(test: SceneTree) -> void:
	_test_matching_transitions_and_one_shot_reward(test)
	_test_checkpoint_restart_and_restore(test)
	_test_malformed_definitions(test)


static func _test_matching_transitions_and_one_shot_reward(test: SceneTree) -> void:
	var parsed: Dictionary = MissionDefinitionScript.parse({
		"id": "runtime_contract",
		"title": "Runtime Contract",
		"reward": 250,
		"objectives": [
			{"id": "reach", "type": "reach", "text": "Reach it", "target": "pier", "radius": 12.0, "checkpoint": true},
			{"id": "interact", "type": "interact", "text": "Use it", "target": "door"},
			{"id": "vehicle", "type": "enter_vehicle", "text": "Get in", "entity": "escape_car"},
			{"id": "encounter", "type": "defeat_encounter", "text": "Win", "encounter": "dock_ambush"},
			{"id": "heat", "type": "lose_heat", "text": "Lose heat", "max_heat": 0},
			{"id": "survive", "type": "survive", "text": "Hold out", "duration": 5.0},
			{"id": "dialogue", "type": "dialogue", "text": "Talk", "dialogue": "sully_intro"},
		],
	})
	test.assert_eq(parsed.get("error", ""), "", "valid mission definition parses")
	var runtime: RefCounted = MissionRuntimeScript.new()
	var rewards: Array[int] = []
	runtime.mission_completed.connect(func(reward: int, _effects: Dictionary) -> void: rewards.append(reward))
	runtime.start(parsed["definition"])

	runtime.dispatch(MissionEventScript.create("interact", "wrong"))
	test.assert_eq(runtime.current_objective_id(), "reach", "unrelated event does not advance")
	runtime.dispatch(MissionEventScript.create("reach", "pier", 8.0))
	runtime.dispatch(MissionEventScript.create("interact", "door"))
	runtime.dispatch(MissionEventScript.create("enter_vehicle", "escape_car"))
	runtime.dispatch(MissionEventScript.create("defeat_encounter", "dock_ambush"))
	runtime.dispatch(MissionEventScript.create("heat_changed", "", 0.0))
	runtime.dispatch(MissionEventScript.create("survived", "", 5.0))
	runtime.dispatch(MissionEventScript.create("dialogue", "sully_intro"))

	test.assert_true(runtime.is_completed(), "all matching objective events complete the mission")
	test.assert_eq(rewards, [250], "mission reward emits exactly once")
	runtime.dispatch(MissionEventScript.create("dialogue", "sully_intro"))
	test.assert_eq(rewards, [250], "completed mission ignores later events")


static func _test_checkpoint_restart_and_restore(test: SceneTree) -> void:
	var definition = MissionDefinitionScript.parse({
		"id": "checkpoint_contract",
		"title": "Checkpoint Contract",
		"reward": 0,
		"objectives": [
			{"id": "start", "type": "reach", "text": "Start", "target": "start", "radius": 5.0, "checkpoint": true},
			{"id": "danger", "type": "interact", "text": "Danger", "target": "switch"},
		],
	})["definition"]
	var runtime: RefCounted = MissionRuntimeScript.new()
	runtime.start(definition)
	runtime.dispatch(MissionEventScript.create("reach", "start", 2.0))
	runtime.dispatch(MissionEventScript.create("failed", "caught"))
	test.assert_eq(runtime.snapshot().get("checkpoint_objective_id"), "start", "failure retains last checkpoint")
	runtime.restart_checkpoint()
	test.assert_eq(runtime.current_objective_id(), "start", "restart restores checkpoint objective")

	runtime.dispatch(MissionEventScript.create("reach", "start", 1.0))
	var saved: Dictionary = runtime.snapshot()
	var restored: RefCounted = MissionRuntimeScript.new()
	restored.start(definition)
	test.assert_eq(restored.restore(saved), OK, "valid mission snapshot restores")
	test.assert_eq(restored.current_objective_id(), "danger", "restore retains current objective")


static func _test_malformed_definitions(test: SceneTree) -> void:
	var empty_result: Dictionary = MissionDefinitionScript.parse({
		"id": "empty",
		"title": "Empty",
		"objectives": [],
	})
	test.assert_eq(empty_result.get("error"), "no_objectives", "empty mission has a named validation error")

	var duplicate_result: Dictionary = MissionDefinitionScript.parse({
		"id": "duplicate",
		"title": "Duplicate",
		"objectives": [
			{"id": "same", "type": "interact", "text": "One", "target": "a"},
			{"id": "same", "type": "interact", "text": "Two", "target": "b"},
		],
	})
	test.assert_eq(duplicate_result.get("error"), "duplicate_objective_id", "duplicate objective IDs are rejected")

	var unsupported_result: Dictionary = MissionDefinitionScript.parse({
		"id": "unsupported",
		"title": "Unsupported",
		"objectives": [{"id": "bad", "type": "escort", "text": "No"}],
	})
	test.assert_eq(unsupported_result.get("error"), "unsupported_objective_type", "unsupported types are rejected")

	var duplicate_mission_result: Dictionary = MissionDefinitionScript.parse({
		"id": "known",
		"title": "Known",
		"objectives": [{"id": "talk", "type": "interact", "text": "Talk", "target": "contact"}],
	}, {"known": true})
	test.assert_eq(duplicate_mission_result.get("error"), "duplicate_mission_id", "duplicate mission IDs are rejected")

	var missing_target_result: Dictionary = MissionDefinitionScript.parse({
		"id": "missing_target",
		"title": "Missing Target",
		"objectives": [{"id": "reach", "type": "reach", "text": "Reach", "radius": 5.0}],
	})
	test.assert_eq(missing_target_result.get("error"), "missing_target", "reach requires a target")

	var bad_radius_result: Dictionary = MissionDefinitionScript.parse({
		"id": "bad_radius",
		"title": "Bad Radius",
		"objectives": [{"id": "reach", "type": "reach", "text": "Reach", "target": "pier", "radius": 0.0}],
	})
	test.assert_eq(bad_radius_result.get("error"), "non_positive_reach_radius", "reach radius must be positive")

	var bad_duration_result: Dictionary = MissionDefinitionScript.parse({
		"id": "bad_duration",
		"title": "Bad Duration",
		"objectives": [{"id": "wait", "type": "survive", "text": "Wait", "duration": -1.0}],
	})
	test.assert_eq(bad_duration_result.get("error"), "non_positive_survive_duration", "survive duration must be positive")

	var negative_reward_result: Dictionary = MissionDefinitionScript.parse({
		"id": "negative_reward",
		"title": "Negative Reward",
		"reward": -1,
		"objectives": [{"id": "talk", "type": "interact", "text": "Talk", "target": "contact"}],
	})
	test.assert_eq(negative_reward_result.get("error"), "negative_reward", "negative rewards are rejected")
