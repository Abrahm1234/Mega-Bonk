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
# Ramps (procedural in terrain mesh)
# -----------------------------
@export var enable_ramps: bool = true
@export_range(1, 3, 1) var ramp_step_count: int = 1
@export_range(0, 8, 1) var extra_ramps_per_component: int = 0
@export_range(0, 4, 1) var walk_up_steps_without_ramp: int = 0
@export_range(0, 4, 1) var walk_down_steps_without_ramp: int = 4
@export_range(0, 4, 1) var pit_fill_passes: int = 2
@export_range(0, 512, 1) var per_level_ramp_budget: int = 96
@export var ramp_color: Color = Color(1.0, 0.0, 1.0, 1.0)
@export var auto_raise_unescapable_basins: bool = true
@export_range(1, 16, 1) var ramp_regen_guard: int = 8
@export var auto_lower_unreachable_peaks: bool = true
@export_range(1, 64, 1) var peak_max_cells: int = 4

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
var _ramp_up_dir: PackedInt32Array
var _ramps_need_regen: bool = false

const RAMP_NONE := -1
const RAMP_EAST := 0
const RAMP_WEST := 1
const RAMP_SOUTH := 2
const RAMP_NORTH := 3

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

func _low_exit_ok(n: int, lx: int, lz: int, dir_up: int) -> bool:
	var low_idx: int = lz * n + lx
	var h: float = _heights[low_idx]
	var max_drop: float = float(maxi(0, walk_down_steps_without_ramp)) * height_step

	for d in [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]:
		if d == dir_up:
			continue
		var nb: Vector2i = _neighbor_of(lx, lz, d)
		if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
			continue
		var nh: float = _heights[nb.y * n + nb.x]
		if (h - nh) <= max_drop:
			return true

	return false

func _count_ramps() -> int:
	var n: int = max(2, cells_per_side)
	var count: int = 0
	for i in range(n * n):
		if _ramp_up_dir[i] != RAMP_NONE:
			count += 1
	return count

func _is_ramp_bridge(a_idx: int, b_idx: int, dir_a_to_b: int, want: int, levels: PackedInt32Array) -> bool:
	if _ramp_up_dir[a_idx] == dir_a_to_b and levels[b_idx] == levels[a_idx] + want:
		return true
	var dir_b_to_a: int = _opposite_dir(dir_a_to_b)
	if _ramp_up_dir[b_idx] == dir_b_to_a and levels[a_idx] == levels[b_idx] + want:
		return true
	return false

func _dir_to_edge(dir: int) -> int:
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

func _cell_edge_dir(x: int, z: int, dir: int) -> Vector2:
	return _edge_pair(_cell_corners(x, z), _dir_to_edge(dir))

func _edges_match(a: Vector2, b: Vector2, eps: float = 0.001) -> bool:
	return absf(a.x - b.x) <= eps and absf(a.y - b.y) <= eps

func _is_flat_edge_at(edge: Vector2, h: float, eps: float = 0.001) -> bool:
	return absf(edge.x - h) <= eps and absf(edge.y - h) <= eps

func _is_stacked_with_this(down_x: int, down_z: int, up_x: int, up_z: int, dir_up: int, want: int) -> bool:
	var n: int = max(2, cells_per_side)
	var down_idx: int = down_z * n + down_x
	if _ramp_up_dir[down_idx] != dir_up:
		return false
	var nn: Vector2i = _neighbor_of(down_x, down_z, dir_up)
	if nn.x != up_x or nn.y != up_z:
		return false
	var down_lvl: int = _h_to_level(_cell_h(down_x, down_z))
	var up_lvl: int = _h_to_level(_cell_h(up_x, up_z))
	return (down_lvl + want) == up_lvl

func _apply_levels_to_heights(n: int, levels: PackedInt32Array) -> void:
	var min_lvl: int = _h_to_level(min_height)
	var max_lvl: int = _h_to_level(minf(max_height, box_height - 0.5))
	for i in range(n * n):
		var lv: int = clampi(levels[i], min_lvl, max_lvl)
		levels[i] = lv
		_heights[i] = _level_to_h(lv)

