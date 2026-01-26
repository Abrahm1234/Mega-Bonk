extends Node3D
class_name BlockyTerrain

@export var size_x: int = 256
@export var size_z: int = 256
@export var cell_size: float = 2.0

# Voxel look
@export var height_step: float = 2.0
@export var min_height: float = -10.0

# Box / world bounds
@export var outer_floor_height: float = -40.0
@export var box_height: float = 80.0
@export var build_ceiling: bool = false

# Low-res arena noise (macro shapes)
@export var arena_lr_cells: int = 32
@export var arena_noise_seed: int = 1234
@export var arena_noise_frequency: float = 0.08
@export var arena_noise_octaves: int = 3
@export var arena_noise_lacunarity: float = 2.0
@export var arena_noise_gain: float = 0.5
@export var arena_height_scale: float = 26.0

# Arena shaping / readability
@export var center_flat_radius_m: float = 55.0
@export var center_flat_strength: float = 0.75  # 0..1
@export var outer_ramp_strength: float = 0.35   # 0..1

# Make hills chunkier (horizontal block size)
@export var macro_block_size_m: float = 8.0
@export var use_nearest_upsample: bool = true

# Optional slope control (can flatten if too aggressive)
@export var max_step_per_cell: float = 0.0      # set 0 to disable
@export var step_clamp_passes: int = 0

# 1-step ramp rule
@export var enable_step_ramps: bool = true

# Access ramp pass (multi-step grading)
@export var ensure_access: bool = true
@export var access_ramp_count: int = 12
@export var access_ramp_width_cells: int = 3
@export var access_run_per_step: int = 3
@export var access_max_iterations: int = 4
@export var access_min_cliff_steps: int = 2

# Roads (connect unreachable regions)
@export var build_roads: bool = true
@export var road_count_budget: int = 32
@export var road_width_cells: int = 4
@export var road_run_per_step: int = 3
@export var road_max_iters: int = 6
@export var road_min_region_size: int = 64
@export var road_extra_loops: int = 2

@export var terrain_color: Color = Color(0.32, 0.68, 0.34, 1.0)
@export var road_color: Color = Color(0.85, 0.12, 0.12, 1.0)

@onready var mesh_instance: MeshInstance3D = $TerrainBody/TerrainMesh
@onready var collision_shape: CollisionShape3D = $TerrainBody/TerrainCollision

var heights: PackedFloat32Array
var road_mask: PackedByteArray
var _ox: float
var _oz: float

func _ready() -> void:
	generate()

func generate() -> void:
	_ox = -float(size_x) * cell_size * 0.5
	_oz = -float(size_z) * cell_size * 0.5
	_generate_heights()
	road_mask = PackedByteArray()
	road_mask.resize(size_x * size_z)
	for i in range(road_mask.size()):
		road_mask[i] = 0
	if build_roads:
		_build_roads()
	if ensure_access:
		_build_access_ramps()
	_build_blocky_mesh_and_collision()

