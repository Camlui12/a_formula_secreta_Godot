class_name IdleState
extends State

func entrar() -> void:
	entidade.velocity = Vector2.ZERO
	sprite_anim.play("idle_" + (entidade as Player).obter_direcao_cardinal())
	
func atualizar_fisica(_delta: float) -> void:
	var dir := (entidade as Player).capturar_direcao_entrada()
	if dir != Vector2.ZERO:
		transicionado.emit(self, &"walk")
