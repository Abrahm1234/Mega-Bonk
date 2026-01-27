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

# Roads (connect peaks + valleys)
@export var enable_roads: bool = true
@export var road_peak_count: int = 6
@export var road_valley_count: int = 6
@export var road_min_anchor_spacing: int = 18
@export var road_width: int = 2
@export var road_budget_extra_links: int = 8
@export var road_cliff_penalty: float = 30.0
@export var road_allow_diagonals: bool = true
@export var road_cut_max_steps: int = 0
@export var road_turn_penalty: float = 2.0
@export var road_smooth_los: bool = true
@export var road_smooth_max_hops: int = 64
@export var road_run_per_height_step: int = 3
@export var road_profile_smooth_passes: int = 3
@export var road_profile_quant_step: float = 0.0
@export var road_peak_height_percentile: float = 0.88
@export var road_peak_min_height_abs: float = 0.0
@export var road_peak_region_step_merge: int = 1
@export var road_max_peak_regions: int = 64
@export var road_connect_all_regions: bool = true
@export var road_max_extra_region_links: int = 128
@export var road_grade_passes: int = 8
@export var road_raise_only: bool = true
@export var road_edge_falloff_power: float = 1.6

@export var terrain_color: Color = Color(0.32, 0.68, 0.34, 1.0)
@export var road_color: Color = Color(0.85, 0.12, 0.12, 1.0)

@onready var mesh_instance: MeshInstance3D = $TerrainBody/TerrainMesh
@onready var collision_shape: CollisionShape3D = $TerrainBody/TerrainCollision

var heights: PackedFloat32Array
var road_mask: PackedByteArray
var ramp_dir: PackedByteArray
var ramp_kind: PackedByteArray
var road_flow: PackedByteArray
var _ox: float
var _oz: float

const RAMP_NONE: int = 0
const RAMP_PX: int = 1
const RAMP_NX: int = 2
const RAMP_PZ: int = 4
const RAMP_NZ: int = 8
const CELL_RAMP_NONE: int = 0
const CELL_RAMP_EAST: int = 1
const CELL_RAMP_SOUTH: int = 2
const FLOW_NONE: int = 0
const FLOW_X: int = 1
const FLOW_Z: int = 2

class CellCorners:
	var a: float
	var b: float
	var c: float
	var d: float

func _ready() -> void:
	print("BlockyTerrain ACTIVE: ", get_path(), " enable_roads=", enable_roads, " ensure_access=", ensure_access)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = mat
	generate()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_R:
		generate()

func generate() -> void:
	_ox = -float(size_x) * cell_size * 0.5
	_oz = -float(size_z) * cell_size * 0.5
	_generate_heights()
	road_mask = PackedByteArray()
	road_mask.resize(size_x * size_z)
	for i in range(road_mask.size()):
		road_mask[i] = 0
	ramp_dir = PackedByteArray()
	ramp_dir.resize(size_x * size_z)
	for i in range(ramp_dir.size()):
		ramp_dir[i] = RAMP_NONE
	road_flow = PackedByteArray()
	road_flow.resize(size_x * size_z)
	for i in range(road_flow.size()):
		road_flow[i] = FLOW_NONE
	# 1) Ensure access first so later roads carve on reachable terrain.
	if ensure_access:
		_build_access_ramps()
	# 2) Build roads on top of the access-adjusted heights.
	if enable_roads:
		_build_road_network()
	_compute_ramp_kind()
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
func _build_road_network() -> void:
	road_mask.fill(0)
	ramp_dir.fill(RAMP_NONE)
	road_flow.fill(FLOW_NONE)

	var peaks: Array[Vector2i] = _pick_peak_anchors_threshold()
	var valleys: Array[Vector2i] = _pick_valleys(road_valley_count, road_min_anchor_spacing)
	var anchors: Array[Vector2i] = []
	anchors.append_array(peaks)
	anchors.append_array(valleys)
	if anchors.size() < 2:
		return

	var mst_edges: Array = _mst_edges(anchors)
	for e in mst_edges:
		var a: Vector2i = anchors[e[0]]
		var b: Vector2i = anchors[e[1]]
		var path: Array[Vector2i] = _astar_road_path(a, b)
		if path.is_empty():
			continue
			var waypoints: Array[Vector2i] = path
			if road_smooth_los:
				waypoints = _simplify_path_los(waypoints)
			var dense: Array[Vector2i]
			if road_allow_diagonals:
				dense = _rasterize_waypoints_8(waypoints)
			else:
				dense = _rasterize_waypoints_4(waypoints)
			_write_flow_from_path(dense)
			_stamp_road_path(dense)

	if road_connect_all_regions:
		var guard: int = 0
		while guard < road_max_extra_region_links and _connect_one_unroaded_region():
			guard += 1
	else:
		for _i in range(road_budget_extra_links):
			if not _connect_one_unroaded_region():
				break

	_grade_road_surface()
	_derive_road_ramps_full()

