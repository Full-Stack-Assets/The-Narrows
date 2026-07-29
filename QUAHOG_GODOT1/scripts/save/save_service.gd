extends RefCounted
class_name SaveService

const SaveMigrationsScript = preload("res://scripts/save/save_migrations.gd")
const SaveSchemaScript = preload("res://scripts/save/save_schema.gd")

const PRIMARY_NAME := "the_narrows_save.json"
const BACKUP_NAME := "save.backup.json"
const TEMP_NAME := "save.tmp.json"
const LEGACY_NAME := "mount_hope_save.json"

var _directory: String


func _init(directory: String = "user://") -> void:
	_directory = directory.trim_suffix("/")


func write(snapshot: Dictionary) -> Error:
	var normalized := SaveMigrationsScript.to_current(snapshot)
	if normalized.is_empty() or not SaveSchemaScript.is_valid(normalized):
		return ERR_INVALID_DATA
	if str(normalized.get("saved_at", "")).is_empty():
		normalized["saved_at"] = Time.get_datetime_string_from_system(true, true)
	var directory_error := _ensure_directory()
	if directory_error != OK:
		return directory_error
	var temp_error := _write_text(_path(TEMP_NAME), JSON.stringify(normalized, "\t"))
	if temp_error != OK:
		return temp_error
	var validated_temp := _read_path(_path(TEMP_NAME))
	if validated_temp.is_empty():
		_remove_if_present(_path(TEMP_NAME))
		return ERR_INVALID_DATA

	var primary := _path(PRIMARY_NAME)
	var backup := _path(BACKUP_NAME)
	if not _read_path(primary).is_empty():
		_remove_if_present(backup)
		var rotate_error := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(primary),
			ProjectSettings.globalize_path(backup)
		)
		if rotate_error != OK:
			_remove_if_present(_path(TEMP_NAME))
			return rotate_error
	else:
		_remove_if_present(primary)

	var promote_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(_path(TEMP_NAME)),
		ProjectSettings.globalize_path(primary)
	)
	if promote_error != OK and FileAccess.file_exists(backup):
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(backup),
			ProjectSettings.globalize_path(primary)
		)
	return promote_error


func read() -> Dictionary:
	var primary := _read_path(_path(PRIMARY_NAME))
	if not primary.is_empty():
		return primary
	if FileAccess.file_exists(_path(PRIMARY_NAME)):
		return {}
	var legacy := _read_path(_path(LEGACY_NAME))
	if legacy.is_empty():
		return {}
	if write(legacy) != OK:
		return legacy
	return _read_path(_path(PRIMARY_NAME))


func has_valid_save() -> bool:
	return not read().is_empty()


func has_recoverable_backup() -> bool:
	return not _read_path(_path(BACKUP_NAME)).is_empty()


func recover_backup() -> Error:
	var backup := _read_path(_path(BACKUP_NAME))
	if backup.is_empty():
		return ERR_FILE_CORRUPT
	_remove_if_present(_path(PRIMARY_NAME))
	return write(backup)


func clear_progress_preserve_settings() -> Error:
	var existing := read()
	if existing.is_empty() and has_recoverable_backup():
		existing = _read_path(_path(BACKUP_NAME))
	var fresh := SaveSchemaScript.blank()
	if not existing.is_empty():
		fresh["settings"] = existing["settings"].duplicate(true)
	return write(fresh)


func write_raw_primary_for_test(text: String) -> Error:
	return _write_text(_path(PRIMARY_NAME), text)


func remove_test_files() -> void:
	if not _directory.ends_with("the-narrows-codex-save-service-tests"):
		return
	for filename in [PRIMARY_NAME, BACKUP_NAME, TEMP_NAME, LEGACY_NAME]:
		_remove_if_present(_path(filename))


func _read_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	return SaveMigrationsScript.from_json(text)


func _write_text(path: String, text: String) -> Error:
	var directory_error := _ensure_directory()
	if directory_error != OK:
		return directory_error
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.flush()
	file.close()
	return OK


func _ensure_directory() -> Error:
	if _directory == "user:" or _directory == "user://":
		return OK
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_directory))


func _path(filename: String) -> String:
	return "%s/%s" % [_directory, filename]


func _remove_if_present(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
