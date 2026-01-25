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

@onready var mesh_instance: MeshInstance3D = $TerrainBody/TerrainMesh
@onready var collision_shape: CollisionShape3D = $TerrainBody/TerrainCollision

var heights: PackedFloat32Array
var _ox: float
var _oz: float

func _ready() -> void:
	generate()

func generate() -> void:
	_ox = -float(size_x) * cell_size * 0.5
	_oz = -float(size_z) * cell_size * 0.5
	_generate_heights()
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

			_add_quad(
				st,
				_pos(x,     z,     a_y),
				_pos(x + 1, z,     b_y),
				_pos(x + 1, z + 1, c_y),
				_pos(x,     z + 1, d_y),
				Vector2(float(x), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z + 1)) * uv_scale_top,
				Vector2(float(x), float(z + 1)) * uv_scale_top
			)

			# Walls: only where neighbor is lower AND not replaced by a ramp on that edge
			var hn: float = _h(x, z - 1) if z > 0 else h00
			var hs: float = _h(x, z + 1)
			var hw: float = _h(x - 1, z) if x > 0 else h00
			var he: float = _h(x + 1, z)

			# North edge (no ramp handled here)
			if z > 0 and hn < h00:
				_add_wall_z(st, x, z, hn, h00, true, uv_scale_wall)

			# West edge (no ramp handled here)
			if x > 0 and hw < h00:
				_add_wall_x(st, x, z, hw, h00, true, uv_scale_wall)

			# South edge: skip the wall if this cell ramps south into it
			if hs < h00 and not ramp_south:
				_add_wall_z(st, x, z + 1, hs, h00, false, uv_scale_wall)

			# East edge: skip the wall if this cell ramps east into it
			if he < h00 and not ramp_east:
				_add_wall_x(st, x + 1, z, he, h00, false, uv_scale_wall)

	_add_box_walls(st, uv_scale_wall)

	if build_ceiling:
		_add_ceiling(st)

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	mesh_instance.mesh = mesh
	collision_shape.shape = mesh.create_trimesh_shape()

func _add_box_walls(st: SurfaceTool, uv_scale_wall: float) -> void:
	var floor_y: float = minf(outer_floor_height, min_height)
	var top_y: float = box_height

	for x in range(size_x - 1):
		_add_wall_z_one_sided(st, x, 0, floor_y, top_y, true, uv_scale_wall)
	for x in range(size_x - 1):
		_add_wall_z_one_sided(st, x, size_z - 1, floor_y, top_y, false, uv_scale_wall)

	for z in range(size_z - 1):
		_add_wall_x_one_sided(st, 0, z, floor_y, top_y, true, uv_scale_wall)
	for z in range(size_z - 1):
		_add_wall_x_one_sided(st, size_x - 1, z, floor_y, top_y, false, uv_scale_wall)

func _add_ceiling(st: SurfaceTool) -> void:
	var y: float = box_height
	var a: Vector3 = _pos(0, 0, y)
	var b: Vector3 = _pos(size_x - 1, 0, y)
	var c: Vector3 = _pos(size_x - 1, size_z - 1, y)
	var d: Vector3 = _pos(0, size_z - 1, y)
	_add_quad(st, a, d, c, b, Vector2(0,0), Vector2(0,1), Vector2(1,1), Vector2(1,0))

# -----------------------------
# Geometry helpers
# -----------------------------
func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	st.set_uv(ua); st.add_vertex(a)
	st.set_uv(ub); st.add_vertex(b)
	st.set_uv(uc); st.add_vertex(c)
	st.set_uv(ua); st.add_vertex(a)
	st.set_uv(uc); st.add_vertex(c)
	st.set_uv(ud); st.add_vertex(d)

func _add_wall_z(st: SurfaceTool, x: int, z_edge: int, h_low: float, h_high: float, north: bool, uv_scale: float) -> void:
	_add_wall_z_one_sided(st, x, z_edge, h_low, h_high, north, uv_scale)
	_add_wall_z_one_sided(st, x, z_edge, h_low, h_high, not north, uv_scale)

func _add_wall_x(st: SurfaceTool, x_edge: int, z: int, h_low: float, h_high: float, west: bool, uv_scale: float) -> void:
	_add_wall_x_one_sided(st, x_edge, z, h_low, h_high, west, uv_scale)
	_add_wall_x_one_sided(st, x_edge, z, h_low, h_high, not west, uv_scale)

func _add_wall_z_one_sided(st: SurfaceTool, x: int, z_edge: int, h_low: float, h_high: float, north: bool, uv_scale: float) -> void:
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
			_add_quad(st, p1, p0, p3, p2, uv0, uv1, uv2, uv3)
		else:
			_add_quad(st, p0, p1, p2, p3, uv0, uv1, uv2, uv3)

		y0 = y1

func _add_wall_x_one_sided(st: SurfaceTool, x_edge: int, z: int, h_low: float, h_high: float, west: bool, uv_scale: float) -> void:
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
			_add_quad(st, p0, p1, p2, p3, uv0, uv1, uv2, uv3)
		else:
			_add_quad(st, p1, p0, p3, p2, uv0, uv1, uv2, uv3)

		y0 = y1
