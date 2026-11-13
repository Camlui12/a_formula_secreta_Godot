class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	await owner.ready

	var entity = owner as CharacterBody2D
	var sprite_anim = owner.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.entity = entity
			child.sprite_anim = sprite_anim
			child.transitioned.connect(on_child_transitioned)

	if initial_state:
		current_state = initial_state
		current_state.enter()

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func on_child_transitioned(state: State, new_state_name: StringName) -> void:
	if state != current_state:
		return

	var new_state: State = states.get(new_state_name.to_lower())
	if not new_state:
		push_warning("State does not exist: %s" % new_state_name)
		return

	if new_state == current_state:
		return

	current_state.exit()
	current_state = new_state
	new_state.enter()
