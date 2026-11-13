class_name GuardInvestigateState
extends State

@onready var guard: Guard = owner

var _target := Vector2.ZERO
var _waiting := false
var _wait_left := 0.0
var _travel_left := 0.0


func enter() -> void:
	_target = guard.investigate_target
	_waiting = false
	_travel_left = guard.global_position.distance_to(_target) / guard.speed * 2.0 + 1.0


func physics_update(delta: float) -> void:
	if _waiting:
		_wait_left -= delta
		if _wait_left <= 0.0:
			transitioned.emit(self, &"return")
		return

	_travel_left -= delta
	if guard.move_toward_point(_target) or _travel_left <= 0.0:
		guard.velocity = Vector2.ZERO
		_waiting = true
		_wait_left = guard.investigate_wait
		guard.play_idle()
