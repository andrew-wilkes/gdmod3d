# GdUnit generated TestSuite
class_name TriangulateTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://scripts/triangulate.gd'


func test_get_normal() -> void:
	var tri = Triangulate.new()
	var polygon = [Vector3(0, 0, 0), Vector3(0, 2, 0), Vector3(2, 2, 0)]
	assert_vector(tri.get_normal(polygon)).is_equal(Vector3(0, 0, 1))
	
	polygon = [Vector3(0, 0, 0), Vector3(0, 2, 0), Vector3(2, 2, 0), Vector3(3, 0, 0)]
	assert_vector(tri.get_normal(polygon)).is_equal(Vector3(0, 0, 1))


func test_triangle_area_squared() -> void:
	var tri = Triangulate.new()
	assert_float(tri.triangle_area_squared(Vector3(0, 0, 0), Vector3(0, 2, 0), Vector3(2, 2, 0))).is_equal_approx(4.0, 0.0001)


func test_convex() -> void:
	var tri = Triangulate.new()
	var polygon = [Vector3(0, 0, 0), Vector3(0, 2, 0), Vector3(2, 2, 0), Vector3(3, 0, 0)]
	var norm = Vector3(0, 0, 1)
	assert_bool(tri.convex(polygon, norm)).is_equal(true)
	polygon = [Vector3(0, 0, 0), Vector3(0, 2, 0), Vector3(2, 2, 0), Vector3(1, 1, 0), Vector3(2, 0, 0)]
	assert_bool(tri.convex(polygon, norm)).is_equal(false)


func test_remove_consecutive_equal_points() -> void:
	var tri = Triangulate.new()
	var polygon = [[Vector3(0, 0, 0)], [Vector3(0, 2, 0)], [Vector3(0, 2, 0)], [Vector3(3, 0, 0)]]
	assert_array(tri.remove_consecutive_equal_points(polygon)).is_equal([[Vector3(0, 0, 0)], [Vector3(0, 2, 0)], [Vector3(3, 0, 0)]])
