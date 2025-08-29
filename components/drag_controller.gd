class_name DragController

extends Node

signal dragged(amount: Vector2)

@export var distance_factor = 50.0

var dragging := false
var return_position: Vector2
var start_drag_position: Vector2
var last_rel_pos: Vector2
var _radius: float
var _parent: CanvasItem

func _init(parent: CanvasItem, radius: float):
	_radius = radius
	_parent = parent


func _input(event):
	if event is InputEventMouseButton and not event.is_pressed() and dragging:
		dragging = false
		Input.warp_mouse(return_position)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if dragging:
			var new_rel_pos = get_viewport().get_mouse_position() - start_drag_position
			var amount = (new_rel_pos - last_rel_pos) / distance_factor
			dragged.emit(amount)
			last_rel_pos = new_rel_pos
			get_viewport().set_input_as_handled()
		else:
			if Helpers.inside_circle(_parent, _radius):
				dragging = true
				Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
				return_position = get_viewport().get_mouse_position()
				last_rel_pos = Vector2.ZERO
				start_drag_position = get_viewport().get_window().size / 2.0
				# Allow for maximum range of movement
				Input.warp_mouse(start_drag_position)
