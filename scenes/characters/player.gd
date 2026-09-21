class_name Player
extends CharacterBody2D

@export var speed = 60.0

var direcao_apontada: Vector2 = Vector2.DOWN

func capturar_direcao_entrada() -> Vector2:
	var direcao := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direcao == Vector2.ZERO:
		return Vector2.ZERO
	if abs(direcao.x) >= abs(direcao.y):
		direcao = Vector2(sign(direcao.x), 0.0)
	else:
		direcao = Vector2(0.0, sign(direcao.y))
	
	direcao_apontada = direcao
	return direcao


func obter_direcao_cardinal() -> String:
	match direcao_apontada:
		Vector2.UP: return "up"
		Vector2.DOWN: return "down"
		Vector2.LEFT: return "left"
		Vector2.RIGHT: return "right"
		_: return "down"
