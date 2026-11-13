extends Node2D

@onready var glow = $bgGlow
@onready var curtains = $bgCurtains
@onready var bg_normal = $bgNormal
@onready var bg_title = $bgTitle
@onready var bg_bright = $bgBright
@onready var ui_menu = $uiMenu
@onready var btn_start: TextureButton = $uiMenu/VBoxContainer/btnStart
@onready var btn_continue: TextureButton = $uiMenu/VBoxContainer/btnContinue
@onready var btn_options: TextureButton = $uiMenu/VBoxContainer/btnOptions

const INTRO_MUSIC := preload("res://assets/audio/intro.wav")
const MENU_DISABLED_COLOR := Color(0.27, 0.27, 0.27)

const MENU_HOVER_COLOR := Color(1.5, 1.5, 1.5)
const MENU_HOVER_SCALE := Vector2(1.15, 1.15)
const MENU_SELECTOR_TEXTURE := preload("res://assets/sprites/selector.png")
const MENU_SELECTOR_GAP := 2.0
const MENU_SELECTOR_SCALE := Vector2(1.0, 1.0)
const MENU_SELECTOR_OFFSET_Y := 2.0
const MENU_SELECTOR_BOB := 4.0
const MENU_SELECTOR_BOB_TIME := 0.5

const CURTAINS_SPEED_SCALE := 0.5

const BOOK_ZOOM_TEXTURE := preload("res://assets/sprites/livroZoom.png")
const BG_CENTER := Vector2(160, 90)
const BOOK_IN_SCENE := Vector2(185, 140)
const BOOK_ZOOM_TARGET := Vector2(160, 98)
const BOOK_ZOOM_SCALE := 1.3
const BOOK_ZOOM_DURATION := 1.2
const BOOK_FADE_DURATION := 1.0

const LINE_ZOOM_BOOK := 1
const LINE_SHOW_OPEN_BOOK := 2

const LEVEL_1_PATH := "res://scenes/levels/level_1.tscn"

const FIRE_TEXTURE := preload("res://assets/sprites/flare.png")
const FIRE_CELL := 16
const FIRE_ORIGIN := Vector2(160, 98)
const FIRE_SPREAD_TIME := 3.0
const FIRE_JITTER := 0.3
const FIRE_GROW_TIME := 0.4
const FIRE_SCALE := 1.6
const FIRE_FPS := 6.0
const FIRE_COAL_COLOR := Color(0.12, 0.04, 0.0, 1.0)
const FIRE_HOLD_TIME := 0.3
const FIRE_SWAP_MARGIN := 0.4
const FIRE_REVEAL_TIME := 2.0
const FIRE_SHRINK_TIME := 0.5

const FIRE_SOUND := preload("res://assets/audio/burning.wav")
const FIRE_SOUND_DB := -8.0
const FIRE_SOUND_SILENT_DB := -40.0
const FIRE_SOUND_FADE_IN := 1.0
const FIRE_SOUND_FADE_OUT := 1.0

const CLICK_PROMPT_TEXT := "Clique para continuar"
const CLICK_PROMPT_DELAY := 2.5
const CLICK_PROMPT_MARGIN := 6
const CLICK_PROMPT_BLINK_TIME := 0.5

var click_prompt: HBoxContainer
var prompt_arrow: TextureRect
var prompt_tween: Tween
var waiting_for_click: bool = false
var book_zoom: TextureRect
var menu_selector: Control
var selector_tween: Tween
var menu_locked: bool = false

var dialogue_lines: Array[String] = [
	"Milão, século XVI.",
	"\"Ars Magna\" — o tratado que sistematiza equações cúbicas.",
	"Compilado por matemáticos como Tartaglia e Scipione."
]