func _height_percentile(p: float) -> float:
	var arr: Array[float] = []
	arr.resize(heights.size())
	for i in range(heights.size()):
		arr[i] = heights[i]
	arr.sort()
	if arr.is_empty():
		return 0.0
	var pp: float = clampf(p, 0.0, 1.0)
	var k: int = int(round(pp * float(arr.size() - 1)))
	return arr[clampi(k, 0, arr.size() - 1)]

func _pick_peak_anchors_threshold() -> Array[Vector2i]:
	var thr: float = maxf(road_peak_min_height_abs, _height_percentile(road_peak_height_percentile))
	var max_step: float = float(maxi(1, road_peak_region_step_merge)) * height_step

	var labels := PackedInt32Array()
	labels.resize(size_x * size_z)
	labels.fill(-1)

	var rid: int = 0
	var best_pos: Array[Vector2i] = []
	var best_h: Array[float] = []
	var stop_early: bool = false

	for z in range(size_z):
		if stop_early:
			break
		for x in range(size_x):
			var idx: int = z * size_x + x
			if labels[idx] != -1:
				continue
			if heights[idx] < thr:
				continue

			var q: Array[Vector2i] = [Vector2i(x, z)]
			labels[idx] = rid

			var region_best := Vector2i(x, z)
			var region_best_h: float = heights[idx]

			while not q.is_empty():
				var p: Vector2i = q[q.size() - 1]
				q.remove_at(q.size() - 1)

				var ph: float = _h(p.x, p.y)
				if ph > region_best_h:
					region_best_h = ph
					region_best = p

				for n in _neighbors4(p):
					if n.x < 0 or n.x >= size_x or n.y < 0 or n.y >= size_z:
						continue
					var ni: int = n.y * size_x + n.x
					if labels[ni] != -1:
						continue
					var nh: float = _h(n.x, n.y)
					if nh < thr:
						continue
					if absf(nh - ph) > max_step:
						continue
					labels[ni] = rid
					q.append(n)

			best_pos.append(region_best)
			best_h.append(region_best_h)

			rid += 1
			if rid >= road_max_peak_regions:
				stop_early = true
				break

	var order: Array[int] = []
	order.resize(best_pos.size())
	for i in range(best_pos.size()):
		order[i] = i
	order.sort_custom(func(a: int, b: int) -> bool:
		return best_h[a] > best_h[b]
	)

	var cands: Array[Vector2i] = []
	for i in order:
		cands.append(best_pos[i])

	return _pick_spaced(cands, road_peak_count, road_min_anchor_spacing)

func _pick_peaks(count: int, min_spacing: int) -> Array[Vector2i]:
	var cands: Array[Vector2i] = []
	for z in range(1, size_z - 1):
		for x in range(1, size_x - 1):
			var h0 := _h(x, z)
			var ok := true
			for n in _neighbors8(Vector2i(x, z)):
				if _h(n.x, n.y) > h0:
					ok = false
					break
			if ok:
				cands.append(Vector2i(x, z))

	cands.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _h(a.x, a.y) > _h(b.x, b.y)
	)

	return _pick_spaced(cands, count, min_spacing)

func _pick_valleys(count: int, min_spacing: int) -> Array[Vector2i]:
	var cands: Array[Vector2i] = []
	for z in range(1, size_z - 1):
		for x in range(1, size_x - 1):
			var h0 := _h(x, z)
			var ok := true
			for n in _neighbors8(Vector2i(x, z)):
				if _h(n.x, n.y) < h0:
					ok = false
					break
			if ok:
				cands.append(Vector2i(x, z))

	cands.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _h(a.x, a.y) < _h(b.x, b.y)
	)

	return _pick_spaced(cands, count, min_spacing)

