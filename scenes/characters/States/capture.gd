class_name GuardCaptureState
extends State

const REACH_DISTANCE := 18.0
const MAX_CHASE_TIME := 2.0

@onready var guard: Guard = owner

var _done := false
var _time_left := 0.0


func enter() -> void:
	_done = false
	_time_left = MAX_CHASE_TIME
	guard.velocity = Vector2.ZERO
	guard.vision_pivot.hide()
	GameManager.can_pause = false
	var player := guard.target as Player
	if player != null:
		player.set_active(false)


func physics_update(delta: float) -> void:
	if _done or guard.target == null:
		return
	_time_left -= delta
	var to_player := guard.target.global_position - guard.global_position
	if to_player.length() > REACH_DISTANCE and _time_left > 0.0:
		guard.move_toward_point(guard.target.global_position)
		return
	guard.velocity = Vector2.ZERO
	guard.set_facing(to_player)
	guard.play_idle()
	_done = true
	guard.player_caught.emit()
