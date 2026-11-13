class_name HurtState
extends State

@onready var player: Player = owner

var _time_left := 0.0


func enter() -> void:
	_time_left = player.knockback_time
	player.velocity = player.knockback_direction * player.knockback_speed
	if sprite_anim != null:
		sprite_anim.pause()


func physics_update(delta: float) -> void:
	player.move_and_slide()
	_time_left -= delta
	if _time_left <= 0.0:
		transitioned.emit(self, &"idle")


func exit() -> void:
	player.velocity = Vector2.ZERO
	if player.slow_after_knockback and not player.is_dead:
		player.slow_after_knockback = false
		player.apply_slow()
