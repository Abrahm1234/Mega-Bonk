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
@export_range(0, 4, 1) var walk_up_steps_without_ramp: int = 0
@export_range(0, 4, 1) var walk_down_steps_without_ramp: int = 4
@export_range(0.0, 1.0, 0.01) var ramp_fill_ratio: float = 0.40
@export_range(0, 256, 1) var connectivity_rescue_budget: int = 64
@export_range(0, 4, 1) var pit_fill_passes: int = 2
@export_range(0, 512, 1) var per_level_ramp_budget: int = 96

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
var _ramp_protect: PackedByteArray

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

func _highside_supported(n: int, x: int, z: int, dir_to_low: int, high_h: float, eps: float) -> bool:
	for d in [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]:
		if d == dir_to_low:
			continue
		var nb: Vector2i = _neighbor_of(x, z, d)
		if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
			continue
		if absf(_cell_h(nb.x, nb.y) - high_h) <= eps:
			return true
	return false

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

func _can_move_dir(n: int, ax: int, az: int, bx: int, bz: int, levels: PackedInt32Array) -> bool:
	var aidx: int = az * n + ax
	var bidx: int = bz * n + bx
	var da: int = levels[bidx] - levels[aidx]
	if da <= walk_up_steps_without_ramp and da >= -walk_down_steps_without_ramp:
		return true
	return _has_ramp_between(ax, az, bx, bz)

func _compute_comp_reachable(n: int, comp_count: int, comp_id: PackedInt32Array, levels: PackedInt32Array,
	start_comp: int, reverse: bool) -> PackedByteArray:
	var adj: Array = []
	adj.resize(comp_count)
	for i in range(comp_count):
		adj[i] = PackedInt32Array()

	for z in range(n):
		for x in range(n):
			var idx: int = z * n + x
			var a: int = comp_id[idx]

			if x + 1 < n:
				var b: int = comp_id[idx + 1]
				if a != b:
					var allow_ab: bool
					if reverse:
						allow_ab = _can_move_dir(n, x + 1, z, x, z, levels)
						if allow_ab:
							var arr_b: PackedInt32Array = adj[b]
							arr_b.append(a)
							adj[b] = arr_b
					else:
						allow_ab = _can_move_dir(n, x, z, x + 1, z, levels)
						if allow_ab:
							var arr_a: PackedInt32Array = adj[a]
							arr_a.append(b)
							adj[a] = arr_a

			if z + 1 < n:
				var cidx: int = idx + n
				var c: int = comp_id[cidx]
				if a != c:
					var allow_ac: bool
					if reverse:
						allow_ac = _can_move_dir(n, x, z + 1, x, z, levels)
						if allow_ac:
							var arr_c: PackedInt32Array = adj[c]
							arr_c.append(a)
							adj[c] = arr_c
					else:
						allow_ac = _can_move_dir(n, x, z, x, z + 1, levels)
						if allow_ac:
							var arr_a2: PackedInt32Array = adj[a]
							arr_a2.append(c)
							adj[a] = arr_a2

	var vis: PackedByteArray = PackedByteArray()
	vis.resize(comp_count)
	for i in range(comp_count):
		vis[i] = 0

	var q: Array[int] = []
	vis[start_comp] = 1
	q.append(start_comp)

	while q.size() > 0:
		var cur: int = int(q.pop_back())
		var neigh: PackedInt32Array = adj[cur]
		for nb in neigh:
			var v: int = int(nb)
			if vis[v] == 0:
				vis[v] = 1
				q.append(v)

	return vis

func _try_place_ramp_down(n: int, hx: int, hz: int, dir_to_low: int, low_h: float, protect: bool) -> bool:
	var hidx: int = hz * n + hx
	if _ramp_dir[hidx] != RAMP_NONE:
		return false
	_ramp_dir[hidx] = dir_to_low
	_ramp_low[hidx] = low_h
	_ramp_protect[hidx] = 1 if protect else 0
	return true

