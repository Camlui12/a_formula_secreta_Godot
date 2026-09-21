extends Node2D

@onready var glow = $bgGlow
@onready var curtains = $bgCurtains
@onready var bg_normal = $bgNormal
@onready var bg_title = $bgTitle
@onready var bg_bright = $bgBright
@onready var ui_menu = $uiMenu

var dialogue_lines: Array[String] = [
	"Milão, século XVI.",
	"\"Ars Magna\" — o tratado que sistematiza equações cúbicas.",
    "Compilado por matemáticos como Tartaglia e ScipioneeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaaaaaaaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee."
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
	
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

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
	
	DialogueManager.show_custom_dialogue(dialogue_lines)

func _on_dialogue_finished():
	DialogueManager.dialogue_finished.disconnect(_on_dialogue_finished)
	get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")