# -----------------------------
# HEIGHTS
# -----------------------------
func _generate_heights() -> void:
	heights = PackedFloat32Array()
	heights.resize(size_x * size_z)

	var lr: int = max(2, arena_lr_cells)
	var lr_grid: PackedFloat32Array = PackedFloat32Array()
	lr_grid.resize(lr * lr)

	var noise := FastNoiseLite.new()
	noise.seed = arena_noise_seed
	noise.frequency = arena_noise_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = arena_noise_octaves
	noise.fractal_lacunarity = arena_noise_lacunarity
	noise.fractal_gain = arena_noise_gain

	for gz in range(lr):
		for gx in range(lr):
			var n: float = noise.get_noise_2d(float(gx), float(gz))
			n = signf(n) * pow(absf(n), 1.35)
			lr_grid[gz * lr + gx] = n

	var cx_cells: float = (float(size_x) - 1.0) * 0.5
	var cz_cells: float = (float(size_z) - 1.0) * 0.5
	var flat_r_cells: float = maxf(0.0, center_flat_radius_m / cell_size)
	var block_cells: int = max(1, int(round(macro_block_size_m / cell_size)))

	for z in range(size_z):
		for x in range(size_x):
			# Macro chunking (sample the same low-res coord within each macro block)
			var sx: int = int(floor(float(x) / float(block_cells))) * block_cells
			var sz: int = int(floor(float(z) / float(block_cells))) * block_cells

			var u: float = float(sx) / maxf(1.0, float(size_x - 1)) * float(lr - 1)
			var v: float = float(sz) / maxf(1.0, float(size_z - 1)) * float(lr - 1)

			var nxy: float
			if use_nearest_upsample:
				var gx_i: int = clampi(int(round(u)), 0, lr - 1)
				var gz_i: int = clampi(int(round(v)), 0, lr - 1)
				nxy = lr_grid[gz_i * lr + gx_i]
			else:
				var x0: int = int(floor(u))
				var z0: int = int(floor(v))
				var x1: int = min(x0 + 1, lr - 1)
				var z1: int = min(z0 + 1, lr - 1)
				var fu: float = u - float(x0)
				var fv: float = v - float(z0)

				var n00: float = lr_grid[z0 * lr + x0]
				var n10: float = lr_grid[z0 * lr + x1]
				var n01: float = lr_grid[z1 * lr + x0]
				var n11: float = lr_grid[z1 * lr + x1]

				var nx0: float = lerpf(n00, n10, fu)
				var nx1: float = lerpf(n01, n11, fu)
				nxy = lerpf(nx0, nx1, fv)

			# IMPORTANT: heights are around 0, not around outer_floor_height
			var h: float = nxy * arena_height_scale

			# Center flatten blends toward 0.0 (NOT toward floor_y)
			if flat_r_cells > 0.0:
				var dx: float = float(x) - cx_cells
				var dz: float = float(z) - cz_cells
				var d: float = sqrt(dx * dx + dz * dz)
				var t: float = clampf(d / flat_r_cells, 0.0, 1.0)
				var flatten: float = lerpf(center_flat_strength, 0.0, t)
				h = lerpf(h, 0.0, flatten)

			# Raise edges a bit (optional)
			var dxw: float = absf(float(x) - cx_cells) / maxf(1.0, cx_cells)
			var dzw: float = absf(float(z) - cz_cells) / maxf(1.0, cz_cells)
			var edge_t: float = clampf(maxf(dxw, dzw), 0.0, 1.0)
			h += edge_t * edge_t * arena_height_scale * outer_ramp_strength

			h = maxf(h, min_height)
			h = _quantize(h, height_step)
			heights[z * size_x + x] = h

	# Optional: this can “flatten” if too small. Keep disabled first.
	for _p in range(step_clamp_passes):
		_apply_step_limit(max_step_per_cell)

func _apply_step_limit(max_step: float) -> void:
	if max_step <= 0.0:
		return

	for z in range(size_z):
		for x in range(size_x):
			var idx: int = z * size_x + x
			var h0: float = heights[idx]

			if x + 1 < size_x:
				var j: int = z * size_x + (x + 1)
				var h1: float = heights[j]
				var d: float = h0 - h1
				if d > max_step:
					h0 = h1 + max_step
				elif d < -max_step:
					h0 = h1 - max_step

			if z + 1 < size_z:
				var j2: int = (z + 1) * size_x + x
				var h2: float = heights[j2]
				var d2: float = h0 - h2
				if d2 > max_step:
					h0 = h2 + max_step
				elif d2 < -max_step:
					h0 = h2 - max_step

			heights[idx] = _quantize(h0, height_step)

func _quantize(h: float, step: float) -> float:
	if step <= 0.0:
		return h
	return roundf(h / step) * step

func _h(x: int, z: int) -> float:
	return heights[z * size_x + x]

func _pos(x: int, z: int, y: float) -> Vector3:
	return Vector3(_ox + float(x) * cell_size, y, _oz + float(z) * cell_size)

