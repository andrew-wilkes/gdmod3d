extends Node3D

class_name ThreeD

signal camera_rotated(trans: Transform3D)

const ZOOM_SPEED = 0.1
const SLOW_ZOOM_MULTIPLIER = 0.1
const FAST_ZOOM_MULTIPLIER = 4.0
const MAX_ZOOM = 100.0
const MIN_ZOOM = 0.1
const CIRCLE_GROW_SPEED = 3.0 * ZOOM_SPEED
const CIRCLE_MIN_SCALE = 0.5
const CIRCLE_MAX_SCALE = 30.0
const GRID_SQUARES_DENSITY = 160
const GRID_MAJOR_INTERVAL = 5
const GRID_SQUARES_ZOOM_JUMP_FACTOR = 2.24
const UPDATE_TIME = 0.5
const RGB = [Color.RED, Color.GREEN, Color.BLUE]

enum { BOX, CIRCLE }
enum { VERTEX, EDGE, FACE }
enum { TRIANGLES, WIREMESH, SOLID, TEXTURED }
enum { CUBE, CYLINDER, SPHERE }

var axis: ArrayMesh
var mdt: MeshDataTool
var selected_vertices: Dictionary
var current_mesh: ArrayMesh
var model: MeshInstance3D
@onready var base = $Base
@onready var arm = $Base/Arm

@export var mat: Material
@export var amesh: ArrayMesh

var MAX_VERTEX_VALUE = 9999
var axis_shader = preload("res://shaders/axis.gdshader")
var wireframe_shader = preload("res://shaders/wireframe.gdshader")
var back_face_shader = preload("res://shaders/back_face.gdshader")
var faces_shader = preload("res://shaders/faces.gdshader")
var arrow = preload("res://assets/arrow.png")
var selection_debugger: SelectionDebugger
var face_outliner: FaceOutliner
var cam_base_z
var zoom_level = 2.5
var dragging := false
var drag_start_position: Vector2
var box_selector: Sprite2D
var circle_selector: Sprite2D
var circle_selector_scale = 2.0
var selection_tool = BOX
var selection_mode = VERTEX
var view_mode = WIREMESH
var quad_mode = true
var selecting = false
var camera: Camera3D
var front_facing_faces: Dictionary
var update_timer = 0
var check_if_vertex_hidden = true
var input_handled = false
var common_faces: Dictionary
var debug_edge_selection = false
var debug_face_selection = false

func _ready() -> void:
	model = $Model
	if debug_edge_selection:
		var sb = load("res://tools/selection_debugger.tscn")
		selection_debugger = sb.instantiate()
		add_child(selection_debugger)
	if debug_face_selection:
		var fs = load("res://tools/face_outliner.tscn")
		face_outliner = fs.instantiate()
		add_child(face_outliner)
	add_axes()
	$Base.rotate_y(-PI/4.0)
	$Base/Arm.rotate_x(-PI/8.0)
	cam_base_z = $Base/Arm/Camera3D.position.z
	camera = $Base/Arm/Camera3D
	camera.size = zoom_level * zoom_level

	box_selector = $BoxSelector
	circle_selector = $CircleSelector
	
	# amesh is passed by reference so is modified my the MeshDataTool
	mdt = MeshDataTool.new()
	# Prevent over-writing of the imported mesh data
	#https://github.com/godotengine/godot/issues/91618
	
	# Init the starting mesh
	match 0:
		0:
			# Used to test with mesh added to the scene export var
			current_mesh = amesh.duplicate()
			deindex_mesh()
		1:
			# Run the primitive mesh selector
			add_selection(CUBE)
		2:
			# Load from SVG
			var svgt = SVG_Tool.new()
			svgt.load_svg("res://assets/example.svg")
			var triangles = svgt.get_triangles()
			current_mesh = svgt.get_mesh(triangles)
	model.mesh = current_mesh
	set_mesh_vertex_data()
	if get_parent().name == "MainViewport":
		call_deferred("deferred_setup")


