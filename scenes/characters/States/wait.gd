class_name GuardWaitState
extends State

@onready var guard: Guard = owner

var timer: float = 0.0


func enter() -> void:
	timer = guard.turn_wait
	guard.velocity = Vector2.ZERO
	guard.play_idle()


func physics_update(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		guard.flip_direction()
		transitioned.emit(self, &"patrol")