# -----------------------------
# ACCESS RAMPS
# -----------------------------
func _build_access_ramps() -> void:
	var step: float = maxf(0.001, height_step)
	var min_cliff_steps: int = max(1, access_min_cliff_steps)
	var run_per_step: int = max(1, access_run_per_step)
	var remaining: int = max(0, access_ramp_count)
	if remaining == 0 or access_max_iterations <= 0:
		return

	var start_cells: PackedInt32Array = _access_start_cells()
	if start_cells.is_empty():
		return

	var reachable: PackedByteArray = _flood_reachable(start_cells, step)

	for _iter in range(access_max_iterations):
		if remaining <= 0:
			break

		var candidates: Array = _collect_access_candidates(reachable, step, min_cliff_steps)
		if candidates.is_empty():
			break

		candidates.sort_custom(Callable(self, "_sort_access_candidates"))
		var chosen: Array = []
		var min_dist: int = max(2, access_ramp_width_cells * 2)
		for candidate in candidates:
			if remaining <= 0:
				break
			if _candidate_too_close(candidate, chosen, min_dist):
				continue
			_carve_access_ramp(candidate, step, run_per_step)
			chosen.append(candidate)
			remaining -= 1

		if chosen.is_empty():
			break

		reachable = _flood_reachable(start_cells, step)

func _access_start_cells() -> PackedInt32Array:
	var cells := PackedInt32Array()
	if size_x <= 0 or size_z <= 0:
		return cells

	var cx: int = size_x / 2
	var cz: int = size_z / 2
	cells.append(cz * size_x + cx)

	for x in range(size_x):
		cells.append(0 * size_x + x)
		cells.append((size_z - 1) * size_x + x)
	for z in range(1, size_z - 1):
		cells.append(z * size_x + 0)
		cells.append(z * size_x + (size_x - 1))

	return cells

func _flood_reachable(start_cells: PackedInt32Array, step: float) -> PackedByteArray:
	var reachable := PackedByteArray()
	reachable.resize(size_x * size_z)

	var queue: Array[int] = []
	queue.resize(start_cells.size())
	for i in range(start_cells.size()):
		queue[i] = start_cells[i]

	var head: int = 0
	while head < queue.size():
		var idx: int = queue[head]
		head += 1
		if idx < 0 or idx >= reachable.size():
			continue
		if reachable[idx] == 1:
			continue
		reachable[idx] = 1
		var x: int = idx % size_x
		var z: int = idx / size_x
		var h0: float = heights[idx]

		if x > 0:
			_try_reach(queue, reachable, x - 1, z, h0, step)
		if x + 1 < size_x:
			_try_reach(queue, reachable, x + 1, z, h0, step)
		if z > 0:
			_try_reach(queue, reachable, x, z - 1, h0, step)
		if z + 1 < size_z:
			_try_reach(queue, reachable, x, z + 1, h0, step)

	return reachable

func _try_reach(queue: Array[int], reachable: PackedByteArray, x: int, z: int, h0: float, step: float) -> void:
	var idx: int = z * size_x + x
	if reachable[idx] == 1:
		return
	if absf(heights[idx] - h0) <= step + 0.0001:
		queue.append(idx)

func _collect_access_candidates(reachable: PackedByteArray, step: float, min_cliff_steps: int) -> Array:
	var candidates: Array = []
	var threshold: float = float(min_cliff_steps) * step

	for z in range(size_z):
		for x in range(size_x):
			var idx: int = z * size_x + x
			if reachable[idx] == 0:
				continue
			var h0: float = heights[idx]

			_add_access_candidate(candidates, reachable, x, z, x + 1, z, h0, step, threshold)
			_add_access_candidate(candidates, reachable, x, z, x - 1, z, h0, step, threshold)
			_add_access_candidate(candidates, reachable, x, z, x, z + 1, h0, step, threshold)
			_add_access_candidate(candidates, reachable, x, z, x, z - 1, h0, step, threshold)

	return candidates

func _add_access_candidate(candidates: Array, reachable: PackedByteArray, x: int, z: int, nx: int, nz: int,
		h0: float, step: float, threshold: float) -> void:
	if nx < 0 or nx >= size_x or nz < 0 or nz >= size_z:
		return
	var nidx: int = nz * size_x + nx
	if reachable[nidx] == 1:
		return
	var h1: float = heights[nidx]
	var diff: float = h1 - h0
	if absf(diff) < threshold - 0.0001:
		return
	var diff_steps: int = int(absf(diff) / step)
	var flat_score: int = _flat_area_score(x, z, step)

	candidates.append({
		"x": x,
		"z": z,
		"nx": nx,
		"nz": nz,
		"diff_steps": diff_steps,
		"flat_score": flat_score,
		"start_height": h0,
		"end_height": h1
	})