func _try_place_ramp_candidate(low_idx: int, dir_up: int, n: int, levels: PackedInt32Array, want_levels: int) -> bool:
	if _ramp_up_dir[low_idx] != RAMP_NONE:
		return false

	var low_level: int = levels[low_idx]
	var low_x: int = low_idx % n
	var low_z: int = int(float(low_idx) / float(n))

	var high: Vector2i = _neighbor_of(low_x, low_z, dir_up)
	if high.x < 0 or high.x >= n or high.y < 0 or high.y >= n:
		return false
	var high_idx: int = high.y * n + high.x
	if levels[high_idx] != low_level + want_levels:
		return false

	if _ramp_up_dir[high_idx] != RAMP_NONE and _ramp_up_dir[high_idx] != dir_up:
		return false

	var dir_down: int = _opposite_dir(dir_up)
	var dn: Vector2i = _neighbor_of(low_x, low_z, dir_down)
	if dn.x < 0 or dn.x >= n or dn.y < 0 or dn.y >= n:
		return false
	var dn_idx: int = dn.y * n + dn.x

	if _ramp_up_dir[dn_idx] == RAMP_NONE:
		if levels[dn_idx] != low_level:
			return false
	else:
		if not _is_stacked_with_this(dn.x, dn.y, low_x, low_z, dir_up, want_levels):
			return false

	for sd in _perp_dirs(dir_up):
		var nb_side: Vector2i = _neighbor_of(low_x, low_z, sd)
		if nb_side.x < 0 or nb_side.x >= n or nb_side.y < 0 or nb_side.y >= n:
			continue
		var side_idx: int = nb_side.y * n + nb_side.x
		if _ramp_up_dir[side_idx] != RAMP_NONE:
			return false

	_ramp_up_dir[low_idx] = dir_up
	if not _ramp_is_valid_strict(low_x, low_z, dir_up):
		_ramp_up_dir[low_idx] = RAMP_NONE
		return false

	return true

func _try_place_any_from_candidates(cands: Array, n: int, levels: PackedInt32Array, want_levels: int, rng: RandomNumberGenerator) -> bool:
	if cands.is_empty():
		return false

	var order: Array[int] = []
	order.resize(cands.size())
	for i in range(cands.size()):
		order[i] = i
	for i in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp

	for k in order:
		var item = cands[k]
		var low_idx: int = int(item[0])
		var dir_up: int = int(item[1])
		if _try_place_ramp_candidate(low_idx, dir_up, n, levels, want_levels):
			return true

	return false

func _perp_dirs(dir: int) -> Array[int]:
	if dir == RAMP_EAST or dir == RAMP_WEST:
		return [RAMP_NORTH, RAMP_SOUTH]
	return [RAMP_EAST, RAMP_WEST]

