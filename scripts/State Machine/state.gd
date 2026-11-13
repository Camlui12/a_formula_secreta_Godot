class_name State
extends Node

signal transitioned(state: State, new_state_name: StringName)

var entity: CharacterBody2D
var sprite_anim: AnimatedSprite2D

func enter() -> void:
	pass

func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
