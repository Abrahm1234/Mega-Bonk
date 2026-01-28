extends Node3D
class_name BlockyTerrain

# -----------------------------
# Arena size (14x14)
# -----------------------------
@export_range(2, 128, 1) var cells_per_side: int = 14
@export var world_size_m: float = 256.0  # total arena width/depth in meters

# -----------------------------
# Heightmap (low-res noise)
# -----------------------------
@export var noise_seed: int = 1234
@export var noise_frequency: float = 0.12
@export var noise_octaves: int = 3
@export var noise_lacunarity: float = 2.0
@export var noise_gain: float = 0.5

@export var height_scale: float = 26.0
@export var height_step: float = 2.0
@export var min_height: float = -10.0
@export var max_height: float = 60.0

# Optional: make the map chunkier by sampling the same value for blocks of cells.
# 1 = true 14x14 detail. 2 = 7x7 “macro” feel, etc.
@export_range(1, 8, 1) var block_size_cells: int = 1

# Optional shaping (similar to your previous arena shaping)
@export var center_flat_radius_m: float = 55.0
@export_range(0.0, 1.0, 0.01) var center_flat_strength: float = 0.75
@export_range(0.0, 1.0, 0.01) var edge_ramp_strength: float = 0.35

# -----------------------------
# Containing box
# -----------------------------
@export var outer_floor_height: float = -40.0
@export var box_height: float = 80.0
@export var build_ceiling: bool = false

# -----------------------------
# Ramps (Mega Bonk style connectivity)
# -----------------------------
@export var enable_ramps: bool = true
@export_range(0, 64, 1) var ramp_count: int = 18
@export_range(1, 3, 1) var ramp_step_count: int = 1
@export var ramp_color: Color = Color(0.32, 0.68, 0.34, 1.0)
@export_range(1, 64, 1) var min_plateau_cells: int = 3
@export_range(0.0, 1.0, 0.01) var extra_ramp_skip_chance: float = 0.10
@export_range(1, 64, 1) var rescue_min_plateau_cells: int = 1
@export_range(0, 256, 1) var rescue_ramp_budget: int = 32
@export_range(0, 4, 1) var min_component_degree: int = 1
@export_range(0, 256, 1) var degree_rescue_budget: int = 96
@export_range(0, 4, 1) var walk_up_steps_without_ramp: int = 0
@export_range(0, 4, 1) var walk_down_steps_without_ramp: int = 4
@export_range(0, 256, 1) var trap_rescue_budget: int = 128

# -----------------------------
# Traversal constraints
# -----------------------------
@export_range(1, 4, 1) var max_neighbor_steps: int = 1
@export_range(0, 64, 1) var relax_passes: int = 24

# -----------------------------
# Visuals
# -----------------------------
@export var terrain_color: Color = Color(0.32, 0.68, 0.34, 1.0)
@export var box_color: Color = Color(0.12, 0.12, 0.12, 1.0)

@onready var mesh_instance: MeshInstance3D = get_node_or_null("TerrainBody/TerrainMesh")
@onready var collision_shape: CollisionShape3D = get_node_or_null("TerrainBody/TerrainCollision")

var _cell_size: float
var _ox: float
var _oz: float
var _heights: PackedFloat32Array  # one height per cell (cells_per_side * cells_per_side)
var _ramp_dir: PackedInt32Array
var _ramp_low: PackedFloat32Array

const RAMP_NONE := -1
const RAMP_EAST := 0
const RAMP_WEST := 1
const RAMP_SOUTH := 2
const RAMP_NORTH := 3

class RampCandidate:
	var x: int
	var z: int
	var dir: int
	var low: float

	func _init(_x: int, _z: int, _dir: int, _low: float) -> void:
		x = _x
		z = _z
		dir = _dir
		low = _low

func _neighbor_of(x: int, z: int, dir: int) -> Vector2i:
	match dir:
		RAMP_EAST:
			return Vector2i(x + 1, z)
		RAMP_WEST:
			return Vector2i(x - 1, z)
		RAMP_SOUTH:
			return Vector2i(x, z + 1)
		RAMP_NORTH:
			return Vector2i(x, z - 1)
		_:
			return Vector2i(x, z)

func _opposite_dir(dir: int) -> int:
	match dir:
		RAMP_EAST:
			return RAMP_WEST
		RAMP_WEST:
			return RAMP_EAST
		RAMP_SOUTH:
			return RAMP_NORTH
		RAMP_NORTH:
			return RAMP_SOUTH
		_:
			return dir

