extends CanvasLayer

@onready var ui_dialog = $uiDialog
@onready var txt_dialog = $uiDialog/MarginContainer/txtDialog

signal dialogue_finished

var dialogue_lines: Array[String] = []
var current_line: int = 0
var is_typing: bool = false
var text_tween: Tween

const MAX_CHARS_PER_PAGE: int = 75

func _ready() -> void:
	ui_dialog.hide()

func show_custom_dialogue(lines: Array[String]) -> void:
	var final_pages: Array[String] = []
	for line in lines:
		var pages = paginate_text(line)
		final_pages.append_array(pages)
		
	dialogue_lines = final_pages
	current_line = 0
	ui_dialog.show()
	show_text()

func show_auto_dialogue(full_text: String) -> void:
	dialogue_lines = paginate_text(full_text)
	current_line = 0
	ui_dialog.show()
	show_text()

func show_text() -> void:
	if current_line >= dialogue_lines.size():
		ui_dialog.hide()
		dialogue_finished.emit()
		return
		
	txt_dialog.text = dialogue_lines[current_line]
	txt_dialog.visible_characters = 0
	is_typing = true
	
	if text_tween and text_tween.is_running():
		text_tween.kill()
		
	text_tween = create_tween()
	var text_length = txt_dialog.get_total_character_count()
	var duration = text_length * 0.035
	
	text_tween.tween_property(txt_dialog, "visible_characters", text_length, duration)
	text_tween.finished.connect(on_typing_finished)

func on_typing_finished() -> void:
	is_typing = false

func _input(event: InputEvent) -> void:
	if not ui_dialog.visible:
		return

	var is_confirm = event.is_action_pressed("ui_accept") or (
		event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	)
	
	if is_confirm:
		if is_typing:
			if text_tween and text_tween.is_running():
				text_tween.kill()
			txt_dialog.visible_characters = -1
			is_typing = false
		else:
			current_line += 1
			show_text()

func paginate_text(text: String) -> Array[String]:
	var pages: Array[String] = []
	var words = text.split(" ")
	var current_page: String = ""

	for word in words:
		if word.strip_edges() == "":
			continue

		if word.length() > MAX_CHARS_PER_PAGE:
			if current_page != "":
				pages.append(current_page.strip_edges())
				current_page = ""
			# Divide apenas palavras gigantes anormais em blocos
			while word.length() > MAX_CHARS_PER_PAGE:
				pages.append(word.substr(0, MAX_CHARS_PER_PAGE))
				word = word.substr(MAX_CHARS_PER_PAGE)
			current_page = word
			continue

		if (current_page.length() + word.length() + 1) > MAX_CHARS_PER_PAGE:
			if current_page != "":
				pages.append(current_page.strip_edges())
			current_page = word
		else:
			if current_page == "":
				current_page = word
			else:
				current_page += " " + word

	if current_page.strip_edges() != "":
		pages.append(current_page.strip_edges())

	return pages
