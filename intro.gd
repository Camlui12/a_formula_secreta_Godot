extends Node2D

@onready var glow = $bgGlow
@onready var curtains = $bgCurtains
@onready var bg_normal = $bgNormal
@onready var bg_title = $bgTitle
@onready var bg_bright = $bgBright
@onready var ui_dialog = $uiDialog
@onready var bg_dialog = $uiDialog/bgDialog
@onready var txt_dialog = $uiDialog/bgDialog/txtDialog
@onready var ui_menu = $uiMenu

const MENU_HOVER_COLOR := Color(1.5, 1.5, 1.5)
const MENU_HOVER_SCALE := Vector2(1.15, 1.15)
const MENU_SELECTOR_TEXTURE := preload("res://assets/sprites/selector.png")
const MENU_SELECTOR_GAP := 2.0
const MENU_SELECTOR_SCALE := Vector2(1.0, 1.0)
const MENU_SELECTOR_OFFSET_Y := 2.0

const CURTAINS_SPEED_SCALE := 0.5 # 1.0 = velocidade original (0,8 s); 0.5 = metade da velocidade

const BOOK_ZOOM_TEXTURE := preload("res://assets/sprites/livroZoom.png")
const BG_CENTER := Vector2(160, 90)
const BOOK_IN_SCENE := Vector2(185, 140)   # centro do livro na imagem scene1_2
const BOOK_ZOOM_TARGET := Vector2(160, 98) # onde o livro fica em livroZoom.png
const BOOK_ZOOM_SCALE := 1.3
const BOOK_ZOOM_DURATION := 1.2  # zoom que começa rápido e freia no final
const BOOK_FADE_DURATION := 1.0  # troca para a imagem do livro aberto

# Em qual caixa de diálogo (índice, começando em 0) cada efeito acontece.
const LINE_ZOOM_BOOK := 1
const LINE_SHOW_OPEN_BOOK := 2

# Vogais (inclusive acentuadas) -> vogal base, que escolhe o áudio da voz.
const VOWEL_MAP := {
	"a": "a", "á": "a", "à": "a", "â": "a", "ã": "a",
	"e": "e", "é": "e", "ê": "e",
	"i": "i", "í": "i",
	"o": "o", "ó": "o", "ô": "o", "õ": "o",
	"u": "u", "ú": "u",
}

const DIALOG_SECONDS_PER_CHAR := 0.06 # tempo para revelar cada caractere (antes: 0.04)
const DIALOG_FONT_SIZE := 12           # tamanho padrão do RichTextLabel é 16
const DIALOG_FADE_DURATION := 0.7     # fade in/out da caixa de diálogo

const VOICE_VOLUME_DB := -15.0 # 0 = volume original; quanto menor, mais baixo

const DIALOG_ARROW_MARGIN := Vector2(6, 6) # distância da seta até o canto da caixa
const DIALOG_ARROW_BOB := 5.0              # quantos pixels a seta sobe
const DIALOG_ARROW_BOB_TIME := 0.6         # duração da subida (e da descida)

const LEVEL_1_PATH := "res://scenes/levels/level_1.tscn"

# Transição de fogo (último clique da intro -> level_1)
const FIRE_TEXTURE := preload("res://assets/sprites/flare.png")
const FIRE_CELL := 16                      # lado de cada chama no flare.png
const FIRE_ORIGIN := Vector2(160, 98)      # de onde o fogo começa (centro do livro)
const FIRE_SPREAD_TIME := 3.0              # tempo para o fogo chegar ao canto mais distante
const FIRE_JITTER := 0.3                   # atraso aleatório por chama
const FIRE_GROW_TIME := 0.4                # tempo de cada chama para crescer
const FIRE_SCALE := 1.6                    # tamanho final das chamas (>1 cobre as frestas)
const FIRE_FPS := 6.0                      # velocidade do tremular das chamas
const FIRE_COAL_COLOR := Color(0.12, 0.04, 0.0, 1.0) # cor da imagem queimada (opaca: esconde o level na troca)
const FIRE_HOLD_TIME := 0.3                # pausa com a tela toda em chamas, antes de trocar de cena
const FIRE_SWAP_MARGIN := 0.4              # folga depois da troca, antes do fogo começar a abrir
const FIRE_REVEAL_TIME := 2.0              # tempo para o fogo abrir do centro até os cantos
const FIRE_SHRINK_TIME := 0.5              # tempo de cada chama para encolher e sumir

