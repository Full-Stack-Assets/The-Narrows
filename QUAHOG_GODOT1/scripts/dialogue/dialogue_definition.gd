extends RefCounted
class_name DialogueDefinition

var id: String = ""
var lines: Array[Dictionary] = []


static func parse(data: Dictionary) -> Dictionary:
	var conversation_id := str(data.get("id", "")).strip_edges()
	if conversation_id.is_empty():
		return {"definition": null, "error": "missing_conversation_id"}
	var raw_lines: Variant = data.get("lines", [])
	if not raw_lines is Array or raw_lines.is_empty():
		return {"definition": null, "error": "no_dialogue_lines"}
	var definition := DialogueDefinition.new()
	definition.id = conversation_id
	for raw_line in raw_lines:
		if not raw_line is Dictionary:
			return {"definition": null, "error": "malformed_dialogue_line"}
		var line: Dictionary = raw_line.duplicate(true)
		if str(line.get("speaker", "")).strip_edges().is_empty():
			return {"definition": null, "error": "missing_speaker"}
		if str(line.get("text", "")).strip_edges().is_empty():
			return {"definition": null, "error": "missing_dialogue_text"}
		if float(line.get("auto_advance", 0.0)) < 0.0:
			return {"definition": null, "error": "negative_auto_advance"}
		definition.lines.append(line)
	return {"definition": definition, "error": ""}
