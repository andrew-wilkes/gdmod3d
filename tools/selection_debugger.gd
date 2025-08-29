extends Node2D

class_name SelectionDebugger

var mouse_position: Vector2
var line: Line2D
var num_points = 0

func update(mouse_position_: Vector2) -> void:
	mouse_position = mouse_position_
	num_points = 0
	line = $Line
	for idx in get_child_count():
		if idx > 1:
			get_child(idx).queue_free()


func add_point(vertex: Vector2, _idx: int):
	if num_points > 0:
		line = line.duplicate()
		add_child(line)
	num_points += 1
	line.clear_points()
	line.add_point(vertex)
	line.add_point(mouse_position)
