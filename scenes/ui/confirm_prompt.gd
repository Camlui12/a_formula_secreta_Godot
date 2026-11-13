class_name ConfirmPrompt
extends CanvasLayer

signal answered(accepted: bool)

const BOX := preload("res://assets/sprites/confirm_box.png")

var message := ""
var _no_button: Button


static func ask(host: Node, text: String) -> bool:
	var prompt := ConfirmPrompt.new()
	prompt.message = text
	host.add_child(prompt)
	var accepted: bool = await prompt.answered
	prompt.queue_free()
	return accepted


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := TextureRect.new()
	box.texture = BOX
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	center.add_child(box)

	var list := VBoxContainer.new()
	list.alignment = BoxContainer.ALIGNMENT_CENTER
	list.add_theme_constant_override(&"separation", -4)
	list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(list)

	var label := UIKit.make_label(message, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 40)
	list.add_child(row)

	var yes := UIKit.make_text_button("Sim")
	yes.pressed.connect(answered.emit.bind(true))
	row.add_child(yes)
	_no_button = UIKit.make_text_button("Não")
	_no_button.pressed.connect(answered.emit.bind(false))
	row.add_child(_no_button)
	_no_button.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		answered.emit(false)
