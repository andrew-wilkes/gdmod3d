# GdUnit generated TestSuite
class_name Triangulate2dTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://scripts/triangulate2d.gd'


func test_is_reflex() -> void:
	var tri = Triangulate2D.new()
	var vert = tri.Vertex.new()
	vert.point = Vector2(1,0)
	vert.prev = tri.Vertex.new()
	vert.prev.point = Vector2(0, 0)
	vert.next = tri.Vertex.new()
	vert.next.point = Vector2(-3, -3)
	assert_bool(tri.is_reflex(vert)).is_true()
	vert.next.point = Vector2(-3, 1.5)
	assert_bool(tri.is_reflex(vert)).is_false()


func test_empty_triangle() -> void:
	var tri = Triangulate2D.new()
	var vert = tri.Vertex.new()
	vert.point = Vector2(0,2)
	vert.prev = tri.Vertex.new()
	vert.prev.point = Vector2(-1, 0)
	vert.next = tri.Vertex.new()
	vert.next.point = Vector2(1, 0)
	assert_bool(tri.empty_triangle(vert, [vert])).is_false()


func test_empty_triangle2() -> void:
	var tri = Triangulate2D.new()
	var vert = tri.Vertex.new()
	vert.point = Vector2(0,2)
	vert.type = tri.VertexType.Convex
	vert.prev = tri.Vertex.new()
	vert.prev.point = Vector2(-1, 0)
	vert.next = tri.Vertex.new()
	vert.next.point = Vector2(1, 0)
	assert_bool(tri.empty_triangle(vert, [vert])).is_true()


func test_empty_triangle_point_inside() -> void:
	var tri = Triangulate2D.new()
	var vert = tri.Vertex.new()
	vert.point = Vector2(0,2)
	vert.type = tri.VertexType.Convex
	vert.prev = tri.Vertex.new()
	vert.prev.point = Vector2(-1, 0)
	vert.next = tri.Vertex.new()
	vert.next.point = Vector2(1, 0)
	var v2 = tri.Vertex.new()
	v2.point = Vector2(0.5, 0.5)
	assert_bool(tri.empty_triangle(vert, [v2])).is_false()


func test_empty_triangle_point_on_edge() -> void:
	var tri = Triangulate2D.new()
	var vert = tri.Vertex.new()
	vert.point = Vector2(0,2)
	vert.type = tri.VertexType.Convex
	vert.prev = tri.Vertex.new()
	vert.prev.point = Vector2(-1, 0)
	vert.next = tri.Vertex.new()
	vert.next.point = Vector2(1, 0)
	var v2 = tri.Vertex.new()
	v2.point = Vector2(0.5, 0.0001)
	assert_bool(tri.empty_triangle(vert, [v2])).is_false()


func test_empty_triangle_point_outside() -> void:
	var tri = Triangulate2D.new()
	var vert = tri.Vertex.new()
	vert.point = Vector2(0,2)
	vert.type = tri.VertexType.Convex
	vert.prev = tri.Vertex.new()
	vert.prev.point = Vector2(-1, 0)
	vert.next = tri.Vertex.new()
	vert.next.point = Vector2(1, 0)
	var v2 = tri.Vertex.new()
	v2.point = Vector2(1.5, 0)
	assert_bool(tri.empty_triangle(vert, [v2])).is_true()


func test_triangulate() -> void:
	var poly = [Vector2(3, 48), Vector2(52, 8), Vector2(99, 50), Vector2(138, 25),
		Vector2(175, 77), Vector2(131, 72), Vector2(111, 113), Vector2(72, 43),
		Vector2(26, 55), Vector2(29, 100)]
	var ans = [[2,3,4],[2,4,5],[2,5,6],[2,6,7],[8,9,0],[8,0,1],[1,2,7],[1,7,8]]
	var tri = Triangulate2D.new()
	var tris = tri.triangulate(poly)
	var ok = true
	for idx in ans.size():
		for n in 3:
			if not tris[idx][n].is_equal_approx(poly[ans[idx][n]]):
				ok = false
				break
		if not ok:
			break
	assert_bool(ok).is_true()


func test_is_clockwise() -> void:
	var poly = [Vector2(0, 0), Vector2(4,5), Vector2(1, 3)] # Clockwise
	var tri = Triangulate2D.new()
	assert_bool(tri.is_clockwise(poly)).is_true()
