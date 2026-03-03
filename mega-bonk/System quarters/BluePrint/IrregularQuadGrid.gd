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

	var used_tri: PackedByteArray = PackedByteArray()
	used_tri.resize(triangles.size())
	for i in range(used_tri.size()):
		used_tri[i] = 0

	var quads: Array[PackedInt32Array] = []

	# Greedy maximal pairing of triangles into quads.
	# Pass 0 respects dissolve_chance (controls irregularity).
	# Pass 1+ tries to pair any remaining triangles (prevents lots of leftover triangles,
	# which would otherwise force extra subdivisions and raise resolution).
	var max_passes: int = 6
	for pass_i in range(max_passes):
		var candidates: Array[String] = []
		for key in edge_to_tris.keys():
			var tri_list: Array = edge_to_tris[key]
			if tri_list.size() != 2:
				continue
			var t0i: int = tri_list[0]
			var t1i: int = tri_list[1]
			if used_tri[t0i] != 0 or used_tri[t1i] != 0:
				continue
			candidates.append(key)

		# Shuffle candidates deterministically using rng.
		for i in range(candidates.size() - 1, 0, -1):
			var j: int = rng.randi_range(0, i)
			var tmp: String = candidates[i]
			candidates[i] = candidates[j]
			candidates[j] = tmp

		var did_pair: bool = false
		for key in candidates:
			var tri_list: Array = edge_to_tris[key]
			if tri_list.size() != 2:
				continue
			var t0i: int = tri_list[0]
			var t1i: int = tri_list[1]
			if used_tri[t0i] != 0 or used_tri[t1i] != 0:
				continue

			# Only the first pass is "random dissolve". Later passes finish pairing.
			if pass_i == 0 and rng.randf() > dissolve_chance:
				continue

			var shared: PackedInt32Array = _edge_from_key(key)
			var t0: PackedInt32Array = triangles[t0i]
			var t1: PackedInt32Array = triangles[t1i]
			var a: int = _tri_other(t0, shared[0], shared[1])
			var b: int = _tri_other(t1, shared[0], shared[1])
			var q: PackedInt32Array = _sort_cycle([a, shared[0], b, shared[1]], points)
			quads.append(q)
			used_tri[t0i] = 1
			used_tri[t1i] = 1
			did_pair = true

		if not did_pair:
			break

	# Remaining triangles: convert each to ONE quad (adds a single midpoint).
	# This keeps resolution low (avoid triangle -> 3 quads which explodes detail).
	var cap_mid: Dictionary = {}


	for ti in range(triangles.size()):
		if used_tri[ti] != 0:
			continue
		var t: PackedInt32Array = triangles[ti]
		var a: int = t[0]
		var b: int = t[1]
		var c: int = t[2]
		var pa: Vector2 = points[a]
		var pb: Vector2 = points[b]
		var pc: Vector2 = points[c]

		# Pick the longest edge to split for a nicer quad.
		var dab: float = pa.distance_squared_to(pb)
		var dbc: float = pb.distance_squared_to(pc)
		var dca: float = pc.distance_squared_to(pa)

		var v0: int
		var v1: int
		var v2: int
		if dab >= dbc and dab >= dca:
			v0 = a; v1 = b; v2 = c
		elif dbc >= dab and dbc >= dca:
			v0 = b; v1 = c; v2 = a
		else:
			v0 = c; v1 = a; v2 = b

		var mid_idx: int = _get_or_create_midpoint(cap_mid, points, boundary, v0, v1)
		var q: PackedInt32Array = _sort_cycle([v0, mid_idx, v1, v2], points)
		quads.append(q)

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