func _flat_area_score(x: int, z: int, step: float) -> int:
	var score: int = 0
	var h0: float = _h(x, z)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var nx: int = x + dx
			var nz: int = z + dz
			if nx < 0 or nx >= size_x or nz < 0 or nz >= size_z:
				continue
			if absf(_h(nx, nz) - h0) <= step + 0.0001:
				score += 1
	return score

func _sort_access_candidates(a: Dictionary, b: Dictionary) -> bool:
	if a["diff_steps"] == b["diff_steps"]:
		if a["flat_score"] == b["flat_score"]:
			return a["start_height"] < b["start_height"]
		return a["flat_score"] > b["flat_score"]
	return a["diff_steps"] < b["diff_steps"]

func _candidate_too_close(candidate: Dictionary, chosen: Array, min_dist: int) -> bool:
	var x: int = candidate["x"]
	var z: int = candidate["z"]
	var min_dist_sq: int = min_dist * min_dist
	for other in chosen:
		var ox: int = other["x"]
		var oz: int = other["z"]
		var dx: int = x - ox
		var dz: int = z - oz
		if dx * dx + dz * dz <= min_dist_sq:
			return true
	return false

func _carve_access_ramp(candidate: Dictionary, step: float, run_per_step: int) -> void:
	var start_x: int = candidate["x"]
	var start_z: int = candidate["z"]
	var end_x: int = candidate["nx"]
	var end_z: int = candidate["nz"]
	var start_height: float = candidate["start_height"]
	var end_height: float = candidate["end_height"]
	var diff: float = end_height - start_height

	var steps_needed: int = int(absf(diff) / step)
	if steps_needed <= 0:
		return
	var length: int = steps_needed * run_per_step
	var dir_x: int = end_x - start_x
	var dir_z: int = end_z - start_z
	var dir_sign: float = 1.0 if diff >= 0.0 else -1.0

	var width: int = max(1, access_ramp_width_cells)
	var half: int = width / 2
	var perp_x: int = 0
	var perp_z: int = 0
	if dir_x != 0:
		perp_z = 1
	else:
		perp_x = 1

	for i in range(length + 1):
		var step_index: int = int(floor(float(i) / float(run_per_step)))
		var target_height: float = start_height + dir_sign * step * float(step_index)
		for w in range(-half, width - half):
			var rx: int = start_x + dir_x * i + perp_x * w
			var rz: int = start_z + dir_z * i + perp_z * w
			if rx < 0 or rx >= size_x or rz < 0 or rz >= size_z:
				continue
			var idx: int = rz * size_x + rx
			heights[idx] = _quantize(target_height, height_step)

# -----------------------------
# ROADS
# -----------------------------
func _build_roads() -> void:
	var step: float = maxf(0.001, height_step)
	var run_per_step: int = max(1, road_run_per_step)
	var width: int = max(1, road_width_cells)

	var carved_budget: int = max(0, road_count_budget)
	if carved_budget <= 0:
		return

	var start_cells: PackedInt32Array = _access_start_cells()
	if start_cells.is_empty():
		return

	for _iter in range(road_max_iters):
		var region_info: Dictionary = _label_regions(step)
		var labels: PackedInt32Array = region_info["labels"]
		var region_sizes: PackedInt32Array = region_info["sizes"]
		var region_count: int = region_info["count"]

		var main_region: int = _find_main_region(labels, start_cells)
		if main_region < 0:
			return

		var other_regions: Array[int] = []
		for r in range(region_count):
			if r == main_region:
				continue
			if region_sizes[r] < road_min_region_size:
				continue
			other_regions.append(r)

		if other_regions.is_empty():
			break

		var anchors: Array[Vector2i] = []
		anchors.append(_pick_region_anchor(labels, main_region, step))
		for r in other_regions:
			anchors.append(_pick_region_anchor(labels, r, step))

		var edges: Array = _mst_edges(anchors)
		if road_extra_loops > 0:
			_add_loop_edges(anchors, edges, road_extra_loops)

		for e in edges:
			if carved_budget <= 0:
				return
			var a: Vector2i = e["a"]
			var b: Vector2i = e["b"]
			var path: Array[Vector2i] = _astar_2d(a, b, step)
			if path.size() < 2:
				continue
			_carve_road_path(path, step, run_per_step, width)
			carved_budget -= 1

	for i in range(size_x * size_z):
		heights[i] = _quantize(heights[i], height_step)

