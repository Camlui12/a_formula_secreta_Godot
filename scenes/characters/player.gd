extends CharacterBody2D
const SPEED = 150.0
@onready var anim = $AnimatedSprite2D

var last_direction = "down"

func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = direction * SPEED
	move_and_slide()
	
	if direction != Vector2.ZERO:
		if direction.x > 0:
			anim.play("walk_right")
			last_direction = "right"
		elif direction.x < 0:
			anim.play("walk_left")
			last_direction = "left"
		elif direction.y > 0:
			anim.play("walk_down")
			last_direction = "down"
		elif direction.y < 0:
			anim.play("walk_up")
			last_direction = "up"
	else:
		anim.play("idle_" + last_direction)