func _ramp_is_valid_strict(x: int, z: int, _dir_up_unused: int) -> bool:
	var n: int = max(2, cells_per_side)
	var idx: int = z * n + x
	var dir_up: int = _ramp_up_dir[idx]
	if dir_up == RAMP_NONE:
		return true

	var low_h: float = _cell_h(x, z)
	var nb: Vector2i = _neighbor_of(x, z, dir_up)
	if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
		return false

	var high_h: float = _cell_h(nb.x, nb.y)
	var want: int = maxi(1, ramp_step_count)
	var rise_h: float = float(want) * height_step
	if absf((high_h - low_h) - rise_h) > 0.001:
		return false

	var top_a: Vector2 = _cell_edge_dir(x, z, dir_up)
	var top_b: Vector2 = _cell_edge_dir(nb.x, nb.y, _opposite_dir(dir_up))
	if not _edges_match(top_a, top_b):
		return false

	var high_idx: int = nb.y * n + nb.x
	if _ramp_up_dir[high_idx] != RAMP_NONE:
		if _ramp_up_dir[high_idx] != dir_up:
			return false
		var hi_down: Vector2i = _neighbor_of(nb.x, nb.y, _opposite_dir(dir_up))
		if hi_down.x != x or hi_down.y != z:
			return false

	var dir_down: int = _opposite_dir(dir_up)
	var dn: Vector2i = _neighbor_of(x, z, dir_down)
	if dn.x < 0 or dn.x >= n or dn.y < 0 or dn.y >= n:
		return false

	var dn_idx: int = dn.y * n + dn.x
	var bottom_here: Vector2 = _cell_edge_dir(x, z, dir_down)
	var bottom_there: Vector2 = _cell_edge_dir(dn.x, dn.y, dir_up)

	if _ramp_up_dir[dn_idx] != RAMP_NONE:
		if not _is_stacked_with_this(dn.x, dn.y, x, z, dir_up, want):
			return false
		if not _edges_match(bottom_here, bottom_there):
			return false
	else:
		if not _is_flat_edge_at(bottom_there, low_h):
			return false

	for sd in _perp_dirs(dir_up):
		var nb_side: Vector2i = _neighbor_of(x, z, sd)
		if nb_side.x < 0 or nb_side.x >= n or nb_side.y < 0 or nb_side.y >= n:
			continue
		var side_idx: int = nb_side.y * n + nb_side.x
		if _ramp_up_dir[side_idx] != RAMP_NONE:
			return false

	return true

func _prune_ramps_strict() -> void:
	var n: int = max(2, cells_per_side)
	var changed: bool = true
	var guard: int = 0
	while changed and guard < 8:
		guard += 1
		changed = false
		for z in range(n):
			for x in range(n):
				var idx: int = z * n + x
				var dir: int = _ramp_up_dir[idx]
				if dir == RAMP_NONE:
					continue
				if not _ramp_is_valid_strict(x, z, dir):
					_ramp_up_dir[idx] = RAMP_NONE
					changed = true

func _ensure_basin_escapes(n: int, want: int, levels: PackedInt32Array) -> bool:
	var comp_id: PackedInt32Array = PackedInt32Array()
	comp_id.resize(n * n)
	for i in range(n * n):
		comp_id[i] = -1

	var queue: Array[int] = []
	var next_comp: int = 0
	var raised_any: bool = false

	for z in range(n):
		for x in range(n):
			var start: int = z * n + x
			if comp_id[start] != -1:
				continue

			var level: int = levels[start]
			var cells: Array[int] = []
			queue.clear()
			queue.append(start)
			comp_id[start] = next_comp

			while queue.size() > 0:
				var i0: int = int(queue.pop_back())
				cells.append(i0)
				var cx: int = i0 % n
				var cz: int = int(float(i0) / float(n))
				for dir in [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]:
					var nb: Vector2i = _neighbor_of(cx, cz, dir)
					if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
						continue
					var ni: int = nb.y * n + nb.x
					if comp_id[ni] == -1 and levels[ni] == level:
						comp_id[ni] = next_comp
						queue.append(ni)

			var min_neighbor: int = 1 << 30
			var exit_keys: Array[int] = []
			var has_escape: bool = false

			for i1 in cells:
				if _ramp_up_dir[i1] == RAMP_NONE:
					continue
				var rx: int = i1 % n
				var rz: int = int(float(i1) / float(n))
				var rdir: int = _ramp_up_dir[i1]
				var rnb: Vector2i = _neighbor_of(rx, rz, rdir)
				if rnb.x < 0 or rnb.x >= n or rnb.y < 0 or rnb.y >= n:
					continue
				var rni: int = rnb.y * n + rnb.x
				if levels[rni] == level + want:
					has_escape = true
					break

			for i2 in cells:
				var cx2: int = i2 % n
				var cz2: int = int(float(i2) / float(n))
				for dir2 in [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]:
					var nb2: Vector2i = _neighbor_of(cx2, cz2, dir2)
					if nb2.x < 0 or nb2.x >= n or nb2.y < 0 or nb2.y >= n:
						continue
					var ni2: int = nb2.y * n + nb2.x
					if levels[ni2] == level:
						continue

					min_neighbor = mini(min_neighbor, levels[ni2])

					if levels[ni2] == level + want:
						exit_keys.append((int(i2) << 2) | int(dir2))

			if min_neighbor > level and not has_escape:
				exit_keys.sort()
				var placed: bool = false
				for key in exit_keys:
					var low_idx: int = key >> 2
					var dir_up: int = key & 3
					if _try_place_ramp_candidate(low_idx, dir_up, n, levels, want):
						placed = true
						break

				if not placed and auto_raise_unescapable_basins:
					for i3 in cells:
						levels[i3] = levels[i3] + 1
					raised_any = true

			next_comp += 1

	return raised_any

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
	_fill_pits()

	var guard: int = 0
	while true:
		_ramps_need_regen = false
		_generate_ramps()
		if not _ramps_need_regen:
			break
		guard += 1
		if guard >= ramp_regen_guard:
			push_warning("Ramp regen guard reached; terrain may still contain rare edge cases.")
			break

	_build_mesh_and_collision()
	print("Ramp slots:", _count_ramps())

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

