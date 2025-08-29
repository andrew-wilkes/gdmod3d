extends TextureRect

class_name MultiGizmo

@export var DIAMETER = 512

enum { OFF, MOVE, ROTATE, SCALE, ALL }

var RADIUS = DIAMETER / 2.0
var MID_POINT = Vector2(RADIUS, RADIUS)

var drag_controller: DragController

# Get shader uniform values
var outer_ring_radius = material.get_shader_parameter("r2") * RADIUS
var inner_ring_radius = material.get_shader_parameter("r1") * RADIUS
var ring_thickness = material.get_shader_parameter("ring_thickness") * RADIUS
var disc_radius = material.get_shader_parameter("disc_radius") * RADIUS
var ellipse_a = material.get_shader_parameter("asize")
var ellipse_thickness = material.get_shader_parameter("ellipse_thickness")
var square_size = material.get_shader_parameter("square_size") * RADIUS
var square_offset = material.get_shader_parameter("square_pos") * RADIUS
var circle_radius = material.get_shader_parameter("small_circle_radius") * RADIUS
var circle_offset = material.get_shader_parameter("small_circle_pos") * RADIUS
var arm_hide_distance = inner_ring_radius / RADIUS * 2.5

var basis: Basis

func _ready() -> void:
	var img = Image.create_empty(DIAMETER, DIAMETER, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(img)
	gui_input.connect(handle_input)
	drag_controller = DragController.new(self, RADIUS)
	add_child(drag_controller)
	#drag_controller.dragged.connect(dragged_event)
	update_rotation(Basis())


func point_in_square(p: Vector2, pos: Vector2, dim: float) -> bool:
	var d2 = dim / 2.0
	pos.x -= d2
	pos.y -= d2
	var rect = Rect2(pos, Vector2(dim, dim))
	return rect.has_point(p)


func point_in_circle(p: Vector2, pos: Vector2, radius: float) -> bool:
	return (p - pos).length() < radius


func point_on_elipse(p: Vector2, a: float, normal: Vector3) -> bool:
	p /= RADIUS
	var up = normal.z > 0
	normal.z = abs(normal.z)
	var b = Vector3.BACK.dot(normal)
	var xy = Vector2(normal.x, normal.y)
	if xy.length() > 0.1:
		if b < 0.3: # Ignore when ring is hidden
			return false
		xy = xy.normalized()
		if b < 0.92: # Tilted
			var pdot = p.dot(xy)
			if up and pdot > 0: # Ignore back face
				return false
			if !up and pdot < 0:
				return false
		# rotate the point
		# Inverse rotation transform
		p = Vector2(xy.x * p.x + xy.y * p.y, -xy.y * p.x + xy.x * p.y)
	a = a / 2.2 * 0.64
	b *= a
	if b < 0.1:
		return false
	# Get a value from the equation for an eclipse and compare it for closeness to 1.0
	var v = (p.y * p.y / a / a + p.x * p.x / b / b)
	return abs(1.0 - v) < 0.12


func get_pos(v: Vector3, offset: float) -> Vector2:
	return Vector2(v.x, v.y) * offset


func check_point(p: Vector2) -> int:
	var pl = p.length()
	# Check for out of bounds
	if pl > RADIUS:
		return 0
	# Check for being inside inner ring
	if pl < inner_ring_radius:
		return 1
	# Check for being over a ball
	var pos = get_pos(basis.x, circle_offset)
	if point_in_circle(p, pos, circle_radius):
		return 2
	pos = get_pos(basis.y, circle_offset)
	if point_in_circle(p, pos, circle_radius):
		return 3
	pos = get_pos(basis.z, circle_offset)
	if point_in_circle(p, pos, circle_radius):
		return 4
	# Check for being over a square
	pos = get_pos(basis.x, square_offset)
	if point_in_square(p, pos, square_size):
		return 5
	pos = get_pos(basis.y, square_offset)
	if point_in_square(p, pos, square_size):
		return 6
	pos = get_pos(basis.z, square_offset)
	if point_in_square(p, pos, square_size):
		return 7
	# Check for being over an ellipse
	if point_on_elipse(p, ellipse_a, basis.x):
		return 8
	if point_on_elipse(p, ellipse_a, basis.y):
		return 9
	if point_on_elipse(p, ellipse_a, basis.z):
		return 10
	# Check for being over the disc
	if pl < disc_radius:
		return 11
	# Check for being over outer ring
	if pl < outer_ring_radius and pl > (outer_ring_radius - ring_thickness):
		return 12
	return 0


func update_rotation(b: Basis):
	basis = b
	material.set_shader_parameter("vx", basis.x)
	material.set_shader_parameter("vy", basis.y)
	material.set_shader_parameter("vz", basis.z)
	# Set visibility of arms
	material.set_shader_parameter("show_x", get_pos(basis.x, 1.0).length() > arm_hide_distance)
	material.set_shader_parameter("show_y", get_pos(basis.y, 1.0).length() > arm_hide_distance)
	material.set_shader_parameter("show_z", get_pos(basis.z, 1.0).length() > arm_hide_distance)


func handle_input(event: InputEvent):
	if event is InputEventMouseMotion:
		var p = Vector2(event.position.x - RADIUS, RADIUS - event.position.y)
		material.set_shader_parameter("mouse_uv", p / RADIUS)