func _label_regions(step: float) -> Dictionary:
	var labels := PackedInt32Array()
	labels.resize(size_x * size_z)
	for i in range(labels.size()):
		labels[i] = -1

	var sizes: Array[int] = []
	var region_id: int = 0

	var queue: Array[int] = []

	for start_idx in range(size_x * size_z):
		if labels[start_idx] != -1:
			continue

		queue.clear()
		queue.append(start_idx)
		labels[start_idx] = region_id
		var count: int = 0

		var head: int = 0
		while head < queue.size():
			var idx: int = queue[head]
			head += 1
			count += 1

			var x: int = idx % size_x
			var z: int = idx / size_x
			var h0: float = heights[idx]

			_region_try(queue, labels, x - 1, z, region_id, h0, step)
			_region_try(queue, labels, x + 1, z, region_id, h0, step)
			_region_try(queue, labels, x, z - 1, region_id, h0, step)
			_region_try(queue, labels, x, z + 1, region_id, h0, step)

		sizes.append(count)
		region_id += 1

	var packed_sizes := PackedInt32Array()
	packed_sizes.resize(sizes.size())
	for i in range(sizes.size()):
		packed_sizes[i] = sizes[i]

	return {
		"labels": labels,
		"sizes": packed_sizes,
		"count": region_id
	}

func _region_try(queue: Array[int], labels: PackedInt32Array, x: int, z: int, rid: int, h0: float, step: float) -> void:
	if x < 0 or x >= size_x or z < 0 or z >= size_z:
		return
	var idx: int = z * size_x + x
	if labels[idx] != -1:
		return
	if absf(heights[idx] - h0) <= step + 0.0001:
		labels[idx] = rid
		queue.append(idx)

func _find_main_region(labels: PackedInt32Array, start_cells: PackedInt32Array) -> int:
	for i in range(start_cells.size()):
		var idx: int = start_cells[i]
		if idx >= 0 and idx < labels.size() and labels[idx] >= 0:
			return labels[idx]
	return -1

func _pick_region_anchor(labels: PackedInt32Array, rid: int, step: float) -> Vector2i:
	var best := Vector2i(size_x / 2, size_z / 2)
	var best_h: float = 1e30
	var best_flat: int = -1

	for z in range(1, size_z - 1):
		for x in range(1, size_x - 1):
			var idx: int = z * size_x + x
			if labels[idx] != rid:
				continue

			var h0: float = heights[idx]
			var flat: int = _flat_area_score(x, z, step)

			if h0 < best_h - 0.0001 or (is_equal_approx(h0, best_h) and flat > best_flat):
				best_h = h0
				best_flat = flat
				best = Vector2i(x, z)

	return best

func _mst_edges(nodes: Array[Vector2i]) -> Array:
	var edges: Array = []
	if nodes.size() < 2:
		return edges

	var in_tree := PackedByteArray()
	in_tree.resize(nodes.size())
	for i in range(in_tree.size()):
		in_tree[i] = 0

	in_tree[0] = 1
	var added: int = 1

	while added < nodes.size():
		var best_i: int = -1
		var best_j: int = -1
		var best_d: int = 1 << 30

		for i in range(nodes.size()):
			if in_tree[i] == 0:
				continue
			for j in range(nodes.size()):
				if in_tree[j] == 1:
					continue
				var d: int = abs(nodes[i].x - nodes[j].x) + abs(nodes[i].y - nodes[j].y)
				if d < best_d:
					best_d = d
					best_i = i
					best_j = j

		if best_i == -1:
			break

		edges.append({ "a": nodes[best_i], "b": nodes[best_j] })
		in_tree[best_j] = 1
		added += 1

	return edges