func _ready():
	bg_bright.modulate.a = 1.0
	glow.modulate.a = 0.0
	
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(glow, "modulate:a", 0.7, 3.0)
	tween.tween_property(glow, "modulate:a", 0.2, 3.0)
	
	curtains.play("default")
	curtains.frame = 0
	curtains.pause()

	menu_selector = Control.new()
	menu_selector.modulate = MENU_HOVER_COLOR
	menu_selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_selector.hide()
	ui_menu.add_child(menu_selector)
	var selector_icon := TextureRect.new()
	selector_icon.texture = MENU_SELECTOR_TEXTURE
	selector_icon.scale = MENU_SELECTOR_SCALE
	selector_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_selector.add_child(selector_icon)
	var bob := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(selector_icon, "position:x", -MENU_SELECTOR_BOB, MENU_SELECTOR_BOB_TIME)
	bob.tween_property(selector_icon, "position:x", 0.0, MENU_SELECTOR_BOB_TIME)

	var prompt_layer := CanvasLayer.new()
	add_child(prompt_layer)
	click_prompt = HBoxContainer.new()
	click_prompt.add_theme_constant_override("separation", 3)
	click_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click_prompt.add_child(UIKit.make_label(CLICK_PROMPT_TEXT, UIKit.DEFAULT_SIZE))
	prompt_arrow = TextureRect.new()
	prompt_arrow.texture = MENU_SELECTOR_TEXTURE
	prompt_arrow.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	prompt_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click_prompt.add_child(prompt_arrow)
	click_prompt.hide()
	prompt_layer.add_child(click_prompt)
	click_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, CLICK_PROMPT_MARGIN)

	book_zoom = TextureRect.new()
	book_zoom.texture = BOOK_ZOOM_TEXTURE
	book_zoom.modulate.a = 0.0
	book_zoom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(book_zoom)

	MusicManager.play(INTRO_MUSIC, 0.5, 2.0)
	_setup_menu()

func _setup_menu() -> void:
	var has_save: bool = SaveManager.has_save()
	btn_continue.disabled = not has_save
	if not has_save:
		btn_continue.modulate = MENU_DISABLED_COLOR

	btn_continue.pressed.connect(_on_continue_pressed)
	btn_options.pressed.connect(_on_options_pressed)

	for button in [btn_start, btn_continue, btn_options]:
		if button.disabled:
			button.focus_mode = Control.FOCUS_NONE
			continue
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_entered.connect(button.grab_focus)
		button.focus_entered.connect(_on_menu_hover.bind(button, true))
		button.focus_exited.connect(_on_menu_hover.bind(button, false))

	btn_start.grab_focus.call_deferred()

func _on_menu_hover(button: TextureButton, hovering: bool) -> void:
	button.pivot_offset = button.size / 2.0

	if hovering:
		var center := button.global_position + button.size / 2.0
		var left_edge := center.x - button.size.x * MENU_HOVER_SCALE.x / 2.0
		var arrow_size := MENU_SELECTOR_TEXTURE.get_size() * MENU_SELECTOR_SCALE
		menu_selector.position = Vector2(
			left_edge - arrow_size.x - MENU_SELECTOR_GAP,
			center.y - arrow_size.y / 2.0 + MENU_SELECTOR_OFFSET_Y
		)

		if selector_tween and selector_tween.is_valid():
			selector_tween.kill()
		menu_selector.modulate = Color(MENU_HOVER_COLOR, 0.0)
		menu_selector.show()
		selector_tween = create_tween().set_trans(Tween.TRANS_SINE)
		selector_tween.tween_property(menu_selector, "modulate:a", 1.0, 0.12)
	else:
		if selector_tween and selector_tween.is_valid():
			selector_tween.kill()
		menu_selector.hide()

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_parallel()
	tween.tween_property(button, "modulate", MENU_HOVER_COLOR if hovering else Color.WHITE, 0.12)
	tween.tween_property(button, "scale", MENU_HOVER_SCALE if hovering else Vector2.ONE, 0.12)

