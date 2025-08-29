extends Node2D

class_name FaceOutliner

func update(points: Array, camera: Camera3D):
	$Line2D.clear_points()
	for point in points:
		$Line2D.add_point(camera.unproject_position(point))