func _landing_ok(n: int, lx: int, lz: int, exit_dir: int) -> bool:
	var landing_idx: int = lz * n + lx
	var h: float = _heights[landing_idx]
	var fwd: Vector2i = _neighbor_of(lx, lz, exit_dir)
	if fwd.x < 0 or fwd.x >= n or fwd.y < 0 or fwd.y >= n:
		return false

	var fwd_h: float = _heights[fwd.y * n + fwd.x]
	var max_drop: float = float(max_neighbor_steps) * height_step
	return (h - fwd_h) <= max_drop

func _landing_ok_loose(n: int, lx: int, lz: int) -> bool:
	return lx >= 0 and lx < n and lz >= 0 and lz < n

func _uphill_supported(n: int, x: int, z: int, dir: int, high_h: float, eps: float) -> bool:
	var up_dir: int = _opposite_dir(dir)
	var up: Vector2i = _neighbor_of(x, z, up_dir)
	if up.x < 0 or up.x >= n or up.y < 0 or up.y >= n:
		return false
	return absf(_cell_h(up.x, up.y) - high_h) <= eps

func _dir_from_to(ax: int, az: int, bx: int, bz: int) -> int:
	if bx == ax + 1 and bz == az:
		return RAMP_EAST
	if bx == ax - 1 and bz == az:
		return RAMP_WEST
	if bx == ax and bz == az + 1:
		return RAMP_SOUTH
	if bx == ax and bz == az - 1:
		return RAMP_NORTH
	return RAMP_NONE

func _has_ramp_between(ax: int, az: int, bx: int, bz: int) -> bool:
	var n: int = max(2, cells_per_side)
	var a_idx: int = az * n + ax
	var b_idx: int = bz * n + bx
	var da: float = _heights[a_idx] - _heights[b_idx]
	if da > 0.0:
		return _ramp_dir[a_idx] == _dir_from_to(ax, az, bx, bz)
	if da < 0.0:
		return _ramp_dir[b_idx] == _dir_from_to(bx, bz, ax, az)
	return true

func _cell_has_exit(n: int, x: int, z: int) -> bool:
	var idx: int = z * n + x
	var h0: float = _heights[idx]
	var dirs: Array[int] = [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]
	for d in dirs:
		var nb: Vector2i = _neighbor_of(x, z, d)
		if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
			continue
		var h1: float = _heights[nb.y * n + nb.x]
		var dh_steps: int = int(roundf((h1 - h0) / maxf(0.0001, height_step)))
		if dh_steps <= walk_up_steps_without_ramp and dh_steps >= -walk_down_steps_without_ramp:
			return true
		if _has_ramp_between(x, z, nb.x, nb.y):
			return true
	return false

func _rescue_trap_cells(n: int, want_delta: float, delta_eps: float) -> void:
	var budget: int = trap_rescue_budget
	var dirs: Array[int] = [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]
	for z in range(n):
		for x in range(n):
			if budget <= 0:
				return
			if _cell_has_exit(n, x, z):
				continue
			var idx_lo: int = z * n + x
			var h_lo: float = _heights[idx_lo]
			for d in dirs:
				var nb: Vector2i = _neighbor_of(x, z, d)
				if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
					continue
				var idx_hi: int = nb.y * n + nb.x
				var h_hi: float = _heights[idx_hi]
				if absf((h_hi - h_lo) - want_delta) > delta_eps:
					continue
				if _ramp_dir[idx_hi] != RAMP_NONE:
					continue
				var dir_hi_to_lo: int = _dir_from_to(nb.x, nb.y, x, z)
				if dir_hi_to_lo == RAMP_NONE:
					continue
				_ramp_dir[idx_hi] = dir_hi_to_lo
				_ramp_low[idx_hi] = h_lo
				budget -= 1
				break

func _validate_ramps_move(n: int, want_delta: float, delta_eps: float) -> void:
	for z in range(n):
		for x in range(n):
			var idx: int = z * n + x
			var dir: int = _ramp_dir[idx]
			if dir == RAMP_NONE:
				continue

			var nb: Vector2i = _neighbor_of(x, z, dir)
			if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
				_ramp_dir[idx] = RAMP_NONE
				continue

			var nidx: int = nb.y * n + nb.x
			var h_here: float = _heights[idx]
			var h_nb: float = _heights[nidx]
			var dh: float = h_here - h_nb

			if absf(dh - want_delta) <= delta_eps:
				_ramp_low[idx] = h_nb
				continue

			if absf(-dh - want_delta) <= delta_eps:
				if _ramp_dir[nidx] == RAMP_NONE:
					_ramp_dir[nidx] = _opposite_dir(dir)
					_ramp_low[nidx] = h_here
				_ramp_dir[idx] = RAMP_NONE
				continue

			_ramp_dir[idx] = RAMP_NONE

