extends Area2D

const REVEAL_SOUND := preload("res://assets/audio/burning.wav")

@export var damage: int = 1
@export var knockback: bool = true
@export var slow: bool = true
@export var anim_fps: float = 8.0
@export var hidden_until_near: bool = false
@export var reveal_radius: float = 48.0
@export var reveal_sound_db: float = -6.0

const HALF_TILE := 16.0

@onready var sprite: AnimatedSprite2D = $FireSprite

var _player: Player
var _base_scale := Vector2.ONE


func _ready() -> void:
	set_physics_process(false)
	_base_scale = sprite.scale
	var frames := sprite.sprite_frames
	sprite.speed_scale = anim_fps / maxf(frames.get_animation_speed(&"default"), 0.01)
	sprite.play(&"default")
	sprite.set_frame_and_progress(randi() % frames.get_frame_count(&"default"), randf())
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if hidden_until_near:
		_setup_reveal()


func _physics_process(_delta: float) -> void:
	var offset := _player.global_position - global_position
	if absf(offset.x) < HALF_TILE and absf(offset.y) < HALF_TILE:
		_player.take_damage(damage, knockback, slow)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player = body as Player
		set_physics_process(true)


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		set_physics_process(false)


func _setup_reveal() -> void:
	sprite.visible = false
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = collision_mask
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = reveal_radius
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_reveal_body_entered.bind(area))


func _on_reveal_body_entered(body: Node2D, area: Area2D) -> void:
	if not body is Player:
		return
	area.queue_free()
	_burst()


func _burst() -> void:
	sprite.visible = true
	sprite.scale = _base_scale * 0.2
	sprite.modulate = Color(2.5, 2.0, 1.2)
	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale", _base_scale * 1.35, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.4)
	tween.chain().tween_property(sprite, "scale", _base_scale, 0.15) \
		.set_trans(Tween.TRANS_SINE)
	_play_reveal_sound()


func _play_reveal_sound() -> void:
	var player := AudioStreamPlayer2D.new()
	player.stream = REVEAL_SOUND
	player.bus = &"SFX"
	player.volume_db = reveal_sound_db
	add_child(player)
	player.play()
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(player, "volume_db", -40.0, 0.6)
	tween.tween_callback(player.queue_free)
