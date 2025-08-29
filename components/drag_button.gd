extends TextureRect

class_name DragButton

# The highlight does not occur exactly on the perimiter of the circle for this small radius

signal pressed

@export var is_drag_button = true

var drag_controller: DragController
var radius: float

func _ready() -> void:
	gui_input.connect(handle_gui_input)
	mouse_exited.connect(handle_mouse_out)
	radius = size.x / 2.0
	drag_controller = DragController.new(self, radius)
	add_child(drag_controller)


func dragged_event(amount: Vector2):
	prints("Dragged by", amount)


func handle_gui_input(event: InputEvent):
	# Respond to entry to circle
	if Helpers.inside_circle(self, radius):
		if event is InputEventMouseMotion:
			material.set_shader_parameter("highlight", 0.3)
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			pressed.emit()


func handle_mouse_out() -> void:
	if !drag_controller.dragging:
		material.set_shader_parameter("highlight", 0.0)
