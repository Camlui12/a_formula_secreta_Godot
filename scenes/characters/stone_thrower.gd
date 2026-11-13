class_name StoneThrower
extends Node2D

const STONE_SCENE := preload("res://scenes/objects/stone.tscn")

@export var collect_radius: float = 40.0
@export var max_throw_distance: float = 200.0
@export var throw_speed: float = 280.0
@export var throw_cooldown: float = 0.4
@export_flags_2d_physics var wall_mask: int = 1
@export var dot_spacing: float = 14.0
@export var dot_radius: float = 2.5

@onready var _player: Player = get_parent()

var _aiming := false
var _aim_end := Vector2.ZERO
var _cooldown := 0.0
var _scan_timer := 0.0
var _nearest: Stone
var _query := PhysicsRayQueryParameters2D.new()


func _ready() -> void:
	_query.collision_mask = wall_mask
	z_as_relative = false
	z_index = 50


func _unhandled_input(event: InputEvent) -> void:
	if _player.frozen:
		return
	if event.is_action_pressed(&"interact"):
		_try_collect()
	elif event.is_action_pressed(&"throw"):
		if _player.stones_carried > 0:
			_set_aiming(true)
	elif event.is_action_released(&"throw"):
		if _aiming:
			_release_throw()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)

	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = 0.1
		_refresh_nearest()

	if _aiming:
		if _player.frozen:
			_set_aiming(false)
		else:
			_update_aim()


func _try_collect() -> void:
	_refresh_nearest()
	if _nearest != null and _player.collect_stone():
		_nearest.collect()
		_nearest = null


func _release_throw() -> void:
	_set_aiming(false)
	if _cooldown > 0.0 or not _player.consume_stone():
		return
	var target := _compute_target()
	var stone := STONE_SCENE.instantiate() as Stone
	stone.phase = Stone.Phase.FLYING
	get_tree().current_scene.add_child(stone)
	stone.global_position = _player.global_position
	stone.throw_to(target, throw_speed)
	_cooldown = throw_cooldown


func _set_aiming(on: bool) -> void:
	_aiming = on
	if on:
		_aim_end = Vector2.INF
		_update_aim()
	else:
		queue_redraw()


func _compute_target() -> Vector2:
	var from := _player.global_position
	var to := from + _player.facing_direction * max_throw_distance
	_query.from = from
	_query.to = to
	_query.exclude = [_player.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(_query)
	if hit.is_empty():
		return to
	return hit.position - _player.facing_direction * 2.0


func _update_aim() -> void:
	var end := _compute_target()
	if not end.is_equal_approx(_aim_end):
		_aim_end = end
		queue_redraw()


func _refresh_nearest() -> void:
	var best: Stone = null
	var best_dist := collect_radius * collect_radius
	for node in get_tree().get_nodes_in_group(&"ground_stones"):
		var dist := _player.global_position.distance_squared_to((node as Node2D).global_position)
		if dist <= best_dist:
			best_dist = dist
			best = node as Stone
	if best == _nearest:
		return
	if is_instance_valid(_nearest):
		_nearest.show_prompt(false)
	_nearest = best
	if _nearest != null:
		_nearest.show_prompt(true)


func _draw() -> void:
	if not _aiming:
		return
	var start := to_local(_player.global_position)
	var end := to_local(_aim_end)
	var total := start.distance_to(end)
	var dir := start.direction_to(end)
	var d := dot_spacing
	while d < total:
		draw_circle(start + dir * d, dot_radius, Color(1, 1, 1, 1.0 - (d / max_throw_distance) * 0.6))
		d += dot_spacing
	draw_circle(end, 4.0, Color(1.0, 0.867, 0.533, 0.8))
