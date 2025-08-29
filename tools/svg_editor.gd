class_name SVG_Editor
extends Node2D

const SCALE = 10.0

var svgt: SVG_Tool

func _ready() -> void:
	#draw_lines()
	svgt = SVG_Tool.new()
	draw_svg("res://assets/example.svg")


func draw_svg(file_path: String):
	svgt.load_svg(file_path)
	for loop in svgt.loops:
		draw_box(loop.rect, SCALE)
	var triangles = svgt.get_triangles()
	for idx in triangles.size():
		var ta = triangles[idx]
		if ta.active:
			draw_dot(ta.cp * SCALE)
			draw_tri([ta.a, ta.b, ta.c], SCALE)



func draw_poly(points: Array):
	var poly = Polygon2D.new()
	poly.polygon = points
	poly.color = Color.GREEN
	add_child(poly)


func draw_dot(pos: Vector2):
	var line = Line2D.new()
	line.default_color = Color.AQUA
	line.width = 4.0
	line.add_point(pos)
	pos.x += line.width
	line.add_point(pos)
	add_child(line)


func draw_box(rect: Rect2, _scale: float):
	var line: Line2D = Line2D.new()
	line.width = 2.0
	line.default_color = Color.BLUE
	var a = rect.position * _scale  * 0.998
	var b = rect.end * _scale * 1.002
	line.points = [a, Vector2(a.x, b.y), b, Vector2(b.x, a.y)]
	line.closed = true
	add_child(line)


func draw_tri(points: Array, scale_factor: float):
	for idx in points.size():
		points[idx] *= scale_factor
	var line: Line2D = Line2D.new()
	line.width = 2.0
	line.default_color = Color.RED
	line.points = points
	line.closed = true
	add_child(line)


func add_line_node(loop: SVG_Tool.Loop, scale_factor: float = 1.0, color: Color = Color.WHITE):
	for idx in loop.points.size():
		#loop.points[idx] += loop.rect.position
		loop.points[idx] *= scale_factor
	var line: Line2D = Line2D.new()
	line.width = 2.0
	line.points = loop.points
	line.closed = loop.closed
	line.default_color = color
	add_child(line)