func deferred_setup():
	find_front_facing_faces()

	set_view_mode(SOLID)
	set_selection_mode(selection_mode)
	
	Globals.perspective_button.pressed.connect(perspective_button_pressed)
	Globals.vertex_button.pressed.connect(vertex_button_pressed)
	Globals.edge_button.pressed.connect(edge_button_pressed)
	Globals.face_button.pressed.connect(face_button_pressed)
	
	Globals.triangles_button.pressed.connect(triangles_button_pressed)
	Globals.wireframe_button.pressed.connect(wireframe_button_pressed)
	Globals.solid_button.pressed.connect(solid_button_pressed)
	Globals.textured_button.pressed.connect(textured_button_pressed)
	
	Globals.zoom_button.drag_controller.dragged.connect(drag_zoom)
	Globals.drag_button.drag_controller.dragged.connect(drag_translate)
	
	Globals.main.add_selection.connect(add_selection)
	Globals.main.load_obj_file.connect(load_obj_file)
	Globals.main.save_obj_file.connect(save_obj_file)
	
	camera_rotated.emit(get_camera_basis())


func add_axes():
	var instance = RenderingServer.instance_create()
	# Set the scenario from the world, this ensures it
	# appears with the same objects as the scene.
	var scenario = get_world_3d().scenario
	RenderingServer.instance_set_scenario(instance, scenario)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.set_normal(Vector3.FORWARD)
	st.set_color(Color.RED)
	st.add_vertex(Vector3.LEFT * MAX_VERTEX_VALUE)
	st.add_vertex(Vector3.RIGHT * MAX_VERTEX_VALUE)
	# A vertical line looks bad (also, not used in Blender unless X or Y is UP)
	st.set_color(Color.GREEN)
	st.add_vertex(Vector3.UP * MAX_VERTEX_VALUE)
	st.add_vertex(Vector3.DOWN * MAX_VERTEX_VALUE)
	st.set_color(Color.BLUE)
	st.add_vertex(Vector3.FORWARD * MAX_VERTEX_VALUE)
	st.add_vertex(Vector3.BACK * MAX_VERTEX_VALUE)
	var axis_mat := ShaderMaterial.new()
	axis_mat.shader = axis_shader
	st.set_material(axis_mat)
	axis = st.commit()
	RenderingServer.instance_set_base(instance, axis.get_rid())


func _process(delta: float) -> void:
	if update_timer > 0:
		update_timer -= delta
		if update_timer <= 0:
			do_updates()


func start_update_timer():
	update_timer = UPDATE_TIME


func do_updates():
	find_front_facing_faces()


func find_front_facing_faces():
	# Can't rely on correct normals so check projected face vertex rotation direction
	# This took 2ms to run with the monkey mesh (968 faces)
	front_facing_faces.clear()
	for idx in mdt.get_face_count():
		var p1 = get_unprojected_vertex(idx, 0)
		var p2 = get_unprojected_vertex(idx, 1)
		var p3 = get_unprojected_vertex(idx, 2)
		var xp = (p2 - p1).cross(p3 - p1)
		if sign(xp) > 0:
			front_facing_faces[idx] = [p1, p2, p3]


func get_unprojected_vertex(face_idx: int, n: int) -> Vector2:
	var vertex = mdt.get_vertex(mdt.get_face_vertex(face_idx, n))
	return camera.unproject_position(vertex)


func on_face(pos: Vector2) -> int:
	for idx in front_facing_faces:
		var points = front_facing_faces[idx]
		if Helpers.point_in_triangle(points[0], points[1], points[2], pos):
			return idx
	return -1  


func delete_selected_vertices():
	# Rebuild the mesh by discarding faces that contain any selected vertices
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f_idx in mdt.get_face_count():
		var verts = []
		var skip = false
		for n in 3:
			var v_idx = mdt.get_face_vertex(f_idx, n)
			verts.append(v_idx)
			if v_idx in selected_vertices.keys():
				skip = true
				break
		if skip:
			continue
		for idx in verts:
			st.set_normal(mdt.get_vertex_normal(idx))
			st.add_vertex(mdt.get_vertex(idx))
	#st.index() # This will shrink the vertex count which we don't want.
	current_mesh = st.commit()
	$Model.mesh = current_mesh
	set_mesh_vertex_data()
	find_front_facing_faces()
	selected_vertices.clear()


