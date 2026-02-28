extends RefCounted
class_name IrregularQuadGrid

static func build_hex_patch(
	rings: int,
	spacing: float,
	dissolve_chance: float,
	subdivide_quads: bool,
	relax_iters: int,
	relax_alpha: float,
	rng: RandomNumberGenerator
) -> Dictionary:
	var r: int = max(rings, 1)
	var s: float = max(spacing, 0.001)
	var points: Array[Vector2] = []
	var boundary: PackedByteArray = PackedByteArray()
	var axial_to_idx: Dictionary = {}

	for q in range(-r, r + 1):
		for rr in range(-r, r + 1):
			var ss: int = -q - rr
			if max(abs(q), abs(rr), abs(ss)) > r:
				continue
			var p: Vector2 = Vector2((float(q) + float(rr) * 0.5) * s, float(rr) * s * 0.8660254038)
			axial_to_idx[Vector2i(q, rr)] = points.size()
			points.append(p)
			boundary.append(1 if max(abs(q), abs(rr), abs(ss)) == r else 0)

	var triangles: Array[PackedInt32Array] = []
	for q in range(-r, r):
		for rr in range(-r, r):
			var a: Vector2i = Vector2i(q, rr)
			var b: Vector2i = Vector2i(q + 1, rr)
			var c: Vector2i = Vector2i(q, rr + 1)
			var d: Vector2i = Vector2i(q + 1, rr + 1)
			if axial_to_idx.has(a) and axial_to_idx.has(b) and axial_to_idx.has(c):
				triangles.append(PackedInt32Array([axial_to_idx[a], axial_to_idx[b], axial_to_idx[c]]))
			if axial_to_idx.has(b) and axial_to_idx.has(d) and axial_to_idx.has(c):
				triangles.append(PackedInt32Array([axial_to_idx[b], axial_to_idx[d], axial_to_idx[c]]))

	var edge_to_tris: Dictionary = {}
	for ti in range(triangles.size()):
		var t: PackedInt32Array = triangles[ti]
		for e in range(3):
			var i0: int = t[e]
			var i1: int = t[(e + 1) % 3]
			var key: String = _edge_key(i0, i1)
			var arr: Array = edge_to_tris.get(key, [])
			arr.append(ti)
			edge_to_tris[key] = arr

	var used_tri: Dictionary = {}
	var quads: Array[PackedInt32Array] = []
	for key in edge_to_tris.keys():
		var tri_list: Array = edge_to_tris[key]
		if tri_list.size() != 2:
			continue
		if rng.randf() > dissolve_chance:
			continue
		var t0i: int = tri_list[0]
		var t1i: int = tri_list[1]
		if used_tri.has(t0i) or used_tri.has(t1i):
			continue
		var shared: PackedInt32Array = _edge_from_key(key)
		var t0: PackedInt32Array = triangles[t0i]
		var t1: PackedInt32Array = triangles[t1i]
		var a: int = _tri_other(t0, shared[0], shared[1])
		var b: int = _tri_other(t1, shared[0], shared[1])
		var q: PackedInt32Array = _sort_cycle([a, shared[0], b, shared[1]], points)
		quads.append(q)
		used_tri[t0i] = true
		used_tri[t1i] = true

	for ti in range(triangles.size()):
		if used_tri.has(ti):
			continue
		var t: PackedInt32Array = triangles[ti]
		var a: int = t[0]
		var b: int = t[1]
		var c: int = t[2]
		var pa: Vector2 = points[a]
		var pb: Vector2 = points[b]
		var pc: Vector2 = points[c]
		var m_ab_idx: int = points.size()
		points.append((pa + pb) * 0.5)
		boundary.append(0)
		var m_bc_idx: int = points.size()
		points.append((pb + pc) * 0.5)
		boundary.append(0)
		var m_ca_idx: int = points.size()
		points.append((pc + pa) * 0.5)
		boundary.append(0)
		var center_idx: int = points.size()
		points.append((pa + pb + pc) / 3.0)
		boundary.append(0)
		quads.append(PackedInt32Array([a, m_ab_idx, center_idx, m_ca_idx]))
		quads.append(PackedInt32Array([b, m_bc_idx, center_idx, m_ab_idx]))
		quads.append(PackedInt32Array([c, m_ca_idx, center_idx, m_bc_idx]))

	if subdivide_quads:
		quads = _subdivide_quads(points, boundary, quads)

	_relax(points, boundary, quads, relax_iters, relax_alpha)

	var centers: Array[Vector2] = []
	centers.resize(quads.size())
	for i in range(quads.size()):
		var q: PackedInt32Array = quads[i]
		centers[i] = (points[q[0]] + points[q[1]] + points[q[2]] + points[q[3]]) * 0.25

	var dual_edges: Array[Vector2i] = []
	var edge_to_face: Dictionary = {}
	for fi in range(quads.size()):
		var q: PackedInt32Array = quads[fi]
		for e in range(4):
			var k: String = _edge_key(q[e], q[(e + 1) % 4])
			var arr: Array = edge_to_face.get(k, [])
			arr.append(fi)
			edge_to_face[k] = arr
	for k in edge_to_face.keys():
		var fs: Array = edge_to_face[k]
		if fs.size() == 2:
			dual_edges.append(Vector2i(fs[0], fs[1]))

	return {
		"points": points,
		"quads": quads,
		"boundary": boundary,
		"face_centers": centers,
		"dual_edges": dual_edges,
	}

