extends RefCounted
class_name MissionEvent

var kind: String = ""
var subject_id: String = ""
var value: float = 0.0
var data: Dictionary = {}


static func create(
	event_kind: String,
	event_subject_id: String = "",
	event_value: float = 0.0,
	event_data: Dictionary = {}
) -> MissionEvent:
	var event := MissionEvent.new()
	event.kind = event_kind
	event.subject_id = event_subject_id
	event.value = event_value
	event.data = event_data.duplicate(true)
	return event
