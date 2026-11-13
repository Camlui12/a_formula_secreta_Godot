class_name WalkState
extends State

@onready var player: Player = owner


func enter() -> void:
	Facing.play(sprite_anim, &"walk", player.facing_name)


func physics_update(_delta: float) -> void:
	var dir := player.get_movement_input()
	if dir == Vector2.ZERO:
		transitioned.emit(self, &"idle")
		return

	player.velocity = dir * player.get_current_speed()
	player.move_and_slide()
	Facing.play(sprite_anim, &"walk", player.facing_name)
