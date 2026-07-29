extends RefCounted

const MissionDefinitionScript := preload("res://scripts/missions/mission_definition.gd")
const MissionEventScript := preload("res://scripts/missions/mission_event.gd")
const MissionRuntimeScript := preload("res://scripts/missions/mission_runtime.gd")
const EncounterDirectorScript := preload("res://scripts/missions/encounter_director.gd")
const DialogueDefinitionScript := preload("res://scripts/dialogue/dialogue_definition.gd")
const DialogueRunnerScript := preload("res://scripts/dialogue/dialogue_runner.gd")


static func run(test: SceneTree) -> void:
	_test_golden_path(test)
	_test_failure_restarts(test)
	_test_encounter_lifecycle(test)
	_test_subtitle_definition(test)
	_test_dialogue_runner(test)


static func _load_definition(test: SceneTree):
	var source := FileAccess.open("res://data/missions/off_the_boat.json", FileAccess.READ)
	test.assert_true(source != null, "Off the Boat definition exists")
	if source == null:
		return null
	var parsed_json: Variant = JSON.parse_string(source.get_as_text())
	var parsed: Dictionary = MissionDefinitionScript.parse(parsed_json)
	test.assert_eq(parsed.get("error", ""), "", "Off the Boat definition validates")
	return parsed.get("definition")


static func _test_golden_path(test: SceneTree) -> void:
	var definition = _load_definition(test)
	if definition == null:
		return
	var runtime: RefCounted = MissionRuntimeScript.new()
	var observed: Array[String] = []
	var rewards: Array[int] = []
	runtime.objective_changed.connect(func(id: String) -> void: observed.append(id))
	runtime.mission_completed.connect(func(reward: int, _effects: Dictionary) -> void: rewards.append(reward))
	runtime.start(definition)
	var events: Array = [
		MissionEventScript.create("reach", "seamens_bethel", 0.0),
		MissionEventScript.create("interact", "deacon"),
		MissionEventScript.create("reach", "fish_pier", 0.0),
		MissionEventScript.create("defeat_encounter", "pier_ambush"),
		MissionEventScript.create("enter_vehicle", "getaway_car"),
		MissionEventScript.create("heat_changed", "", 0.0),
		MissionEventScript.create("reach", "opener_safehouse", 0.0),
		MissionEventScript.create("dialogue", "safehouse_wrap"),
	]
	for event in events:
		runtime.dispatch(event)

	test.assert_eq(observed, [
		"reach_bethel",
		"interact_deacon",
		"reach_fish_pier",
		"pier_ambush",
		"enter_getaway_car",
		"lose_police_heat",
		"reach_safehouse",
		"safehouse_dialogue",
	], "Off the Boat follows the exact eight-beat objective order")
	test.assert_true(runtime.is_completed(), "golden path completes Off the Boat")
	test.assert_eq(rewards, [150], "Off the Boat reward emits once")


static func _runtime_at_ambush(test: SceneTree):
	var definition = _load_definition(test)
	if definition == null:
		return null
	var runtime: RefCounted = MissionRuntimeScript.new()
	runtime.start(definition)
	runtime.dispatch(MissionEventScript.create("reach", "seamens_bethel", 0.0))
	runtime.dispatch(MissionEventScript.create("interact", "deacon"))
	runtime.dispatch(MissionEventScript.create("reach", "fish_pier", 0.0))
	return runtime


static func _test_failure_restarts(test: SceneTree) -> void:
	for failure in ["wasted", "assigned_car_destroyed", "left_ambush_boundary"]:
		var runtime = _runtime_at_ambush(test)
		if runtime == null:
			continue
		runtime.dispatch(MissionEventScript.create("failed", failure))
		runtime.restart_checkpoint()
		test.assert_eq(
			runtime.current_objective_id(),
			"reach_fish_pier",
			"%s restarts before the pier encounter" % failure
		)
		test.assert_true(
			not runtime.snapshot().get("reward_emitted", true),
			"%s does not claim the mission reward" % failure
		)


static func _test_encounter_lifecycle(test: SceneTree) -> void:
	var parent := Node.new()
	var director: Node = EncounterDirectorScript.new()
	parent.add_child(director)
	var completions: Array[String] = []
	director.encounter_completed.connect(func(id: String) -> void: completions.append(id))
	test.assert_true(director.start("pier_ambush"), "pier ambush starts")
	test.assert_eq(director.active_actor_count(), 3, "pier ambush spawns exactly three enemies")
	test.assert_eq(director.active_roles(), ["melee", "melee", "ranged"], "pier ambush roles are deterministic")
	director.defeat_all_for_test()
	test.assert_eq(completions, ["pier_ambush"], "encounter completion emits once")
	test.assert_true(not director.start("pier_ambush"), "completed encounter does not respawn")
	parent.free()


static func _test_subtitle_definition(test: SceneTree) -> void:
	var parsed: Dictionary = DialogueDefinitionScript.parse({
		"id": "subtitles",
		"lines": [
			{"speaker": "Deacon", "text": "You made it.", "audio": "res://missing.ogg"},
			{"speaker": "Sully", "text": "Keep moving.", "auto_advance": 2.5},
		],
	})
	test.assert_eq(parsed.get("error", ""), "", "dialogue accepts optional or missing audio assets")
	test.assert_eq(parsed["definition"].lines.size(), 2, "subtitle dialogue retains every authored line")


static func _test_dialogue_runner(test: SceneTree) -> void:
	var runner: Node = DialogueRunnerScript.new()
	var parent := Node.new()
	parent.add_child(runner)
	var lines: Array[String] = []
	var completions: Array[String] = []
	runner.line_changed.connect(
		func(speaker: String, text: String, _audio: String) -> void:
			lines.append("%s:%s" % [speaker, text])
	)
	runner.conversation_completed.connect(func(id: String) -> void: completions.append(id))
	test.assert_eq(runner.load_file("res://data/dialogue/off_the_boat.json"), OK, "tutorial dialogue file loads")
	test.assert_eq(runner.start("safehouse_wrap"), OK, "safehouse dialogue starts")
	runner.advance()
	runner.advance()
	runner.advance()
	test.assert_eq(lines.size(), 3, "dialogue exposes every line as subtitles")
	test.assert_eq(completions, ["safehouse_wrap"], "dialogue completes without requiring audio")
	parent.free()
