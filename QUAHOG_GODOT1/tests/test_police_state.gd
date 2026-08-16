extends RefCounted

const PoliceStateRuntime = preload("res://scripts/ai/police_state.gd")


static func run(t: SceneTree) -> void:
	var pursuit := PoliceStateRuntime.new()
	var first_seen := Vector3(12.0, 0.0, -6.0)
	t.assert_eq(
		pursuit.update(true, true, first_seen, 0.1),
		PoliceStateRuntime.State.PURSUING,
		"sight plus heat enters pursuit"
	)
	t.assert_true(not pursuit.should_decay_heat(), "heat does not decay while actively seen")

	t.assert_eq(
		pursuit.update(true, false, Vector3.ZERO, 0.1),
		PoliceStateRuntime.State.SEARCHING,
		"lost sight enters search"
	)
	t.assert_eq(pursuit.last_known_position, first_seen, "search targets the last-known position")
	t.assert_true(pursuit.should_decay_heat(), "heat can decay while police search")

	var reacquired := Vector3(18.0, 0.0, 4.0)
	t.assert_eq(
		pursuit.update(true, true, reacquired, 0.1),
		PoliceStateRuntime.State.PURSUING,
		"reacquisition returns to pursuit"
	)
	t.assert_eq(pursuit.last_known_position, reacquired, "reacquisition refreshes last-known position")

	pursuit.update(true, false, Vector3.ZERO, 0.0)
	pursuit.update(true, false, Vector3.ZERO, PoliceStateRuntime.SEARCH_DURATION - 0.01)
	t.assert_eq(pursuit.state, PoliceStateRuntime.State.SEARCHING, "search remains active before its duration")
	t.assert_eq(
		pursuit.update(true, false, Vector3.ZERO, 0.01),
		PoliceStateRuntime.State.DISENGAGING,
		"remaining unseen for the configured duration disengages"
	)

	t.assert_eq(PoliceStateRuntime.backup_cap(0, 2), 0, "no heat requests no backup")
	t.assert_eq(PoliceStateRuntime.backup_cap(1, 0), 2, "low quality caps backup at two officers")
	t.assert_eq(PoliceStateRuntime.backup_cap(4, 1), 4, "medium quality caps backup at four officers")
	t.assert_eq(PoliceStateRuntime.backup_cap(5, 2), 5, "high quality respects the global five-officer cap")