func _edge_matches(ca: Vector4, cb: Vector4, edge_a: int, edge_b: int, eps: float) -> bool:
	var ea: Vector2 = _edge_pair(ca, edge_a)
	var eb: Vector2 = _edge_pair(cb, edge_b)
	return absf(ea.x - eb.x) <= eps and absf(ea.y - eb.y) <= eps

func _down_edge(dir: int) -> int:
	match dir:
		RAMP_EAST:
			return 0
		RAMP_WEST:
			return 1
		RAMP_NORTH:
			return 2
		RAMP_SOUTH:
			return 3
		_:
			return 0

func _up_edge(dir: int) -> int:
	match dir:
		RAMP_EAST:
			return 1
		RAMP_WEST:
			return 0
		RAMP_NORTH:
			return 3
		RAMP_SOUTH:
			return 2
		_:
			return 1

func _prune_unconnected_ramps(n: int, eps: float) -> void:
	for z in range(n):
		for x in range(n):
			var idx: int = z * n + x
			var dir: int = _ramp_dir[idx]
			if dir == RAMP_NONE:
				continue

			var down_nb: Vector2i = _neighbor_of(x, z, dir)
			var up_nb: Vector2i = _neighbor_of(x, z, _opposite_dir(dir))

			if down_nb.x < 0 or down_nb.x >= n or down_nb.y < 0 or down_nb.y >= n:
				_ramp_dir[idx] = RAMP_NONE
				continue
			if up_nb.x < 0 or up_nb.x >= n or up_nb.y < 0 or up_nb.y >= n:
				_ramp_dir[idx] = RAMP_NONE
				continue

			var c_here: Vector4 = _cell_corners(x, z)
			var c_down: Vector4 = _cell_corners(down_nb.x, down_nb.y)
			var c_up: Vector4 = _cell_corners(up_nb.x, up_nb.y)

			var d_edge: int = _down_edge(dir)
			var d_opp: int = _up_edge(dir)
			if not _edge_matches(c_here, c_down, d_edge, d_opp, eps):
				_ramp_dir[idx] = RAMP_NONE
				continue

			var u_edge: int = _up_edge(dir)
			var u_opp: int = _down_edge(dir)
			if not _edge_matches(c_here, c_up, u_edge, u_opp, eps):
				_ramp_dir[idx] = RAMP_NONE

func _ready() -> void:
	if mesh_instance == null or collision_shape == null:
		push_error("BlockyTerrain: Expected nodes 'TerrainBody/TerrainMesh' and 'TerrainBody/TerrainCollision'.")
		return

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
	var n: int = max(2, cells_per_side)
	_cell_size = world_size_m / float(n)

	# Center the arena around (0,0) in XZ
	_ox = -world_size_m * 0.5
	_oz = -world_size_m * 0.5

	_generate_heights()
	_limit_neighbor_cliffs()
	_generate_ramps()
	_build_mesh_and_collision()

# -----------------------------
# Height generation (14x14)
# -----------------------------
func _generate_heights() -> void:
	var n: int = max(2, cells_per_side)
	_heights = PackedFloat32Array()
	_heights.resize(n * n)

	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = noise_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = noise_octaves
	noise.fractal_lacunarity = noise_lacunarity
	noise.fractal_gain = noise_gain

	var half_w: float = world_size_m * 0.5
	var flat_r: float = maxf(0.0, center_flat_radius_m)

	var bs: int = max(1, block_size_cells)

	for z in range(n):
		for x in range(n):
			# Optional chunking: force (x,z) to sample on block boundaries
			var sx: int = int(floor(float(x) / float(bs))) * bs
			var sz: int = int(floor(float(z) / float(bs))) * bs

			# Sample noise in cell coordinates (low-res by design: only n x n samples)
			var v: float = noise.get_noise_2d(float(sx), float(sz))

			# Mild shaping for “arena-like” silhouettes
			v = signf(v) * pow(absf(v), 1.35)

			var h: float = v * height_scale

			# Center flatten blends toward 0.0
			if flat_r > 0.0:
				var px: float = _ox + (float(x) + 0.5) * _cell_size
				var pz: float = _oz + (float(z) + 0.5) * _cell_size
				var d: float = sqrt(px * px + pz * pz)
				var t: float = clampf(d / flat_r, 0.0, 1.0)
				var flatten: float = lerpf(center_flat_strength, 0.0, t)
				h = lerpf(h, 0.0, flatten)

			# Edge ramp raises toward boundaries (helps form “bowl/arena” readability)
			var pxn: float = absf((_ox + (float(x) + 0.5) * _cell_size)) / maxf(0.001, half_w)
			var pzn: float = absf((_oz + (float(z) + 0.5) * _cell_size)) / maxf(0.001, half_w)
			var edge_t: float = clampf(maxf(pxn, pzn), 0.0, 1.0)
			h += edge_t * edge_t * height_scale * edge_ramp_strength

			# Clamp + quantize (voxel look)
			h = clampf(h, min_height, minf(max_height, box_height - 0.5))
			h = _quantize(h, height_step)

			_heights[z * n + x] = h

