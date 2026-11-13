class_name OptionsMenu
extends CanvasLayer

signal closed

const VOLUME_STEP := 0.1

var _first_focus: Control
var _voice_button: Button
var _fullscreen_button: Button


static func open(host: Node) -> void:
	var menu := OptionsMenu.new()
	host.get_tree().root.add_child(menu)
	await menu.closed
	menu.queue_free()


func _ready() -> void:
	layer = 130
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.07, 0.06, 0.95)
	style.border_color = Color(0.55, 0.42, 0.3)
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override(&"panel", style)
	center.add_child(panel)

	var list := VBoxContainer.new()
	list.add_theme_constant_override(&"separation", -3)
	panel.add_child(list)

	var title := UIKit.make_label("OPÇÕES")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(title)

	_first_focus = _add_volume_row(list, "Volume geral", GameManager.master_volume,
		func(v: float) -> void: GameManager.master_volume = v)
	_add_volume_row(list, "Música", GameManager.music_volume,
		func(v: float) -> void: GameManager.music_volume = v)
	_add_volume_row(list, "Efeitos", GameManager.sfx_volume,
		func(v: float) -> void: GameManager.sfx_volume = v)

	_voice_button = _add_button(list, "", _toggle_voice)
	_fullscreen_button = _add_button(list, "", _toggle_fullscreen)
	_add_button(list, "Voltar", _close)
	_refresh_toggles()

	_first_focus.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	GameManager.save_settings()
	closed.emit()


func _toggle_voice() -> void:
	GameManager.voice_enabled = not GameManager.voice_enabled
	GameManager.apply_settings()
	_refresh_toggles()


func _toggle_fullscreen() -> void:
	GameManager.fullscreen = not GameManager.fullscreen
	GameManager.apply_settings()
	_refresh_toggles()


func _refresh_toggles() -> void:
	_voice_button.text = "Voz do narrador: %s" % ("Ligada" if GameManager.voice_enabled else "Desligada")
	_fullscreen_button.text = "Tela cheia: %s" % ("Sim" if GameManager.fullscreen else "Não")


func _add_volume_row(parent: Control, text: String, value: float, setter: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	parent.add_child(row)

	var name_label := UIKit.make_label(text)
	name_label.custom_minimum_size.x = 72
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = VOLUME_STEP
	slider.value = value
	slider.custom_minimum_size = Vector2(70, 10)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_slider(slider)
	row.add_child(slider)

	var value_label := UIKit.make_label("%d%%" % roundi(value * 100.0))
	value_label.custom_minimum_size.x = 30
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	var on_changed := func(v: float) -> void:
		setter.call(v)
		GameManager.apply_settings()
		value_label.text = "%d%%" % roundi(v * 100.0)
	slider.value_changed.connect(on_changed)
	name_label.modulate = Color(0.67, 0.67, 0.67)
	slider.focus_entered.connect(func() -> void: name_label.modulate = Color.WHITE)
	slider.focus_exited.connect(func() -> void: name_label.modulate = Color(0.67, 0.67, 0.67))
	slider.mouse_entered.connect(slider.grab_focus)
	return slider


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := UIKit.make_text_button(text)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.3, 0.25, 0.2)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var filled := StyleBoxFlat.new()
	filled.bg_color = Color(0.85, 0.65, 0.35)
	filled.content_margin_top = 2
	filled.content_margin_bottom = 2
	slider.add_theme_stylebox_override(&"slider", track)
	slider.add_theme_stylebox_override(&"grabber_area", filled)
	slider.add_theme_stylebox_override(&"grabber_area_highlight", filled)
	slider.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())

	var image := Image.create(4, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var grabber := ImageTexture.create_from_image(image)
	var highlight_image := Image.create(4, 8, false, Image.FORMAT_RGBA8)
	highlight_image.fill(Color(1.0, 0.87, 0.53))
	var grabber_highlight := ImageTexture.create_from_image(highlight_image)
	slider.add_theme_icon_override(&"grabber", grabber)
	slider.add_theme_icon_override(&"grabber_highlight", grabber_highlight)
