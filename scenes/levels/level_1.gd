extends Node2D

const MUSIC := preload("res://assets/audio/level1.wav")

const STORY_LINES: Array[String] = [
	"Brescia, Itália, 1512.\nUm menino corre entre chamas e espadas.",
	"Seu nome é Niccolò Fontana.\nO mundo logo o chamará de Tartaglia.",
]
const DISTRACTION_LINE := "“Se eu lançar a pedra longe o bastante…\nele vai seguir o som.”"

const END_TEXT := "Fim da Parte 1."

@export var skip_intro: bool = false

@onready var player: Player = $Player

var _ended := false
var _distraction_explained := false


func _ready() -> void:
	GameManager.set_gameplay_active(false)
	GameManager.can_pause = false
	_setup_camera_limits()

	player.died.connect(_end_run.bind("Niccolò sucumbiu às chamas!"))
	for node in get_tree().get_nodes_in_group(&"guards"):
		var guard := node as Guard
		guard.player_caught.connect(_end_run.bind("Você foi visto pelos guardas!"))
		guard.distracted.connect(_on_guard_distracted)
	for node in get_tree().get_nodes_in_group(&"dialogue_triggers"):
		var trigger := node as DialogueTrigger
		if trigger.ends_level:
			trigger.completed.connect(_finish_level)

	var show_story := false
	var mode := GameManager.consume_start_mode()
	if mode == GameManager.StartMode.NEW:
		SaveManager.save_game(scene_file_path, player.global_position, player.current_health, false)
		show_story = true
	elif mode == GameManager.StartMode.CONTINUE:
		var data := SaveManager.load_game()
		if not data.is_empty():
			player.restore(data["health"], data["position"])
			show_story = not data["story_seen"]

	if show_story and not skip_intro:
		await _play_story()
		SaveManager.save_game(scene_file_path, player.global_position, player.current_health, true)

	MusicManager.play(MUSIC, 0.5, 1.0)
	GameManager.set_gameplay_active(true)
	GameManager.can_pause = true


func _play_story() -> void:
	if GameManager.transition_running:
		await GameManager.transition_finished
	MusicManager.play(MUSIC, 0.5, 4.0)
	await get_tree().create_timer(2.0).timeout
	await DialogueManager.say_lines(STORY_LINES)


func _on_guard_distracted() -> void:
	if _distraction_explained or _ended:
		return
	_distraction_explained = true
	await get_tree().create_timer(0.6, false).timeout
	if _ended:
		return
	GameManager.set_gameplay_active(false)
	await DialogueManager.say_text(DISTRACTION_LINE)
	if not _ended:
		GameManager.set_gameplay_active(true)


func _finish_level() -> void:
	if _ended:
		return
	_ended = true
	GameManager.can_pause = false
	GameManager.set_gameplay_active(false)
	await DialogueManager.say_text(END_TEXT)
	MusicManager.stop_all(1.5)
	GameManager.go_to_menu()


func _end_run(message: String) -> void:
	if _ended:
		return
	_ended = true
	GameManager.can_pause = false
	GameManager.set_gameplay_active(false)
	GameOver.trigger_game_over(message)


func _setup_camera_limits() -> void:
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	var bounds := Rect2()
	for node in find_children("*", "TileMap", true, false) + find_children("*", "TileMapLayer", true, false):
		var map := node as Node2D
		var tile_set: TileSet = map.get(&"tile_set")
		var used: Rect2i = map.call(&"get_used_rect")
		if tile_set == null or used.size == Vector2i.ZERO:
			continue
		var size := Vector2(tile_set.tile_size)
		var area := Rect2(map.global_position + Vector2(used.position) * size, Vector2(used.size) * size)
		bounds = area if bounds.size == Vector2.ZERO else bounds.merge(area)
	if bounds.size == Vector2.ZERO:
		return
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
