extends Node

signal phase_marked(name: String, elapsed_from_boot_ms: int)

const PHASE_ORDER: Array[String] = [
	"boot",
	"menu_visible",
	"play_pressed",
	"core_map_ready",
	"player_ready",
	"world_interactive",
]

var _marks: Dictionary = {}
var _order: Array[String] = []
var _last_timestamp_ms: int = -1


func _ready() -> void:
	if _order.is_empty():
		mark("boot")


func reset() -> void:
	_marks.clear()
	_order.clear()
	_last_timestamp_ms = -1


func mark(name: String, timestamp_ms: int = -1) -> bool:
	var expected_index := _order.size()
	if expected_index >= PHASE_ORDER.size() or PHASE_ORDER[expected_index] != name:
		push_warning("StartupMetrics rejected out-of-order or duplicate phase: %s" % name)
		return false

	var recorded_at := Time.get_ticks_msec() if timestamp_ms < 0 else timestamp_ms
	if _last_timestamp_ms >= 0 and recorded_at < _last_timestamp_ms:
		push_warning("StartupMetrics rejected negative duration at phase: %s" % name)
		return false

	_marks[name] = recorded_at
	_order.append(name)
	_last_timestamp_ms = recorded_at
	var boot_at: int = int(_marks.get("boot", recorded_at))
	phase_marked.emit(name, recorded_at - boot_at)
	print("STARTUP %s +%dms" % [name, recorded_at - boot_at])
	return true


func elapsed_ms(from_phase: String, to_phase: String) -> int:
	if not _marks.has(from_phase) or not _marks.has(to_phase):
		return -1
	var elapsed := int(_marks[to_phase]) - int(_marks[from_phase])
	return elapsed if elapsed >= 0 else -1


func snapshot() -> Dictionary:
	return {
		"order": _order.duplicate(),
		"marks_ms": _marks.duplicate(true),
		"boot_to_menu_ms": elapsed_ms("boot", "menu_visible"),
		"play_to_interactive_ms": elapsed_ms("play_pressed", "world_interactive"),
	}
