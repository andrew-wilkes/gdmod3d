extends RefCounted

class_name Wavefront

class MeshData:
	var vertices = []
	var normals = []
	var uvs = []
	var faces = []


static func obj_to_mesh_data(obj_data: String) -> MeshData:
	var md = MeshData.new()
	var lines = obj_data.split("\n")
	for line in lines:
		if line.length() == 0:
			continue
		var el = line.split(" ")
		match el[0]:
			"v":
				if el.size() > 3:
					var vert = Vector3(float(el[1]), float(el[2]), float(el[3]))
					md.vertices.append(vert)
			"vt":
				if el.size() > 1:
					var uv = Vector2(float(el[1]), 0.0)
					if el.size() > 2:
						uv.y = float(el[2])
					md.uvs.append(uv)
			"vn":
				if el.size() > 3:
					var normal = Vector3(float(el[1]), float(el[2]), float(el[3])).normalized()
					md.normals.append(normal)
			"f": # Faces are likely to have 3 or more vertices in anti-clockwise winding order
				if el.size() > 3:
					var face = []
					for n in el.size() - 1:
						var ids = el[n + 1].split("/")
						var v_idx = int(ids[0]) - 1 # Index of vertex
						if v_idx < 0 or v_idx >= md.vertices.size():
							break
						var vert = [md.vertices[v_idx], -1, -1]
						if ids.size() > 1: # Texture
							if ids[1] != "":
								vert[1] = int(ids[1]) - 1
						if ids.size() > 2: # Normal
							if ids[2] != "":
								vert[2] = int(ids[2]) - 1
						face.append(vert)
					md.faces.append(face)
	return md


static func create_triangluated_mesh(md: MeshData) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tri = Triangulate.new()
	for face in md.faces:
		if face.size() == 0:
			continue
		var tris_norm = tri.triangulate(face)
		for triangle in tris_norm[0]:
			for vert in triangle:
				if vert[1] > -1:
					st.set_uv(md.uvs[vert[1]])
				if vert[2] > -1:
					st.set_normal(md.normals[vert[2]])
				st.add_vertex(vert[0])
	st.index()
	var mesh = st.commit()
	return mesh


static func mesh_to_obj(mdt: MeshDataTool, smoothed = false):
	var lines = ["# File exported from devmod3"]
	var normals = []
	var uvs = []
	var faces = []
	for v_idx in mdt.get_vertex_count():
		var vert = mdt.get_vertex(v_idx)
		lines.append("v %s %s %s" % [vert.x, vert.y, vert.z])
		if smoothed:
			normals.append(mdt.get_vertex_normal(v_idx))
		uvs.append(mdt.get_vertex_uv(v_idx))
	for f_idx in mdt.get_face_count():
		var fvs = []
		var fns = []
		for n in 3:
			var v_idx = mdt.get_face_vertex(f_idx, n)
			fvs.append(v_idx + 1)
			if smoothed:
				fns.append(v_idx + 1)
			else:
				fns.append(f_idx + 1)
		if not smoothed:
			normals.append(mdt.get_face_normal(f_idx))
		# Reverse the winding order
		faces.append("f %d/%d/%d %d/%d/%d %d/%d/%d" % [fvs[2],fvs[2],fns[2],fvs[1],fvs[1],fns[1],fvs[0],fvs[0],fns[0]])
	for normal in normals:
		lines.append("vn %s %s %s" % [normal.x, normal.y, normal.z])
	for uv in uvs:
		lines.append("vt %s %s" % [uv.x, uv.y])
	lines.append_array(faces)
	var txt = "\n".join(lines)
	return txt
