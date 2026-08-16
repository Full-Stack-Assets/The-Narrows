extends RefCounted
class_name MissionProgress

var objective_index: int = 0
var checkpoint_index: int = -1
var completed: bool = false
var failed: bool = false
var reward_emitted: bool = false


func reset() -> void:
	objective_index = 0
	checkpoint_index = -1
	completed = false
	failed = false
	reward_emitted = false
