extends CharacterBody2D

const SPEED: float = 60.0
const WALK_TIME: float = 3.0
const WAIT_TIME: float = 1.5

var direction: float = 1.0
var is_waiting: bool = false
var state_timer: float = 0.0
var is_capturing: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_sprite: Node2D = $GuardVisionSprite
@onready var vision_area: Area2D = $Area2D

func _ready() -> void:
	state_timer = WALK_TIME
	if sprite:
		sprite.play("default")

func _physics_process(delta: float) -> void:
	if is_capturing:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	handle_patrol(delta)
	move_and_slide()

func handle_patrol(delta: float) -> void:
	if not is_waiting and is_on_wall():
		flip_direction()
		state_timer = WALK_TIME
		return

	state_timer -= delta
	if state_timer <= 0.0:
		if is_waiting:
			flip_direction()
			is_waiting = false
			state_timer = WALK_TIME
			if sprite:
				sprite.play("default")
		else:
			is_waiting = true
			state_timer = WAIT_TIME
			if sprite:
				sprite.stop()

	if is_waiting:
		velocity = Vector2.ZERO
	else:
		velocity = Vector2(direction * SPEED, 0.0)

func flip_direction() -> void:
	direction *= -1.0
	
	if sprite:
		sprite.flip_h = (direction < 0.0)
	
	if vision_sprite:
		vision_sprite.scale.x = direction
		
	if vision_area:
		vision_area.scale.x = direction

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("Player"):
		start_capture(body)

func start_capture(target: Node2D) -> void:
	if is_capturing:
		return
		
	is_capturing = true
	velocity = Vector2.ZERO
	
	if vision_sprite:
		vision_sprite.hide()
		
	target.set_physics_process(false)
	if target.has_node("AnimatedSprite2D"):
		target.get_node("AnimatedSprite2D").stop()
		
	DialogueManager.show_auto_dialogue("Parado aí!")
