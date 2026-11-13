class_name Facing
extends RefCounted

const ANIMS := {
	&"walk": {&"up": &"walk_up", &"down": &"walk_down", &"left": &"walk_left", &"right": &"walk_right"},
	&"idle": {&"up": &"idle_up", &"down": &"idle_down", &"left": &"idle_left", &"right": &"idle_right"},
}


static func from_vector(v: Vector2, fallback: StringName = &"down") -> StringName:
	if v.is_zero_approx():
		return fallback
	if absf(v.x) >= absf(v.y):
		return &"right" if v.x > 0.0 else &"left"
	return &"down" if v.y > 0.0 else &"up"


static func play(sprite: AnimatedSprite2D, prefix: StringName, dir: StringName) -> void:
	if sprite == null:
		return
	var anim: StringName = ANIMS[prefix][dir]
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)
