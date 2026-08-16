extends RefCounted

const ActivityRuntime = preload("res://scripts/activities/activity_runtime.gd")


static func run(t: SceneTree) -> void:
	var definition := {
		"id": "test_race",
		"title": "Test Race",
		"mode": "car",
		"time_limit": 60.0,
		"reward": 250,
		"checkpoints": [
			{"id": "one", "position": [0.0, 0.0, 0.0], "radius": 6.0},
			{"id": "two", "position": [10.0, 0.0, 0.0], "radius": 6.0},
			{"id": "finish", "position": [20.0, 0.0, 0.0], "radius": 6.0},
		],
	}
	var runtime := ActivityRuntime.new()
	t.assert_eq(runtime.start(definition), OK, "activity starts with a valid definition")
	t.assert_eq(runtime.reach_checkpoint("two"), ERR_INVALID_DATA, "skipped checkpoints are rejected")
	t.assert_eq(runtime.current_checkpoint_id(), "one", "rejected skip does not advance")
	runtime.tick(4.0)
	t.assert_eq(runtime.reach_checkpoint("one"), OK, "first ordered checkpoint advances")
	runtime.tick(5.0)
	t.assert_eq(runtime.reach_checkpoint("two"), OK, "second ordered checkpoint advances")
	runtime.tick(3.0)
	var rewards: Array[int] = []
	runtime.completed.connect(func(_id: String, _time: float, reward: int): rewards.append(reward))
	t.assert_eq(runtime.reach_checkpoint("finish"), OK, "finish completes the activity")
	t.assert_eq(rewards, [250], "first completion grants the reward once")
	t.assert_eq(runtime.best_time, 12.0, "first completion records best time")

	var saved := runtime.snapshot()
	var replay := ActivityRuntime.new()
	t.assert_eq(replay.start(definition, saved), OK, "completed activity save restores")
	var replay_rewards: Array[int] = []
	replay.completed.connect(func(_id: String, _time: float, reward: int): replay_rewards.append(reward))
	replay.restart()
	replay.tick(3.0)
	replay.reach_checkpoint("one")
	replay.tick(3.0)
	replay.reach_checkpoint("two")
	replay.tick(3.0)
	replay.reach_checkpoint("finish")
	t.assert_eq(replay.best_time, 9.0, "a faster replay updates best time")
	t.assert_eq(replay_rewards, [0], "replay completion does not duplicate the payout")

	var resumed := ActivityRuntime.new()
	var mid_run := {
		"checkpoint_index": 1,
		"elapsed": 7.5,
		"best_time": 15.0,
		"reward_claimed": true,
		"active": true,
	}
	t.assert_eq(resumed.start(definition, mid_run), OK, "mid-activity save restores")
	t.assert_eq(resumed.current_checkpoint_id(), "two", "restore resumes at saved checkpoint")
	t.assert_eq(resumed.elapsed, 7.5, "restore resumes saved timer")

	var timeout := ActivityRuntime.new()
	var failures: Array[String] = []
	timeout.failed.connect(func(_id: String, reason: String): failures.append(reason))
	timeout.start(definition)
	timeout.tick(60.1)
	t.assert_eq(failures, ["timeout"], "time limit fails the activity")
	t.assert_true(not timeout.active, "timeout stops the activity")

	var abandoned := ActivityRuntime.new()
	var abandon_failures: Array[String] = []
	abandoned.failed.connect(func(_id: String, reason: String): abandon_failures.append(reason))
	abandoned.start(definition)
	abandoned.abandon()
	t.assert_eq(abandon_failures, ["abandoned"], "cancel reports an abandoned activity")
	t.assert_true(not abandoned.active, "abandon stops the activity")

	for path in [
		"res://data/activities/new_bedford_race.json",
		"res://data/activities/harbor_run.json",
	]:
		var file := FileAccess.open(path, FileAccess.READ)
		t.assert_true(file != null, "%s ships in the activity content pack" % path)
		var parsed: Variant = JSON.parse_string(file.get_as_text()) if file else {}
		t.assert_true(parsed is Dictionary, "%s contains valid JSON" % path)
		t.assert_eq(ActivityRuntime.validate_definition(parsed), OK, "%s matches the runtime schema" % path)
	t.assert_eq(
		ActivityRuntime.validate_definition({"id": "bad"}),
		ERR_INVALID_DATA,
		"incomplete activities are rejected"
	)