func _pick_spaced(sorted: Array[Vector2i], count: int, min_spacing: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for p in sorted:
		var ok := true
		for q in out:
			if absi(p.x - q.x) + absi(p.y - q.y) < min_spacing:
				ok = false
				break
		if ok:
			out.append(p)
			if out.size() >= count:
				break
	return out

func _neighbors8(p: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(p.x + 1, p.y), Vector2i(p.x - 1, p.y),
		Vector2i(p.x, p.y + 1), Vector2i(p.x, p.y - 1),
		Vector2i(p.x + 1, p.y + 1), Vector2i(p.x + 1, p.y - 1),
		Vector2i(p.x - 1, p.y + 1), Vector2i(p.x - 1, p.y - 1),
	]

func _neighbors4(p: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(p.x + 1, p.y), Vector2i(p.x - 1, p.y),
		Vector2i(p.x, p.y + 1), Vector2i(p.x, p.y - 1),
	]

func _mst_edges(points: Array[Vector2i]) -> Array:
	var n := points.size()
	var in_tree := PackedByteArray()
	in_tree.resize(n)
	in_tree.fill(0)

	var best_cost := PackedFloat32Array()
	best_cost.resize(n)
	for i in range(n):
		best_cost[i] = 1e30

	var parent := PackedInt32Array()
	parent.resize(n)
	for i in range(n):
		parent[i] = -1

	in_tree[0] = 1
	for i in range(1, n):
		best_cost[i] = _road_edge_cost(points[0], points[i])
		parent[i] = 0

	var edges: Array = []
	for _k in range(n - 1):
		var v := -1
		var v_cost := 1e30
		for i in range(n):
			if in_tree[i] == 1:
				continue
			if best_cost[i] < v_cost:
				v_cost = best_cost[i]
				v = i
		if v == -1:
			break
		in_tree[v] = 1
		edges.append([parent[v], v])

		for u in range(n):
			if in_tree[u] == 1:
				continue
			var c := _road_edge_cost(points[v], points[u])
			if c < best_cost[u]:
				best_cost[u] = c
				parent[u] = v

	return edges

func _road_edge_cost(a: Vector2i, b: Vector2i) -> float:
	var d := float(absi(a.x - b.x) + absi(a.y - b.y))
	var dh := absf(_h(a.x, a.y) - _h(b.x, b.y)) / height_step
	return d + dh * 6.0

func _flow_set(x: int, z: int, v: int) -> void:
	road_flow[z * size_x + x] = v

func _flow_get(x: int, z: int) -> int:
	return int(road_flow[z * size_x + x])

func _heuristic(a: Vector2i, b: Vector2i) -> float:
	var dx: int = absi(a.x - b.x)
	var dz: int = absi(a.y - b.y)
	if road_allow_diagonals:
		var mn: int = mini(dx, dz)
		var mx: int = maxi(dx, dz)
		return float(mx - mn) + float(mn) * 1.41421356
	return float(dx + dz)

func _astar_road_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var open: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g: Dictionary = {}
	var f: Dictionary = {}

	var sk: int = start.y * size_x + start.x
	g[sk] = 0.0
	f[sk] = _heuristic(start, goal)

	var in_open: Dictionary = { sk: true }

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
		var ck: int = cur.y * size_x + cur.x
		in_open.erase(ck)

		if cur == goal:
			return _reconstruct_path(came_from, cur)

		var ch: float = _h(cur.x, cur.y)
		var neighs: Array[Vector2i] = _neighbors8(cur) if road_allow_diagonals else _neighbors4(cur)

		var has_parent: bool = came_from.has(ck)
		var parent: Vector2i = came_from[ck] if has_parent else Vector2i(0, 0)
		var pdx: int = cur.x - parent.x
		var pdz: int = cur.y - parent.y

		for n: Vector2i in neighs:
			if n.x < 0 or n.x >= size_x or n.y < 0 or n.y >= size_z:
				continue
			var nk: int = n.y * size_x + n.x
			var nh: float = _h(n.x, n.y)
			var dh: float = absf(nh - ch)

			var ndx: int = n.x - cur.x
			var ndz: int = n.y - cur.y
			var step_len: float = 1.41421356 if (ndx != 0 and ndz != 0) else 1.0

			var slope_steps: float = dh / height_step
			var slope_pen: float = slope_steps * slope_steps * road_cliff_penalty

			var step_cost: float = step_len + slope_pen
			if has_parent and (ndx != pdx or ndz != pdz):
				step_cost += road_turn_penalty
			var tentative: float = float(g.get(ck, 1e30)) + step_cost

			if tentative < float(g.get(nk, 1e30)):
				came_from[nk] = cur
				g[nk] = tentative
				f[nk] = tentative + _heuristic(n, goal)
				if not in_open.has(nk):
					open.append(n)
					in_open[nk] = true

	return []

func _reconstruct_path(came_from: Dictionary, cur: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [cur]
	var ck: int = cur.y * size_x + cur.x
	while came_from.has(ck):
		cur = came_from[ck]
		path.append(cur)
		ck = cur.y * size_x + cur.x
	path.reverse()
	return path

func _in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < size_x and p.y >= 0 and p.y < size_z

func _line_4_connected_supercover(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var x0: int = a.x
	var y0: int = a.y
	var x1: int = b.x
	var y1: int = b.y

	var dx: int = absi(x1 - x0)
	var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy

	out.append(Vector2i(x0, y0))

	while not (x0 == x1 and y0 == y1):
		var e2: int = err * 2
		var step_x: bool = e2 > -dy
		var step_y: bool = e2 < dx

		if step_x and step_y:
			if dx >= dy:
				err -= dy
				x0 += sx
				out.append(Vector2i(x0, y0))
				err += dx
				y0 += sy
				out.append(Vector2i(x0, y0))
			else:
				err += dx
				y0 += sy
				out.append(Vector2i(x0, y0))
				err -= dy
				x0 += sx
				out.append(Vector2i(x0, y0))
		elif step_x:
			err -= dy
			x0 += sx
			out.append(Vector2i(x0, y0))
		else:
			err += dx
			y0 += sy
			out.append(Vector2i(x0, y0))

	return out

func _line_8_connected(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var x0: int = a.x
	var y0: int = a.y
	var x1: int = b.x
	var y1: int = b.y

	var dx: int = absi(x1 - x0)
	var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy

	while true:
		out.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2: int = err * 2
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return out

func _rasterize_waypoints_4(waypoints: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if waypoints.is_empty():
		return out
	out.append(waypoints[0])
	for i in range(waypoints.size() - 1):
		var seg: Array[Vector2i] = _line_4_connected_supercover(waypoints[i], waypoints[i + 1])
		for j in range(1, seg.size()):
			out.append(seg[j])
	return out

func _rasterize_waypoints_8(waypoints: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if waypoints.is_empty():
		return out
	out.append(waypoints[0])
	for i in range(waypoints.size() - 1):
		var seg: Array[Vector2i] = _line_8_connected(waypoints[i], waypoints[i + 1])
		for j in range(1, seg.size()):
			out.append(seg[j])
	return out

func _has_los(a: Vector2i, b: Vector2i) -> bool:
	var seg: Array[Vector2i] = _line_4_connected_supercover(a, b)
	for c: Vector2i in seg:
		if not _in_bounds(c):
			return false
	return true

func _simplify_path_los(path: Array[Vector2i]) -> Array[Vector2i]:
	if path.size() <= 2:
		return path
	var out: Array[Vector2i] = []
	var i: int = 0
	out.append(path[0])
	while i < path.size() - 1:
		var best_j: int = i + 1
		var j_limit: int = mini(path.size() - 1, i + road_smooth_max_hops)
		for j in range(i + 2, j_limit + 1):
			if _has_los(path[i], path[j]):
				best_j = j
		out.append(path[best_j])
		i = best_j
	return out

func _write_flow_from_path(dense: Array[Vector2i]) -> void:
	for i in range(dense.size() - 1):
		var a: Vector2i = dense[i]
		var b: Vector2i = dense[i + 1]
		var dx: int = b.x - a.x
		var dz: int = b.y - a.y
		if absi(dx) > absi(dz):
			_flow_set(a.x, a.y, FLOW_X)
		elif absi(dz) > absi(dx):
			_flow_set(a.x, a.y, FLOW_Z)

func _smooth_profile_1d(prof: Array[float]) -> void:
	if prof.size() < 3:
		return
	var tmp: Array[float] = []
	tmp.resize(prof.size())
	tmp[0] = prof[0]
	tmp[prof.size() - 1] = prof[prof.size() - 1]
	for i in range(1, prof.size() - 1):
		tmp[i] = prof[i - 1] * 0.25 + prof[i] * 0.5 + prof[i + 1] * 0.25
	for i in range(prof.size()):
		prof[i] = tmp[i]

func _stamp_road_path(path: Array[Vector2i]) -> void:
	if path.size() < 2:
		return

	var max_dy: float = height_step / float(maxi(1, road_run_per_height_step))
	var prof: Array[float] = []
	prof.resize(path.size())
	for i in range(path.size()):
		prof[i] = _h(path[i].x, path[i].y)

	for _iter in range(road_profile_smooth_passes):
		_smooth_profile_1d(prof)

	for _iter2 in range(4):
		for i in range(1, prof.size()):
			prof[i] = clampf(prof[i], prof[i - 1] - max_dy, prof[i - 1] + max_dy)
		for i in range(prof.size() - 2, -1, -1):
			prof[i] = clampf(prof[i], prof[i + 1] - max_dy, prof[i + 1] + max_dy)

	if road_profile_quant_step > 0.0:
		for i in range(prof.size()):
			prof[i] = _quantize(prof[i], road_profile_quant_step)

	for i in range(path.size()):
		_paint_road_ribbon(path[i], prof[i])

	for i in range(path.size() - 1):
		var a := path[i]
		var b := path[i + 1]
		var dha := prof[i + 1] - prof[i]
		if dha == height_step:
			_set_ramp_from_to(a, b)
		elif dha == -height_step:
			_set_ramp_from_to(b, a)

func _paint_road_ribbon(p: Vector2i, target_h: float) -> void:
	var cut_max: float = float(road_cut_max_steps) * height_step
	var width: int = maxi(1, road_width)
	var r2: int = width * width

	for dz: int in range(-width, width + 1):
		for dx: int in range(-width, width + 1):
			var dd: int = dx * dx + dz * dz
			if dd > r2:
				continue

			var x: int = p.x + dx
			var z: int = p.y + dz
			if x < 0 or x >= size_x or z < 0 or z >= size_z:
				continue

			var idx: int = z * size_x + x
			road_mask[idx] = 1

			var dist: float = sqrt(float(dd))
			var t: float = 1.0 - (dist / float(width + 0.0001))
			t = pow(t, road_edge_falloff_power)
			var h0: float = heights[idx]
			var h1: float = lerpf(h0, target_h, t)
			h1 = clampf(h1, h0 - cut_max, 1e30)
			if road_raise_only and h1 < h0:
				h1 = h0

			heights[idx] = _quantize(h1, height_step)

func _set_ramp_from_to(low: Vector2i, high: Vector2i) -> void:
	var dx := high.x - low.x
	var dz := high.y - low.y
	var idx := low.y * size_x + low.x
	if dx == 1 and dz == 0:
		ramp_dir[idx] = int(ramp_dir[idx]) | RAMP_PX
	elif dx == -1 and dz == 0:
		ramp_dir[idx] = int(ramp_dir[idx]) | RAMP_NX
	elif dx == 0 and dz == 1:
		ramp_dir[idx] = int(ramp_dir[idx]) | RAMP_PZ
	elif dx == 0 and dz == -1:
		ramp_dir[idx] = int(ramp_dir[idx]) | RAMP_NZ

func _grade_road_surface() -> void:
	if road_grade_passes <= 0:
		return
	var step: float = height_step

	for _pass in range(road_grade_passes):
		var changed: bool = false
		for z in range(size_z):
			for x in range(size_x):
				var idx := z * size_x + x
				if road_mask[idx] == 0:
					continue

				var h0: float = heights[idx]

				for n in _neighbors4(Vector2i(x, z)):
					if n.x < 0 or n.x >= size_x or n.y < 0 or n.y >= size_z:
						continue
					var ni: int = n.y * size_x + n.x
					if road_mask[ni] == 0:
						continue

					var h1: float = heights[ni]
					var diff: float = h1 - h0

					if diff > step + 0.0001:
						if road_raise_only:
							var new_h: float = _quantize(h1 - step, height_step)
							if new_h > h0:
								heights[idx] = new_h
								h0 = new_h
								changed = true
						else:
							var new_hn: float = _quantize(h0 + step, height_step)
							if new_hn < h1:
								heights[ni] = new_hn
								changed = true
					elif diff < -step - 0.0001:
						if road_raise_only:
							var new_hn2: float = _quantize(h0 - step, height_step)
							if new_hn2 > h1:
								heights[ni] = new_hn2
								changed = true
						else:
							var new_h2: float = _quantize(h1 + step, height_step)
							if new_h2 < h0:
								heights[idx] = new_h2
								h0 = new_h2
								changed = true

		if not changed:
			break

func _derive_road_ramps_full() -> void:
	ramp_dir.fill(RAMP_NONE)
	var step: float = height_step

	for z in range(size_z):
		for x in range(size_x):
			var idx := z * size_x + x
			if road_mask[idx] == 0:
				continue
			var h0 := _h(x, z)
			var best_flag: int = RAMP_NONE
			var best_score: int = -1

			var dirs: Array = [
				{"x": x + 1, "z": z, "flag": RAMP_PX},
				{"x": x - 1, "z": z, "flag": RAMP_NX},
				{"x": x, "z": z + 1, "flag": RAMP_PZ},
				{"x": x, "z": z - 1, "flag": RAMP_NZ},
			]

			for d in dirs:
				var nx: int = d["x"]
				var nz: int = d["z"]
				if nx < 0 or nx >= size_x or nz < 0 or nz >= size_z:
					continue
				var ni: int = nz * size_x + nx
				if road_mask[ni] == 0:
					continue
				if _h(nx, nz) != h0 + step:
					continue

				var score: int = 0
				for nn in _neighbors4(Vector2i(nx, nz)):
					if nn.x < 0 or nn.x >= size_x or nn.y < 0 or nn.y >= size_z:
						continue
					if road_mask[nn.y * size_x + nn.x] == 1:
						score += 1

				if score > best_score:
					best_score = score
					best_flag = d["flag"]

			ramp_dir[idx] = best_flag

func _connect_one_unroaded_region() -> bool:
	var regions := _label_regions_by_step(height_step)
	if regions.size() <= 1:
		return false

	var road_region := -1
	for z in range(size_z):
		for x in range(size_x):
			var idx := z * size_x + x
			if road_mask[idx] == 1:
				road_region = regions[idx]
				break
		if road_region != -1:
			break
	if road_region == -1:
		return false

	var best_peak := Vector2i(-1, -1)
	var best_h := -1e30
	var best_reg := -1

	for z in range(size_z):
		for x in range(size_x):
			var idx := z * size_x + x
			var r := regions[idx]
			if r == road_region:
				continue
			var h := heights[idx]
			if h > best_h:
				best_h = h
				best_peak = Vector2i(x, z)
				best_reg = r

	if best_reg == -1:
		return false

	var road_cell := Vector2i(-1, -1)
	var best_d := 1 << 30
	for z in range(size_z):
		for x in range(size_x):
			var idx := z * size_x + x
			if road_mask[idx] == 0:
				continue
			var d: int = absi(x - best_peak.x) + absi(z - best_peak.y)
			if d < best_d:
				best_d = d
				road_cell = Vector2i(x, z)

	if road_cell.x == -1:
		return false

	var path := _astar_road_path(best_peak, road_cell)
	if path.is_empty():
		return false
	var waypoints: Array[Vector2i] = path
	if road_smooth_los:
		waypoints = _simplify_path_los(waypoints)
	var dense: Array[Vector2i]
	if road_allow_diagonals:
		dense = _rasterize_waypoints_8(waypoints)
	else:
		dense = _rasterize_waypoints_4(waypoints)
	_write_flow_from_path(dense)
	_stamp_road_path(dense)
	return true

func _label_regions_by_step(max_step: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(size_x * size_z)
	out.fill(-1)

	var rid := 0
	for z in range(size_z):
		for x in range(size_x):
			var idx := z * size_x + x
			if out[idx] != -1:
				continue
			var q: Array[Vector2i] = [Vector2i(x, z)]
			out[idx] = rid
			while not q.is_empty():
				var p: Vector2i = q[q.size() - 1]
				q.remove_at(q.size() - 1)
				var ph := _h(p.x, p.y)
				for n in _neighbors4(p):
					if n.x < 0 or n.x >= size_x or n.y < 0 or n.y >= size_z:
						continue
					var ni := n.y * size_x + n.x
					if out[ni] != -1:
						continue
					var nh := _h(n.x, n.y)
					if absf(nh - ph) > max_step:
						continue
					out[ni] = rid
					q.append(n)
			rid += 1
	return out

func _edge_is_ramp_x(x: int, z: int, step: float) -> bool:
	if x + 1 >= size_x:
		return false
	if enable_step_ramps and is_equal_approx(_h(x + 1, z) - _h(x, z), step):
		return true
	var idx := z * size_x + x
	if (int(ramp_dir[idx]) & RAMP_PX) != 0:
		return _h(x + 1, z) == _h(x, z) + step
	if x + 1 < size_x:
		var idx2 := z * size_x + (x + 1)
		if (int(ramp_dir[idx2]) & RAMP_NX) != 0:
			return _h(x, z) == _h(x + 1, z) + step
	return false

func _edge_is_ramp_z(x: int, z: int, step: float) -> bool:
	if z + 1 >= size_z:
		return false
	if enable_step_ramps and is_equal_approx(_h(x, z + 1) - _h(x, z), step):
		return true
	var idx := z * size_x + x
	if (int(ramp_dir[idx]) & RAMP_PZ) != 0:
		return _h(x, z + 1) == _h(x, z) + step
	if z + 1 < size_z:
		var idx2 := (z + 1) * size_x + x
		if (int(ramp_dir[idx2]) & RAMP_NZ) != 0:
			return _h(x, z) == _h(x, z + 1) + step
	return false

func _cell_index(x: int, z: int) -> int:
	return z * (size_x - 1) + x

func _compute_ramp_kind() -> void:
	ramp_kind = PackedByteArray()
	ramp_kind.resize((size_x - 1) * (size_z - 1))
	for z in range(size_z - 1):
		for x in range(size_x - 1):
			var step: float = height_step
			var do_x: bool = enable_step_ramps and _edge_is_ramp_x(x, z, step)
			var do_z: bool = enable_step_ramps and _edge_is_ramp_z(x, z, step)
			if do_x and do_z:
				var flow: int = _flow_get(x, z)
				if flow == FLOW_X:
					do_z = false
				elif flow == FLOW_Z:
					do_x = false
				else:
					var score_x: int = 0
					var score_z: int = 0
					if enable_roads:
						if road_mask[z * size_x + (x + 1)] == 1:
							score_x += 10
						if road_mask[(z + 1) * size_x + x] == 1:
							score_z += 10
					if score_x >= score_z:
						do_z = false
					else:
						do_x = false
			var kind: int = CELL_RAMP_NONE
			if do_x:
				kind = CELL_RAMP_EAST
			elif do_z:
				kind = CELL_RAMP_SOUTH
			ramp_kind[_cell_index(x, z)] = kind

func _cell_corners(x: int, z: int) -> CellCorners:
	var cc: CellCorners = CellCorners.new()
	var h00: float = _h(x, z)
	cc.a = h00
	cc.b = h00
	cc.c = h00
	cc.d = h00
	var kind: int = ramp_kind[_cell_index(x, z)]
	if kind == CELL_RAMP_EAST:
		var he: float = _h(x + 1, z)
		cc.b = he
		cc.c = he
	elif kind == CELL_RAMP_SOUTH:
		var hs: float = _h(x, z + 1)
		cc.c = hs
		cc.d = hs
	return cc

# -----------------------------
# MESH
# -----------------------------
func _build_blocky_mesh_and_collision() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var uv_scale_top: float = 0.08
	var uv_scale_wall: float = 0.08
	var floor_y: float = minf(outer_floor_height, min_height)

	for z in range(size_z - 1):
		for x in range(size_x - 1):
			var top_idx: int = z * size_x + x
			var is_road: bool = enable_roads and road_mask[top_idx] == 1
			var cc: CellCorners = _cell_corners(x, z)
			var a_y: float = cc.a
			var b_y: float = cc.b
			var c_y: float = cc.c
			var d_y: float = cc.d

			var top_color: Color = road_color if is_road else terrain_color

			_add_quad_smart(
				st,
				_pos(x,     z,     a_y),
				_pos(x + 1, z,     b_y),
				_pos(x + 1, z + 1, c_y),
				_pos(x,     z + 1, d_y),
				Vector2(float(x), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z + 1)) * uv_scale_top,
				Vector2(float(x), float(z + 1)) * uv_scale_top,
				top_color,
				a_y,
				b_y,
				c_y,
				d_y
			)

			var road_n: bool = z > 0 and enable_roads and road_mask[(z - 1) * size_x + x] == 1
			var road_s: bool = enable_roads and road_mask[(z + 1) * size_x + x] == 1
			var road_w: bool = x > 0 and enable_roads and road_mask[z * size_x + (x - 1)] == 1
			var road_e: bool = enable_roads and road_mask[z * size_x + (x + 1)] == 1

			if z == 0:
				var border_n_color: Color = road_color if is_road else terrain_color
				_add_edge_face_z(st, x, z, a_y, b_y, floor_y, true, uv_scale_wall, border_n_color)
			if x == 0:
				var border_w_color: Color = road_color if is_road else terrain_color
				_add_edge_face_x(st, x, z, a_y, d_y, floor_y, true, uv_scale_wall, border_w_color)
			if z == size_z - 2:
				var border_s_color: Color = road_color if is_road else terrain_color
				_add_edge_face_z(st, x, z + 1, d_y, c_y, floor_y, false, uv_scale_wall, border_s_color)
			if x == size_x - 2:
				var border_e_color: Color = road_color if is_road else terrain_color
				_add_edge_face_x(st, x + 1, z, b_y, c_y, floor_y, false, uv_scale_wall, border_e_color)

			if x < size_x - 2:
				var east_cc: CellCorners = _cell_corners(x + 1, z)
				var seam_e_color: Color = road_color if (is_road or road_e) else terrain_color
				_add_seam_x(st, x + 1, z, z + 1, b_y, c_y, east_cc.a, east_cc.d, uv_scale_wall, seam_e_color)
			if z < size_z - 2:
				var south_cc: CellCorners = _cell_corners(x, z + 1)
				var seam_s_color: Color = road_color if (is_road or road_s) else terrain_color
				_add_seam_z(st, z + 1, x, x + 1, d_y, c_y, south_cc.a, south_cc.b, uv_scale_wall, seam_s_color)

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

func _add_quad_smart(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2, color: Color,
	ya: float, yb: float, yc: float, yd: float) -> void:
	var ac: float = absf(ya - yc)
	var bd: float = absf(yb - yd)
	if ac <= bd:
		st.set_color(color); st.set_uv(ua); st.add_vertex(a)
		st.set_color(color); st.set_uv(ub); st.add_vertex(b)
		st.set_color(color); st.set_uv(uc); st.add_vertex(c)
		st.set_color(color); st.set_uv(ua); st.add_vertex(a)
		st.set_color(color); st.set_uv(uc); st.add_vertex(c)
		st.set_color(color); st.set_uv(ud); st.add_vertex(d)
	else:
		st.set_color(color); st.set_uv(ua); st.add_vertex(a)
		st.set_color(color); st.set_uv(ub); st.add_vertex(b)
		st.set_color(color); st.set_uv(ud); st.add_vertex(d)
		st.set_color(color); st.set_uv(ub); st.add_vertex(b)
		st.set_color(color); st.set_uv(uc); st.add_vertex(c)
		st.set_color(color); st.set_uv(ud); st.add_vertex(d)

func _add_seam_x(st: SurfaceTool, x_edge: int, z0: int, z1: int,
		y_left0: float, y_left1: float, y_right0: float, y_right1: float,
		uv_scale: float, color: Color) -> void:
	if is_equal_approx(y_left0, y_right0) and is_equal_approx(y_left1, y_right1):
		return
	var v0: Vector3 = _pos(x_edge, z0, y_left0)
	var v1: Vector3 = _pos(x_edge, z0, y_right0)
	var v2: Vector3 = _pos(x_edge, z1, y_right1)
	var v3: Vector3 = _pos(x_edge, z1, y_left1)
	var uv0: Vector2 = Vector2(0.0, y_left0 * uv_scale)
	var uv1: Vector2 = Vector2(cell_size * uv_scale, y_right0 * uv_scale)
	var uv2: Vector2 = Vector2(cell_size * uv_scale, y_right1 * uv_scale)
	var uv3: Vector2 = Vector2(0.0, y_left1 * uv_scale)
	_add_quad(st, v0, v1, v2, v3, uv0, uv1, uv2, uv3, color)

func _add_seam_z(st: SurfaceTool, z_edge: int, x0: int, x1: int,
		y_north0: float, y_north1: float, y_south0: float, y_south1: float,
		uv_scale: float, color: Color) -> void:
	if is_equal_approx(y_north0, y_south0) and is_equal_approx(y_north1, y_south1):
		return
	var v0: Vector3 = _pos(x0, z_edge, y_north0)
	var v1: Vector3 = _pos(x0, z_edge, y_south0)
	var v2: Vector3 = _pos(x1, z_edge, y_south1)
	var v3: Vector3 = _pos(x1, z_edge, y_north1)
	var uv0: Vector2 = Vector2(0.0, y_north0 * uv_scale)
	var uv1: Vector2 = Vector2(0.0, y_south0 * uv_scale)
	var uv2: Vector2 = Vector2(cell_size * uv_scale, y_south1 * uv_scale)
	var uv3: Vector2 = Vector2(cell_size * uv_scale, y_north1 * uv_scale)
	_add_quad(st, v0, v1, v2, v3, uv0, uv1, uv2, uv3, color)

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

func _add_road_skirt_z(st: SurfaceTool, x: int, z_edge: int, top0: float, top1: float, bottom0: float, bottom1: float,
		north: bool, uv_scale: float, color: Color) -> void:
	var p0: Vector3 = _pos(x,     z_edge, top0)
	var p1: Vector3 = _pos(x + 1, z_edge, top1)
	var p2: Vector3 = _pos(x + 1, z_edge, bottom1)
	var p3: Vector3 = _pos(x,     z_edge, bottom0)

	var uv0: Vector2 = Vector2(0.0, top0 * uv_scale)
	var uv1: Vector2 = Vector2(cell_size * uv_scale, top1 * uv_scale)
	var uv2: Vector2 = Vector2(cell_size * uv_scale, bottom1 * uv_scale)
	var uv3: Vector2 = Vector2(0.0, bottom0 * uv_scale)

	if north:
		_add_quad(st, p1, p0, p3, p2, uv0, uv1, uv2, uv3, color)
	else:
		_add_quad(st, p0, p1, p2, p3, uv0, uv1, uv2, uv3, color)

func _add_road_skirt_x(st: SurfaceTool, x_edge: int, z: int, top0: float, top1: float, bottom0: float, bottom1: float,
		west: bool, uv_scale: float, color: Color) -> void:
	var p0: Vector3 = _pos(x_edge, z,     top0)
	var p1: Vector3 = _pos(x_edge, z + 1, top1)
	var p2: Vector3 = _pos(x_edge, z + 1, bottom1)
	var p3: Vector3 = _pos(x_edge, z,     bottom0)

	var uv0: Vector2 = Vector2(0.0, top0 * uv_scale)
	var uv1: Vector2 = Vector2(cell_size * uv_scale, top1 * uv_scale)
	var uv2: Vector2 = Vector2(cell_size * uv_scale, bottom1 * uv_scale)
	var uv3: Vector2 = Vector2(0.0, bottom0 * uv_scale)

	if west:
		_add_quad(st, p0, p1, p2, p3, uv0, uv1, uv2, uv3, color)
	else:
		_add_quad(st, p1, p0, p3, p2, uv0, uv1, uv2, uv3, color)

const EPS: float = 0.0001

func _add_edge_face_z(st: SurfaceTool, x: int, z_edge: int, top0: float, top1: float, neighbor_h: float, north: bool,
		uv_scale: float, color: Color) -> void:
	var b0: float = minf(neighbor_h, top0)
	var b1: float = minf(neighbor_h, top1)
	if (top0 - b0) <= EPS and (top1 - b1) <= EPS:
		return
	_add_road_skirt_z(st, x, z_edge, top0, top1, b0, b1, north, uv_scale, color)

func _add_edge_face_x(st: SurfaceTool, x_edge: int, z: int, top0: float, top1: float, neighbor_h: float, west: bool,
		uv_scale: float, color: Color) -> void:
	var b0: float = minf(neighbor_h, top0)
	var b1: float = minf(neighbor_h, top1)
	if (top0 - b0) <= EPS and (top1 - b1) <= EPS:
		return
	_add_road_skirt_x(st, x_edge, z, top0, top1, b0, b1, west, uv_scale, color)