func is_vertex_in_rect(vertex: Vector3, rect: Rect2) -> bool:
	var pos = camera.unproject_position(vertex)
	if rect.abs().has_point(pos):
		return true
	return false


func keep_or_deselect_vertices():
	if not Input.is_key_pressed(KEY_CTRL):
		selected_vertices.clear()
		remove_highlighting()


func get_faces_in_selection() -> Array:
	# The 3 vertices of a triangle must be selected
	var faces = []
	for f_idx in mdt.get_face_count():
		var v1 = mdt.get_face_vertex(f_idx, 0)
		var v2 = mdt.get_face_vertex(f_idx, 1)
		var v3 = mdt.get_face_vertex(f_idx, 2)
		if selected_vertices.has(v1) and selected_vertices.has(v2) and selected_vertices.has(v3):
			faces.append(f_idx)
	selected_vertices.clear()
	for f_idx in faces:
		select_vertices_of_face(f_idx)
	return faces


# Minimize the number of selected vertices
# It turned out not good to do this because it bypasses checking for obscured vertices
func select_new_position(idx: int, vertex: Vector3):
	for id in selected_vertices:
		if selected_vertices[id].is_equal_approx(vertex):
			return
	selected_vertices[idx] = vertex


func select_vertex(mouse_pos: Vector2):
	keep_or_deselect_vertices()
	var f_idx = get_face(mouse_pos)
	if f_idx > -1:
		select_nearest_vertex_in_face(mouse_pos, f_idx)
	else:
		select_nearest_vertex(mouse_pos)


func select_nearest_vertex_in_face(mouse_pos: Vector2, f_idx: int):
	var dist = INF
	var pos: Vector3
	for n in 3:
		var idx = mdt.get_face_vertex(f_idx, n)
		var p = mdt.get_vertex(idx)
		var spos = camera.unproject_position(p)
		var d = spos.distance_squared_to(mouse_pos)
		if d < dist:
			dist = d
			pos = p
	select_all_vertices_at_pos(pos, selected_vertices)


func select_nearest_vertex(mouse_pos: Vector2):
	var dist = INF
	var pos: Vector3
	for idx in mdt.get_vertex_count():
		var p = mdt.get_vertex(idx)
		var spos = camera.unproject_position(p)
		var d = spos.distance_squared_to(mouse_pos)
		if d < dist:
			dist = d
			pos = p
			if d < 100.0: # Check this
				break
	select_all_vertices_at_pos(pos, selected_vertices)


func select_vertices_in_rect(rect: Rect2):
	keep_or_deselect_vertices()
	for idx in mdt.get_vertex_count():
		var vertex = mdt.get_vertex(idx)
		if is_vertex_in_rect(vertex, rect):
			selected_vertices[idx] = vertex


func select_vertices_in_circle(radius: float, mouse_pos: Vector2):
	keep_or_deselect_vertices()
	radius *= radius
	for idx in mdt.get_vertex_count():
		var vertex = mdt.get_vertex(idx)
		var pos = camera.unproject_position(vertex)
		if (mouse_pos.distance_squared_to(pos) < radius):
			selected_vertices[idx] = vertex


