extends Node

const SAVE_PATH := "user://save.json"


func save_game(level_path: String, position: Vector2, health: int, story_seen: bool = true) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Falha ao salvar: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify({
		"level": level_path,
		"x": position.x,
		"y": position.y,
		"health": health,
		"story_seen": story_seen,
		"timestamp": Time.get_unix_time_from_system(),
	}))


func load_game() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var raw: Dictionary = parsed
	return {
		"level": str(raw.get("level", "")),
		"position": Vector2(float(raw.get("x", 0.0)), float(raw.get("y", 0.0))),
		"health": int(raw.get("health", 0)),
		"story_seen": bool(raw.get("story_seen", true)),
	}


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
