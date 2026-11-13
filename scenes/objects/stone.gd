class_name Stone
extends Node2D

signal landed(position: Vector2)

enum Phase { ON_GROUND, FLYING, LANDED }

@export var linger_time: float = 1.5

var phase: Phase = Phase.ON_GROUND

var _prompt: Label


func _ready() -> void:
	if phase == Phase.ON_GROUND:
		add_to_group(&"ground_stones")


func show_prompt(on: bool) -> void:
	if on and _prompt == null:
		_prompt = UIKit.make_label("[E] Pegar")
		_prompt.z_index = 100
		add_child(_prompt)
		var size := _prompt.get_minimum_size()
		_prompt.position = Vector2(-size.x * 0.5, -size.y - 8.0)
	if _prompt != null:
		_prompt.visible = on


func collect() -> void:
	remove_from_group(&"ground_stones")
	queue_free()


func throw_to(target: Vector2, speed: float) -> void:
	phase = Phase.FLYING
	remove_from_group(&"ground_stones")
	var duration := maxf(global_position.distance_to(target) / speed, 0.01)
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, duration)
	tween.tween_callback(_land)


func _land() -> void:
	if phase == Phase.LANDED:
		return
	phase = Phase.LANDED
	landed.emit(global_position)
	get_tree().call_group(&"guards", &"hear_noise", global_position)
	var tween := create_tween()
	tween.tween_interval(maxf(linger_time - 0.3, 0.0))
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