func _quantize(h: float, step: float) -> float:
	if step <= 0.0:
		return h
	return roundf(h / step) * step

func _cell_h(x: int, z: int) -> float:
	var n: int = max(2, cells_per_side)
	return _heights[z * n + x]

# -----------------------------
# Cliff limiter (enforces max neighbor delta)
# -----------------------------
func _h_to_level(h: float) -> int:
	return int(roundf(h / maxf(0.0001, height_step)))

func _level_to_h(level: int) -> float:
	return float(level) * height_step

func _limit_neighbor_cliffs() -> void:
	var n: int = max(2, cells_per_side)
	if height_step <= 0.0:
		return

	var levels := PackedInt32Array()
	levels.resize(n * n)

	for i in range(n * n):
		levels[i] = _h_to_level(_heights[i])

	for _pass in range(relax_passes):
		var changed := false

		for z in range(n):
			for x in range(n):
				var idx := z * n + x
				var level := levels[idx]

				var min_n := level
				var max_n := level

				if x > 0:
					min_n = mini(min_n, levels[idx - 1])
					max_n = maxi(max_n, levels[idx - 1])
				if x + 1 < n:
					min_n = mini(min_n, levels[idx + 1])
					max_n = maxi(max_n, levels[idx + 1])
				if z > 0:
					min_n = mini(min_n, levels[idx - n])
					max_n = maxi(max_n, levels[idx - n])
				if z + 1 < n:
					min_n = mini(min_n, levels[idx + n])
					max_n = maxi(max_n, levels[idx + n])

				if level > min_n + max_neighbor_steps:
					levels[idx] = min_n + max_neighbor_steps
					changed = true
				elif level < max_n - max_neighbor_steps:
					levels[idx] = max_n - max_neighbor_steps
					changed = true

		if not changed:
			break

	for i in range(n * n):
		var h: float = _level_to_h(levels[i])
		h = clampf(h, min_height, minf(max_height, box_height - 0.5))
		_heights[i] = h