const FIRE_SOUND := preload("res://assets/audio/burning.wav")
const FIRE_SOUND_DB := -8.0                # volume do fogo (0 = original)
const FIRE_SOUND_SILENT_DB := -40.0
const FIRE_SOUND_FADE_IN := 1.0
const FIRE_SOUND_FADE_OUT := 1.0           # termina junto com o fim do arquivo (5 s)

const CLICK_PROMPT_TEXT := "Clique para continuar"
const CLICK_PROMPT_FONT_SIZE := 10

var click_prompt: Label
var prompt_tween: Tween
var waiting_for_click: bool = false
var voice_player: AudioStreamPlayer
var voice_streams: Dictionary = {}
var voiced_characters: int = 0
var book_zoom: TextureRect
var menu_selector: TextureRect
var selector_tween: Tween

var dialogue_lines: Array[String] = [
	"Milão, século XVI.",
	"\"Ars Magna\" — o tratado que sistematiza equações cúbicas.",
	"Compilado por matemáticos como Tartaglia e Scipione."
]
var current_line: int = 0
var is_typing: bool = false
var is_transitioning: bool = false # true durante fades/zoom: ignora cliques
var text_tween: Tween

func _ready():
	ui_dialog.hide()
	txt_dialog.add_theme_font_size_override("normal_font_size", DIALOG_FONT_SIZE)
	
	bg_bright.modulate.a = 1.0
	glow.modulate.a = 0.0
	
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(glow, "modulate:a", 0.7, 3.0)
	tween.tween_property(glow, "modulate:a", 0.2, 3.0)
	
	curtains.play("default")
	curtains.frame = 0
	curtains.pause()

	menu_selector = TextureRect.new()
	menu_selector.texture = MENU_SELECTOR_TEXTURE
	menu_selector.modulate = MENU_HOVER_COLOR
	menu_selector.scale = MENU_SELECTOR_SCALE
	menu_selector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_selector.hide()
	ui_menu.add_child(menu_selector)

	voice_player = AudioStreamPlayer.new()
	voice_player.volume_db = VOICE_VOLUME_DB
	add_child(voice_player)
	for vowel in "aeiou":
		voice_streams[vowel] = load("res://assets/audio/voices/voice1/voice_%s.wav" % vowel)

	# Seta no canto inferior direito da caixa de diálogo, subindo e descendo.
	# Fica dentro de bg_dialog, então acompanha o fade in/out da caixa.
	var arrow := TextureRect.new()
	arrow.texture = MENU_SELECTOR_TEXTURE
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_dialog.add_child(arrow)
	arrow.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	var arrow_size := arrow.texture.get_size()
	arrow.pivot_offset = arrow_size / 2.0
	arrow.rotation_degrees = 90.0 # gira a seta (que aponta para a direita) para baixo
	var bottom := -DIALOG_ARROW_MARGIN.y
	var top := bottom - arrow_size.y
	arrow.offset_right = -DIALOG_ARROW_MARGIN.x
	arrow.offset_left = arrow.offset_right - arrow_size.x
	arrow.offset_bottom = bottom
	arrow.offset_top = top

	var arrow_tween := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	arrow_tween.tween_property(arrow, "offset_top", top - DIALOG_ARROW_BOB, DIALOG_ARROW_BOB_TIME)
	arrow_tween.parallel().tween_property(arrow, "offset_bottom", bottom - DIALOG_ARROW_BOB, DIALOG_ARROW_BOB_TIME)
	arrow_tween.tween_property(arrow, "offset_top", top, DIALOG_ARROW_BOB_TIME)
	arrow_tween.parallel().tween_property(arrow, "offset_bottom", bottom, DIALOG_ARROW_BOB_TIME)

	var prompt_layer := CanvasLayer.new()
	add_child(prompt_layer)
	click_prompt = Label.new()
	click_prompt.text = CLICK_PROMPT_TEXT
	click_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	click_prompt.position = Vector2(0, 150)
	click_prompt.size = Vector2(320, 16)
	click_prompt.add_theme_font_size_override("font_size", CLICK_PROMPT_FONT_SIZE)
	click_prompt.add_theme_constant_override("outline_size", 3)
	click_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	click_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click_prompt.hide()
	prompt_layer.add_child(click_prompt)

	book_zoom = TextureRect.new()
	book_zoom.texture = BOOK_ZOOM_TEXTURE
	book_zoom.modulate.a = 0.0
	book_zoom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(book_zoom)

	for button in ui_menu.get_node("VBoxContainer").get_children():
		if button is TextureButton:
			button.mouse_entered.connect(_on_menu_hover.bind(button, true))
			button.mouse_exited.connect(_on_menu_hover.bind(button, false))

