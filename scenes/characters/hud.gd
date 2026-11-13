extends CanvasLayer

const STONE_ICON := preload("res://assets/sprites/stone.png")

@onready var player: Player = get_parent()
@onready var hearts = [
	$HeartContainer/Slot1/Heart1,
	$HeartContainer/Slot2/Heart2,
	$HeartContainer/Slot3/Heart3,
]

var _stone_box: HBoxContainer
var _stone_label: Label
var _throw_prompt: Label


func _ready() -> void:
	_build_stone_ui()
	player.health_changed.connect(update_hearts)
	player.stones_changed.connect(_on_stones_changed)
	if not player.is_node_ready():
		await player.ready
	update_hearts(player.current_health)
	_on_stones_changed(player.stones_carried)


func update_hearts(current_health: int) -> void:
	for i in hearts.size():
		var heart_health := current_health - i * 2
		var anim := &"empty"
		if heart_health >= 2:
			anim = &"full"
		elif heart_health == 1:
			anim = &"half"
		if hearts[i].animation != anim:
			hearts[i].animation = anim


func _on_stones_changed(count: int) -> void:
	_stone_box.visible = count > 0
	_throw_prompt.visible = count > 0
	_stone_label.text = "x %d" % count


func _build_stone_ui() -> void:
	_stone_box = HBoxContainer.new()
	_stone_box.position = Vector2(16, 32)
	_stone_box.add_theme_constant_override(&"separation", 4)
	var icon := TextureRect.new()
	icon.texture = STONE_ICON
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	_stone_box.add_child(icon)
	_stone_label = UIKit.make_label("x 0", UIKit.DEFAULT_SIZE, Color(0.8, 0.8, 0.8))
	_stone_box.add_child(_stone_label)
	add_child(_stone_box)

	_throw_prompt = UIKit.make_label("[F] Segure para mirar", UIKit.DEFAULT_SIZE, Color(1.0, 0.867, 0.533))
	_throw_prompt.position = Vector2(16, 52)
	add_child(_throw_prompt)
