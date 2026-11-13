extends Node

signal transition_finished

enum StartMode { NEW, RESTART, CONTINUE }

const SETTINGS_PATH := "user://settings.cfg"
const INTRO_SCENE := "res://scenes/levels/intro.tscn"
const FIRST_LEVEL := "res://scenes/levels/level_1.tscn"

var start_mode: StartMode = StartMode.NEW
var gameplay_active := false
var can_pause := false
var transition_running := false

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var voice_enabled: bool = true
var fullscreen: bool = false

var _fade_rect: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()
	_setup_audio_buses()
	load_settings()
	apply_settings()
	_build_fade()


func set_gameplay_active(active: bool) -> void:
	gameplay_active = active
	get_tree().call_group(&"gameplay", &"set_active", active)


func consume_start_mode() -> StartMode:
	var mode := start_mode
	start_mode = StartMode.NEW
	return mode


func continue_game() -> void:
	var data := SaveManager.load_game()
	if data.is_empty():
		return
	start_mode = StartMode.CONTINUE
	var path: String = data["level"]
	if not ResourceLoader.exists(path):
		path = FIRST_LEVEL
	await fade_to_scene(path)


func restart_level() -> void:
	start_mode = StartMode.RESTART
	get_tree().paused = false
	get_tree().reload_current_scene()


func go_to_menu() -> void:
	can_pause = false
	gameplay_active = false
	get_tree().paused = false
	await fade_to_scene(INTRO_SCENE, 0.5)


func fade_to_scene(path: String, duration: float = 0.8) -> void:
	_fade_rect.show()
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, duration)
	await tween.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, duration * 0.5)
	await tween.finished
	_fade_rect.hide()


func _setup_audio_buses() -> void:
	for bus_name in [&"Music", &"SFX", &"Voice"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	AudioServer.set_bus_send(AudioServer.get_bus_index(&"Music"), &"Master")
	AudioServer.set_bus_send(AudioServer.get_bus_index(&"SFX"), &"Master")
	AudioServer.set_bus_send(AudioServer.get_bus_index(&"Voice"), &"SFX")


func apply_settings() -> void:
	_set_bus_volume(&"Master", master_volume)
	_set_bus_volume(&"Music", music_volume)
	_set_bus_volume(&"SFX", sfx_volume)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Voice"), not voice_enabled)
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("audio", "voice", voice_enabled)
	config.set_value("video", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = config.get_value("audio", "master", master_volume)
	music_volume = config.get_value("audio", "music", music_volume)
	sfx_volume = config.get_value("audio", "sfx", sfx_volume)
	voice_enabled = config.get_value("audio", "voice", voice_enabled)
	fullscreen = config.get_value("video", "fullscreen", fullscreen)


func _set_bus_volume(bus_name: StringName, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, volume <= 0.0)


func finish_transition() -> void:
	transition_running = false
	transition_finished.emit()


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 200
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.modulate.a = 0.0
	_fade_rect.hide()
	layer.add_child(_fade_rect)


func _ensure_input_actions() -> void:
	_add_keys(&"move_left", [KEY_A, KEY_LEFT])
	_add_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_add_keys(&"move_up", [KEY_W, KEY_UP])
	_add_keys(&"move_down", [KEY_S, KEY_DOWN])
	_add_keys(&"interact", [KEY_E])
	_add_keys(&"throw", [KEY_F])
	_add_keys(&"pause", [KEY_ESCAPE])
	_add_keys(&"ui_up", [KEY_W])
	_add_keys(&"ui_down", [KEY_S])
	_add_keys(&"ui_left", [KEY_A])
	_add_keys(&"ui_right", [KEY_D])


func _add_keys(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		var already := false
		for event in InputMap.action_get_events(action):
			var key := event as InputEventKey
			if key != null and (key.physical_keycode == keycode or key.keycode == keycode):
				already = true
				break
		if not already:
			var new_event := InputEventKey.new()
			new_event.physical_keycode = keycode
			InputMap.action_add_event(action, new_event)