func _on_menu_hover(button: TextureButton, hovering: bool) -> void:
	button.pivot_offset = button.size / 2.0

	if hovering:
		# O botão cresce a partir do centro, então a borda esquerda visual
		# já considera a escala do hover.
		var center := button.global_position + button.size / 2.0
		var left_edge := center.x - button.size.x * MENU_HOVER_SCALE.x / 2.0
		var arrow_size := menu_selector.texture.get_size() * MENU_SELECTOR_SCALE
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
	
	show_click_prompt()
	
# Mostra "Clique para continuar" piscando e espera o clique antes da primeira caixa.
func show_click_prompt() -> void:
	click_prompt.modulate.a = 0.0
	click_prompt.show()

	var fade_in := create_tween()
	fade_in.tween_property(click_prompt, "modulate:a", 1.0, 0.5)
	await fade_in.finished

	prompt_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	prompt_tween.tween_property(click_prompt, "modulate:a", 0.35, 0.9)
	prompt_tween.tween_property(click_prompt, "modulate:a", 1.0, 0.9)
	waiting_for_click = true

func dismiss_click_prompt() -> void:
	waiting_for_click = false
	prompt_tween.kill()

	var fade_out := create_tween()
	fade_out.tween_property(click_prompt, "modulate:a", 0.0, 0.4)
	await fade_out.finished
	click_prompt.hide()

	start_dialogue()

func start_dialogue():
	is_transitioning = true
	bg_dialog.modulate.a = 0.0
	ui_dialog.show()
	current_line = 0
	await show_text()
	is_transitioning = false

# Chamado quando o jogador clica com o texto já todo na tela:
# some a caixa, troca a cena (se essa fala tiver efeito) e mostra a próxima caixa.
func advance_dialogue() -> void:
	is_transitioning = true
	await fade_dialog(0.0)

	current_line += 1
	if current_line >= dialogue_lines.size():
		ui_dialog.hide()
		# Mantém is_transitioning = true: depois disso a cena é trocada.
		play_fire_transition()
		return

	match current_line:
		LINE_ZOOM_BOOK: await zoom_to_book()
		LINE_SHOW_OPEN_BOOK: await show_open_book()

	await show_text()
	is_transitioning = false

# A imagem "pega fogo": chamas (flare.png) surgem a partir do livro e se espalham
# até cobrir a tela toda, escurecendo a imagem por baixo. Com a tela coberta, troca
# para o level_1 e o fogo se abre (a partir do centro da tela), revelando o nível.
#
# Tudo vive em um CanvasLayer na raiz da árvore, para continuar depois que a cena da
# intro for destruída. Por isso os tweens são criados por fire_layer, e não por esta cena.
func play_fire_transition() -> void:
	ResourceLoader.load_threaded_request(LEVEL_1_PATH) # carrega o level durante o fogo

	var fire_layer := CanvasLayer.new()
	fire_layer.layer = 10
	get_tree().root.add_child(fire_layer)
	var char_layer := Node2D.new()   # "carvão" que escurece a imagem
	var flame_layer := Node2D.new()  # chamas, sempre por cima do carvão
	fire_layer.add_child(char_layer)
	fire_layer.add_child(flame_layer)

	# Linha do tempo (segundos desde o clique)
	var cover_end := FIRE_SPREAD_TIME + FIRE_JITTER + FIRE_GROW_TIME  # tela toda coberta
	var t_change := cover_end + FIRE_HOLD_TIME                        # troca de cena
	var t_reveal := t_change + FIRE_SWAP_MARGIN                       # fogo começa a abrir
	var t_end := t_reveal + FIRE_REVEAL_TIME + FIRE_JITTER + FIRE_SHRINK_TIME + 0.1

	# Som do fogo: entra aos poucos e sai antes de o arquivo acabar.
	var sound := AudioStreamPlayer.new()
	sound.stream = FIRE_SOUND
	sound.volume_db = FIRE_SOUND_SILENT_DB
	fire_layer.add_child(sound)
	sound.play()
	var sound_tween := fire_layer.create_tween()
	sound_tween.tween_property(sound, "volume_db", FIRE_SOUND_DB, FIRE_SOUND_FADE_IN)
	sound_tween.tween_interval(maxf(FIRE_SOUND.get_length() - FIRE_SOUND_FADE_IN - FIRE_SOUND_FADE_OUT, 0.0))
	sound_tween.tween_property(sound, "volume_db", FIRE_SOUND_SILENT_DB, FIRE_SOUND_FADE_OUT)

	# flare.png tem 2 quadros de 16x16 lado a lado.
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
			# Quanto mais longe da origem, mais tarde o fogo chega (com um pouco de aleatoriedade).
			var cover_delay := center.distance_to(FIRE_ORIGIN) / max_dist_cover * FIRE_SPREAD_TIME \
				+ randf_range(0.0, FIRE_JITTER)
			# Na abertura, o fogo some primeiro no centro e por último nos cantos.
			var reveal_delay := t_reveal + center.distance_to(BG_CENTER) / max_dist_reveal * FIRE_REVEAL_TIME \
				+ randf_range(0.0, FIRE_JITTER)

			var coal := ColorRect.new()
			coal.size = Vector2.ONE * (FIRE_CELL + 1) # +1 evita frestas entre as células
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
	master.tween_callback(fire_layer.queue_free)