func select_edge(mouse_pos: Vector2):
	keep_or_deselect_vertices()
	var dist = INF
	var screen_pos1: Vector2
	var screen_pos2: Vector2
	var vertex1_idx := -1
	var vertex2_idx := -1
	var vpos1: Vector3
	var vpos2: Vector3
	var edge := -1
	var pi2 = PI / 2.0
	for e_idx in mdt.get_edge_count():
		var v1 = mdt.get_edge_vertex(e_idx, 0)
		var v2 = mdt.get_edge_vertex(e_idx, 1)
		var vp1 = mdt.get_vertex(v1)
		var p1 = camera.unproject_position(vp1)
		var vp2 = mdt.get_vertex(v2)
		var p2 = camera.unproject_position(vp2)
		var d = distance_from_line(p1, p2, mouse_pos)
		if d > dist:
			continue
		var vec1 = p1 - mouse_pos
		var vec2 = p2 - mouse_pos
		if abs(vec1.angle_to(vec2)) < pi2:
			continue
		if view_mode != TRIANGLES:
			# Reject if diagonal
			var col: Color = mdt.get_vertex_color(mdt.get_edge_vertex(e_idx, 0))
			if col.a < 0.1:
				continue
		if view_mode == TRIANGLES or view_mode == WIREMESH or edge_on_front_face_or_mouse_over_gap(e_idx, mouse_pos):
				screen_pos1 = p1
				screen_pos2 = p2
				vertex1_idx = v1
				vertex2_idx = v2
				vpos1 = vp1
				vpos2 = vp2
				dist = d
				edge = e_idx
				if dist < 5:
					break
	if edge > -1:
		if debug_edge_selection:
			selection_debugger.update(mouse_pos)
			selection_debugger.add_point(screen_pos1, vertex1_idx)
			selection_debugger.add_point(screen_pos2, vertex2_idx)
		select_all_vertices_at_pos(vpos1, selected_vertices)
		select_all_vertices_at_pos(vpos2, selected_vertices)
		check_if_vertex_hidden = false
	if Input.is_key_pressed(KEY_SHIFT):
		# Loop select (doesn't work well)
		var vect = Vector3(vpos2 - vpos1)
		var end_pos = vpos1
		while true:
			var done = true
			for e_idx in mdt.get_edge_count():
				var v1 = mdt.get_edge_vertex(e_idx, 0)
				var v2 = mdt.get_edge_vertex(e_idx, 1)
				var p1 = mdt.get_vertex(v1)
				var p2 = mdt.get_vertex(v2)
				if p1.is_equal_approx(vpos2) and not p2.is_equal_approx(vpos1):
					if p2.is_equal_approx(end_pos):
						return
					var vect2 = Vector3(p2 - p1)
					if vect.dot(vect2) > 0.3:
						select_all_vertices_at_pos(p2, selected_vertices)
						vect = vect2
						vpos1 = p1
						vpos2 = p2
						done = false
				elif p2.is_equal_approx(vpos2) and not p1.is_equal_approx(vpos1):
					if p1.is_equal_approx(end_pos):
						return
					var vect2 = Vector3(p1 - p2)
					if vect.dot(vect2) > 0.3:
						select_all_vertices_at_pos(p1, selected_vertices)
						vect = vect2
						vpos1 = p2
						vpos2 = p1
						done = false
			if done:
				return


func get_edges_in_selection() -> Array:
	# Discard vertices that are not part of an edge pair
	var edges = []
	var vertices = Dictionary()
	for e_idx in mdt.get_edge_count():
		var v1 = mdt.get_edge_vertex(e_idx, 0)
		var v2 = mdt.get_edge_vertex(e_idx, 1)
		if selected_vertices.has(v1) and selected_vertices.has(v2):
			vertices[v1] = selected_vertices[v1]
			vertices[v2] = selected_vertices[v2]
			edges.append(e_idx)
	selected_vertices = vertices
	return edges


func select_face(mouse_pos):
	var selected_face = get_face(mouse_pos)
	if selected_face > -1:
		check_if_vertex_hidden = false
		select_vertices_of_face(selected_face)


func select_vertices_of_face(face_idx: int):
	keep_or_deselect_vertices()
	for n in 3:
		var v_idx = mdt.get_face_vertex(face_idx, n)
		selected_vertices[v_idx] = mdt.get_vertex(v_idx)
	var idx = common_faces.get(face_idx, -1)
	if idx > -1:
		# Add vertex from common face
		for n in 3:
			var v_idx = mdt.get_face_vertex(idx, n)
			if v_idx not in selected_vertices.keys():
				selected_vertices[v_idx] = mdt.get_vertex(v_idx)
				break


