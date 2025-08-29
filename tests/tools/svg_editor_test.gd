# GdUnit generated TestSuite
class_name SvgEditorTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://tools/svg_editor.gd'


func test_get_main_loop() -> void:
	var ed = SVG_Editor.new()
	var l1 = ed.Loop.new()
	var l2 = ed.Loop.new()
	# Clockwise
	l1.points = [Vector2(0,0), Vector2(0,10), Vector2(10,10), Vector2(10,0)]
	l2.points = [Vector2(1,1), Vector2(1,2), Vector2(2,2), Vector2(2,1)]
	l1.rect = Helpers.rect_from_points(l1.points)
	l2.rect = Helpers.rect_from_points(l2.points)
	# l1 contains l2
	ed.loops = [l1, l2]
	var loop = ed.get_main_loop()
	assert_bool(loop.outer).is_true()
	ed.free()


func test_get_main_loop2() -> void:
	var ed = SVG_Editor.new()
	var l1 = ed.Loop.new()
	var l2 = ed.Loop.new()
	# Clockwise
	l1.points = [Vector2(0,0), Vector2(0,10), Vector2(10,10), Vector2(10,0)]
	l2.points = [Vector2(1,1), Vector2(1,2), Vector2(2,2), Vector2(2,1)]
	l1.rect = Helpers.rect_from_points(l1.points)
	l2.rect = Helpers.rect_from_points(l2.points)
	# l1 contains l2
	ed.loops = [l2, l1]
	var loop = ed.get_main_loop()
	assert_bool(loop.outer).is_true()
	print(loop.points)
	ed.free()
