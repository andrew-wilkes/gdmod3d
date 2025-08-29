extends Node2D

var base: Transform3D
var arm: Transform3D
@onready var multi: MultiGizmo = $MultiGizmo

func _ready() -> void:
	base = Transform3D()
	arm = Transform3D()
	$orbit_gizmo.rotated.connect(apply_rotation)
	$orbit_gizmo.button_clicked.connect(align_camera)


func apply_rotation(amount: Vector2):
	# x,y here are in 2D screen space
	base.basis = base.basis.rotated(Vector3.UP, amount.x)
	arm.basis = arm.basis.rotated(Vector3.RIGHT, amount.y)
	update_rotation()


func align_camera(target_basis: Basis):
	var xyrot = Helpers.decompose_rotation(target_basis)
	base.basis = Basis()
	arm.basis = Basis()
	base.basis = base.basis.rotated(Vector3.UP, xyrot.y)
	arm.basis = arm.basis.rotated(Vector3.RIGHT, xyrot.x)
	update_rotation()


func update_rotation():
	var trans = base * arm
	multi.update_rotation(trans.basis)
	$orbit_gizmo.update(trans.basis)
