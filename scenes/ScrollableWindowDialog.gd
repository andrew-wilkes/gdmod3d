extends PopupPanel

const MARGIN = 10

@export_multiline var dialogue_text: String:
	set(value):
		set_dialogue_text(value)

func set_dialogue_text(txt):
	$VBox/SC/Dialog.text = txt.c_unescape()


func _on_ok_pressed() -> void:
	hide()


func _on_size_changed() -> void:
	$VBox.position = Vector2(MARGIN, MARGIN)
	$VBox.size = size - 2 * Vector2i(MARGIN, MARGIN)
