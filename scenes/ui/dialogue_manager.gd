extends CanvasLayer

signal dialogue_started
signal dialogue_finished

const VOICES := {
	"a": preload("res://assets/audio/voices/voice1/voice_a.wav"),
	"e": preload("res://assets/audio/voices/voice1/voice_e.wav"),
	"i": preload("res://assets/audio/voices/voice1/voice_i.wav"),
	"o": preload("res://assets/audio/voices/voice1/voice_o.wav"),
	"u": preload("res://assets/audio/voices/voice1/voice_u.wav"),
}
const VOWEL_MAP := {
	"a": "a", "á": "a", "à": "a", "â": "a", "ã": "a",
	"e": "e", "é": "e", "ê": "e",
	"i": "i", "í": "i",
	"o": "o", "ó": "o", "ô": "o", "õ": "o",
	"u": "u", "ú": "u", "ü": "u",
}
const ARROW := preload("res://assets/sprites/selector.png")

const MAX_CHARS_PER_PAGE: int = 75
const PUNCTUATION := ".!?,"

@export var seconds_per_char: float = 0.045
@export var newline_pause: float = 0.4
@export var punctuation_pause: float = 0.15
@export var voice_volume_db: float = -6.0
@export var arrow_delay: float = 1.5
@export var arrow_bounce: float = 4.0

@onready var ui_dialog: TextureRect = $uiDialog
@onready var txt_dialog: RichTextLabel = $uiDialog/MarginContainer/txtDialog

var dialogue_lines: Array[String] = []
var current_line: int = 0
var is_typing: bool = false
var is_dialogue_active: bool = false

var _plain := ""
var _revealed := 0
var _timer := 0.0
var _accepting := false
var _voices: Array[AudioStreamPlayer] = []
var _voice_index := 0
var _arrow: TextureRect
var _fade_tween: Tween
var _arrow_tween: Tween


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_dialog.hide()
	set_process(false)
	for i in 4:
		var player := AudioStreamPlayer.new()
		player.volume_db = voice_volume_db
		player.bus = &"Voice"
		add_child(player)
		_voices.append(player)
	_build_arrow()


func show_custom_dialogue(lines: Array[String]) -> void:
	if is_dialogue_active:
		return
	var pages: Array[String] = []
	for line in lines:
		pages.append_array(paginate_text(line))
	_start_dialogue(pages)


func show_auto_dialogue(full_text: String) -> void:
	if is_dialogue_active:
		return
	_start_dialogue(paginate_text(full_text))


func say_lines(lines: Array[String]) -> void:
	while is_dialogue_active:
		await dialogue_finished
	show_custom_dialogue(lines)
	await dialogue_finished


func say_text(text: String) -> void:
	var lines: Array[String] = [text]
	await say_lines(lines)


func paginate_text(text: String) -> Array[String]:
	var tokens: Array[String] = []
	var lines := text.split("\n")
	for i in lines.size():
		for word in lines[i].split(" ", false):
			tokens.append(word)
		if i < lines.size() - 1:
			tokens.append("\n")

	var pages: Array[String] = []
	var page := ""
	for token in tokens:
		if token == "\n":
			if page != "":
				page += "\n"
			continue
		while token.length() > MAX_CHARS_PER_PAGE:
			if page.strip_edges() != "":
				pages.append(page.strip_edges())
				page = ""
			pages.append(token.substr(0, MAX_CHARS_PER_PAGE))
			token = token.substr(MAX_CHARS_PER_PAGE)
		var sep := "" if page == "" or page.ends_with("\n") else " "
		if page != "" and page.length() + sep.length() + token.length() > MAX_CHARS_PER_PAGE:
			pages.append(page.strip_edges())
			page = token
		else:
			page += sep + token
	if page.strip_edges() != "":
		pages.append(page.strip_edges())
	return pages


func _start_dialogue(pages: Array[String]) -> void:
	if pages.is_empty():
		dialogue_finished.emit.call_deferred()
		return
	dialogue_lines = pages
	current_line = 0
	is_dialogue_active = true
	_accepting = false
	txt_dialog.text = ""
	ui_dialog.modulate.a = 0.0
	ui_dialog.show()
	dialogue_started.emit()
	_kill(_fade_tween)
	_fade_tween = create_tween()
	_fade_tween.tween_property(ui_dialog, "modulate:a", 1.0, 0.3)
	_fade_tween.tween_callback(_show_page)


func _show_page() -> void:
	if current_line >= dialogue_lines.size():
		_close()
		return
	_hide_arrow()
	txt_dialog.text = dialogue_lines[current_line]
	_plain = txt_dialog.get_parsed_text()
	txt_dialog.visible_characters = 0
	_revealed = 0
	_timer = 0.0
	is_typing = true
	_accepting = true
	set_process(true)


func _process(delta: float) -> void:
	_timer -= delta
	while is_typing and _timer <= 0.0:
		if _revealed >= _plain.length():
			_finish_typing()
			return
		var ch := _plain[_revealed]
		_revealed += 1
		txt_dialog.visible_characters = _revealed
		_play_voice(ch)
		if ch == "\n":
			_timer += newline_pause
		elif PUNCTUATION.contains(ch):
			_timer += punctuation_pause
		else:
			_timer += seconds_per_char


func _finish_typing() -> void:
	is_typing = false
	set_process(false)
	txt_dialog.visible_characters = -1
	_show_arrow()


func _close() -> void:
	_accepting = false
	_hide_arrow()
	_kill(_fade_tween)
	_fade_tween = create_tween()
	_fade_tween.tween_property(ui_dialog, "modulate:a", 0.0, 0.3)
	_fade_tween.tween_callback(_on_closed)


func _on_closed() -> void:
	ui_dialog.hide()
	is_dialogue_active = false
	dialogue_finished.emit()


func _input(event: InputEvent) -> void:
	if not _accepting:
		return
	var confirm: bool = event.is_action_pressed(&"ui_accept") or (
		event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	)
	if not confirm:
		return
	get_viewport().set_input_as_handled()
	if is_typing:
		_finish_typing()
	else:
		current_line += 1
		_show_page()


func _play_voice(ch: String) -> void:
	if not GameManager.voice_enabled:
		return
	var vowel: String = VOWEL_MAP.get(ch.to_lower(), "")
	if vowel == "":
		return
	var player := _voices[_voice_index]
	_voice_index = (_voice_index + 1) % _voices.size()
	player.stream = VOICES[vowel]
	player.pitch_scale = randf_range(0.97, 1.03)
	player.play()


func _build_arrow() -> void:
	_arrow = TextureRect.new()
	_arrow.texture = ARROW
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.visible = false
	ui_dialog.add_child(_arrow)


func _show_arrow() -> void:
	_kill(_arrow_tween)
	var base: Vector2 = ui_dialog.size - ARROW.get_size() - Vector2(6, 6) - Vector2(arrow_bounce, 0)
	_arrow.position = base
	_arrow.modulate.a = 0.0
	_arrow.visible = true
	_arrow_tween = create_tween()
	_arrow_tween.tween_interval(arrow_delay)
	_arrow_tween.tween_property(_arrow, "modulate:a", 1.0, 0.3)
	_arrow_tween.tween_callback(_bounce.bind(base.x))


func _bounce(base_x: float) -> void:
	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_property(_arrow, "position:x", base_x + arrow_bounce, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_arrow_tween.tween_property(_arrow, "position:x", base_x, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_arrow_tween.tween_interval(0.25)


func _hide_arrow() -> void:
	_kill(_arrow_tween)
	_arrow.visible = false


func _kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
