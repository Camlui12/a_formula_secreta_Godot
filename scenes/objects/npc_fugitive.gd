class_name NpcFugitive
extends CharacterBody2D

const WALK_FRAMES := [0, 1, 2, 1]
const ROWS := {&"down": 0, &"left": 1, &"right": 2, &"up": 3}

@export var max_speed: float = 100.0
@export var min_speed: float = 30.0
@export var world_bounds: Rect2 = Rect2(0, 0, 1952, 1120)
@export var anim_fps: float = 6.0

@onready var sprite: Sprite2D = $Sprite2D

var _anim_time := 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group(&"gameplay")
	velocity = Vector2(randf_range(-max_speed, max_speed), randf_range(-max_speed, max_speed))
	if velocity.length() < min_speed:
		velocity = Vector2.from_angle(randf() * TAU) * min_speed
	_anim_time = randf()


func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision != null:
		velocity = velocity.bounce(collision.get_normal())

	var pos := global_position
	if (pos.x < world_bounds.position.x and velocity.x < 0.0) or (pos.x > world_bounds.end.x and velocity.x > 0.0):
		velocity.x = -velocity.x
	if (pos.y < world_bounds.position.y and velocity.y < 0.0) or (pos.y > world_bounds.end.y and velocity.y > 0.0):
		velocity.y = -velocity.y

	_anim_time += delta
	var row: int = ROWS[Facing.from_vector(velocity)]
	sprite.frame = row * 3 + WALK_FRAMES[int(_anim_time * anim_fps) % WALK_FRAMES.size()]


func set_active(active: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