func _fill_pits() -> void:
	var n: int = max(2, cells_per_side)
	if height_step <= 0.0:
		return

	var levels: PackedInt32Array = PackedInt32Array()
	levels.resize(n * n)
	for i in range(n * n):
		levels[i] = _h_to_level(_heights[i])

	for _p in range(pit_fill_passes):
		var changed: bool = false
		for z in range(n):
			for x in range(n):
				var idx: int = z * n + x
				var lvl: int = levels[idx]

				var min_nb: int = 1 << 30
				var has_nb: bool = false

				if x > 0:
					min_nb = mini(min_nb, levels[idx - 1])
					has_nb = true
				if x + 1 < n:
					min_nb = mini(min_nb, levels[idx + 1])
					has_nb = true
				if z > 0:
					min_nb = mini(min_nb, levels[idx - n])
					has_nb = true
				if z + 1 < n:
					min_nb = mini(min_nb, levels[idx + n])
					has_nb = true

				if not has_nb:
					continue

				if min_nb >= lvl + 1:
					levels[idx] = min_nb
					changed = true

		if not changed:
			break

	for i in range(n * n):
		_heights[i] = _level_to_h(levels[i])

# -----------------------------
# Ramp generation (procedural in terrain mesh)
# -----------------------------
func _generate_ramps() -> void:
	var n: int = max(2, cells_per_side)
	_ramp_up_dir = PackedInt32Array()
	_ramp_up_dir.resize(n * n)
	for i in range(n * n):
		_ramp_up_dir[i] = RAMP_NONE

	if not enable_ramps:
		return

	var want_levels: int = maxi(1, ramp_step_count)

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
			var start_idx: int = z * n + x
			if comp_id[start_idx] != -1:
				continue

			var target_level: int = levels[start_idx]
			comp_id[start_idx] = comp_count
			queue.clear()
			queue.append(start_idx)

			while queue.size() > 0:
				var cur: int = int(queue.pop_back())
				var cx: int = cur % n
				var cz: int = int(float(cur) / float(n))

				if cx > 0:
					var left: int = cur - 1
					if comp_id[left] == -1 and levels[left] == target_level:
						comp_id[left] = comp_count
						queue.append(left)
				if cx + 1 < n:
					var right: int = cur + 1
					if comp_id[right] == -1 and levels[right] == target_level:
						comp_id[right] = comp_count
						queue.append(right)
				if cz > 0:
					var up: int = cur - n
					if comp_id[up] == -1 and levels[up] == target_level:
						comp_id[up] = comp_count
						queue.append(up)
				if cz + 1 < n:
					var down: int = cur + n
					if comp_id[down] == -1 and levels[down] == target_level:
						comp_id[down] = comp_count
						queue.append(down)

			comp_count += 1

	var edge_candidates: Dictionary = {}
	var low_to_high: Array = []
	low_to_high.resize(comp_count)
	for i in range(comp_count):
		low_to_high[i] = []

	var dirs: Array = [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]
	for z in range(n):
		for x in range(n):
			var idx: int = z * n + x
			var cid: int = comp_id[idx]

			for d in dirs:
				var nb: Vector2i = _neighbor_of(x, z, d)
				if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
					continue

				var nb_idx: int = nb.y * n + nb.x
				var nb_cid: int = comp_id[nb_idx]
				if nb_cid == cid:
					continue

				var dh: int = levels[nb_idx] - levels[idx]
				if abs(dh) != want_levels:
					continue

				var low_cid: int
				var high_cid: int
				var low_idx: int
				var dir_up: int

				if dh == want_levels:
					low_cid = cid
					high_cid = nb_cid
					low_idx = idx
					dir_up = d
				else:
					low_cid = nb_cid
					high_cid = cid
					low_idx = nb_idx
					dir_up = _opposite_dir(d)

				var key: int = low_cid * comp_count + high_cid
				var list: Array = edge_candidates.get(key, [])
				list.append([low_idx, dir_up])
				edge_candidates[key] = list

				var neighs: Array = low_to_high[low_cid]
				if not neighs.has(high_cid):
					neighs.append(high_cid)
					low_to_high[low_cid] = neighs

	var cx0: int = n >> 1
	var cz0: int = n >> 1
	var best_idx: int = cz0 * n + cx0
	var best_lv: int = levels[best_idx]

	for dz in range(-2, 3):
		for dx in range(-2, 3):
			var xx: int = cx0 + dx
			var zz: int = cz0 + dz
			if xx < 0 or xx >= n or zz < 0 or zz >= n:
				continue
			var ii: int = zz * n + xx
			if levels[ii] < best_lv:
				best_lv = levels[ii]
				best_idx = ii

	var root_cid: int = comp_id[best_idx]

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(noise_seed) ^ 0x6d2b79f5

	var reachable: PackedByteArray = PackedByteArray()
	reachable.resize(comp_count)
	for i in range(comp_count):
		reachable[i] = 0
	reachable[root_cid] = 1

	var q: Array[int] = []
	q.append(root_cid)

	var budget: int = maxi(per_level_ramp_budget, comp_count * 4)

	while q.size() > 0 and budget > 0:
		var low_cid2: int = int(q.pop_front())
		var neighs2: Array = low_to_high[low_cid2]

		for high_cid2 in neighs2:
			if budget <= 0:
				break

			var hc: int = int(high_cid2)
			if reachable[hc] != 0:
				continue

			var key2: int = low_cid2 * comp_count + hc
			if not edge_candidates.has(key2):
				continue

			var cands2: Array = edge_candidates[key2]
			if _try_place_any_from_candidates(cands2, n, levels, want_levels, rng):
				reachable[hc] = 1
				q.append(hc)
				budget -= 1

	if extra_ramps_per_component > 0 and budget > 0:
		for low_cid3 in range(comp_count):
			if budget <= 0:
				break
			if reachable[low_cid3] == 0:
				continue

			var neighs3: Array = low_to_high[low_cid3]
			var extras_left: int = extra_ramps_per_component

			while extras_left > 0 and budget > 0:
				var placed_any: bool = false

				for high_cid3 in neighs3:
					if budget <= 0 or extras_left <= 0:
						break

					var hc3: int = int(high_cid3)
					if reachable[hc3] == 0:
						continue

					var key3: int = low_cid3 * comp_count + hc3
					if not edge_candidates.has(key3):
						continue

					if _try_place_any_from_candidates(edge_candidates[key3], n, levels, want_levels, rng):
						extras_left -= 1
						budget -= 1
						placed_any = true
						if extras_left <= 0:
							break

				if not placed_any:
					break

	_prune_ramps_strict()

	var raised: bool = _ensure_basin_escapes(n, want_levels, levels)
	if raised:
		_apply_levels_to_heights(n, levels)
		_limit_neighbor_cliffs()
		_fill_pits()
		_ramps_need_regen = true
		return

	_prune_ramps_strict()

	if auto_lower_unreachable_peaks:
		var lowered_any: bool = false

		var comp_sz: PackedInt32Array = PackedInt32Array()
		comp_sz.resize(comp_count)
		for i in range(comp_count):
			comp_sz[i] = 0

		var comp_max_nb: PackedInt32Array = PackedInt32Array()
		comp_max_nb.resize(comp_count)
		for i in range(comp_count):
			comp_max_nb[i] = -1 << 30

		for i in range(n * n):
			comp_sz[comp_id[i]] += 1

		for z2 in range(n):
			for x2 in range(n):
				var idx2: int = z2 * n + x2
				var cid2: int = comp_id[idx2]
				for d2 in [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]:
					var nbv: Vector2i = _neighbor_of(x2, z2, d2)
					if nbv.x < 0 or nbv.x >= n or nbv.y < 0 or nbv.y >= n:
						continue
					var ni2: int = nbv.y * n + nbv.x
					if comp_id[ni2] == cid2:
						continue
					comp_max_nb[cid2] = maxi(comp_max_nb[cid2], levels[ni2])

		var has_incoming: PackedByteArray = PackedByteArray()
		has_incoming.resize(comp_count)
		for i in range(comp_count):
			has_incoming[i] = 0

		for z3 in range(n):
			for x3 in range(n):
				var lowi: int = z3 * n + x3
				var dir3: int = _ramp_up_dir[lowi]
				if dir3 == RAMP_NONE:
					continue
				var nb3: Vector2i = _neighbor_of(x3, z3, dir3)
				if nb3.x < 0 or nb3.x >= n or nb3.y < 0 or nb3.y >= n:
					continue
				var highi: int = nb3.y * n + nb3.x
				has_incoming[comp_id[highi]] = 1

		for c in range(comp_count):
			var lv_c: int = -2147483648
			for i in range(n * n):
				if comp_id[i] == c:
					lv_c = levels[i]
					break

			if comp_max_nb[c] <= lv_c and has_incoming[c] == 0 and comp_sz[c] <= peak_max_cells:
				for i in range(n * n):
					if comp_id[i] == c:
						levels[i] -= 1
				lowered_any = true

		if lowered_any:
			_apply_levels_to_heights(n, levels)
			_limit_neighbor_cliffs()
			_fill_pits()
			_ramps_need_regen = true
			return