func _add_loop_edges(nodes: Array[Vector2i], edges: Array, loops: int) -> void:
	if nodes.size() < 3:
		return

	var existing: Dictionary = {}
	for e in edges:
		existing[_edge_key(e["a"], e["b"])] = true

	var candidates: Array = []
	for i in range(nodes.size()):
		for j in range(i + 1, nodes.size()):
			var key: String = _edge_key(nodes[i], nodes[j])
			if existing.has(key):
				continue
			var d: int = abs(nodes[i].x - nodes[j].x) + abs(nodes[i].y - nodes[j].y)
			candidates.append({ "a": nodes[i], "b": nodes[j], "d": d })

	candidates.sort_custom(Callable(self, "_sort_loop_candidates"))
	var k: int = min(loops, candidates.size())
	for i in range(k):
		edges.append({ "a": candidates[i]["a"], "b": candidates[i]["b"] })

func _sort_loop_candidates(a: Dictionary, b: Dictionary) -> bool:
	return a["d"] < b["d"]

func _edge_key(a: Vector2i, b: Vector2i) -> String:
	var ax: int = a.x
	var az: int = a.y
	var bx: int = b.x
	var bz: int = b.y
	if (bx < ax) or (bx == ax and bz < az):
		ax = b.x
		az = b.y
		bx = a.x
		bz = a.y
	return str(ax) + "," + str(az) + "->" + str(bx) + "," + str(bz)

func _astar_2d(start: Vector2i, goal: Vector2i, step: float) -> Array[Vector2i]:
	var open: Array[Vector2i] = [start]
	var came: Dictionary = {}
	var g: Dictionary = {}
	var f: Dictionary = {}

	var sk: int = start.y * size_x + start.x
	g[sk] = 0.0
	f[sk] = float(abs(start.x - goal.x) + abs(start.y - goal.y))

	var in_open: Dictionary = {}
	in_open[sk] = true

	while not open.is_empty():
		var best_i: int = 0
		var best_f: float = 1e30
		for i in range(open.size()):
			var v: Vector2i = open[i]
			var k: int = v.y * size_x + v.x
			var fv: float = float(f.get(k, 1e30))
			if fv < best_f:
				best_f = fv
				best_i = i

		var cur: Vector2i = open[best_i]
		open.remove_at(best_i)
		in_open.erase(cur.y * size_x + cur.x)

		if cur == goal:
			return _reconstruct_astar(came, cur)

		var ch: float = _h(cur.x, cur.y)

		for n in [Vector2i(cur.x + 1, cur.y), Vector2i(cur.x - 1, cur.y), Vector2i(cur.x, cur.y + 1), Vector2i(cur.x, cur.y - 1)]:
			if n.x < 0 or n.x >= size_x or n.y < 0 or n.y >= size_z:
				continue

			var nh: float = _h(n.x, n.y)
			var dh: float = nh - ch

			var slope_pen: float = absf(dh) * 4.0
			var cliff_pen: float = 0.0
			if absf(dh) > step + 0.0001:
				cliff_pen = 25.0 + absf(dh) * 2.0

			var ck: int = cur.y * size_x + cur.x
			var nk: int = n.y * size_x + n.x
			var tentative: float = float(g.get(ck, 1e30)) + 1.0 + slope_pen + cliff_pen

			if tentative < float(g.get(nk, 1e30)):
				came[nk] = cur
				g[nk] = tentative
				f[nk] = tentative + float(abs(n.x - goal.x) + abs(n.y - goal.y))

				if not in_open.has(nk):
					open.append(n)
					in_open[nk] = true

	return []

