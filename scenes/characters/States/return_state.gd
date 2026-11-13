class_name GuardReturnState
extends State

@onready var guard: Guard = owner

var _travel_left := 0.0


func enter() -> void:
	_travel_left = guard.global_position.distance_to(guard.spawn_position) / guard.speed * 2.0 + 1.0


func physics_update(delta: float) -> void:
	_travel_left -= delta
	var arrived := guard.move_toward_point(guard.spawn_position)
	if not arrived and _travel_left > 0.0:
		return
	if not arrived:
		guard.global_position = guard.spawn_position
	guard.patrol_dir = guard.random_patrol_dir()
	transitioned.emit(self, &"patrol")
