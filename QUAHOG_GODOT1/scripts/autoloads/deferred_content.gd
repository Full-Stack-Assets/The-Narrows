extends Node

signal content_ready(success: bool)

const PACK_NAME := "deferred_content.pck"
const LOCAL_PACK_PATH := "user://" + PACK_NAME

var is_ready: bool = false
var is_loading: bool = false


func ensure_loaded() -> bool:
	if is_ready:
		return true
	if is_loading:
		while is_loading:
			await get_tree().process_frame
		return is_ready
	if not OS.has_feature("web"):
		is_ready = true
		content_ready.emit(true)
		return true

	is_loading = true
	if FileAccess.file_exists(LOCAL_PACK_PATH) and ProjectSettings.load_resource_pack(LOCAL_PACK_PATH):
		return _finish(true)

	var request := HTTPRequest.new()
	add_child(request)
	request.download_file = LOCAL_PACK_PATH
	var completed := false
	var succeeded := false
	request.request_completed.connect(
		func(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
			completed = true
			succeeded = result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
	)
	var current_url := str(JavaScriptBridge.eval("window.location.href"))
	var last_slash := current_url.rfind("/")
	var pack_url := current_url.substr(0, last_slash + 1) + PACK_NAME
	var request_error := request.request(pack_url)
	if request_error != OK:
		request.queue_free()
		return _finish(false)
	while not completed:
		await get_tree().process_frame
	request.queue_free()
	if not succeeded:
		return _finish(false)
	return _finish(ProjectSettings.load_resource_pack(LOCAL_PACK_PATH))


func _finish(success: bool) -> bool:
	is_loading = false
	is_ready = success
	if success and Radio and Radio.has_method("reload_content"):
		Radio.reload_content()
	if not success:
		push_warning("Deferred content pack could not be loaded; the New Bedford core remains playable.")
	content_ready.emit(success)
	return success
