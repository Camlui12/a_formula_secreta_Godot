extends Node2D

@onready var glow = $bgGlow
@onready var curtains = $bgCurtains
@onready var bg_normal = $bgNormal
@onready var bg_title = $bgTitle
@onready var bg_bright = $bgBright
@onready var ui_dialog = $uiDialog
@onready var txt_dialog = $uiDialog/bgDialog/txtDialog
@onready var ui_menu = $uiMenu

var dialogue_lines: Array[String] = [
	"Milão, século XVI.",
	"\"Ars Magna\" — o tratado que sistematiza equações cúbicas.",
	"Compilado por matemáticos como Tartaglia e Scipione."
]
var current_line: int = 0
var is_typing: bool = false
var text_tween: Tween

func _ready():
	ui_dialog.hide()
	
	bg_bright.modulate.a = 1.0
	glow.modulate.a = 0.0
	
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(glow, "modulate:a", 0.7, 3.0)
	tween.tween_property(glow, "modulate:a", 0.2, 3.0)
	
	curtains.play("default")
	curtains.frame = 0
	curtains.pause()

func _on_texture_button_pressed() -> void:
	ui_menu.hide()
	bg_title.hide()
	glow.hide()
	
	curtains.frame = 0
	curtains.play("default")
	
	await get_tree().create_timer(1.0).timeout
	
	curtains.hide()
	bg_normal.play("default")
	
	var fade_tween = create_tween()
	fade_tween.tween_property(bg_bright, "modulate:a", 0.0, 1.5)
	
	await get_tree().create_timer(1.5).timeout
	
	start_dialogue()
	
func start_dialogue():
	ui_dialog.show()
	current_line = 0
	show_text()

func show_text():
	if current_line >= dialogue_lines.size():
		ui_dialog.hide()
		return
		
	txt_dialog.text = dialogue_lines[current_line]
	txt_dialog.visible_characters = 0
	is_typing = true
	
	if text_tween and text_tween.is_running():
		text_tween.kill()
		
	text_tween = create_tween()
	var text_length = txt_dialog.get_total_character_count()
	var duration = text_length * 0.04
	
	text_tween.tween_property(txt_dialog, "visible_characters", text_length, duration)
	text_tween.finished.connect(on_typing_finished)

func on_typing_finished():
	is_typing = false
	
func _input(event):
	if ui_dialog.visible:
		if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			if is_typing:
				text_tween.kill()
				txt_dialog.visible_characters = -1
				is_typing = false
			else:
				current_line += 1
				show_text()
