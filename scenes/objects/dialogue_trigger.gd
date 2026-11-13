class_name DialogueTrigger
extends Area2D

signal completed

@export_multiline var text: String = ""
@export var one_shot: bool = true
@export var ends_level: bool = false

var _used := false


func _ready() -> void:
	add_to_group(&"dialogue_triggers")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _used or text.is_empty() or not body is Player:
		return
	if not GameManager.gameplay_active:
		return
	_used = one_shot
	GameManager.set_gameplay_active(false)
	await DialogueManager.say_text(text)
	if ends_level:
		completed.emit()
	else:
		GameManager.set_gameplay_active(true)
		completed.emit()
