class_name Guard
extends CharacterBody2D

signal player_caught
signal distracted

enum Axis { HORIZONTAL, VERTICAL }

@export_group("Patrulha")
@export var patrol_axis: Axis = Axis.VERTICAL
@export var speed: float = 40.0
@export var patrol_range: float = 64.0
@export var turn_wait: float = 1.5

@export_group("Investigação")
@export var hearing_radius: float = 150.0
@export var investigate_wait: float = 2.5
@export var arrive_threshold: float = 12.0

@export_group("Visão")
@export var vision_distance: float = 105.0
@export_range(10.0, 170.0) var vision_angle_deg: float = 45.0
@export_flags_2d_physics var wall_mask: int = 1

const SPEED: float = 40.0

var spawn_position := Vector2.ZERO
var patrol_dir := Vector2.DOWN
var facing := Vector2.DOWN
var facing_name: StringName = &"down"
var target: Node2D = null

var investigate_target := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_pivot: Node2D = $VisionPivot
@onready var state_machine: StateMachine = $StateMachine

var _cos_half := 0.0
var _query := PhysicsRayQueryParameters2D.new()


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	spawn_position = global_position
	add_to_group(&"guards")
	add_to_group(&"gameplay")

	_cos_half = cos(deg_to_rad(vision_angle_deg) * 0.5)
	_query.collision_mask = wall_mask
	_query.exclude = [get_rid()]

	var old_area := get_node_or_null("VisionPivot/Area2D")
	if old_area != null:
		old_area.queue_free()

	patrol_dir = random_patrol_dir()
	set_facing(patrol_dir)


func _physics_process(_delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group(&"player") as Node2D
	if target != null and _can_see(target):
		_on_player_seen()


func random_patrol_dir() -> Vector2:
	var base := Vector2.RIGHT if patrol_axis == Axis.HORIZONTAL else Vector2.DOWN
	return base if randf() < 0.5 else -base


func flip_direction() -> void:
	patrol_dir = -patrol_dir
	set_facing(patrol_dir)


func set_facing(dir: Vector2) -> void:
	if dir.is_zero_approx():
		return
	facing = dir.normalized()
	facing_name = Facing.from_vector(facing, facing_name)
	vision_pivot.rotation = facing.angle()


func get_cardinal_direction() -> String:
	return String(facing_name)


func play_walk() -> void:
	Facing.play(sprite, &"walk", facing_name)


func play_idle() -> void:
	Facing.play(sprite, &"idle", facing_name)


func move_toward_point(point: Vector2) -> bool:
	var to_point := point - global_position
	if to_point.length() <= arrive_threshold:
		velocity = Vector2.ZERO
		return true
	var dir := to_point.normalized()
	velocity = dir * speed
	move_and_slide()
	set_facing(dir)
	play_walk()
	return false


func hear_noise(pos: Vector2) -> void:
	if not _in_state(&"Patrol") and not _in_state(&"Wait"):
		return
	if global_position.distance_to(pos) > hearing_radius:
		return
	investigate_target = pos
	force_state(&"investigate")
	distracted.emit()


func set_active(active: bool) -> void:
	velocity = Vector2.ZERO
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if not active:
		sprite.pause()


func force_state(state_name: StringName) -> void:
	if state_machine.current_state != null:
		state_machine.on_child_transitioned(state_machine.current_state, state_name)


func _in_state(node_name: StringName) -> bool:
	return state_machine.current_state != null and state_machine.current_state.name == node_name


func _can_see(body: Node2D) -> bool:
	var to_target := body.global_position - global_position
	var dist_sq := to_target.length_squared()
	if dist_sq > vision_distance * vision_distance:
		return false
	if dist_sq > 1.0 and facing.dot(to_target / sqrt(dist_sq)) < _cos_half:
		return false
	_query.from = global_position
	_query.to = body.global_position
	var hit := get_world_2d().direct_space_state.intersect_ray(_query)
	return hit.is_empty() or hit.collider == body


func _on_player_seen() -> void:
	if _in_state(&"Capture"):
		return
	force_state(&"capture")