func _on_texture_button_pressed() -> void:
	if menu_locked:
		return
	menu_locked = true
	if SaveManager.has_save():
		var confirmed: bool = await ConfirmPrompt.ask(self, "O save atual será apagado.\nIniciar um novo jogo?")
		if not confirmed:
			menu_locked = false
			btn_start.grab_focus()
			return
		SaveManager.delete_save()

	get_viewport().gui_release_focus()
	ui_menu.hide()
	bg_title.hide()
	glow.hide()
	
	curtains.frame = 0
	curtains.speed_scale = CURTAINS_SPEED_SCALE
	curtains.play("default")

	await curtains.animation_finished
	await get_tree().create_timer(0.2).timeout

	curtains.hide()
	bg_normal.play("default")
	
	var fade_tween = create_tween()
	fade_tween.tween_property(bg_bright, "modulate:a", 0.0, 1.5)
	
	await get_tree().create_timer(1.5).timeout
	await get_tree().create_timer(CLICK_PROMPT_DELAY).timeout

	show_click_prompt()
	
func _on_continue_pressed() -> void:
	if menu_locked or not SaveManager.has_save():
		return
	menu_locked = true
	MusicManager.stop_all(0.8)
	GameManager.continue_game()

func _on_options_pressed() -> void:
	if menu_locked:
		return
	menu_locked = true
	await OptionsMenu.open(self)
	menu_locked = false
	btn_options.grab_focus()

func show_click_prompt() -> void:
	click_prompt.modulate.a = 0.0
	click_prompt.show()

	var fade_in := create_tween()
	fade_in.tween_property(click_prompt, "modulate:a", 1.0, 0.5)
	await fade_in.finished

	prompt_tween = create_tween().set_loops()
	prompt_tween.tween_property(prompt_arrow, "modulate:a", 0.0, CLICK_PROMPT_BLINK_TIME)
	prompt_tween.tween_property(prompt_arrow, "modulate:a", 1.0, CLICK_PROMPT_BLINK_TIME)
	waiting_for_click = true

func dismiss_click_prompt() -> void:
	waiting_for_click = false
	prompt_tween.kill()

	var fade_out := create_tween()
	fade_out.tween_property(click_prompt, "modulate:a", 0.0, 0.4)
	await fade_out.finished
	click_prompt.hide()

	run_dialogue()

func run_dialogue() -> void:
	for i in dialogue_lines.size():
		match i:
			LINE_ZOOM_BOOK: await zoom_to_book()
			LINE_SHOW_OPEN_BOOK: await show_open_book()
		await DialogueManager.say_text(dialogue_lines[i])
	play_fire_transition()

