extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var audio_player := get_node_or_null("AudioStreamPlayer") as AudioStreamPlayer

var _running := false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.modulate.a = 0.0
	color_rect.hide()


func trigger_game_over(message: String = "Niccolò foi preso.") -> void:
	if _running:
		return
	_running = true

	color_rect.show()
	if audio_player != null and audio_player.stream != null:
		audio_player.bus = &"SFX"
		audio_player.play()
	await _fade_to(0.85, 0.6)

	await DialogueManager.say_text(message)

	GameManager.restart_level()
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0, 0.5)
	color_rect.hide()
	_running = false


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", alpha, duration)
	await tween.finished
