extends Node
class_name DialogueRunner

signal line_changed(speaker: String, text: String, audio_path: String)
signal conversation_completed(conversation_id: String)

var _definitions: Dictionary = {}
var _active: DialogueDefinition = null
var _line_index: int = -1
var _auto_remaining: float = 0.0


func load_file(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var source := FileAccess.open(path, FileAccess.READ)
	if source == null:
		return ERR_FILE_CANT_READ
	var data: Variant = JSON.parse_string(source.get_as_text())
	if not data is Dictionary or not data.get("conversations", []) is Array:
		return ERR_PARSE_ERROR
	for raw_conversation in data["conversations"]:
		if not raw_conversation is Dictionary:
			return ERR_INVALID_DATA
		var parsed := DialogueDefinition.parse(raw_conversation)
		if not str(parsed.get("error", "")).is_empty():
			return ERR_INVALID_DATA
		var definition: DialogueDefinition = parsed["definition"]
		if _definitions.has(definition.id):
			return ERR_ALREADY_EXISTS
		_definitions[definition.id] = definition
	return OK


func start(conversation_id: String) -> Error:
	if not _definitions.has(conversation_id):
		return ERR_DOES_NOT_EXIST
	_active = _definitions[conversation_id]
	_line_index = 0
	_emit_current_line()
	return OK


func advance() -> void:
	if _active == null:
		return
	_line_index += 1
	if _line_index >= _active.lines.size():
		_complete()
		return
	_emit_current_line()


func skip() -> void:
	if _active:
		_complete()


func is_active() -> bool:
	return _active != null


func _process(delta: float) -> void:
	if _active == null or _auto_remaining <= 0.0:
		return
	_auto_remaining -= delta
	if _auto_remaining <= 0.0:
		advance()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active():
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		skip()
		get_viewport().set_input_as_handled()


func _emit_current_line() -> void:
	var line: Dictionary = _active.lines[_line_index]
	var audio_path := str(line.get("audio", ""))
	_auto_remaining = float(line.get("auto_advance", 0.0))
	line_changed.emit(str(line["speaker"]), str(line["text"]), audio_path)
	if not audio_path.is_empty() and ResourceLoader.exists(audio_path) and is_inside_tree():
		var audio_manager := get_node_or_null("/root/AudioManager")
		var stream: AudioStream = load(audio_path)
		if stream and audio_manager:
			audio_manager.play_sfx(stream)


func _complete() -> void:
	var completed_id := _active.id
	_active = null
	_line_index = -1
	_auto_remaining = 0.0
	conversation_completed.emit(completed_id)