func _cell_corners(x: int, z: int) -> Vector4:
	var n: int = max(2, cells_per_side)
	var idx: int = z * n + x
	var low_h: float = _heights[idx]

	if not enable_ramps:
		return Vector4(low_h, low_h, low_h, low_h)

	var dir_up: int = _ramp_up_dir[idx]
	if dir_up == RAMP_NONE:
		return Vector4(low_h, low_h, low_h, low_h)

	var nb: Vector2i = _neighbor_of(x, z, dir_up)
	if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
		return Vector4(low_h, low_h, low_h, low_h)

	var high_h: float = _heights[nb.y * n + nb.x]
	if high_h <= low_h:
		return Vector4(low_h, low_h, low_h, low_h)

	match dir_up:
		RAMP_EAST:
			return Vector4(low_h, high_h, high_h, low_h)
		RAMP_WEST:
			return Vector4(high_h, low_h, low_h, high_h)
		RAMP_SOUTH:
			return Vector4(low_h, low_h, high_h, high_h)
		RAMP_NORTH:
			return Vector4(high_h, high_h, low_h, low_h)
		_:
			return Vector4(low_h, low_h, low_h, low_h)

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
	var ramps_openings: bool = enable_ramps
	var want_levels: int = maxi(1, ramp_step_count)
	var levels: PackedInt32Array = PackedInt32Array()
	levels.resize(n * n)
	for i in range(n * n):
		levels[i] = _h_to_level(_heights[i])

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

			var idx: int = z * n + x
			var top_col: Color = terrain_color
			if enable_ramps and _ramp_up_dir[idx] != RAMP_NONE:
				top_col = ramp_color

			_add_quad(
				st, a, b, c, d,
				Vector2(float(x), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z + 1)) * uv_scale_top,
				Vector2(float(x), float(z + 1)) * uv_scale_top,
				top_col
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
				var idx_a: int = z * n + x
				var idx_b: int = z * n + (x + 1)
				if (not ramps_openings) or (not _is_ramp_bridge(idx_a, idx_b, RAMP_EAST, want_levels, levels)):
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
				var idx_c: int = z * n + x
				var idx_d: int = (z + 1) * n + x
				if (not ramps_openings) or (not _is_ramp_bridge(idx_c, idx_d, RAMP_SOUTH, want_levels, levels)):
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
	var eps: float = 0.0005
	var d0: float = absf(high0 - low0)
	var d1: float = absf(high1 - low1)
	if d0 <= eps and d1 <= eps:
		return

	var a := Vector3(x_edge, high0, z0)
	var b := Vector3(x_edge, high1, z1)
	var c := Vector3(x_edge, low1, z1)
	var d := Vector3(x_edge, low0, z0)

	if d0 > eps and d1 > eps:
		_add_quad(st, a, b, c, d,
			Vector2(0, high0 * uv_scale), Vector2(1, high1 * uv_scale),
			Vector2(1, low1 * uv_scale), Vector2(0, low0 * uv_scale),
			terrain_color
		)
		return

	st.set_color(terrain_color)
	st.set_uv(Vector2(0, high0 * uv_scale)); st.add_vertex(a)
	st.set_uv(Vector2(1, high1 * uv_scale)); st.add_vertex(b)
	st.set_uv(Vector2(1, low1 * uv_scale)); st.add_vertex(c)

	st.set_color(terrain_color)
	st.set_uv(Vector2(0, high0 * uv_scale)); st.add_vertex(a)
	st.set_uv(Vector2(1, low1 * uv_scale)); st.add_vertex(c)
	st.set_uv(Vector2(0, low0 * uv_scale)); st.add_vertex(d)

