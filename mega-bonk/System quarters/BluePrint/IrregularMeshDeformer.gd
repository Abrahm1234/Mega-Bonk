extends RefCounted
class_name IrregularMeshDeformer

# Deform a source mesh that fits inside its own AABB into a target quad prism.
# For each vertex v in source space:
#   u = % along X in source AABB (0..1)
#   t = % along Y in source AABB (0..1)
#   w = % along Z in source AABB (0..1)
# Then we reconstruct:
#   bottom(u,w) = bilerp(quad bottom corners)
#   top(u,w)    = bilerp(quad top corners)
#   out         = lerp(bottom, top, t)
#
# This is a simple 8-handle (AABB corners) lattice deformer.

static func _clamp01(x: float) -> float:
	return clamp(x, 0.0, 1.0)

static func _bilerp(p00: Vector3, p10: Vector3, p11: Vector3, p01: Vector3, u: float, w: float) -> Vector3:
	# (0,0)=p00, (1,0)=p10, (1,1)=p11, (0,1)=p01
	var a: Vector3 = p00.lerp(p10, u)
	var b: Vector3 = p01.lerp(p11, u)
	return a.lerp(b, w)

static func append_deformed_mesh_to_surfacetool(
		st: SurfaceTool,
		src_mesh: Mesh,
		quad_world: Array[Vector3], # size 4, CCW: p0,p1,p2,p3
		up: Vector3,
		height: float
	) -> void:
	# Duplicates vertices per triangle to avoid index-offset bookkeeping.
	if st == null or src_mesh == null or quad_world.size() != 4:
		return

	var aabb: AABB = src_mesh.get_aabb()
	var sx: float = max(aabb.size.x, 1e-6)
	var sy: float = max(aabb.size.y, 1e-6)
	var sz: float = max(aabb.size.z, 1e-6)

	var p00: Vector3 = quad_world[0]
	var p10: Vector3 = quad_world[1]
	var p11: Vector3 = quad_world[2]
	var p01: Vector3 = quad_world[3]
	var p00t: Vector3 = p00 + up * height
	var p10t: Vector3 = p10 + up * height
	var p11t: Vector3 = p11 + up * height
	var p01t: Vector3 = p01 + up * height

	for si in range(src_mesh.get_surface_count()):
		var arrays: Array = src_mesh.surface_get_arrays(si)
		if arrays.is_empty():
			continue

		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if verts.is_empty():
			continue

		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var has_uv: bool = (uvs.size() == verts.size())

		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var has_idx: bool = not idx.is_empty()

		if has_idx:
			for i in range(0, idx.size(), 3):
				for k in range(3):
					var vi: int = int(idx[i + k])
					var v: Vector3 = verts[vi]

					var u: float = _clamp01((v.x - aabb.position.x) / sx)
					var t: float = _clamp01((v.y - aabb.position.y) / sy)
					var w: float = _clamp01((v.z - aabb.position.z) / sz)

					var btm: Vector3 = _bilerp(p00, p10, p11, p01, u, w)
					var top: Vector3 = _bilerp(p00t, p10t, p11t, p01t, u, w)
					var outp: Vector3 = btm.lerp(top, t)

					if has_uv:
						st.set_uv(uvs[vi])
					else:
						st.set_uv(Vector2(u, w))
					st.add_vertex(outp)
		else:
			# No indices: assume triangles packed.
			for vi in range(0, verts.size(), 3):
				for k in range(3):
					var v: Vector3 = verts[vi + k]

					var u: float = _clamp01((v.x - aabb.position.x) / sx)
					var t: float = _clamp01((v.y - aabb.position.y) / sy)
					var w: float = _clamp01((v.z - aabb.position.z) / sz)

					var btm: Vector3 = _bilerp(p00, p10, p11, p01, u, w)
					var top: Vector3 = _bilerp(p00t, p10t, p11t, p01t, u, w)
					var outp: Vector3 = btm.lerp(top, t)

					if has_uv:
						st.set_uv(uvs[vi + k])
					else:
						st.set_uv(Vector2(u, w))
					st.add_vertex(outp)