func get_face(mouse_pos) -> int:
	var selected_face = -1
	for face_idx in front_facing_faces:
		var a = front_facing_faces[face_idx][0]
		var b = front_facing_faces[face_idx][1]
		var c = front_facing_faces[face_idx][2]
		if Helpers.point_in_triangle(a, b, c, mouse_pos):
			selected_face = face_idx
			break
	if selected_face < 0:
		for face_idx in mdt.get_face_count():
			if face_idx not in front_facing_faces:
				var points = []
				var verts = []
				var indices = []
				for n in 3:
					var v_idx = mdt.get_face_vertex(face_idx, n)
					var p = mdt.get_vertex(v_idx)
					points.append(camera.unproject_position(p))
					verts.append(p)
					indices.append(v_idx)
				if Helpers.point_in_triangle(points[0], points[1], points[2], mouse_pos):
					selected_face = face_idx
					break
	return selected_face


func distance_from_line(a: Vector2, b: Vector2, c: Vector2) -> float:
	var ayby = a.y - b.y
	var half_area = abs(a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * ayby)
	var tbase = sqrt((a.x - b.x) * (a.x - b.x) + ayby * ayby)
	return half_area / tbase


func edge_on_front_face_or_mouse_over_gap(edge_idx: int, mouse_pos: Vector2) -> bool:
	for face_idx in front_facing_faces:
		var a = front_facing_faces[face_idx][0]
		var b = front_facing_faces[face_idx][1]
		var c = front_facing_faces[face_idx][2]
		if Geometry2D.point_is_inside_triangle(mouse_pos, a, b, c):
			for fidx in mdt.get_edge_faces(edge_idx):
				if fidx == face_idx:
					return true
			# Edge belongs to a back face that is covered by the selected front face
			return false
	# Over a gap
	return true


func select_all_vertices_at_pos(pos: Vector3, vertex_positions: Dictionary):
	for idx in mdt.get_vertex_count():
		if pos.is_equal_approx(mdt.get_vertex(idx)):
			vertex_positions[idx] = pos


func update_selection():
	if debug_face_selection:
		face_outliner.update(selected_vertices.values(), camera)
	# Only select new vertices since the previously selected vertices are highlighted
	if view_mode > WIREMESH and check_if_vertex_hidden:
		var vertex_positions = Dictionary()
		var discarded_vertices = []
		# Add unobscured vertices
		for idx in selected_vertices:
			var in_face = false
			for f_idx in front_facing_faces:
				for n in 3:
					var v_idx = mdt.get_face_vertex(f_idx, n)
					if idx == v_idx:
						vertex_positions[idx] = selected_vertices[idx]
						in_face = true
						break
			if not in_face:
				discarded_vertices.append(idx)
		if selection_mode == EDGE:
			# Check for disconnected edge vertices
			for idx in mdt.get_edge_count():
				var v1 = mdt.get_edge_vertex(idx, 0)
				var v2 = mdt.get_edge_vertex(idx, 1)
				if discarded_vertices.has(v1):
					vertex_positions.erase(v2)
				if discarded_vertices.has(v2):
					vertex_positions.erase(v1)
		selected_vertices = vertex_positions
	#if selected_vertices.size() < 3: # If single vertex or edge was selected
	#	for pos in selected_vertices.values():
	#		select_all_vertices_at_pos(pos, selected_vertices)
	check_if_vertex_hidden = true
	# Set highlight value
	for idx in selected_vertices:
		mdt.set_vertex_uv2(idx, Vector2.ONE)
	# Can't select only 2 edges of a triangle
	current_mesh.clear_surfaces()
	mdt.commit_to_surface(current_mesh)


func remove_highlighting():
	for idx in mdt.get_vertex_count():
		mdt.set_vertex_uv2(idx, Vector2.ZERO)
	current_mesh.clear_surfaces()
	mdt.commit_to_surface(current_mesh)


func deindex_mesh():
	# This is to make the mesh consist of triangles with individual vertices
	# So vertices in the same position may be set with different data
	var st = SurfaceTool.new()
	st.create_from(current_mesh, 0)
	st.deindex()
	current_mesh = st.commit()


