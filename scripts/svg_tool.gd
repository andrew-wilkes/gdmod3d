class_name SVG_Tool
extends RefCounted

const SCALE = 10.0

var loops = []
var inner_verts = []

class Loop:
	var points: Array
	var outer: bool
	var rect: Rect2
	var closed: bool

class Triangle:
	var active: bool
	var cp: Vector2
	var a: Vector2
	var b: Vector2
	var c: Vector2
	func _init(active_, cp_, a_, b_, c_):
		active = active_
		cp = cp_
		a = a_
		b = b_
		c = c_
	func _to_string() -> String:
		return JSON.stringify([active, cp, a, b, c])


func get_main_loop() -> Loop:
	if loops.size() < 2:
		return Loop.new()
	# Find outer loop
	var outer_loop = loops[0]
	for idx in range(1, loops.size()):
		var r1: Rect2 = outer_loop.rect
		var r2: Rect2 = loops[idx].rect
		if r2.encloses(r1):
			outer_loop = loops[idx]
	outer_loop.outer = true
	# Correct the order of the points in a loop
	for l in loops:
		var loop: Loop = l
		if loop.outer:
			if Geometry2D.is_polygon_clockwise(loop.points):
				loop.points.reverse()
		else:
			if not Geometry2D.is_polygon_clockwise(loop.points):
				loop.points.reverse()
			inner_verts.append(loop.points)
	# Connect outer loop to inner loops
	for l in loops:
		if l == outer_loop:
			continue
		var verts = Helpers.get_closest_corners(outer_loop.rect, l.rect)
		# Insert inner loop into outer loop
		var idx1 = Helpers.get_index_of_closest_point(outer_loop.points, verts.vout)
		var idx2 = Helpers.get_index_of_closest_point(l.points, verts.vin)
		var new_points = outer_loop.points.slice(0, idx1 + 1)
		new_points.append_array(l.points.slice(idx2))
		new_points.append_array(l.points.slice(0, idx2 + 1))
		new_points.append_array(outer_loop.points.slice(idx1))
		outer_loop.points = new_points
	return outer_loop


func get_mesh(triangles: Array[Triangle]) -> ArrayMesh:
	# Triangle verts are in ant-clockwise order but surface tool needs clockwise order
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for tri in triangles:
		if tri.active:
			st.add_vertex(Vector3(tri.c.x, 0, tri.c.y) / SCALE)
			st.add_vertex(Vector3(tri.b.x, 0, tri.b.y) / SCALE)
			st.add_vertex(Vector3(tri.a.x, 0, tri.a.y) / SCALE)
	return st.commit()


func get_triangles() -> Array[Triangle]:
	var loop = get_main_loop()
	var tpoints = Geometry2D.triangulate_delaunay(loop.points)
	var triangles: Array[Triangle]
	for idx in range(0, tpoints.size(), 3):
		var x = tpoints[idx]
		var y = tpoints[idx+1]
		var z = tpoints[idx+2]
		if x == y or y == z or x == z:
			continue
		var a = loop.points[x]
		var b = loop.points[y]
		var c = loop.points[z]
		if a.is_equal_approx(b) or a.is_equal_approx(c) or b.is_equal_approx(c):
			continue
		var cp = Helpers.centroid_of_triangle(a,b,c)
		var accept = true
		for poly in inner_verts:
			if Geometry2D.is_point_in_polygon(cp, poly):
				accept = false
				break
		if accept:
			if Geometry2D.is_polygon_clockwise([a, b, c]):
				triangles.append(Triangle.new(accept, cp, a, b, c))
			else:
				triangles.append(Triangle.new(accept, cp, c, b, a))
	for idx in range(triangles.size() - 1, 0, -1):
		var ta = triangles[idx]
		if ta.active:
			for idxb in range(idx - 1, -1, -1):
				var tb = triangles[idxb]
				if tb.active and Geometry2D.point_is_inside_triangle(ta.cp, tb.a, tb.b, tb.c):
					if Helpers.largeness_of_triangle(ta.a, ta.b, ta.c) > Helpers.largeness_of_triangle(tb.a, tb.b, tb.c):
						tb.active = false
					else:
						ta.active = false
	
	for idx in triangles.size() - 1:
		var ta = triangles[idx]
		if ta.active:
			for idxb in range(idx + 1, triangles.size()):
				var tb = triangles[idxb]
				if Geometry2D.point_is_inside_triangle(ta.cp, tb.a, tb.b, tb.c):
					if Helpers.largeness_of_triangle(ta.a, ta.b, ta.c) > Helpers.largeness_of_triangle(tb.a, tb.b, tb.c):
						tb.active = false
					else:
						ta.active = false
	return triangles


func load_svg(file_path: String):
	var svg_points = SVGPoints.new()
	var nodes = Helpers.get_xml_nodes(file_path)
	var translation = Vector2(10, 10)
	for node in nodes:
		for attribs in nodes[node]:
			var point_data: SVGPoints.ReturnPoints
			match node:
				"rect":
					point_data = svg_points.get_rectangle(attribs)
				"circle":
					point_data = svg_points.get_circle(attribs)
				"ellipse":
					point_data = svg_points.get_ellipse(attribs)
				"line":
					point_data = svg_points.get_line(attribs)
				"polyline":
					point_data = svg_points.get_polyline(attribs)
				"polygon":
					point_data = svg_points.get_polygon(attribs)
				"path":
					point_data = svg_points.get_path_line(attribs)
				"g":
					translation += svg_points.get_translation(attribs)
			if point_data:
				point_data.position += translation
				var loop = Loop.new()
				loop.points = point_data.points
				for idx in loop.points.size():
					loop.points[idx] += point_data.position
				loop.rect = Helpers.rect_from_points(loop.points)
				loop.closed = point_data.close
				loops.append(loop)
