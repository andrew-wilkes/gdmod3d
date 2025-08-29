extends Node2D

# The circles have an idx meta value set associated with their child node index
# value for use in signal handling.

signal button_clicked(basis: Basis)
signal rotated(amount: Vector2)

@export var bg_color: Color
@export var red_color_x: Color
@export var green_color_x: Color
@export var blue_color_x: Color
@export var ring_radius = 0.35 # This is using UV dimensions of 0.0 .. 0.5
@export var bar_width = 2.0
@export var small_smoothing_factor = 0.02

const LARGE_RADIUS = 50
const SMALL_SIZE = 22
const CIRCLE_OFFSET = LARGE_RADIUS - SMALL_SIZE / 2.0
const MID_POINT = Vector2(LARGE_RADIUS, LARGE_RADIUS)
const SMALL_OFFSET = Vector2(SMALL_SIZE, SMALL_SIZE) / 2.0
const tt_text = "Click to set preset viewpoint"

var circle_idx = 0
var basis: Basis
var axis_positions = []
var red_color: Color
var green_color: Color
var blue_color: Color
var labels = [""]
var highlight_bg = false
var rotating = false
var drag_controller: DragController

enum { CB, RB, GB, BB, RBR, GBR, BBR, RF, GF, BF, RFR, GFR, BFR }

func _ready() -> void:
	configure_axes([0,1,2])
	generate_circles()
	set_circles()
	drag_controller = DragController.new(self, LARGE_RADIUS)
	add_child(drag_controller)
	drag_controller.dragged.connect(drag_event)


func configure_axes(rgb_order: Array) -> void:
	var chrs = "xyz"
	var colors = [red_color_x, green_color_x, blue_color_x]
	for n in 2:
		for idx in rgb_order:
			labels.append(chrs[idx])
		for idx in rgb_order:
			labels.append("-" + chrs[idx])
	red_color = colors[rgb_order[0]]
	green_color = colors[rgb_order[1]]
	blue_color = colors[rgb_order[2]]


func _draw() -> void:
	draw_line(axis_positions[0] + SMALL_OFFSET, MID_POINT, red_color, bar_width)
	draw_line(axis_positions[1] + SMALL_OFFSET, MID_POINT, green_color, bar_width)
	draw_line(axis_positions[2] + SMALL_OFFSET, MID_POINT, blue_color, bar_width)


func set_circles() -> void:
	basis.orthonormalized()
	axis_positions.clear()
	var front
	var back
	if basis.x.z >= 0.0: # Front
		front = get_child(RF)
		front.show()
		back = get_child(RBR)
		back.show()
		get_child(RB).hide()
		get_child(RFR).hide()
		set_circle_positions(front, back, basis.x)
		axis_positions.append(front.position)
	else:
		front = get_child(RFR)
		front.show()
		back = get_child(RB)
		back.show()
		get_child(RBR).hide()
		get_child(RF).hide()
		set_circle_positions(back, front, basis.x)
		axis_positions.append(back.position)
	if basis.y.z >= 0.0: # Front
		front = get_child(GF)
		front.show()
		back = get_child(GBR)
		back.show()
		get_child(GB).hide()
		get_child(GFR).hide()
		set_circle_positions(front, back, basis.y)
		axis_positions.append(front.position)
	else:
		front = get_child(GFR)
		front.show()
		back = get_child(GB)
		back.show()
		get_child(GBR).hide()
		get_child(GF).hide()
		set_circle_positions(back, front, basis.y)
		axis_positions.append(back.position)
	if basis.z.z >= 0.0: # Front
		front = get_child(BF)
		front.show()
		back = get_child(BBR)
		back.show()
		get_child(BB).hide()
		get_child(BFR).hide()
		set_circle_positions(front, back, basis.z)
		axis_positions.append(front.position)
	else:
		front = get_child(BFR)
		front.show()
		back = get_child(BB)
		back.show()
		get_child(BBR).hide()
		get_child(BF).hide()
		set_circle_positions(back, front, basis.z)
		axis_positions.append(back.position)


func set_circle_positions(front: Control, back: Control, v: Vector3) -> void:
	v *= CIRCLE_OFFSET

	front.position = Vector2(v.x + CIRCLE_OFFSET, CIRCLE_OFFSET - v.y)
	back.position = Vector2(CIRCLE_OFFSET - v.x, CIRCLE_OFFSET + v.y)