func list_face_vertices():
	for idx in mdt.get_face_count():
		var verts = []
		for n in 3:
			verts.append(mdt.get_vertex(mdt.get_face_vertex(idx, n)))
		print(verts)


func set_mesh_vertex_data() -> void:
	mdt.clear()
	mdt.create_from_surface(current_mesh, 0)
	prints("Faces:", mdt.get_face_count(), "Verts:", mdt.get_vertex_count())
	
	# Common faces share an edge and will be adjacent triangles in the list of faces
	var a = []
	var b = []
	var compare = false
	for idx in mdt.get_face_count():
		set_verts(idx)
		a = b
		b = []
		for m in 3:
			b.append(mdt.get_face_edge(idx, m))
		if compare:
			for k in 3:
				# Check for common edge
				var j = find_edge(a[k], b)
				if j > -1 and mdt.get_face_normal(idx).dot(mdt.get_face_normal(idx - 1)) > 0.98:
						common_faces[idx - 1] = idx
						common_faces[idx] = idx - 1
						compare = false
						# Mark the edge vertices for hiding
						for e in 2:
							var v = mdt.get_edge_vertex(a[k], e)
							var col: Color = mdt.get_vertex_color(v)
							col.a = 0
							mdt.set_vertex_color(v, col)
							v = mdt.get_edge_vertex(b[j], e)
							col = mdt.get_vertex_color(v)
							col.a = 0
							mdt.set_vertex_color(v, col)
						break
		else:
			compare = true
	current_mesh.clear_surfaces() # A new surface will be added
	mdt.commit_to_surface(current_mesh)


func find_edge(a: int, b: Array) -> int:
	var va1: Vector3 = mdt.get_vertex(mdt.get_edge_vertex(a, 0))
	var va2: Vector3 = mdt.get_vertex(mdt.get_edge_vertex(a, 1))
	for n in 3:
		var vb1 = mdt.get_vertex(mdt.get_edge_vertex(b[n], 1))
		var vb2 = mdt.get_vertex(mdt.get_edge_vertex(b[n], 0))
		if va1.is_equal_approx(vb1):
			if va2.is_equal_approx(vb2):
				return n
		elif va1.is_equal_approx(vb2) and va2.is_equal_approx(vb1):
			return n
	return -1


