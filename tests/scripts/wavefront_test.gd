# GdUnit generated TestSuite
class_name WavefrontTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

# TestSuite generated from
const __source = 'res://scripts/wavefront.gd'

func get_mesh_data():
	var cube = Helpers.load_from_file("res://assets/cube.obj")
	var md = Wavefront.obj_to_mesh_data(cube)
	return md


func get_mesh_data_tool_object():
	var md = get_mesh_data()
	var mesh = Wavefront.create_triangluated_mesh(md)
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	return mdt


func test_obj_to_mesh_data() -> void:
	var md = get_mesh_data()
	assert_int(md.faces.size()).is_equal(6)
	assert_int(md.normals.size()).is_equal(6)
	assert_int(md.vertices.size()).is_equal(8)
	assert_int(md.uvs.size()).is_equal(14)


func test_create_triangluated_mesh() -> void:
	var mdt = get_mesh_data_tool_object()
	assert_int(mdt.get_face_count()).is_equal(12)
	assert_int(mdt.get_vertex_count()).is_equal(24)


func test_mesh_to_obj() -> void:
	var mdt = get_mesh_data_tool_object()
	var txt = Wavefront.mesh_to_obj(mdt)
	assert_int(txt.split("\n").size()).is_equal(73)


func test_mesh_to_obj_smoothed() -> void:
	var mdt = get_mesh_data_tool_object()
	var txt = Wavefront.mesh_to_obj(mdt, true)
	assert_int(txt.split("\n").size()).is_equal(85)