func _ensure_each_component_has_incident_ramp(n: int, comp_count: int, comp_id: PackedInt32Array,
	levels: PackedInt32Array, want_delta: float, delta_eps: float, rng: RandomNumberGenerator) -> void:
	var has_down: PackedByteArray = PackedByteArray()
	has_down.resize(comp_count)
	var has_in: PackedByteArray = PackedByteArray()
	has_in.resize(comp_count)

	for i in range(comp_count):
		has_down[i] = 0
		has_in[i] = 0

	for z in range(n):
		for x in range(n):
			var idx: int = z * n + x
			var dir: int = _ramp_dir[idx]
			if dir == RAMP_NONE:
				continue
			var nb: Vector2i = _neighbor_of(x, z, dir)
			if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
				continue
			var nidx: int = nb.y * n + nb.x
			if levels[idx] > levels[nidx]:
				var hi_c: int = comp_id[idx]
				var lo_c: int = comp_id[nidx]
				has_down[hi_c] = 1
				has_in[lo_c] = 1

	var min_lvl: int = 1 << 30
	var max_lvl: int = -(1 << 30)
	for i in range(n * n):
		min_lvl = mini(min_lvl, levels[i])
		max_lvl = maxi(max_lvl, levels[i])

	var budget: int = maxi(per_level_ramp_budget, comp_count * 2)

	for target_c in range(comp_count):
		if budget <= 0:
			break

		var target_level: int = 0
		var found_level: bool = false
		for i in range(n * n):
			if comp_id[i] == target_c:
				target_level = levels[i]
				found_level = true
				break
		if not found_level:
			continue
		if target_level <= min_lvl:
			continue
		if has_down[target_c] != 0:
			continue

		var pick: int = 0
		var pick_dir: int = RAMP_NONE
		var pick_low_h: float = 0.0
		var seen: int = 0

		for z in range(n):
			for x in range(n):
				var idx: int = z * n + x
				if comp_id[idx] != target_c:
					continue

				var h0: float = _heights[idx]
				for dir in [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]:
					var nb: Vector2i = _neighbor_of(x, z, dir)
					if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
						continue
					var nidx: int = nb.y * n + nb.x

					var dh: float = h0 - _heights[nidx]
					if absf(dh - want_delta) > delta_eps:
						continue
					if not _highside_supported(n, x, z, dir, h0, delta_eps):
						continue

					seen += 1
					if rng.randi_range(1, seen) == 1:
						pick = idx
						pick_dir = dir
						pick_low_h = _heights[nidx]

		if pick_dir != RAMP_NONE:
			var px: int = pick % n
			var pz: int = int(float(pick) / float(n))
			if _try_place_ramp_down(n, px, pz, pick_dir, pick_low_h, true):
				has_down[target_c] = 1
				var low_nb: Vector2i = _neighbor_of(px, pz, pick_dir)
				var low_cid: int = comp_id[low_nb.y * n + low_nb.x]
				has_in[low_cid] = 1
				budget -= 1

	if walk_up_steps_without_ramp == 0:
		for low_c in range(comp_count):
			if budget <= 0:
				break

			var low_level: int = 0
			var found_low: bool = false
			for i in range(n * n):
				if comp_id[i] == low_c:
					low_level = levels[i]
					found_low = true
					break
			if not found_low:
				continue
			if low_level >= max_lvl:
				continue
			if has_in[low_c] != 0:
				continue

			var pick_hi: int = -1
			var pick_hi_dir: int = RAMP_NONE
			var pick_low_h2: float = 0.0
			var seen2: int = 0

			for z in range(n):
				for x in range(n):
					var low_idx: int = z * n + x
					if comp_id[low_idx] != low_c:
						continue

					for dir_to_hi in [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]:
						var hi: Vector2i = _neighbor_of(x, z, dir_to_hi)
						if hi.x < 0 or hi.x >= n or hi.y < 0 or hi.y >= n:
							continue
						var hi_idx: int = hi.y * n + hi.x

						var dh2: float = _heights[hi_idx] - _heights[low_idx]
						if absf(dh2 - want_delta) > delta_eps:
							continue

						var dir_hi_to_low: int = _opposite_dir(dir_to_hi)
						var hi_h: float = _heights[hi_idx]

						if not _highside_supported(n, hi.x, hi.y, dir_hi_to_low, hi_h, delta_eps):
							continue
						if _ramp_dir[hi_idx] != RAMP_NONE:
							continue

						seen2 += 1
						if rng.randi_range(1, seen2) == 1:
							pick_hi = hi_idx
							pick_hi_dir = dir_hi_to_low
							pick_low_h2 = _heights[low_idx]

			if pick_hi_dir != RAMP_NONE and pick_hi >= 0:
				var hx: int = pick_hi % n
				var hz: int = int(float(pick_hi) / float(n))
				if _try_place_ramp_down(n, hx, hz, pick_hi_dir, pick_low_h2, true):
					has_in[low_c] = 1
					var hi_cid: int = comp_id[pick_hi]
					has_down[hi_cid] = 1
					budget -= 1