func generate_circles() -> void:
	var img = Image.create_empty(LARGE_RADIUS * 2, LARGE_RADIUS * 2, false, Image.FORMAT_RGBA8)
	$circle.texture = ImageTexture.create_from_image(img)
	var mat = $circle.material
	mat.set_shader_parameter("r1", 0.0)
	mat.set_shader_parameter("smoothing", small_smoothing_factor)
	mat.set_shader_parameter("color", bg_color)
	connect_mouse_events($circle, true)
	var small_img = Image.create_empty(SMALL_SIZE, SMALL_SIZE, false, Image.FORMAT_RGBA8)
	var pos = Vector2(20,20)
	# Back
	add_circle(0.0, red_color, pos, small_img, mat, "RB1")
	pos.x += 40
	add_circle(0.0, green_color, pos, small_img, mat, "GB2")
	pos.x += 40
	add_circle(0.0, blue_color, pos, small_img, mat, "BB3")
	pos = Vector2(20,40)
	add_circle(ring_radius, red_color, pos, small_img, mat, "RBR4")
	pos.x += 40
	add_circle(ring_radius, green_color, pos, small_img, mat, "GBR5")
	pos.x += 40
	add_circle(ring_radius, blue_color, pos, small_img, mat, "BBR6")
	# Front
	pos = Vector2(20,60)
	add_circle(0.0, red_color, pos, small_img, mat, "RF7")
	pos.x += 40
	add_circle(0.0, green_color, pos, small_img, mat, "GF8")
	pos.x += 40
	add_circle(0.0, blue_color, pos, small_img, mat, "BF9")
	pos = Vector2(20,80)
	add_circle(ring_radius, red_color, pos, small_img, mat, "RFR10")
	pos.x += 40

	add_circle(ring_radius, green_color, pos, small_img, mat, "GFR11")
	pos.x += 40
	add_circle(ring_radius, blue_color, pos, small_img, mat, "BFR12")


func add_circle(r1: float, color: Color, pos: Vector2, img: Image, mat: Material, nom: String, smoothing: float = 0.06) -> void:
	circle_idx += 1
	var circle = TextureRect.new()
	circle.set_meta("idx", circle_idx)
	add_child(circle)
	var label = Label.new()
	label.position = Vector2(7,-3)
	label.text = labels[circle_idx]
	circle.add_child(label)
	circle.name = nom
	circle.tooltip_text = tt_text
	# Hide minus labels
	if is_rear_idx(circle_idx):
		label.position.x = 5
		label.hide()
	connect_mouse_events(circle)
	circle.texture = ImageTexture.create_from_image(img)
	mat = mat.duplicate()
	mat.set_shader_parameter("r1", r1)

	mat.set_shader_parameter("smoothing", smoothing)
	mat.set_shader_parameter("color", color)
	circle.set_material(mat)
	circle.position = pos


func connect_mouse_events(node: TextureRect, background: bool = false) -> void:
	if !background:
		node.mouse_entered.connect(handle_mouse_in.bind(node))
	node.mouse_exited.connect(handle_mouse_out.bind(node))
	node.gui_input.connect(handle_gui_input.bind(node))


func handle_gui_input(event: InputEvent, node: TextureRect) -> void:
	get_viewport().set_input_as_handled()
	var node_idx = node.get_meta("idx")
	# Respond to entry to circle
	if distance_from_center() < LARGE_RADIUS:
		if event is InputEventMouseMotion and node_idx == 0:
			show_bg(true)
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if node_idx > 0:
					basis = Basis() 
					# Vector3.FORWARD = (0, 0, -1) The cameras forward direction
					match node_idx:
						RB, RF:
							basis = Basis(Vector3.BACK, Vector3.UP, Vector3.LEFT)
						RBR, RFR:
							basis = Basis(Vector3.FORWARD, Vector3.UP, Vector3.RIGHT)
						GB, GF:
							basis = Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
						GBR, GFR:
							basis = Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)
						BB, BF:
							basis = Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK)
						BBR, BFR:
							basis = Basis(Vector3.LEFT, Vector3.UP, Vector3.FORWARD)
					set_circles()
					queue_redraw()
					button_clicked.emit(basis)
	elif !drag_controller.dragging:
		show_bg(false)


func drag_event(amount: Vector2):
	rotated.emit(amount)


func update(target_basis: Basis):
	basis = target_basis
	set_circles()
	queue_redraw()


func handle_mouse_in(node: TextureRect) -> void:
	var node_idx = node.get_meta("idx")
	node.material.set_shader_parameter("highlight", 0.3)
	if is_rear_idx(node_idx):
		node.get_child(0).show()
	if node_idx > 0: # Allow for node at edge of circle
		show_bg(true)


func handle_mouse_out(node: TextureRect) -> void:
	var node_idx = node.get_meta("idx")
	if distance_from_center() > (LARGE_RADIUS - 2): # Allow for node at edge of circle
		if !drag_controller.dragging:
			show_bg(false)
	if node_idx > 0:
		node.material.set_shader_parameter("highlight", 0.0)
		if is_rear_idx(node_idx):
			node.get_child(0).hide()


func is_rear_idx(idx: int) -> bool:
	return (idx - 1) % 6 > 2


func distance_from_center() -> float:
	return ($circle.get_local_mouse_position() - MID_POINT).length()


func show_bg(showit: bool) -> void:
	if rotating:
		return
	if highlight_bg != showit:
		highlight_bg = showit
		if highlight_bg:
			$circle.modulate = bg_color
		else:
			$circle.modulate.a = 0