# -----------------------------
# Ramp generation (one-cell wedges)
# -----------------------------
func _generate_ramps() -> void:
	var n: int = max(2, cells_per_side)
	_ramp_dir = PackedInt32Array()
	_ramp_low = PackedFloat32Array()
	_ramp_dir.resize(n * n)
	_ramp_low.resize(n * n)

	for i in range(n * n):
		_ramp_dir[i] = RAMP_NONE
		_ramp_low[i] = 0.0

	if not enable_ramps:
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(noise_seed) ^ 0x6c8e9cf1

	var step: float = maxf(0.0001, height_step)
	var want_delta: float = float(ramp_step_count) * step
	var delta_eps: float = step * 0.25

	var levels: PackedInt32Array = PackedInt32Array()
	levels.resize(n * n)
	for i in range(n * n):
		levels[i] = _h_to_level(_heights[i])

	var comp_id: PackedInt32Array = PackedInt32Array()
	comp_id.resize(n * n)
	for i in range(n * n):
		comp_id[i] = -1

	var comp_count: int = 0
	var queue: Array[int] = []

	for z in range(n):
		for x in range(n):
			var idx: int = z * n + x
			if comp_id[idx] != -1:
				continue

			var target_level: int = levels[idx]
			comp_id[idx] = comp_count
			queue.clear()
			queue.append(idx)

			while queue.size() > 0:
				var current: int = int(queue.pop_back())
				var cx: int = current % n
				var cz: int = int(float(current) / float(n))

				if cx > 0:
					var left: int = current - 1
					if comp_id[left] == -1 and levels[left] == target_level:
						comp_id[left] = comp_count
						queue.append(left)
				if cx + 1 < n:
					var right: int = current + 1
					if comp_id[right] == -1 and levels[right] == target_level:
						comp_id[right] = comp_count
						queue.append(right)
				if cz > 0:
					var up: int = current - n
					if comp_id[up] == -1 and levels[up] == target_level:
						comp_id[up] = comp_count
						queue.append(up)
				if cz + 1 < n:
					var down: int = current + n
					if comp_id[down] == -1 and levels[down] == target_level:
						comp_id[down] = comp_count
						queue.append(down)

			comp_count += 1

	var candidates: Array[RampCandidate] = []
	var candidates_relaxed: Array[RampCandidate] = []
	var ramp_dirs: Array[int] = [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]

	var comp_size: PackedInt32Array = PackedInt32Array()
	comp_size.resize(comp_count)
	for i in range(comp_count):
		comp_size[i] = 0
	for i in range(n * n):
		var cid: int = comp_id[i]
		if cid >= 0:
			comp_size[cid] += 1

	for z in range(n):
		for x in range(n):
			var h0: float = _cell_h(x, z)
			for dir in ramp_dirs:
				var nb: Vector2i = _neighbor_of(x, z, dir)
				if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
					continue

				var h1: float = _cell_h(nb.x, nb.y)
				var dh: float = h0 - h1

				if absf(dh - want_delta) <= delta_eps:
					candidates_relaxed.append(RampCandidate.new(x, z, dir, h1))
					var idx0: int = z * n + x
					var idx1: int = nb.y * n + nb.x
					var high_comp: int = comp_id[idx0]
					var low_comp: int = comp_id[idx1]
					if comp_size[high_comp] < min_plateau_cells:
						continue
					if comp_size[low_comp] < min_plateau_cells:
						continue
					if not _landing_ok(n, nb.x, nb.y, dir):
						continue
					if not _uphill_supported(n, x, z, dir, h0, delta_eps):
						continue
					candidates.append(RampCandidate.new(x, z, dir, h1))

	for i in range(candidates.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: RampCandidate = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = temp

	var parent: PackedInt32Array = PackedInt32Array()
	parent.resize(comp_count)
	for i in range(comp_count):
		parent[i] = i

	var find := func(a: int) -> int:
		var root: int = a
		while parent[root] != root:
			root = parent[root]
		while parent[a] != a:
			var next: int = parent[a]
			parent[a] = root
			a = next
		return root

	var union := func(a: int, b: int) -> void:
		var ra: int = find.call(a)
		var rb: int = find.call(b)
		if ra != rb:
			parent[rb] = ra

	var placed: int = 0

	for i in range(candidates.size()):
		var c: RampCandidate = candidates[i]
		var x: int = c.x
		var z: int = c.z
		var idx: int = z * n + x
		if _ramp_dir[idx] != RAMP_NONE:
			continue

		var low: float = c.low
		var low_x: int = x
		var low_z: int = z
		match c.dir:
			RAMP_EAST:
				low_x += 1
			RAMP_WEST:
				low_x -= 1
			RAMP_SOUTH:
				low_z += 1
			RAMP_NORTH:
				low_z -= 1

		if low_x < 0 or low_x >= n or low_z < 0 or low_z >= n:
			continue

		var high_comp: int = comp_id[idx]
		var low_comp: int = comp_id[low_z * n + low_x]

		if find.call(high_comp) == find.call(low_comp):
			continue

		_ramp_dir[idx] = c.dir
		_ramp_low[idx] = low
		placed += 1
		union.call(high_comp, low_comp)

	var extra_budget: int = int(max(0, ramp_count - placed))
	for i in range(candidates.size()):
		if extra_budget <= 0:
			break

		var c: RampCandidate = candidates[i]
		var x: int = c.x
		var z: int = c.z
		var idx: int = z * n + x
		if _ramp_dir[idx] != RAMP_NONE:
			continue

		if rng.randf() < extra_ramp_skip_chance:
			continue

		_ramp_dir[idx] = c.dir
		_ramp_low[idx] = c.low
		placed += 1
		extra_budget -= 1

	_validate_ramps_move(n, want_delta, delta_eps)
	_prune_unconnected_ramps(n, delta_eps)

	var comp_degree: PackedInt32Array = PackedInt32Array()
	comp_degree.resize(comp_count)
	for i in range(comp_count):
		comp_degree[i] = 0

	for z in range(n):
		for x in range(n):
			var idx: int = z * n + x
			var dir: int = _ramp_dir[idx]
			if dir == RAMP_NONE:
				continue
			var nb: Vector2i = _neighbor_of(x, z, dir)
			if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
				continue
			var a: int = comp_id[idx]
			var b: int = comp_id[nb.y * n + nb.x]
			comp_degree[a] += 1
			comp_degree[b] += 1

	var rescue_left: int = rescue_ramp_budget
	for cid in range(comp_count):
		if rescue_left <= 0:
			break
		if comp_degree[cid] > 0:
			continue

		for k in range(candidates_relaxed.size()):
			var c: RampCandidate = candidates_relaxed[k]
			var idx_hi: int = c.z * n + c.x
			var nb: Vector2i = _neighbor_of(c.x, c.z, c.dir)
			if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
				continue
			var idx_lo: int = nb.y * n + nb.x
			var hi_comp: int = comp_id[idx_hi]
			var lo_comp: int = comp_id[idx_lo]

			if hi_comp != cid and lo_comp != cid:
				continue

			if comp_size[hi_comp] < rescue_min_plateau_cells:
				continue
			if comp_size[lo_comp] < rescue_min_plateau_cells:
				continue
			if _ramp_dir[idx_hi] != RAMP_NONE:
				continue
			if not _landing_ok_loose(n, nb.x, nb.y):
				continue

			_ramp_dir[idx_hi] = c.dir
			_ramp_low[idx_hi] = c.low
			comp_degree[hi_comp] += 1
			comp_degree[lo_comp] += 1
			rescue_left -= 1
			break

	_validate_ramps_move(n, want_delta, delta_eps)
	_prune_unconnected_ramps(n, delta_eps)

	var degree_left: int = degree_rescue_budget
	comp_degree = PackedInt32Array()
	comp_degree.resize(comp_count)
	for i in range(comp_count):
		comp_degree[i] = 0

	for z in range(n):
		for x in range(n):
			var idx: int = z * n + x
			var dir: int = _ramp_dir[idx]
			if dir == RAMP_NONE:
				continue
			var nb: Vector2i = _neighbor_of(x, z, dir)
			if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
				continue
			var a: int = comp_id[idx]
			var b: int = comp_id[nb.y * n + nb.x]
			comp_degree[a] += 1
			comp_degree[b] += 1

	for cid in range(comp_count):
		if degree_left <= 0:
			break
		while comp_degree[cid] < min_component_degree and degree_left > 0:
			var placed_degree := false
			for k in range(candidates_relaxed.size()):
				var c: RampCandidate = candidates_relaxed[k]
				var idx_hi: int = c.z * n + c.x
				var nb: Vector2i = _neighbor_of(c.x, c.z, c.dir)
				if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
					continue
				var idx_lo: int = nb.y * n + nb.x
				var hi_comp: int = comp_id[idx_hi]
				var lo_comp: int = comp_id[idx_lo]

				if hi_comp != cid and lo_comp != cid:
					continue
				if _ramp_dir[idx_hi] != RAMP_NONE:
					continue
				if not _landing_ok_loose(n, nb.x, nb.y):
					continue

				_ramp_dir[idx_hi] = c.dir
				_ramp_low[idx_hi] = c.low
				comp_degree[hi_comp] += 1
				comp_degree[lo_comp] += 1
				degree_left -= 1
				placed_degree = true
				break
			if not placed_degree:
				break

	_validate_ramps_move(n, want_delta, delta_eps)
	_prune_unconnected_ramps(n, delta_eps)

	_rescue_trap_cells(n, want_delta, delta_eps)
	_validate_ramps_move(n, want_delta, delta_eps)
	_prune_unconnected_ramps(n, delta_eps)

func _cell_corners(x: int, z: int) -> Vector4:
	var n: int = max(2, cells_per_side)
	var idx := z * n + x
	var h := _cell_h(x, z)

	var dir := _ramp_dir[idx]
	if dir == RAMP_NONE:
		return Vector4(h, h, h, h)

	var low := _ramp_low[idx]

	match dir:
		RAMP_EAST:
			return Vector4(h, low, low, h)
		RAMP_WEST:
			return Vector4(low, h, h, low)
		RAMP_SOUTH:
			return Vector4(h, h, low, low)
		RAMP_NORTH:
			return Vector4(low, low, h, h)
		_:
			return Vector4(h, h, h, h)

func _edge_pair(c: Vector4, edge: int) -> Vector2:
	match edge:
		0:
			return Vector2(c.y, c.z)
		1:
			return Vector2(c.x, c.w)
		2:
			return Vector2(c.x, c.y)
		3:
			return Vector2(c.w, c.z)
		_:
			return Vector2(c.x, c.x)

# -----------------------------
# Mesh building
# -----------------------------
func _build_mesh_and_collision() -> void:
	var n: int = max(2, cells_per_side)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var uv_scale_top: float = 0.08
	var uv_scale_wall: float = 0.08

	# Floor of container
	_add_floor(st, outer_floor_height, uv_scale_top)

	# Terrain cells (flat tops unless ramp)
	for z in range(n):
		for x in range(n):
			var x0: float = _ox + float(x) * _cell_size
			var x1: float = x0 + _cell_size
			var z0: float = _oz + float(z) * _cell_size
			var z1: float = z0 + _cell_size

			var c0 := _cell_corners(x, z)

			var a := Vector3(x0, c0.x, z0)
			var b := Vector3(x1, c0.y, z0)
			var c := Vector3(x1, c0.z, z1)
			var d := Vector3(x0, c0.w, z1)

			var cell_color := terrain_color
			if _ramp_dir[z * n + x] != RAMP_NONE:
				cell_color = ramp_color

			_add_quad(
				st, a, b, c, d,
				Vector2(float(x), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z + 1)) * uv_scale_top,
				Vector2(float(x), float(z + 1)) * uv_scale_top,
				cell_color
			)

	var eps := 0.0001

	for z in range(n):
		for x in range(n):
			var x0: float = _ox + float(x) * _cell_size
			var x1: float = x0 + _cell_size
			var z0: float = _oz + float(z) * _cell_size
			var z1: float = z0 + _cell_size

			var cA := _cell_corners(x, z)

			if x + 1 < n:
				var cB := _cell_corners(x + 1, z)
				var a_e := _edge_pair(cA, 0)
				var b_w := _edge_pair(cB, 1)

				var top0 := maxf(a_e.x, b_w.x)
				var top1 := maxf(a_e.y, b_w.y)
				var bot0 := minf(a_e.x, b_w.x)
				var bot1 := minf(a_e.y, b_w.y)

				if (top0 - bot0) > eps or (top1 - bot1) > eps:
					_add_wall_x_between(st, x1, z0, z1, bot0, bot1, top0, top1, uv_scale_wall)

			if z + 1 < n:
				var cC := _cell_corners(x, z + 1)
				var a_s := _edge_pair(cA, 3)
				var c_n := _edge_pair(cC, 2)

				var top0z := maxf(a_s.x, c_n.x)
				var top1z := maxf(a_s.y, c_n.y)
				var bot0z := minf(a_s.x, c_n.x)
				var bot1z := minf(a_s.y, c_n.y)

				if (top0z - bot0z) > eps or (top1z - bot1z) > eps:
					_add_wall_z_between(st, z1, x0, x1, bot0z, bot1z, top0z, top1z, uv_scale_wall)

	# Container walls (keeps everything “inside a box”)
	_add_box_walls(st, outer_floor_height, box_height, uv_scale_wall)

	if build_ceiling:
		_add_ceiling(st, box_height, uv_scale_top)

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	mesh_instance.mesh = mesh
	collision_shape.shape = mesh.create_trimesh_shape()

