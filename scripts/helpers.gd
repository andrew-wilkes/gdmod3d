class_name Helpers

extends Object

static func inside_circle(canvas: CanvasItem, radius: float) -> bool:
	return (canvas.get_local_mouse_position() - Vector2(radius, radius)).length() <= radius

# Superceeded by Geometry2D.point_is_inside_triangle
static func point_in_triangle(a: Vector2, b: Vector2, c: Vector2, p: Vector2) -> bool:
	var cp1 = (a-b).cross(a-p)
	var cp2 = (b-c).cross(b-p)
	var cp3 = (c-a).cross(c-p)
	return sign(cp1) == sign(cp2) and sign(cp2) == sign(cp3)


static func rect_from_points(points: Array) -> Rect2:
	var r = Rect2(INF, INF, 0, 0)
	r = points.reduce(_update_rect, r)
	return Rect2(r.position, r.size - r.position)


static func index_of_max_x(points: Array) -> int:
	var x = -INF
	var i = -1
	for idx in points.size():
		if points[idx].x > x:
			x = points[idx].x
			i = idx
	return int(i)


static func get_closest_corners(r1: Rect2, r2: Rect2) -> Dictionary:
	var pa = r1.position
	var pb = r1.end
	var pj = r2.position
	var pk = r2.end
	var dist = INF
	var result = { "dist": dist, "vout": Vector2(), "vin": Vector2() }
	_get_closest_points(pa.x, pa.y, pj.x, pj.y, result)
	_get_closest_points(pa.x, pb.y, pj.x, pk.y, result)
	_get_closest_points(pb.x, pa.y, pk.x, pj.y, result)
	_get_closest_points(pb.x, pb.y, pk.x, pk.y, result)
	return result


static func get_index_of_closest_point(points: Array, p: Vector2) -> int:
	var dist = INF
	var i: int
	for idx in points.size():
		var d = (points[idx] - p).length_squared()
		if d < dist:
			dist = d
			i = idx
	return i


static func _get_closest_points(x1: float, y1: float, x2: float, y2: float, result: Dictionary):
	var dist = (Vector2(x1, y1) - Vector2(x2, y2)).length_squared()
	if dist < result.dist:
		result.dist = dist
		result.vout = Vector2(x1, y1)
		result.vin = Vector2(x2, y2)


static func centroid_of_triangle(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	return (a + b + c) / 3.0


static func largeness_of_triangle(a: Vector2, b: Vector2, c: Vector2) -> float:
	return abs((a - b).cross(c - b))


static func _update_rect(r: Rect2, p: Vector2) -> Rect2:
	if p.x < r.position.x:
		r.position.x = p.x
	if p.y < r.position.y:
		r.position.y = p.y
	# The size will not change as position is updated, but end will
	# That is why we must set size here and not end
	if p.x > r.size.x:
		r.size.x = p.x
	if p.y > r.size.y:
		r.size.y = p.y
	return r


static func execution_time(fn: Callable, num_calls = 10000):
	var a = Vector2.ZERO
	var b = Vector2(0, 3)
	var c = Vector2(4, 0)
	var start_time = Time.get_ticks_msec()
	for n in num_calls:
		fn.call(a,b,c)
	var duration = Time.get_ticks_msec() - start_time
	prints("Duration:", duration)


# This function is only called via clicking on the 3D gizmo buttons
static func decompose_rotation(b: Basis) -> Vector2:
	# Get rotation angle of Y axis
	var normal = b.z.cross(b.x)
	var xrot = normal.angle_to(Vector3.UP) * sign(b.y.z) * sign(b.x.x)
	# There is a problem where the maximum angle is around +/-2.75 and not +/-PI
	# Rotate the coordinate system back about the X axis
	var brot = b.rotated(b.x, -xrot)
	var yrot = brot.z.angle_to(Vector3.BACK) * sign(brot.z.x)
	# Special case for -z alignment
	if Vector3.FORWARD.is_equal_approx(brot.z):
		yrot = -PI
	return Vector2(xrot, yrot)


static func get_xml_nodes(file_path: String) -> Dictionary:
	var parser: XMLParser = XMLParser.new()
	var results: Dictionary
	parser.open(file_path)
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name = parser.get_node_name()
			var attributes_dict = {}
			for idx in range(parser.get_attribute_count()):
				attributes_dict[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
			if results.has(node_name):
				results[node_name].append(attributes_dict)
			else:
				results[node_name] = [attributes_dict]
	return results


static func simplified_vertex(v: Vector3) -> Vector3:
	return Vector3i(int(v.x), int(v.y), int(v.z))


static func save_to_file(content: String, file_name: String):
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	file.store_string(content)


static func load_from_file(file_name: String):
	var file = FileAccess.open(file_name, FileAccess.READ)
	var content = file.get_as_text()
	return content