# Chamado com a tela toda coberta de fogo.
func go_to_level_1() -> void:
	var level := ResourceLoader.load_threaded_get(LEVEL_1_PATH) as PackedScene
	get_tree().change_scene_to_packed(level)

func fade_dialog(alpha: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(bg_dialog, "modulate:a", alpha, DIALOG_FADE_DURATION)
	await tween.finished

# Coloca o texto da fala atual na caixa, faz o fade in dela e começa a digitar.
func show_text() -> void:
	txt_dialog.text = dialogue_lines[current_line]
	txt_dialog.visible_characters = 0
	voiced_characters = 0

	await fade_dialog(1.0)
	is_typing = true

	if text_tween and text_tween.is_running():
		text_tween.kill()

	text_tween = create_tween()
	var text_length = txt_dialog.get_total_character_count()
	var duration = text_length * DIALOG_SECONDS_PER_CHAR
	
	text_tween.tween_property(txt_dialog, "visible_characters", text_length, duration)
	text_tween.finished.connect(on_typing_finished)

func _process(_delta: float) -> void:
	if not is_typing:
		return

	var shown: int = txt_dialog.visible_characters
	if shown <= voiced_characters:
		return

	# Toca a voz da última vogal revelada desde o frame anterior.
	var text: String = txt_dialog.get_parsed_text()
	var vowel := ""
	for i in range(voiced_characters, mini(shown, text.length())):
		var base: String = VOWEL_MAP.get(text[i].to_lower(), "")
		if base != "":
			vowel = base
	voiced_characters = shown

	if vowel != "":
		voice_player.stream = voice_streams[vowel]
		voice_player.play()

func zoom_to_book() -> void:
	# Aproxima rápido a câmera do livro em bg_normal (que é centralizado em BG_CENTER).
	var target_position := BOOK_ZOOM_TARGET - BOOK_ZOOM_SCALE * (BOOK_IN_SCENE - BG_CENTER)
	# Com pouco zoom a imagem não cobre a tela se for deslocada demais,
	# então limita a posição para nunca aparecer borda vazia.
	var half_size := BG_CENTER * BOOK_ZOOM_SCALE
	target_position = target_position.clamp(BG_CENTER * 2.0 - half_size, half_size)

	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(bg_normal, "scale", Vector2.ONE * BOOK_ZOOM_SCALE, BOOK_ZOOM_DURATION)
	tween.tween_property(bg_normal, "position", target_position, BOOK_ZOOM_DURATION)
	await tween.finished

func show_open_book() -> void:
	# Troca para a imagem do livro aberto (livroZoom.png) com fade.
	var tween := create_tween()
	tween.tween_property(book_zoom, "modulate:a", 1.0, BOOK_FADE_DURATION)
	await tween.finished
	bg_normal.hide()

func on_typing_finished():
	is_typing = false
	
func _input(event):
	if waiting_for_click:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			dismiss_click_prompt()
		return

	if ui_dialog.visible and not is_transitioning:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			if is_typing:
				text_tween.kill()
				txt_dialog.visible_characters = -1
				is_typing = false
			else:
				advance_dialogue()