func play_fire_transition() -> void:
	ResourceLoader.load_threaded_request(LEVEL_1_PATH)
	MusicManager.stop(INTRO_MUSIC, 2.0)

	var fire_layer := CanvasLayer.new()
	fire_layer.layer = 10
	get_tree().root.add_child(fire_layer)
	var char_layer := Node2D.new()
	var flame_layer := Node2D.new()
	fire_layer.add_child(char_layer)
	fire_layer.add_child(flame_layer)

	var cover_end := FIRE_SPREAD_TIME + FIRE_JITTER + FIRE_GROW_TIME
	var t_change := cover_end + FIRE_HOLD_TIME
	var t_reveal := t_change + FIRE_SWAP_MARGIN
	var t_end := t_reveal + FIRE_REVEAL_TIME + FIRE_JITTER + FIRE_SHRINK_TIME + 0.1

	var sound := AudioStreamPlayer.new()
	sound.stream = FIRE_SOUND
	sound.bus = &"SFX"
	sound.volume_db = FIRE_SOUND_SILENT_DB
	fire_layer.add_child(sound)
	sound.play()
	var sound_tween := fire_layer.create_tween()
	sound_tween.tween_property(sound, "volume_db", FIRE_SOUND_DB, FIRE_SOUND_FADE_IN)
	sound_tween.tween_interval(maxf(FIRE_SOUND.get_length() - FIRE_SOUND_FADE_IN - FIRE_SOUND_FADE_OUT, 0.0))
	sound_tween.tween_property(sound, "volume_db", FIRE_SOUND_SILENT_DB, FIRE_SOUND_FADE_OUT)

	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", FIRE_FPS)
	for x in [0, FIRE_CELL]:
		var frame := AtlasTexture.new()
		frame.atlas = FIRE_TEXTURE
		frame.region = Rect2(x, 0, FIRE_CELL, FIRE_CELL)
		frames.add_frame("default", frame)

	var screen := BG_CENTER * 2.0
	var corners := [Vector2.ZERO, Vector2(screen.x, 0), Vector2(0, screen.y), screen]
	var max_dist_cover := 0.0
	var max_dist_reveal := 0.0
	for corner in corners:
		max_dist_cover = maxf(max_dist_cover, FIRE_ORIGIN.distance_to(corner))
		max_dist_reveal = maxf(max_dist_reveal, BG_CENTER.distance_to(corner))

	for row in ceili(screen.y / FIRE_CELL):
		for col in ceili(screen.x / FIRE_CELL):
			var center := (Vector2(col, row) + Vector2(0.5, 0.5)) * FIRE_CELL
			var cover_delay := center.distance_to(FIRE_ORIGIN) / max_dist_cover * FIRE_SPREAD_TIME \
				+ randf_range(0.0, FIRE_JITTER)
			var reveal_delay := t_reveal + center.distance_to(BG_CENTER) / max_dist_reveal * FIRE_REVEAL_TIME \
				+ randf_range(0.0, FIRE_JITTER)

			var coal := ColorRect.new()
			coal.size = Vector2.ONE * (FIRE_CELL + 1)
			coal.position = center - coal.size / 2.0
			coal.color = Color(FIRE_COAL_COLOR, 0.0)
			char_layer.add_child(coal)

			var flame := AnimatedSprite2D.new()
			flame.sprite_frames = frames
			flame.position = center
			flame.scale = Vector2.ONE * 0.01
			flame.frame = randi() % 2
			flame.speed_scale = randf_range(0.8, 1.2)
			flame_layer.add_child(flame)
			flame.play("default")

			var tween := fire_layer.create_tween()
			tween.tween_interval(cover_delay)
			tween.tween_property(flame, "scale", Vector2.ONE * FIRE_SCALE, FIRE_GROW_TIME) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(coal, "color:a", FIRE_COAL_COLOR.a, FIRE_GROW_TIME)
			tween.tween_interval(reveal_delay - cover_delay - FIRE_GROW_TIME)
			tween.tween_property(flame, "scale", Vector2.ONE * 0.01, FIRE_SHRINK_TIME) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(coal, "color:a", 0.0, FIRE_SHRINK_TIME)

	var master := fire_layer.create_tween()
	master.tween_interval(t_change)
	master.tween_callback(go_to_level_1)
	master.tween_interval(t_end - t_change)
	master.tween_callback(GameManager.finish_transition)
	master.tween_callback(fire_layer.queue_free)

func go_to_level_1() -> void:
	var level := ResourceLoader.load_threaded_get(LEVEL_1_PATH) as PackedScene
	GameManager.start_mode = GameManager.StartMode.NEW
	GameManager.transition_running = true
	get_tree().change_scene_to_packed(level)

func zoom_to_book() -> void:
	var target_position := BOOK_ZOOM_TARGET - BOOK_ZOOM_SCALE * (BOOK_IN_SCENE - BG_CENTER)
	var half_size := BG_CENTER * BOOK_ZOOM_SCALE
	target_position = target_position.clamp(BG_CENTER * 2.0 - half_size, half_size)

	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(bg_normal, "scale", Vector2.ONE * BOOK_ZOOM_SCALE, BOOK_ZOOM_DURATION)
	tween.tween_property(bg_normal, "position", target_position, BOOK_ZOOM_DURATION)
	await tween.finished

func show_open_book() -> void:
	var tween := create_tween()
	tween.tween_property(book_zoom, "modulate:a", 1.0, BOOK_FADE_DURATION)
	await tween.finished
	bg_normal.hide()

func _input(event):
	if waiting_for_click and (event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		get_viewport().set_input_as_handled()
		dismiss_click_prompt()