# -----------------------------
# Container primitives
# -----------------------------
func _add_floor(st: SurfaceTool, y: float, uv_scale: float) -> void:
	var a := Vector3(_ox, y, _oz)
	var b := Vector3(_ox + world_size_m, y, _oz)
	var c := Vector3(_ox + world_size_m, y, _oz + world_size_m)
	var d := Vector3(_ox, y, _oz + world_size_m)
	var u0 := Vector2(0.0, 0.0) * uv_scale
	var u1 := Vector2(1.0, 0.0) * uv_scale
	var u2 := Vector2(1.0, 1.0) * uv_scale
	var u3 := Vector2(0.0, 1.0) * uv_scale
	_add_quad(st, a, b, c, d, u0, u1, u2, u3, box_color)

func _add_box_walls(st: SurfaceTool, y0: float, y1: float, uv_scale: float) -> void:
	# West wall (x = _ox)
	_add_box_wall_plane(st, Vector3(_ox, y0, _oz), Vector3(_ox, y0, _oz + world_size_m), y1, uv_scale, true)
	# East wall (x = _ox + world_size_m)
	_add_box_wall_plane(st, Vector3(_ox + world_size_m, y0, _oz + world_size_m), Vector3(_ox + world_size_m, y0, _oz), y1, uv_scale, true)
	# North wall (z = _oz)
	_add_box_wall_plane(st, Vector3(_ox + world_size_m, y0, _oz), Vector3(_ox, y0, _oz), y1, uv_scale, true)
	# South wall (z = _oz + world_size_m)
	_add_box_wall_plane(st, Vector3(_ox, y0, _oz + world_size_m), Vector3(_ox + world_size_m, y0, _oz + world_size_m), y1, uv_scale, true)