func _reconstruct_astar(came: Dictionary, cur: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [cur]
	var ck: int = cur.y * size_x + cur.x
	while came.has(ck):
		cur = came[ck]
		path.append(cur)
		ck = cur.y * size_x + cur.x
	path.reverse()
	return path

func _carve_road_path(path: Array[Vector2i], step: float, run_per_step: int, width: int) -> void:
	if path.size() < 2:
		return

	var w: int = max(1, width)
	var start: Vector2i = path[0]
	var cur_h: float = _h(start.x, start.y)

	for i in range(1, path.size()):
		var b: Vector2i = path[i]

		var terrain_h: float = _h(b.x, b.y)
		var max_delta: float = step / float(run_per_step)
		var desired: float = move_toward(cur_h, terrain_h, max_delta)

		desired = _quantize(desired, height_step)
		cur_h = desired

		for dz in range(-w, w + 1):
			for dx in range(-w, w + 1):
				var rx: int = b.x + dx
				var rz: int = b.y + dz
				if rx < 0 or rx >= size_x or rz < 0 or rz >= size_z:
					continue
				var idx: int = rz * size_x + rx

				var man: int = abs(dx) + abs(dz)
				var t: float = clampf(1.0 - float(man) / float(w + 1), 0.0, 1.0)

				heights[idx] = _quantize(lerpf(heights[idx], desired, t), height_step)
				road_mask[idx] = 1

# -----------------------------
# MESH
# -----------------------------
func _build_blocky_mesh_and_collision() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var uv_scale_top: float = 0.08
	var uv_scale_wall: float = 0.08
	var step: float = height_step

	for z in range(size_z - 1):
		for x in range(size_x - 1):
			var h00: float = _h(x, z)
			var h10: float = _h(x + 1, z)
			var h01: float = _h(x, z + 1)

			# Default: flat top quad at h00
			var a_y: float = h00
			var b_y: float = h00
			var c_y: float = h00
			var d_y: float = h00

			var ramp_east: bool = false
			var ramp_south: bool = false

			# 1-step ramps: tilt this cell toward a neighbor that is exactly +step higher
			if enable_step_ramps:
				if is_equal_approx(h10 - h00, step):
					# Ramp rises to the east
					ramp_east = true
					b_y = h10
					c_y = h10
				if is_equal_approx(h01 - h00, step):
					# Ramp rises to the south
					ramp_south = true
					c_y = h01
					d_y = h01

			var top_color: Color = terrain_color
			var top_idx: int = z * size_x + x
			if top_idx >= 0 and top_idx < road_mask.size() and road_mask[top_idx] == 1:
				top_color = road_color

			_add_quad(
				st,
				_pos(x,     z,     a_y),
				_pos(x + 1, z,     b_y),
				_pos(x + 1, z + 1, c_y),
				_pos(x,     z + 1, d_y),
				Vector2(float(x), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z + 1)) * uv_scale_top,
				Vector2(float(x), float(z + 1)) * uv_scale_top,
				top_color
			)

			# Walls: only where neighbor is lower AND not replaced by a ramp on that edge
			var hn: float = _h(x, z - 1) if z > 0 else h00
			var hs: float = _h(x, z + 1)
			var hw: float = _h(x - 1, z) if x > 0 else h00
			var he: float = _h(x + 1, z)

			# North edge (no ramp handled here)
			if z > 0 and hn < h00:
				_add_wall_z(st, x, z, hn, h00, true, uv_scale_wall, terrain_color)

			# West edge (no ramp handled here)
			if x > 0 and hw < h00:
				_add_wall_x(st, x, z, hw, h00, true, uv_scale_wall, terrain_color)

			# South edge: skip the wall if this cell ramps south into it
			if hs < h00 and not ramp_south:
				_add_wall_z(st, x, z + 1, hs, h00, false, uv_scale_wall, terrain_color)

			# East edge: skip the wall if this cell ramps east into it
			if he < h00 and not ramp_east:
				_add_wall_x(st, x + 1, z, he, h00, false, uv_scale_wall, terrain_color)

	_add_box_walls(st, uv_scale_wall, terrain_color)

	if build_ceiling:
		_add_ceiling(st, terrain_color)

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	mesh_instance.mesh = mesh
	collision_shape.shape = mesh.create_trimesh_shape()

func _add_box_walls(st: SurfaceTool, uv_scale_wall: float, color: Color) -> void:
	var floor_y: float = minf(outer_floor_height, min_height)
	var top_y: float = box_height

	for x in range(size_x - 1):
		_add_wall_z_one_sided(st, x, 0, floor_y, top_y, true, uv_scale_wall, color)
	for x in range(size_x - 1):
		_add_wall_z_one_sided(st, x, size_z - 1, floor_y, top_y, false, uv_scale_wall, color)

	for z in range(size_z - 1):
		_add_wall_x_one_sided(st, 0, z, floor_y, top_y, true, uv_scale_wall, color)
	for z in range(size_z - 1):
		_add_wall_x_one_sided(st, size_x - 1, z, floor_y, top_y, false, uv_scale_wall, color)

