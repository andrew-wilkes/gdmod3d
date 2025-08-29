class_name Triangulate2D
extends RefCounted

enum VertexType {
		Handled,
		Reflex,
		Convex,
		Tip
	}

class Vertex:
	var point: Vector2
	var prev: Vertex
	var next: Vertex
	var type: int
	
# Depends on winding order
func is_reflex(vert: Vertex) -> bool:
	var a = vert.prev.point
	var b = vert.point
	var c = vert.next.point
	var d = (b-a).cross(c-a)
	return d < 0


func is_clockwise(polygon: Array):
	# Test lowest x point
	var min_x = INF
	var min_idx = -1
	for idx in polygon.size():
		if polygon[idx].x < min_x:
			min_x = polygon[idx].x
			min_idx = idx
	var vert = Vertex.new()
	vert.point = polygon[min_idx]
	vert.prev = Vertex.new()
	vert.next = Vertex.new()
	vert.prev.point = polygon[(min_idx - 1) % polygon.size()]
	vert.next.point = polygon[(min_idx + 1) % polygon.size()]
	return not is_reflex(vert)


func empty_triangle(vert: Vertex, verts: Array) -> bool:
	if vert.type != VertexType.Convex:
		return false
	var a = vert.prev.point
	var b = vert.point
	var c = vert.next.point
	for _v in verts:
		var v: Vertex = _v
		if v == vert or v == vert.prev or v == vert.next:
			continue
		if Helpers.point_in_triangle(a, b, c, v.point):
			return false
	return true


func triangulate(polygon: Array) -> Array:
	var verts = []
	var triangles = []
	
	var n = polygon.size()
	# Set points
	for idx in n:
		var vert = Vertex.new()
		vert.point = polygon[idx]
		verts.append(vert)
	# Set types
	for idx in n:
		verts[idx].prev = verts[(idx - 1) % n]
		verts[idx].next = verts[(idx + 1) % n]
		if is_reflex(verts[idx]):
			verts[idx].type = VertexType.Reflex
		else:
			verts[idx].type = VertexType.Convex
	# Find tips of triangles that don't contain a point
	for idx in n:
		if empty_triangle(verts[idx], verts):
			verts[idx].type = VertexType.Tip
	var idx = -1
	var num_handled = 0
	var count = 0
	while true:
		idx = (idx + 1) % verts.size()
		count += 1
		if count > verts.size():
			break
		var vert: Vertex = verts[idx]
		if vert.type == VertexType.Tip or num_handled == (verts.size() - 3):
			count = 0
			triangles.append([vert.prev.point, vert.point, vert.next.point])
			vert.type = VertexType.Handled
			vert.prev.next = vert.next
			vert.next.prev = vert.prev
			num_handled += 1
			if num_handled > (verts.size() - 3):
				break
			# Update status of adjacent points
			if vert.prev.type == VertexType.Reflex and not is_reflex(vert.prev):
				vert.prev.type = VertexType.Convex
			if vert.prev.type == VertexType.Convex and empty_triangle(vert.prev, verts):
				vert.prev.type = VertexType.Tip
			if vert.next.type == VertexType.Reflex and not is_reflex(vert.next):
				vert.next.type = VertexType.Convex
			if vert.next.type == VertexType.Tip:
				vert.next.type = VertexType.Convex
			if vert.next.type == VertexType.Convex and empty_triangle(vert.next, verts):
				vert.next.type = VertexType.Tip
	return triangles