func _add_box_wall_plane(st: SurfaceTool, p0: Vector3, p1: Vector3, top_y: float, uv_scale: float, outward: bool) -> void:
	var a := p0
	var b := p1
	var c := Vector3(p1.x, top_y, p1.z)
	var d := Vector3(p0.x, top_y, p0.z)

	# Order affects normals; culling is disabled, but keep consistent anyway.
	if outward:
		_add_quad(st, b, a, d, c,
			Vector2(0, a.y * uv_scale), Vector2(1, b.y * uv_scale),
			Vector2(1, top_y * uv_scale), Vector2(0, top_y * uv_scale),
			box_color
		)
	else:
		_add_quad(st, a, b, c, d,
			Vector2(0, a.y * uv_scale), Vector2(1, b.y * uv_scale),
			Vector2(1, top_y * uv_scale), Vector2(0, top_y * uv_scale),
			box_color
		)

func _add_ceiling(st: SurfaceTool, y: float, uv_scale: float) -> void:
	var a := Vector3(_ox, y, _oz)
	var b := Vector3(_ox + world_size_m, y, _oz)
	var c := Vector3(_ox + world_size_m, y, _oz + world_size_m)
	var d := Vector3(_ox, y, _oz + world_size_m)
	# Flip winding vs floor so normals face inward-ish
	var u0 := Vector2(0.0, 0.0) * uv_scale
	var u1 := Vector2(0.0, 1.0) * uv_scale
	var u2 := Vector2(1.0, 1.0) * uv_scale
	var u3 := Vector2(1.0, 0.0) * uv_scale
	_add_quad(st, a, d, c, b, u0, u1, u2, u3, box_color)

