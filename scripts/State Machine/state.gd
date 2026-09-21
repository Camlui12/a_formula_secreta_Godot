class_name State
extends Node

@warning_ignore("unused_signal")
signal transicionado(estado: State,novo_estado: StringName)

var entidade: CharacterBody2D
var sprite_anim: AnimatedSprite2D

func entrar() -> void:
	pass

func sair() -> void:
	pass

func lidar_input(_event: InputEvent) -> void:
	pass

func atualizar(_delta: float) -> void:
	pass

func atualizar_fisica(_delta: float) -> void:
	pass