static func _subdivide_quads(points: Array[Vector2], boundary: PackedByteArray, quads: Array[PackedInt32Array]) -> Array[PackedInt32Array]:
	var out: Array[PackedInt32Array] = []
	for q in quads:
		var i0: int = q[0]
		var i1: int = q[1]
		var i2: int = q[2]
		var i3: int = q[3]
		var p0: Vector2 = points[i0]
		var p1: Vector2 = points[i1]
		var p2: Vector2 = points[i2]
		var p3: Vector2 = points[i3]
		var m01: int = points.size(); points.append((p0 + p1) * 0.5); boundary.append(0)
		var m12: int = points.size(); points.append((p1 + p2) * 0.5); boundary.append(0)
		var m23: int = points.size(); points.append((p2 + p3) * 0.5); boundary.append(0)
		var m30: int = points.size(); points.append((p3 + p0) * 0.5); boundary.append(0)
		var c: int = points.size(); points.append((p0 + p1 + p2 + p3) * 0.25); boundary.append(0)
		out.append(PackedInt32Array([i0, m01, c, m30]))
		out.append(PackedInt32Array([m01, i1, m12, c]))
		out.append(PackedInt32Array([c, m12, i2, m23]))
		out.append(PackedInt32Array([m30, c, m23, i3]))
	return out

static func _relax(points: Array[Vector2], boundary: PackedByteArray, quads: Array[PackedInt32Array], iters: int, alpha: float) -> void:
	var relax_n: int = max(iters, 0)
	var a: float = clamp(alpha, 0.0, 1.0)
	if relax_n == 0 or a <= 0.0:
		return
	var neigh: Array[Dictionary] = []
	neigh.resize(points.size())
	for i in range(points.size()):
		neigh[i] = {}
	for q in quads:
		for e in range(4):
			var i0: int = q[e]
			var i1: int = q[(e + 1) % 4]
			(neigh[i0] as Dictionary)[i1] = true
			(neigh[i1] as Dictionary)[i0] = true
	for _i in range(relax_n):
		var next: Array[Vector2] = []
		next.resize(points.size())
		for p_idx in range(points.size()):
			if p_idx < boundary.size() and boundary[p_idx] != 0:
				next[p_idx] = points[p_idx]
				continue
			var ns: Array = (neigh[p_idx] as Dictionary).keys()
			if ns.is_empty():
				next[p_idx] = points[p_idx]
				continue
			var avg: Vector2 = Vector2.ZERO
			for n in ns:
				avg += points[int(n)]
			avg /= float(ns.size())
			next[p_idx] = points[p_idx].lerp(avg, a)
		points.assign(next)

static func _edge_key(a: int, b: int) -> String:
	if a < b:
		return "%d_%d" % [a, b]
	return "%d_%d" % [b, a]

static func _edge_from_key(key: String) -> PackedInt32Array:
	var parts: PackedStringArray = key.split("_")
	return PackedInt32Array([int(parts[0]), int(parts[1])])

static func _tri_other(t: PackedInt32Array, i0: int, i1: int) -> int:
	for i in t:
		if i != i0 and i != i1:
			return i
	return t[0]

static func _sort_cycle(indices: Array, points: Array[Vector2]) -> PackedInt32Array:
	var center: Vector2 = Vector2.ZERO
	for idx in indices:
		center += points[int(idx)]
	center /= float(indices.size())
	indices.sort_custom(func(a, b):
		var pa: Vector2 = points[int(a)] - center
		var pb: Vector2 = points[int(b)] - center
		return atan2(pa.y, pa.x) < atan2(pb.y, pb.x)
	)
	return PackedInt32Array([int(indices[0]), int(indices[1]), int(indices[2]), int(indices[3])])
