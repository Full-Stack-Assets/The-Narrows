extends RefCounted
class_name PoliceState

enum State {
	UNAWARE,
	PURSUING,
	SEARCHING,
	DISENGAGING,
}

const SEARCH_DURATION: float = 8.0

var state: State = State.UNAWARE
var last_known_position: Vector3 = Vector3.ZERO
var search_elapsed: float = 0.0


func update(has_heat: bool, has_sight: bool, player_position: Vector3, delta: float) -> State:
	if not has_heat:
		state = State.DISENGAGING if state != State.UNAWARE else State.UNAWARE
		search_elapsed = 0.0
		return state

	if has_sight:
		last_known_position = player_position
		search_elapsed = 0.0
		state = State.PURSUING
		return state

	if state == State.PURSUING:
		state = State.SEARCHING
		search_elapsed = 0.0
	elif state == State.SEARCHING:
		search_elapsed += maxf(delta, 0.0)
		if search_elapsed >= SEARCH_DURATION:
			state = State.DISENGAGING
	elif state == State.UNAWARE:
		last_known_position = player_position
		state = State.SEARCHING
		search_elapsed = 0.0

	return state


func is_actively_seen() -> bool:
	return state == State.PURSUING


func should_decay_heat() -> bool:
	return not is_actively_seen()


static func backup_cap(wanted_tier: int, quality_profile: int) -> int:
	var tier_cap: int = clampi(wanted_tier, 0, 5) + 1
	var quality_cap: int = [2, 4, 5][clampi(quality_profile, 0, 2)]
	return mini(tier_cap, quality_cap) if wanted_tier > 0 else 0


static func label(value: State) -> String:
	match value:
		State.PURSUING:
			return "SPOTTED"
		State.SEARCHING:
			return "SEARCHING"
		State.DISENGAGING:
			return "ESCAPED"
		_:
			return ""
