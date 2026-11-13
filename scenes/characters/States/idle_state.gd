class_name IdleState
extends State

@onready var player: Player = owner


func enter() -> void:
	player.velocity = Vector2.ZERO
	player.global_position = player.global_position.round()
	Facing.play(sprite_anim, &"idle", player.facing_name)


func physics_update(_delta: float) -> void:
	if player.get_movement_input() != Vector2.ZERO:
		transitioned.emit(self, &"walk")