func set_verts(idx: int):
	var norm = mdt.get_face_normal(idx)
	for n in 3:
		var v_idx = mdt.get_face_vertex(idx, n)
		mdt.set_vertex_normal(v_idx, norm)
		mdt.set_vertex_color(v_idx, RGB[n])
		mdt.set_vertex_uv2(v_idx, Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if input_handled:
		input_handled = false
		return
	var mouse_pos = get_viewport().get_mouse_position()
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_C:
				selection_tool = CIRCLE
				circle_selector.position = mouse_pos
				set_circle_selector_scale()
				circle_selector.show()
				selecting = true
			KEY_ESCAPE:
				selection_tool = BOX
				circle_selector.hide()
				selecting = false
			KEY_U:
				remove_highlighting()
			KEY_DELETE:
				delete_selected_vertices()
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				if selection_tool == CIRCLE:
					scale_circle_selector(false)
				else:
					zoom_in(false)
			MOUSE_BUTTON_WHEEL_UP:
				if selection_tool == CIRCLE:
					scale_circle_selector(true)
				else:
					zoom_in(true)
			MOUSE_BUTTON_LEFT:
				if dragging and not event.pressed:
					dragging = false
					box_selector.hide()
					#prints("Capture box area", drag_start_position, mouse_pos)
					select_vertices_in_rect(Rect2(drag_start_position, mouse_pos - drag_start_position))
					match selection_mode:
						EDGE:
							var _edges = get_edges_in_selection()
						FACE:
							var _faces = get_faces_in_selection()
					update_selection()
				elif not event.pressed:
					if selection_tool == CIRCLE:
						select_vertices_in_circle(circle_selector.scale.x * 16.0, mouse_pos)
						match selection_mode:
							EDGE:
								var _edges = get_edges_in_selection()
							FACE:
								var _faces = get_faces_in_selection()
						update_selection()
					else:
						match selection_mode:
							FACE:
								select_face(mouse_pos)
								update_selection()
							EDGE:
								select_edge(mouse_pos)
								update_selection()
							VERTEX:
								select_vertex(mouse_pos)
								update_selection()
	if event is InputEventMouseMotion:
		if selecting:
			circle_selector.position = mouse_pos
			return
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			var dist = event.screen_relative / 100
			if Input.is_key_pressed(KEY_SHIFT):
				base.translate(-arm.transform.basis.x * dist.x * zoom_level)
				base.translate(arm.transform.basis.y * dist.y * zoom_level)
			else:
				base.rotate_y(-dist.x)
				arm.rotate_x(-dist.y)
				camera_rotated.emit(get_camera_basis())
			start_update_timer()
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if dragging:
				if Input.is_key_pressed(KEY_SPACE):
					var dist = event.screen_relative
					box_selector.position += dist
					drag_start_position += dist
				else:
					var amount = (mouse_pos - drag_start_position) / 32.0
					box_selector.scale = amount
					box_selector.material.set_shader_parameter("scale", amount)
					box_selector.show()
			else:
				drag_start_position = mouse_pos
				dragging = true
				box_selector.position = drag_start_position


func zoom_in(inwards: bool):
	# Only camera position.z changes
	var delta = 1.0
	if Input.is_key_pressed(KEY_CTRL): # Slow zoom
		delta = SLOW_ZOOM_MULTIPLIER
	elif Input.is_key_pressed(KEY_SHIFT): # Fast zoom
		delta = FAST_ZOOM_MULTIPLIER
	if inwards:
		delta *= -1
	apply_zoom(delta)


func drag_zoom(amount: Vector2):
	input_handled = true
	apply_zoom(amount.x / 10.0 + amount.y)


func drag_translate(amount: Vector2):
	input_handled = true
	$Base.translate(-$Base/Arm.transform.basis.x * amount.x * zoom_level)
	$Base.translate($Base/Arm.transform.basis.y * amount.y * zoom_level)
	start_update_timer()


func apply_zoom(delta):
	# May add a function to notify user about hitting the limits
	zoom_level = clamp(zoom_level + delta * ZOOM_SPEED, MIN_ZOOM, MAX_ZOOM)
	camera.position.z = zoom_level * zoom_level
	# Like a LOD feature for the grid
	var div = floor(sqrt(camera.position.z / cam_base_z) / GRID_SQUARES_ZOOM_JUMP_FACTOR)
	div = pow(GRID_MAJOR_INTERVAL, div)
	var grid_mat = $Grid.get_surface_override_material(0)
	grid_mat.set_shader_parameter("num_squares", int(GRID_SQUARES_DENSITY / div))
	grid_mat.set_shader_parameter("zoom", camera.position.z / cam_base_z)
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		camera.size = zoom_level * zoom_level
	start_update_timer()


func scale_circle_selector(shrink):
	var delta = 1.0
	if Input.is_key_pressed(KEY_SHIFT): # Fast zoom
		delta = FAST_ZOOM_MULTIPLIER
	if shrink:
		delta *= -1
	# May add a function to notify user about hitting the limits
	circle_selector_scale = clamp(circle_selector_scale + delta * CIRCLE_GROW_SPEED, CIRCLE_MIN_SCALE, CIRCLE_MAX_SCALE)
	set_circle_selector_scale()


func set_circle_selector_scale():
	circle_selector.material.set_shader_parameter("scale", circle_selector_scale)
	circle_selector.scale = Vector2(circle_selector_scale, circle_selector_scale)


func apply_rotation(amount: Vector2):
	base.rotate_y(-amount.x)
	arm.rotate_x(-amount.y)
	camera_rotated.emit(get_camera_basis())
	start_update_timer()


func get_camera_basis():
	return camera.global_basis.inverse()


func align_camera(target_basis: Basis):
	var xyrot = Helpers.decompose_rotation(target_basis)
	base.basis = Basis()
	arm.basis = Basis()
	# The basis if from a rotated gizmo so we invert the rotations that we apply to the camera
	base.rotate_y(-xyrot.y)
	arm.rotate_x(-xyrot.x)
	start_update_timer()


#region UI Actions
func _on_reset_basis_button_down() -> void:
	$Base.transform = Transform3D()
	start_update_timer()


func set_selection_mode(mode):
	input_handled = true
	Globals.vertex_button.deselect()
	Globals.edge_button.deselect()
	Globals.face_button.deselect()
	match mode:
		VERTEX:
			Globals.vertex_button.select()
			model.material_override.set_shader_parameter("edge_mode", 0.0)
			model.material_override.set_shader_parameter("vertex_mode", 1.0)
		EDGE:
			Globals.edge_button.select()
			model.material_override.set_shader_parameter("edge_mode", 1.0)
			model.material_override.set_shader_parameter("vertex_mode", 0.0)
		FACE:
			Globals.face_button.select()
			model.material_override.set_shader_parameter("edge_mode", 0.0)
			model.material_override.set_shader_parameter("vertex_mode", 0.0)
	selection_mode = mode
	remove_highlighting()


func perspective_button_pressed():
	if camera.projection == camera.PROJECTION_ORTHOGONAL:
		camera.projection = camera.PROJECTION_PERSPECTIVE
		camera.size = zoom_level * zoom_level
	else:
		camera.projection = camera.PROJECTION_ORTHOGONAL
		camera.position.z = camera.size


func vertex_button_pressed():
	set_selection_mode(VERTEX)


func edge_button_pressed():
	set_selection_mode(EDGE)


func face_button_pressed():
	set_selection_mode(FACE)


func triangles_button_pressed():
	set_view_mode(TRIANGLES)


func wireframe_button_pressed():
	set_view_mode(WIREMESH)


func solid_button_pressed():
	set_view_mode(SOLID)


func textured_button_pressed():
	set_view_mode(TEXTURED)


func set_view_mode(mode):
	input_handled = true
	if view_mode == mode:
		return
	view_mode = mode
	Globals.triangles_button.deselect()
	Globals.wireframe_button.deselect()
	Globals.solid_button.deselect()
	Globals.textured_button.deselect()
	model.material_override.set_shader_parameter("quad_mode", 1.0)
	match mode:
		TRIANGLES:
			Globals.triangles_button.select()
			model.material_overlay.shader = null
			model.material_override.shader = wireframe_shader
			model.material_override.set_shader_parameter("quad_mode", 0.0)
			#%Background.hide()
		WIREMESH:
			Globals.wireframe_button.select()
			model.material_overlay.shader = null
			model.material_override.shader = wireframe_shader
			#%Background.hide()
		SOLID:
			Globals.solid_button.select()
			model.material_override.shader = back_face_shader
			model.material_overlay.shader = faces_shader
			#%Background.show()
		TEXTURED:
			Globals.textured_button.select()
			model.material_override.shader = back_face_shader
			model.material_overlay.shader = faces_shader
			#%Background.show()


func add_selection(id: int):
	var mesh: PrimitiveMesh
	match id:
		CUBE:
			mesh = BoxMesh.new()
		CYLINDER:
			mesh = CylinderMesh.new()
		SPHERE:
			mesh = SphereMesh.new()
	current_mesh = ArrayMesh.new()
	current_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.get_mesh_arrays())
	deindex_mesh()
	set_mesh_vertex_data()
	$Model.mesh = current_mesh


func load_obj_file(txt: String):
	var mesh_data = Wavefront.obj_to_mesh_data(txt)
	current_mesh = Wavefront.create_triangluated_mesh(mesh_data)
	deindex_mesh()
	set_mesh_vertex_data()
	$Model.mesh = current_mesh


func save_obj_file(file: FileAccess):
	var txt = Wavefront.mesh_to_obj(mdt)
	file.store_string(txt)
#endregion


func _exit_tree() -> void:
	RenderingServer.free_rid(axis)