func _validate_ramps_move(n: int, want_delta: float, delta_eps: float) -> void:
	for z in range(n):
		for x in range(n):
			var idx: int = z * n + x
			var dir: int = _ramp_dir[idx]
			if dir == RAMP_NONE:
				continue

			var prot: int = _ramp_protect[idx]

			var nb: Vector2i = _neighbor_of(x, z, dir)
			if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
				_ramp_dir[idx] = RAMP_NONE
				_ramp_protect[idx] = 0
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
					_ramp_protect[nidx] = prot
				_ramp_dir[idx] = RAMP_NONE
				_ramp_protect[idx] = 0
				continue

			_ramp_dir[idx] = RAMP_NONE
			_ramp_protect[idx] = 0

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
			if down_nb.x < 0 or down_nb.x >= n or down_nb.y < 0 or down_nb.y >= n:
				_ramp_dir[idx] = RAMP_NONE
				_ramp_protect[idx] = 0
				continue

			var c_here: Vector4 = _cell_corners(x, z)
			var c_down: Vector4 = _cell_corners(down_nb.x, down_nb.y)

			var d_edge: int = _down_edge(dir)
			var d_opp: int = _up_edge(dir)
			if not _edge_matches(c_here, c_down, d_edge, d_opp, eps):
				_ramp_dir[idx] = RAMP_NONE
				_ramp_protect[idx] = 0
				continue

			if _ramp_protect[idx] != 0:
				continue

			var high_h: float = _cell_h(x, z)
			if not _highside_supported(n, x, z, dir, high_h, eps):
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
	_fill_pits()
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
# Ramp generation (one-cell wedges)
# -----------------------------
func _generate_ramps() -> void:
	var n: int = max(2, cells_per_side)
	_ramp_dir = PackedInt32Array()
	_ramp_low = PackedFloat32Array()
	_ramp_dir.resize(n * n)
	_ramp_low.resize(n * n)
	_ramp_protect = PackedByteArray()
	_ramp_protect.resize(n * n)

	for i in range(n * n):
		_ramp_dir[i] = RAMP_NONE
		_ramp_low[i] = 0.0
		_ramp_protect[i] = 0

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
	var candidates_mid: Array[RampCandidate] = []
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
					# loosest pool: only “right height delta”
					candidates_relaxed.append(RampCandidate.new(x, z, dir, h1))

					# mid pool: additionally requires landing + high-side support
					if _landing_ok(n, nb.x, nb.y, dir) and _highside_supported(n, x, z, dir, h0, delta_eps):
						candidates_mid.append(RampCandidate.new(x, z, dir, h1))

						# strict pool: additionally requires both plateaus meet min size
						var idx0: int = z * n + x
						var idx1: int = nb.y * n + nb.x
						var high_comp: int = comp_id[idx0]
						var low_comp: int = comp_id[idx1]
						if comp_size[high_comp] < min_plateau_cells:
							continue
						if comp_size[low_comp] < min_plateau_cells:
							continue

						candidates.append(RampCandidate.new(x, z, dir, h1))

	for i in range(candidates.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: RampCandidate = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = temp

	for i in range(candidates_mid.size() - 1, 0, -1):
		var j_mid: int = rng.randi_range(0, i)
		var temp_mid: RampCandidate = candidates_mid[i]
		candidates_mid[i] = candidates_mid[j_mid]
		candidates_mid[j_mid] = temp_mid

	for i in range(candidates_relaxed.size() - 1, 0, -1):
		var j_relaxed: int = rng.randi_range(0, i)
		var temp_relaxed: RampCandidate = candidates_relaxed[i]
		candidates_relaxed[i] = candidates_relaxed[j_relaxed]
		candidates_relaxed[j_relaxed] = temp_relaxed

	var target_total: int = maxi(ramp_count, int(roundf(float(candidates_mid.size()) * ramp_fill_ratio)))

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
		_ramp_protect[idx] = 1
		placed += 1
		union.call(high_comp, low_comp)

	var extra_budget: int = int(max(0, target_total - placed))
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

	for i in range(candidates_mid.size()):
		if extra_budget <= 0:
			break

		var c_mid: RampCandidate = candidates_mid[i]
		var x_mid: int = c_mid.x
		var z_mid: int = c_mid.z
		var idx_mid: int = z_mid * n + x_mid
		if _ramp_dir[idx_mid] != RAMP_NONE:
			continue

		if rng.randf() < extra_ramp_skip_chance:
			continue

		_ramp_dir[idx_mid] = c_mid.dir
		_ramp_low[idx_mid] = c_mid.low
		placed += 1
		extra_budget -= 1

	_ensure_each_component_has_incident_ramp(n, comp_count, comp_id, levels, want_delta, delta_eps, rng)

	var start_x: int = n / 2
	var start_z: int = n / 2
	var start_comp: int = comp_id[start_z * n + start_x]
	var rescue_budget: int = connectivity_rescue_budget

	while rescue_budget > 0:
		var fwd: PackedByteArray = _compute_comp_reachable(n, comp_count, comp_id, levels, start_comp, false)
		var rev: PackedByteArray = _compute_comp_reachable(n, comp_count, comp_id, levels, start_comp, true)
		var all_ok: bool = true
		for cid in range(comp_count):
			if fwd[cid] == 0 or rev[cid] == 0:
				all_ok = false
				break
		if all_ok:
			break

		var placed_one: bool = false
		for c_mid in candidates_mid:
			var idx_hi: int = c_mid.z * n + c_mid.x
			if _ramp_dir[idx_hi] != RAMP_NONE:
				continue
			var nb: Vector2i = _neighbor_of(c_mid.x, c_mid.z, c_mid.dir)
			if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
				continue
			var idx_lo: int = nb.y * n + nb.x
			var hi_comp: int = comp_id[idx_hi]
			var lo_comp: int = comp_id[idx_lo]
			if fwd[hi_comp] == fwd[lo_comp] and rev[hi_comp] == rev[lo_comp]:
				continue

			_ramp_dir[idx_hi] = c_mid.dir
			_ramp_low[idx_hi] = c_mid.low
			_ramp_protect[idx_hi] = 1
			rescue_budget -= 1
			placed_one = true
			break

		if not placed_one:
			break

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