# -----------------------------
# Terrain wall helpers (between unequal cells)
# -----------------------------
func _add_wall_x_between(st: SurfaceTool, x_edge: float, z0: float, z1: float,
	low0: float, low1: float, high0: float, high1: float, uv_scale: float) -> void:
	var a := Vector3(x_edge, high0, z0)
	var b := Vector3(x_edge, high1, z1)
	var c := Vector3(x_edge, low1, z1)
	var d := Vector3(x_edge, low0, z0)

	_add_quad(st, a, b, c, d,
		Vector2(0, high0 * uv_scale), Vector2(1, high1 * uv_scale),
		Vector2(1, low1 * uv_scale), Vector2(0, low0 * uv_scale),
		terrain_color
	)

func _add_wall_z_between(st: SurfaceTool, z_edge: float, x0: float, x1: float,
	low0: float, low1: float, high0: float, high1: float, uv_scale: float) -> void:
	var a := Vector3(x0, high0, z_edge)
	var b := Vector3(x1, high1, z_edge)
	var c := Vector3(x1, low1, z_edge)
	var d := Vector3(x0, low0, z_edge)

	_add_quad(st, a, b, c, d,
		Vector2(0, high0 * uv_scale), Vector2(1, high1 * uv_scale),
		Vector2(1, low1 * uv_scale), Vector2(0, low0 * uv_scale),
		terrain_color
	)

# -----------------------------
# Quad writer
# -----------------------------
func _add_quad(
	st: SurfaceTool,
	a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2,
	color: Color
) -> void:
	st.set_color(color); st.set_uv(ua); st.add_vertex(a)
	st.set_color(color); st.set_uv(ub); st.add_vertex(b)
	st.set_color(color); st.set_uv(uc); st.add_vertex(c)

	st.set_color(color); st.set_uv(ua); st.add_vertex(a)
	st.set_color(color); st.set_uv(uc); st.add_vertex(c)
	st.set_color(color); st.set_uv(ud); st.add_vertex(d)