# Step 6: Tile multiple hex patches into a larger, seamless quad grid.
# - tile_radius = 0 -> single patch (same as build_hex_patch)
# - tile_radius = 1 -> 7 patches (center + 6 neighbors), 2 -> 19, etc.
#
# Important implementation detail:
# We build ONE canonical patch topology, then instance it many times.
# Boundary vertices of the canonical patch are NOT jittered so seams weld perfectly.
# After welding, we run a GLOBAL relaxation with only the OUTER boundary pinned,
# so former patch seams become interior and smooth out.
static func build_tiled_hex_grid(
	rings: int,
	spacing: float,
	tile_radius: int,
	dissolve_chance: float,
	subdivide_quads: bool,
	relax_iters: int,
	relax_alpha: float,
	rng: RandomNumberGenerator,
	interior_jitter: float = -1.0
) -> Dictionary:
	var r: int = max(rings, 1)
	var s: float = max(spacing, 0.001)
	var tr: int = max(tile_radius, 0)
	if tr <= 0:
		return build_hex_patch(r, s, dissolve_chance, subdivide_quads, relax_iters, relax_alpha, rng)

	# Patch-to-patch center spacing (flat-top hex tiling).
	# Canonical patch is a regular flat-top hex with side length A = r * s.
	var A: float = float(r) * s
	var ROOT3: float = 1.7320508075688772

	# Build ONE canonical patch (no relaxation yet; we do global relaxation after welding).
	var base_rng := RandomNumberGenerator.new()
	base_rng.seed = rng.randi()
	var base: Dictionary = build_hex_patch(r, s, dissolve_chance, subdivide_quads, 0, 0.0, base_rng)
	var base_points: Array[Vector2] = base.get("points", [])
	var base_quads: Array[PackedInt32Array] = base.get("quads", [])

	# Recompute canonical boundary from quads (captures any boundary midpoints).
	var base_boundary: PackedByteArray = _compute_boundary_from_quads(base_quads, base_points.size())

	# Default jitter (~12% of point spacing).
	var jitter: float = interior_jitter
	if jitter < 0.0:
		jitter = s * 0.12
	jitter = max(jitter, 0.0)

	# Weld tolerance (quantization).
	var eps: float = max(s * 0.001, 0.0001)

	var points: Array[Vector2] = []
	var quads: Array[PackedInt32Array] = []
	var weld: Dictionary = {} # Vector2i -> global vertex index

	for cx in range(-tr, tr + 1):
		for cy in range(-tr, tr + 1):
			var cz: int = -cx - cy
			if max(abs(cx), abs(cy), abs(cz)) > tr:
				continue

			# Convert axial (q=cx, r=cy) to 2D center offset for flat-top hex tiling.
			# x = 3/2 * A * q
			# y = sqrt(3) * A * (r + q/2)
			var ox: float = 1.5 * A * float(cx)
			var oy: float = ROOT3 * A * (float(cy) + float(cx) * 0.5)
			var offset: Vector2 = Vector2(ox, oy)

			# Per-patch rng for interior jitter (keeps patch topology the same, avoids identical-looking repeats).
			var prng := RandomNumberGenerator.new()
			prng.seed = int(rng.randi()) ^ int((cx + 1000) * 73856093) ^ int((cy + 1000) * 19349663)

			var remap: PackedInt32Array = PackedInt32Array()
			remap.resize(base_points.size())

			for i in range(base_points.size()):
				var p: Vector2 = base_points[i] + offset
				# Only jitter INTERIOR vertices so boundary seams weld perfectly.
				if base_boundary[i] == 0 and jitter > 0.0:
					p += Vector2(prng.randf_range(-jitter, jitter), prng.randf_range(-jitter, jitter))

				var key := Vector2i(int(round(p.x / eps)), int(round(p.y / eps)))
				if weld.has(key):
					remap[i] = int(weld[key])
				else:
					var gi: int = points.size()
					points.append(p)
					weld[key] = gi
					remap[i] = gi

			for q in base_quads:
				quads.append(PackedInt32Array([
					remap[q[0]],
					remap[q[1]],
					remap[q[2]],
					remap[q[3]],
				]))

	# Global boundary + global relaxation (outer boundary pinned only).
	var boundary: PackedByteArray = _compute_boundary_from_quads(quads, points.size())
	_relax(points, boundary, quads, relax_iters, relax_alpha)

	# Dual graph (face centers + adjacency).
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

static func _compute_boundary_from_quads(quads: Array[PackedInt32Array], point_count: int) -> PackedByteArray:
	var edge_count: Dictionary = {}
	for q in quads:
		for e in range(4):
			var k: String = _edge_key(q[e], q[(e + 1) % 4])
			edge_count[k] = int(edge_count.get(k, 0)) + 1

	var boundary: PackedByteArray = PackedByteArray()
	boundary.resize(point_count)
	for i in range(point_count):
		boundary[i] = 0

	for k in edge_count.keys():
		if int(edge_count[k]) == 1:
			var edge: PackedInt32Array = _edge_from_key(k)
			boundary[edge[0]] = 1
			boundary[edge[1]] = 1

	return boundary

static func _subdivide_quads(points: Array[Vector2], boundary: PackedByteArray, quads: Array[PackedInt32Array]) -> Array[PackedInt32Array]:
	# IMPORTANT: reuse edge midpoints across adjacent quads so we don't accidentally
	# create "extra resolution" and seams where edges should be shared.
	var out: Array[PackedInt32Array] = []
	var edge_mid: Dictionary = {}
	for q in quads:
		var i0: int = q[0]
		var i1: int = q[1]
		var i2: int = q[2]
		var i3: int = q[3]
		var m01: int = _get_or_create_midpoint(edge_mid, points, boundary, i0, i1)
		var m12: int = _get_or_create_midpoint(edge_mid, points, boundary, i1, i2)
		var m23: int = _get_or_create_midpoint(edge_mid, points, boundary, i2, i3)
		var m30: int = _get_or_create_midpoint(edge_mid, points, boundary, i3, i0)
		var c: int = points.size()
		points.append((points[i0] + points[i1] + points[i2] + points[i3]) * 0.25)
		boundary.append(0)
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

static func _get_or_create_midpoint(edge_mid: Dictionary, points: Array[Vector2], boundary: PackedByteArray, a: int, b: int) -> int:
	var k: String = _edge_key(a, b)
	if edge_mid.has(k):
		return int(edge_mid[k])
	var p: Vector2 = (points[a] + points[b]) * 0.5
	var idx: int = points.size()
	points.append(p)
	# If both endpoints are boundary points, keep the midpoint on the boundary too.
	boundary.append(1 if boundary[a] != 0 and boundary[b] != 0 else 0)
	edge_mid[k] = idx
	return idx


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
