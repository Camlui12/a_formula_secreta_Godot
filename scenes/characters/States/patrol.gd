class_name GuardPatrolState
extends State

const TURN_COOLDOWN := 0.25

@onready var guard: Guard = owner

var _turn_cooldown := 0.0


func enter() -> void:
	_turn_cooldown = TURN_COOLDOWN
	guard.set_facing(guard.patrol_dir)
	guard.play_walk()


func physics_update(delta: float) -> void:
	_turn_cooldown = maxf(0.0, _turn_cooldown - delta)

	guard.velocity = guard.patrol_dir * guard.speed
	guard.move_and_slide()
	guard.play_walk()

	if _turn_cooldown > 0.0:
		return

	var advanced := (guard.global_position - guard.spawn_position).dot(guard.patrol_dir)
	if guard.get_slide_collision_count() > 0 or advanced >= guard.patrol_range:
		if guard.turn_wait > 0.0:
			transitioned.emit(self, &"wait")
		else:
			guard.flip_direction()
			_turn_cooldown = TURN_COOLDOWN
