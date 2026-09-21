class_name StateMachine
extends Node

@export var estado_inicial: State

var estado_atual: State
var estados: Dictionary = {}

func _ready() -> void:
	await owner.ready

	var entidade = owner as CharacterBody2D
	var sprite_anim = owner.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	for child in get_children():
		if child is State:
			estados[child.name.to_lower()] = child
			child.entidade = entidade
			child.sprite_anim = sprite_anim
			child.transicionado.connect(on_child_transitioned)

	if estado_inicial:
		estado_atual = estado_inicial
		estado_atual.entrar()

func _unhandled_input(event: InputEvent) -> void:
	if estado_atual:
		estado_atual.lidar_input(event)

func _process(delta: float) -> void:
	if estado_atual:
		estado_atual.atualizar(delta)

func _physics_process(delta: float) -> void:
	if estado_atual:
		estado_atual.atualizar_fisica(delta)

func on_child_transitioned(estado: State, novo_estado_nome: StringName) -> void:
	if estado != estado_atual:
		return

	var novo_estado: State = estados.get(novo_estado_nome.to_lower())
	if not novo_estado:
		push_warning("Estado Inexistente: %s" % novo_estado_nome)
		return

	if novo_estado == estado_atual:
		return

	estado_atual.sair()
	estado_atual = novo_estado
	novo_estado.entrar()
