class_name UIKit
extends RefCounted

const FONT := preload("res://assets/fonts/Silver.ttf")
const DEFAULT_SIZE := 19


static func apply_font(control: Control, size: int = DEFAULT_SIZE) -> void:
	control.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	control.add_theme_font_override(&"font", FONT)
	control.add_theme_font_size_override(&"font_size", size)


static func make_label(text: String, size: int = DEFAULT_SIZE, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	apply_font(label, size)
	label.add_theme_color_override(&"font_color", color)
	return label


static func make_text_button(text: String, size: int = DEFAULT_SIZE) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	apply_font(button, size)
	button.add_theme_color_override(&"font_color", Color(0.67, 0.67, 0.67))
	button.add_theme_color_override(&"font_focus_color", Color.WHITE)
	button.add_theme_color_override(&"font_hover_color", Color.WHITE)
	button.add_theme_color_override(&"font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	button.mouse_entered.connect(button.grab_focus)
	return button