func _add_ceiling(st: SurfaceTool, color: Color) -> void:
	var y: float = box_height
	var a: Vector3 = _pos(0, 0, y)
	var b: Vector3 = _pos(size_x - 1, 0, y)
	var c: Vector3 = _pos(size_x - 1, size_z - 1, y)
	var d: Vector3 = _pos(0, size_z - 1, y)
	_add_quad(st, a, d, c, b, Vector2(0,0), Vector2(0,1), Vector2(1,1), Vector2(1,0), color)

# -----------------------------
# Geometry helpers
# -----------------------------
func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2, color: Color) -> void:
	st.set_color(color); st.set_uv(ua); st.add_vertex(a)
	st.set_color(color); st.set_uv(ub); st.add_vertex(b)
	st.set_color(color); st.set_uv(uc); st.add_vertex(c)
	st.set_color(color); st.set_uv(ua); st.add_vertex(a)
	st.set_color(color); st.set_uv(uc); st.add_vertex(c)
	st.set_color(color); st.set_uv(ud); st.add_vertex(d)

func _add_wall_z(st: SurfaceTool, x: int, z_edge: int, h_low: float, h_high: float, north: bool, uv_scale: float, color: Color) -> void:
	_add_wall_z_one_sided(st, x, z_edge, h_low, h_high, north, uv_scale, color)
	_add_wall_z_one_sided(st, x, z_edge, h_low, h_high, not north, uv_scale, color)

func _add_wall_x(st: SurfaceTool, x_edge: int, z: int, h_low: float, h_high: float, west: bool, uv_scale: float, color: Color) -> void:
	_add_wall_x_one_sided(st, x_edge, z, h_low, h_high, west, uv_scale, color)
	_add_wall_x_one_sided(st, x_edge, z, h_low, h_high, not west, uv_scale, color)

func _add_wall_z_one_sided(st: SurfaceTool, x: int, z_edge: int, h_low: float, h_high: float, north: bool, uv_scale: float, color: Color) -> void:
	var step: float = maxf(0.001, height_step)
	var y0: float = h_low
	while y0 < h_high - 0.0001:
		var y1: float = minf(y0 + step, h_high)

		var p0: Vector3 = _pos(x,     z_edge, y0)
		var p1: Vector3 = _pos(x + 1, z_edge, y0)
		var p2: Vector3 = _pos(x + 1, z_edge, y1)
		var p3: Vector3 = _pos(x,     z_edge, y1)

		var uv0: Vector2 = Vector2(0.0, y0 * uv_scale)
		var uv1: Vector2 = Vector2(cell_size * uv_scale, y0 * uv_scale)
		var uv2: Vector2 = Vector2(cell_size * uv_scale, y1 * uv_scale)
		var uv3: Vector2 = Vector2(0.0, y1 * uv_scale)

		if north:
			_add_quad(st, p1, p0, p3, p2, uv0, uv1, uv2, uv3, color)
		else:
			_add_quad(st, p0, p1, p2, p3, uv0, uv1, uv2, uv3, color)

		y0 = y1

func _add_wall_x_one_sided(st: SurfaceTool, x_edge: int, z: int, h_low: float, h_high: float, west: bool, uv_scale: float, color: Color) -> void:
	var step: float = maxf(0.001, height_step)
	var y0: float = h_low
	while y0 < h_high - 0.0001:
		var y1: float = minf(y0 + step, h_high)

		var p0: Vector3 = _pos(x_edge, z,     y0)
		var p1: Vector3 = _pos(x_edge, z + 1, y0)
		var p2: Vector3 = _pos(x_edge, z + 1, y1)
		var p3: Vector3 = _pos(x_edge, z,     y1)

		var uv0: Vector2 = Vector2(0.0, y0 * uv_scale)
		var uv1: Vector2 = Vector2(cell_size * uv_scale, y0 * uv_scale)
		var uv2: Vector2 = Vector2(cell_size * uv_scale, y1 * uv_scale)
		var uv3: Vector2 = Vector2(0.0, y1 * uv_scale)

		if west:
			_add_quad(st, p0, p1, p2, p3, uv0, uv1, uv2, uv3, color)
		else:
			_add_quad(st, p1, p0, p3, p2, uv0, uv1, uv2, uv3, color)

		y0 = y1
