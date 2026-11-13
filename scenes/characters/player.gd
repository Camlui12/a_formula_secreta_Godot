class_name Player
extends CharacterBody2D

signal health_changed(current_health: int)
signal stones_changed(count: int)
signal died

@export var speed: float = 75.0
@export var max_health: int = 6
@export var max_stones: int = 3

@export_group("Dano")
@export var invulnerability_time: float = 1.0
@export var knockback_speed: float = 150.0
@export var knockback_time: float = 0.18
@export_range(0.1, 1.0) var slow_multiplier: float = 0.5
@export var slow_time: float = 0.5

var facing_direction: Vector2 = Vector2.DOWN
var facing_name: StringName = &"down"
var current_health: int = 0
var stones_carried: int = 0
var speed_multiplier: float = 1.0
var is_invulnerable := false
var is_dead := false
var frozen := false

var knockback_direction := Vector2.ZERO
var slow_after_knockback := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: StateMachine = $StateMachine

var _invulnerability_timer: Timer
var _slow_timer: Timer
var _flash_tween: Tween


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	current_health = max_health
	add_to_group(&"player")
	add_to_group(&"gameplay")
	_invulnerability_timer = _make_timer(func(): is_invulnerable = false)
	_slow_timer = _make_timer(func(): speed_multiplier = 1.0)


func get_movement_input() -> Vector2:
	if frozen:
		return Vector2.ZERO
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if direction.is_zero_approx():
		return Vector2.ZERO
	if absf(direction.x) >= absf(direction.y):
		direction = Vector2(signf(direction.x), 0.0)
	else:
		direction = Vector2(0.0, signf(direction.y))
	facing_direction = direction
	facing_name = Facing.from_vector(direction, facing_name)
	return direction


func get_cardinal_direction() -> String:
	return String(facing_name)


func get_current_speed() -> float:
	return speed * speed_multiplier


func take_damage(amount: int, with_knockback: bool = false, with_slow: bool = false) -> void:
	if is_invulnerable or is_dead or frozen:
		return

	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health)
	_flash_red()

	if current_health == 0:
		_die()
		return

	is_invulnerable = true
	_invulnerability_timer.start(invulnerability_time)

	if with_knockback:
		knockback_direction = -facing_direction
		slow_after_knockback = with_slow
		force_state(&"hurt")
	elif with_slow:
		apply_slow()


func apply_slow() -> void:
	speed_multiplier = slow_multiplier
	_slow_timer.start(slow_time)


func set_active(active: bool) -> void:
	frozen = not active
	if frozen:
		velocity = Vector2.ZERO
		force_state(&"idle")


func force_state(state_name: StringName) -> void:
	if state_machine.current_state != null:
		state_machine.on_child_transitioned(state_machine.current_state, state_name)


func collect_stone() -> bool:
	if stones_carried >= max_stones:
		return false
	stones_carried += 1
	stones_changed.emit(stones_carried)
	return true


func consume_stone() -> bool:
	if stones_carried <= 0:
		return false
	stones_carried -= 1
	stones_changed.emit(stones_carried)
	return true


func restore(health: int, pos: Vector2) -> void:
	current_health = clampi(health, 1, max_health)
	global_position = pos
	health_changed.emit(current_health)


func _die() -> void:
	is_dead = true
	set_active(false)
	sprite.modulate = Color(1.0, 0.3, 0.3)
	died.emit()


func _flash_red() -> void:
	if _flash_tween != null:
		_flash_tween.kill()
	sprite.modulate = Color(1.0, 0.25, 0.25)
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _make_timer(on_timeout: Callable) -> Timer:
	var timer := Timer.new()
	timer.one_shot = true
	timer.timeout.connect(on_timeout)
	add_child(timer)
	return timer
