class_name  WalkState
extends State

func atualizar_fisica(_delta: float) -> void:
	var player := entidade as Player
	var dir := player.capturar_direcao_entrada()
	
	if dir == Vector2.ZERO:
		transicionado.emit(self, &"idle")
		return
	
	player.velocity = dir.normalized() * player.speed
	player.move_and_slide()
	
	sprite_anim.play("walk_" + player.obter_direcao_cardinal())