func _add_wall_z_between(st: SurfaceTool, z_edge: float, x0: float, x1: float,
	low0: float, low1: float, high0: float, high1: float, uv_scale: float) -> void:
	var eps: float = 0.0005
	var d0: float = absf(high0 - low0)
	var d1: float = absf(high1 - low1)
	if d0 <= eps and d1 <= eps:
		return

	var a := Vector3(x0, high0, z_edge)
	var b := Vector3(x1, high1, z_edge)
	var c := Vector3(x1, low1, z_edge)
	var d := Vector3(x0, low0, z_edge)

	if d0 > eps and d1 > eps:
		_add_quad(st, a, b, c, d,
			Vector2(0, high0 * uv_scale), Vector2(1, high1 * uv_scale),
			Vector2(1, low1 * uv_scale), Vector2(0, low0 * uv_scale),
			terrain_color
		)
		return

	st.set_color(terrain_color)
	st.set_uv(Vector2(0, high0 * uv_scale)); st.add_vertex(a)
	st.set_uv(Vector2(1, high1 * uv_scale)); st.add_vertex(b)
	st.set_uv(Vector2(1, low1 * uv_scale)); st.add_vertex(c)

	st.set_color(terrain_color)
	st.set_uv(Vector2(0, high0 * uv_scale)); st.add_vertex(a)
	st.set_uv(Vector2(1, low1 * uv_scale)); st.add_vertex(c)
	st.set_uv(Vector2(0, low0 * uv_scale)); st.add_vertex(d)

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
