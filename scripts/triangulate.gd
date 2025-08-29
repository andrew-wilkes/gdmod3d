class_name Triangulate
extends RefCounted

# Based on: https://github.com/StefanJohnsen/pyTriangulate/blob/main/Triangulate.py

# Read: https://www.geometrictools.com/Documentation/TriangulationByEarClipping.pdf

enum TurnDirection {
	NoTurn,
	Left,
	Right,
}

func get_normal(polygon: Array) -> Vector3:
	var n = len(polygon)
	var v = Vector3.ZERO

	if n < 3:
		return v

	for index in range(n):
		var item = polygon[index % n][0]
		var next = polygon[(index + 1) % n][0]

		v.x += (next.y - item.y) * (next.z + item.z)
		v.y += (next.z - item.z) * (next.x + item.x)
		v.z += (next.x - item.x) * (next.y + item.y)

	return v.normalized()


func triangle_area_squared(a: Vector3, b: Vector3, c: Vector3) -> float:
	c = (b - a).cross(c - a)
	return pow(c.length(), 2.0) / 4.0


func turn(p: Vector3, u: Vector3, n: Vector3, q: Vector3):
   
	var v = (q - p).cross(u)
		
	var d = v.dot(n)

	if d > 0.0001: return TurnDirection.Right
	if d < -0.0001: return TurnDirection.Left

	return TurnDirection.NoTurn


func convex(polygon: Array, normal: Vector3) -> bool:
	var n = polygon.size()

	if n <  3: return false
	if n == 3: return true

	var polygonTurn = TurnDirection.NoTurn

	for index in n:
		var prev: Vector3 = polygon[(index - 1 + n) % n][0]
		var item: Vector3 = polygon[index % n][0]
		var next: Vector3 = polygon[(index + 1) % n][0]

		var u = (item - prev).normalized()

		var item_turn = turn(prev, u, normal, next)

		if item_turn == TurnDirection.NoTurn:
			continue

		if polygonTurn == TurnDirection.NoTurn:
			polygonTurn = item_turn

		if polygonTurn != item_turn:
			return false

	return true


func clockwise_oriented(polygon: Array, normal: Vector3) -> bool:
	var n = polygon.size()

	if n < 3: return false

	var orientation_sum = 0.0

	for index in range(n):
		var prev = polygon[(index - 1 + n) % n][0]
		var item = polygon[index % n][0]
		var next = polygon[(index + 1) % n][0]

		var edge = item - prev
		var to_next_point = next - item

		var v = edge.cross(to_next_point)
		orientation_sum += v.dot(normal)

	return orientation_sum < 0.0


func make_clockwise_orientation(polygon: Array, normal: Vector3) -> void:
	if polygon.size() < 3:
		return

	if not clockwise_oriented(polygon, normal):
		polygon.reverse()


func point_inside_or_edge_triangle(a: Vector3, b: Vector3, c: Vector3, p: Vector3):
	var zero = 1e-15  # A small value close to zero for comparisons

	var edge = false

	# Vectors from point p to vertices of the triangle
	var v0 = c - a
	var v1 = b - a
	var v2 = p - a

	var dot00 = v0.dot(v0)
	var dot01 = v0.dot(v1)
	var dot02 = v0.dot(v2)
	var dot11 = v1.dot(v1)
	var dot12 = v1.dot(v2)

	# Check for degenerate triangle
	var denom = dot00 * dot11 - dot01 * dot01

	if abs(denom) < zero:
		# The triangle is degenerate (i.e., has no area)
		return [false, edge]

	# Compute barycentric coordinates
	var inv_denom = 1.0 / denom

	var u = (dot11 * dot02 - dot01 * dot12) * inv_denom
	var v = (dot00 * dot12 - dot01 * dot02) * inv_denom

	# Check for edge condition
	if abs(u) < zero or abs(v) < zero or abs(u + v - 1) < zero:
		edge = true

	# Check if point is inside the triangle (including edges)
	return [u >= 0.0 and v >= 0.0 and u + v < 1.0, edge]


func is_ear(index: int, polygon: Array, normal: Vector3) -> bool:
	var n = polygon.size()

	if n <  3: return false
	if n == 3: return true

	var prevIndex = (index - 1 + n) % n
	var itemIndex = index % n
	var nextIndex = (index + 1) % n

	var prev = polygon[prevIndex][0]
	var item = polygon[itemIndex][0]
	var next = polygon[nextIndex][0]

	var u = (item - prev).normalized()

	if turn(prev, u, normal, next) != TurnDirection.Right:
		return false

	for i in n:
		if i in [prevIndex, itemIndex, nextIndex]:
			continue

		var p = polygon[i][0]

		var inside = point_inside_or_edge_triangle(prev, item, next, p)

		if inside: return false

	return true
	

func get_biggest_ear(polygon: Array, normal: Vector3) -> int:
	var n = polygon.size()

	if n == 3: return 0
	if n == 0: return -1

	var max_index = -1
	var max_area = -INF

	for index in range(n):
		if is_ear(index, polygon, normal):
			var prev = polygon[(index - 1 + n) % n][0]
			var item = polygon[index % n][0]
			var next = polygon[(index + 1) % n][0]

			var area = triangle_area_squared(prev, item, next)

			if area > max_area:
				max_index = index
				max_area = area

	return max_index


func get_overlapping_ear(polygon: Array, normal: Vector3):
	var n = polygon.size()

	if n == 3: return 0
	if n == 0: return -1

	for index in n:
		var prev = polygon[(index - 1 + n) % n][0]
		var item = polygon[index % n][0]
		var next = polygon[(index + 1) % n][0]

		var u = (item - prev).normalized()

		if turn(prev, u, normal, next) != TurnDirection.NoTurn:
			continue
		
		var v = (next - item).normalized()

		if u.dot(v) < 0.0: 
			return index

	return -1


func fan_triangulation(polygon: Array) -> Array:
	var triangles = []
	for index in range(1, polygon.size() - 1):
		triangles.append([polygon[0], polygon[index + 1], polygon[index]])
	return triangles


func cut_triangulation(polygon: Array, normal: Vector3) -> Array:
	
	var triangles = []

	make_clockwise_orientation(polygon, normal)

	while polygon:
		var index = get_biggest_ear(polygon, normal)
		
		if index == -1:
			index = get_overlapping_ear(polygon, normal)

		if index == -1: return []

		var n = len(polygon)

		var prev = polygon[(index - 1 + n) % n]
		var item = polygon[index % n]
		var next = polygon[(index + 1) % n]

		triangles.append(Vector3(prev, item, next))

		polygon.remove_at(index)

		if polygon.size() < 3:
			break

	return triangles if polygon.size() < 3 else []


func remove_consecutive_equal_points(polygon: Array) -> Array:
	var unique_polygon = []
	var n = polygon.size()
	for index in n:
		var item = polygon[index % n]
		var next = polygon[(index + 1) % n]
		# Compare vertices
		if item[0] != next[0]:
			unique_polygon.append(item)
	return unique_polygon


func triangulate(polygon: Array) -> Array:
	
	# This shouldn't be needed I think:
	# polygon = remove_consecutive_equal_points(polygon)

	var n = get_normal(polygon)

	if polygon.size() < 3: return [[], n]

	if polygon.size() == 3:
		return [[[polygon[2], polygon[1], polygon[0]]], n]

	if convex(polygon, n):
		return [fan_triangulation(polygon), n]

	return [cut_triangulation(polygon, n), n]
