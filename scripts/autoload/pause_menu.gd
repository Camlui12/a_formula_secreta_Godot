extends CanvasLayer

const MENU_BOX := preload("res://assets/sprites/menu_box.png")

var _root: Control
var _first_button: Button
var _message: Label
var _message_timer: SceneTreeTimer
var _options_open := false


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.hide()


func _unhandled_input(event: InputEvent) -> void:
	if _options_open or not event.is_action_pressed(&"pause"):
		return
	if _root.visible:
		close()
	elif GameManager.can_pause and GameManager.gameplay_active:
		open()
	else:
		return
	get_viewport().set_input_as_handled()


func open() -> void:
	_message.text = ""
	_root.show()
	get_tree().paused = true
	_first_button.grab_focus()


func close() -> void:
	_root.hide()
	get_tree().paused = false


func _on_save() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player == null:
		return
	SaveManager.save_game(get_tree().current_scene.scene_file_path, player.global_position, player.current_health)
	_message.text = "Jogo salvo!"
	_message_timer = get_tree().create_timer(1.5, true)
	var timer := _message_timer
	await timer.timeout
	if timer == _message_timer:
		_message.text = ""


func _on_options() -> void:
	_options_open = true
	await OptionsMenu.open(self)
	_options_open = false
	_first_button.grab_focus()


func _on_quit() -> void:
	close()
	MusicManager.stop_all(0.5)
	GameManager.go_to_menu()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var box := TextureRect.new()
	box.texture = MENU_BOX
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	center.add_child(box)

	var list := VBoxContainer.new()
	list.alignment = BoxContainer.ALIGNMENT_CENTER
	list.add_theme_constant_override(&"separation", -6)
	list.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(list)

	var title := UIKit.make_label("PAUSADO")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(title)

	_first_button = _add_button(list, "Continuar", close)
	_add_button(list, "Salvar", _on_save)
	_add_button(list, "Opções", _on_options)
	_add_button(list, "Sair", _on_quit)

	_message = UIKit.make_label("", UIKit.DEFAULT_SIZE, Color(0.0, 1.0, 0.53))
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(_message)


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := UIKit.make_text_button(text)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
