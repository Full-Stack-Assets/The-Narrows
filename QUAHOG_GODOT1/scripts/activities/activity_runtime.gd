extends RefCounted
class_name ActivityRuntime

signal checkpoint_changed(activity_id: String, checkpoint_id: String, index: int)
signal completed(activity_id: String, elapsed: float, reward: int)
signal failed(activity_id: String, reason: String)

var definition: Dictionary = {}
var active: bool = false
var checkpoint_index: int = 0
var elapsed: float = 0.0
var best_time: float = 0.0
var reward_claimed: bool = false


func start(activity_definition: Dictionary, saved: Dictionary = {}) -> Error:
	var error := validate_definition(activity_definition)
	if error != OK:
		return error
	definition = activity_definition.duplicate(true)
	active = true
	checkpoint_index = 0
	elapsed = 0.0
	best_time = 0.0
	reward_claimed = false
	if not saved.is_empty():
		return restore(saved)
	checkpoint_changed.emit(str(definition["id"]), current_checkpoint_id(), checkpoint_index)
	return OK


func restart() -> void:
	if definition.is_empty():
		return
	active = true
	checkpoint_index = 0
	elapsed = 0.0
	checkpoint_changed.emit(str(definition["id"]), current_checkpoint_id(), checkpoint_index)


func tick(delta: float) -> void:
	if not active:
		return
	elapsed += maxf(delta, 0.0)
	if elapsed > float(definition["time_limit"]):
		_fail("timeout")


func reach_checkpoint(checkpoint_id: String) -> Error:
	if not active:
		return ERR_UNAVAILABLE
	if checkpoint_id != current_checkpoint_id():
		return ERR_INVALID_DATA
	checkpoint_index += 1
	if checkpoint_index >= definition["checkpoints"].size():
		active = false
		if best_time <= 0.0 or elapsed < best_time:
			best_time = elapsed
		var reward := 0
		if not reward_claimed:
			reward_claimed = true
			reward = int(definition["reward"])
		completed.emit(str(definition["id"]), elapsed, reward)
		return OK
	checkpoint_changed.emit(str(definition["id"]), current_checkpoint_id(), checkpoint_index)
	return OK


func abandon() -> void:
	if active:
		_fail("abandoned")


func current_checkpoint_id() -> String:
	if definition.is_empty() or checkpoint_index < 0 or checkpoint_index >= definition["checkpoints"].size():
		return ""
	return str(definition["checkpoints"][checkpoint_index]["id"])


func current_checkpoint() -> Dictionary:
	if current_checkpoint_id().is_empty():
		return {}
	return definition["checkpoints"][checkpoint_index]


func snapshot() -> Dictionary:
	return {
		"checkpoint_index": checkpoint_index,
		"elapsed": elapsed,
		"best_time": best_time,
		"reward_claimed": reward_claimed,
		"active": active,
	}


func restore(saved: Dictionary) -> Error:
	if definition.is_empty():
		return ERR_UNCONFIGURED
	var restored_index := int(saved.get("checkpoint_index", 0))
	if restored_index < 0 or restored_index > definition["checkpoints"].size():
		return ERR_INVALID_DATA
	checkpoint_index = restored_index
	elapsed = maxf(float(saved.get("elapsed", 0.0)), 0.0)
	best_time = maxf(float(saved.get("best_time", 0.0)), 0.0)
	reward_claimed = bool(saved.get("reward_claimed", false))
	active = bool(saved.get("active", restored_index < definition["checkpoints"].size()))
	if active and checkpoint_index >= definition["checkpoints"].size():
		return ERR_INVALID_DATA
	if active:
		checkpoint_changed.emit(str(definition["id"]), current_checkpoint_id(), checkpoint_index)
	return OK


static func validate_definition(candidate: Dictionary) -> Error:
	for field in ["id", "title", "mode", "time_limit", "reward", "checkpoints"]:
		if not candidate.has(field):
			return ERR_INVALID_DATA
	if str(candidate["id"]).is_empty() or str(candidate["title"]).is_empty():
		return ERR_INVALID_DATA
	if str(candidate["mode"]) not in ["car", "boat"]:
		return ERR_INVALID_DATA
	if float(candidate["time_limit"]) <= 0.0 or int(candidate["reward"]) < 0:
		return ERR_INVALID_DATA
	if not candidate["checkpoints"] is Array or candidate["checkpoints"].size() < 2:
		return ERR_INVALID_DATA
	var ids := {}
	for checkpoint in candidate["checkpoints"]:
		if not checkpoint is Dictionary:
			return ERR_INVALID_DATA
		var checkpoint_id := str(checkpoint.get("id", ""))
		var position: Variant = checkpoint.get("position", [])
		if checkpoint_id.is_empty() or ids.has(checkpoint_id):
			return ERR_INVALID_DATA
		if not position is Array or position.size() != 3:
			return ERR_INVALID_DATA
		if float(checkpoint.get("radius", 0.0)) <= 0.0:
			return ERR_INVALID_DATA
		ids[checkpoint_id] = true
	return OK


func _fail(reason: String) -> void:
	active = false
	failed.emit(str(definition.get("id", "")), reason)
