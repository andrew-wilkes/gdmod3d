extends TextureRect

class_name ClickButton

signal pressed

const HIGHLIGHT = 0.3

func _ready() -> void:
	mouse_exited.connect(handle_mouse_out)
	mouse_entered.connect(handle_mouse_in)
	gui_input.connect(handle_gui_input)


func select():
	material.set_shader_parameter("select", HIGHLIGHT)


func deselect():
	material.set_shader_parameter("select", 0.0)


func handle_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		accept_event()
		pressed.emit()


func handle_mouse_in():
	material.set_shader_parameter("highlight", HIGHLIGHT)


func handle_mouse_out() -> void:
	material.set_shader_parameter("highlight", 0.0)
