# GdUnit generated TestSuite
class_name HelpersTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://scripts/helpers.gd'


func test_decompose_rotation() -> void:
	# The angles are in radians and there are quadrants of interest such as < +/-PI/2 and up to +/-PI
	# Also, we rotate on the Y-axis followed by a rotation on the X-axis - this affects the signs of
	# the x,y,z parts of the cartesian coordinates of the axis normal vectors
	var b = Basis()
	assert_vector(Helpers.decompose_rotation(b)).is_equal_approx(Vector2(0.0, 0.0), Vector2(0.001, 0.001))

	b = Basis(Vector3.RIGHT, 0.7)
	assert_vector(Helpers.decompose_rotation(b)).is_equal_approx(Vector2(0.7, 0.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.RIGHT, 3.1)
	assert_vector(Helpers.decompose_rotation(b)).is_equal_approx(Vector2(3.1, 0.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.RIGHT, -0.7)
	assert_vector(Helpers.decompose_rotation(b)).is_equal_approx(Vector2(-0.7, 0.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.RIGHT, -3.1)
	assert_vector(Helpers.decompose_rotation(b)).is_equal_approx(Vector2(-3.1, 0.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 3.1)
	assert_vector(Helpers.decompose_rotation(b)).is_equal_approx(Vector2(0.0, 3.1), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 0.7)
	assert_vector(Helpers.decompose_rotation(b)).is_equal_approx(Vector2(0.0, 0.7), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, -3.1)
	assert_vector(Helpers.decompose_rotation(b)).is_equal_approx(Vector2(0.0, -3.1), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, -0.7)
	assert_vector(Helpers.decompose_rotation(b)).is_equal_approx(Vector2(0.0, -0.7), Vector2(0.001, 0.001))

	b = Basis(Vector3.UP, -1.2)
	var br = b.rotated(b.x, 0.6)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(0.6, -1.2), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 1.2)
	br = b.rotated(b.x, 0.6)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(0.6, 1.2), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, -3.0)
	br = b.rotated(b.x, 0.6)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(0.6, -3.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 3.0)
	br = b.rotated(b.x, 0.6)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(0.6, 3.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, -1.2)
	br = b.rotated(b.x, 1.8)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(1.8, -1.2), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 1.2)
	br = b.rotated(b.x, 1.8)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(1.8, 1.2), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, -3.0)
	br = b.rotated(b.x, 1.8)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(1.8, -3.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 3.0)
	br = b.rotated(b.x, 1.8)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(1.8, 3.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, -1.2)
	br = b.rotated(b.x, 0.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(0.7, -1.2), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 1.2)
	br = b.rotated(b.x, 0.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(0.7, 1.2), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, -3.0)
	br = b.rotated(b.x, 0.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(0.7, -3.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 3.0)
	br = b.rotated(b.x, 0.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(0.7, 3.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, -1.2)
	br = b.rotated(b.x, -0.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(-0.7, -1.2), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 1.2)
	br = b.rotated(b.x, -0.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(-0.7, 1.2), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, -3.0)
	br = b.rotated(b.x, -0.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(-0.7, -3.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 3.0)
	br = b.rotated(b.x, -0.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(-0.7, 3.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, -1.2)
	br = b.rotated(b.x, -1.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(-1.7, -1.2), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 1.2)
	br = b.rotated(b.x, -1.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(-1.7, 1.2), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, -3.0)
	br = b.rotated(b.x, -1.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(-1.7, -3.0), Vector2(0.001, 0.001))
	
	b = Basis(Vector3.UP, 3.0)
	br = b.rotated(b.x, -1.7)
	assert_vector(Helpers.decompose_rotation(br)).is_equal_approx(Vector2(-1.7, 3.0), Vector2(0.001, 0.001)) 


func test_rect_from_points() -> void:
	var points = [Vector2(8,9), Vector2(12,12), Vector2(9,10), Vector2(15, 16)]
	var r = Helpers.rect_from_points(points)
	assert_vector(r.position).is_equal_approx(Vector2(8,9), Vector2(0.001, 0.001))


func test_rect_from_points2() -> void:
	var points = [Vector2(8,9), Vector2(12,12), Vector2(9,10), Vector2(15, 16)]
	var r = Helpers.rect_from_points(points)
	assert_vector(r.size).is_equal_approx(Vector2(7,7), Vector2(0.001, 0.001))


func test_index_of_max_x() -> void:
	var points = [Vector2(8,9), Vector2(12,12), Vector2(9,10), Vector2(15, 16)]
	assert_int(Helpers.index_of_max_x(points)).is_equal(3)


func test_get_closest_corners() -> void:
	# Top left
	var r1 = Rect2()
	r1.position = Vector2(0,90)
	r1.end = Vector2(90, 0)
	var r2 = Rect2()
	r2.position = Vector2(1, 89)
	r2.end = Vector2(40, 3)
	var result = Helpers.get_closest_corners(r1, r2)
	assert_vector(result.vout).is_equal_approx(r1.position, Vector2(0.001, 0.001))
	assert_vector(result.vin).is_equal_approx(r2.position, Vector2(0.001, 0.001))


func test_get_closest_corners2() -> void:
	# Botton left
	var r1 = Rect2()
	r1.position = Vector2(0,90)
	r1.end = Vector2(90, 0)
	var r2 = Rect2()
	r2.position = Vector2(1, 80)
	r2.end = Vector2(40, 3)
	var result = Helpers.get_closest_corners(r1, r2)
	assert_vector(result.vout).is_equal_approx(Vector2(0,0), Vector2(0.001, 0.001))
	assert_vector(result.vin).is_equal_approx(Vector2(1,3), Vector2(0.001, 0.001))

func test_get_closest_corners3() -> void:
	# Top right
	var r1 = Rect2()
	r1.position = Vector2(0,90)
	r1.end = Vector2(90, 0)
	var r2 = Rect2()
	r2.position = Vector2(10, 89)
	r2.end = Vector2(88, 3)
	var result = Helpers.get_closest_corners(r1, r2)
	assert_vector(result.vout).is_equal_approx(Vector2(90,90), Vector2(0.001, 0.001))
	assert_vector(result.vin).is_equal_approx(Vector2(88,89), Vector2(0.001, 0.001))

func test_get_closest_corners4() -> void:
	# Bottom right
	var r1 = Rect2()
	r1.position = Vector2(0,90)
	r1.end = Vector2(90, 0)
	var r2 = Rect2()
	r2.position = Vector2(10, 80)
	r2.end = Vector2(88, 3)
	var result = Helpers.get_closest_corners(r1, r2)
	assert_vector(result.vout).is_equal_approx(Vector2(90,0), Vector2(0.001, 0.001))
	assert_vector(result.vin).is_equal_approx(Vector2(88,3), Vector2(0.001, 0.001))


func test_get_index_of_closest_point() -> void:
	var points = [Vector2(8,9), Vector2(12,12), Vector2(9,10), Vector2(15, 16)]
	var p = Vector2(10,11)
	assert_int(Helpers.get_index_of_closest_point(points, p)).is_equal(2)


func test_centroid_of_triangle() -> void:
	var a = Vector2(1, 1)
	var b = Vector2(3, 4)
	var c = Vector2(5, 1)
	assert_vector(Helpers.centroid_of_triangle(a,b,c)).is_equal_approx(Vector2(3, 2), Vector2(0.001, 0.001))


func test_largeness_of_triangle() -> void:
	var a = Vector2(0, 1)
	var b = Vector2(1, 1)
	var c = Vector2(0, 0)
	var aa = Vector2(0, 0)
	var bb = Vector2(0, 4)
	var cc = Vector2(5,5)
	assert_float(Helpers.largeness_of_triangle(a,b,c)).is_less(Helpers.largeness_of_triangle(aa,bb,cc))
