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
# Ramps (separate wedge instances)
# -----------------------------
@export var enable_ramps: bool = true
@export_range(1, 3, 1) var ramp_step_count: int = 1
@export var ramp_scene: PackedScene
@export var ramp_model_cell_size_m: float = 1.0
@export var ramp_model_rise_m: float = 1.0
@export var ramp_y_epsilon: float = 0.02
@export_range(0, 8, 1) var extra_ramps_per_component: int = 0
@export var ramp_model_up_is_south: bool = true
@export_range(0, 4, 1) var walk_up_steps_without_ramp: int = 0
@export_range(0, 4, 1) var walk_down_steps_without_ramp: int = 4
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
var _ramp_up_dir: PackedInt32Array
var _ramp_nodes: Array = []

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

func _clear_ramps() -> void:
	for node in _ramp_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_ramp_nodes.clear()

func _dir_to_yaw(dir_up: int) -> float:
	if ramp_model_up_is_south:
		match dir_up:
			RAMP_SOUTH:
				return 0.0
			RAMP_EAST:
				return deg_to_rad(-90.0)
			RAMP_WEST:
				return deg_to_rad(90.0)
			RAMP_NORTH:
				return deg_to_rad(180.0)
			_:
				return 0.0

	match dir_up:
		RAMP_EAST:
			return 0.0
		RAMP_SOUTH:
			return deg_to_rad(90.0)
		RAMP_NORTH:
			return deg_to_rad(-90.0)
		RAMP_WEST:
			return deg_to_rad(180.0)
		_:
			return 0.0

func _has_ramp_bridge_x(n: int, x: int, z: int) -> bool:
	var a: int = z * n + x
	var b: int = z * n + (x + 1)
	return _ramp_up_dir[a] == RAMP_EAST or _ramp_up_dir[b] == RAMP_WEST

func _has_ramp_bridge_z(n: int, x: int, z: int) -> bool:
	var a: int = z * n + x
	var b: int = (z + 1) * n + x
	return _ramp_up_dir[a] == RAMP_SOUTH or _ramp_up_dir[b] == RAMP_NORTH

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
	_spawn_ramps()

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
# Ramp generation (separate wedges on low cells)
# -----------------------------
func _generate_ramps() -> void:
	var n: int = max(2, cells_per_side)
	_ramp_up_dir = PackedInt32Array()
	_ramp_up_dir.resize(n * n)
	for i in range(n * n):
		_ramp_up_dir[i] = RAMP_NONE

	_clear_ramps()

	if not enable_ramps:
		return

	var want_levels: int = maxi(1, ramp_step_count)

	var levels: PackedInt32Array = PackedInt32Array()
	levels.resize(n * n)
	var min_lvl: int = 1 << 30
	var max_lvl: int = -(1 << 30)
	for i in range(n * n):
		var lv: int = _h_to_level(_heights[i])
		levels[i] = lv
		min_lvl = mini(min_lvl, lv)
		max_lvl = maxi(max_lvl, lv)

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

	var comp_cells: Array = []
	var comp_level: Array = []
	comp_cells.resize(comp_count)
	comp_level.resize(comp_count)
	for i in range(comp_count):
		comp_cells[i] = PackedInt32Array()
		comp_level[i] = 0

	for i in range(n * n):
		var cid: int = comp_id[i]
		var arr: PackedInt32Array = comp_cells[cid]
		arr.append(i)
		comp_cells[cid] = arr
		comp_level[cid] = levels[i]

	var has_down: PackedByteArray = PackedByteArray()
	has_down.resize(comp_count)
	var has_in: PackedByteArray = PackedByteArray()
	has_in.resize(comp_count)
	for i in range(comp_count):
		has_down[i] = 0
		has_in[i] = 0

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(noise_seed) ^ 0x51f2a9d3

	var try_place_low := func(lx: int, lz: int, dir_up: int) -> bool:
		var low_idx: int = lz * n + lx
		if _ramp_up_dir[low_idx] != RAMP_NONE:
			return false
		var hi: Vector2i = _neighbor_of(lx, lz, dir_up)
		if hi.x < 0 or hi.x >= n or hi.y < 0 or hi.y >= n:
			return false
		var hi_idx: int = hi.y * n + hi.x
		if (levels[hi_idx] - levels[low_idx]) != want_levels:
			return false
		if not _low_exit_ok(n, lx, lz, dir_up):
			return false

		_ramp_up_dir[low_idx] = dir_up
		return true

	var budget: int = maxi(per_level_ramp_budget, comp_count * 4)

	for L in range(max_lvl, min_lvl + want_levels - 1, -1):
		for cid in range(comp_count):
			if budget <= 0:
				break
			if int(comp_level[cid]) != L:
				continue
			if has_down[cid] != 0:
				continue

			var cells: PackedInt32Array = comp_cells[cid]
			var picked_hidx: int = -1
			var picked_dir: int = RAMP_NONE
			var seen: int = 0

			for cell_idx in cells:
				var hi_idx: int = int(cell_idx)
				var hx: int = hi_idx % n
				var hz: int = int(float(hi_idx) / float(n))

				for dir_to_low in [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]:
					var low: Vector2i = _neighbor_of(hx, hz, dir_to_low)
					if low.x < 0 or low.x >= n or low.y < 0 or low.y >= n:
						continue

					var low_idx: int = low.y * n + low.x
					if (levels[hi_idx] - levels[low_idx]) != want_levels:
						continue

					var dir_up: int = _opposite_dir(dir_to_low)
					if _ramp_up_dir[low_idx] != RAMP_NONE:
						continue
					if not _low_exit_ok(n, low.x, low.y, dir_up):
						continue

					seen += 1
					if rng.randi_range(1, seen) == 1:
						picked_hidx = low_idx
						picked_dir = dir_up

			if picked_hidx != -1 and picked_dir != RAMP_NONE:
				var lx: int = picked_hidx % n
				var lz: int = int(float(picked_hidx) / float(n))
				if try_place_low.call(lx, lz, picked_dir):
					has_down[cid] = 1
					var low_cid: int = comp_id[picked_hidx]
					has_in[low_cid] = 1
					budget -= 1

	if extra_ramps_per_component > 0 and budget > 0:
		for L in range(max_lvl, min_lvl + want_levels - 1, -1):
			for cid in range(comp_count):
				if budget <= 0:
					break
				if int(comp_level[cid]) != L:
					continue

				var extras_left: int = extra_ramps_per_component
				while extras_left > 0 and budget > 0:
					var picked_low_idx: int = -1
					var picked_dir_up: int = RAMP_NONE
					var seen2: int = 0

					var cells2: PackedInt32Array = comp_cells[cid]
					for cell_idx2 in cells2:
						var hi_idx2: int = int(cell_idx2)
						var hx2: int = hi_idx2 % n
						var hz2: int = int(float(hi_idx2) / float(n))

						for dir_to_low2 in [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]:
							var low2: Vector2i = _neighbor_of(hx2, hz2, dir_to_low2)
							if low2.x < 0 or low2.x >= n or low2.y < 0 or low2.y >= n:
								continue

							var low_idx2: int = low2.y * n + low2.x
							if (levels[hi_idx2] - levels[low_idx2]) != want_levels:
								continue

							if _ramp_up_dir[low_idx2] != RAMP_NONE:
								continue

							var dir_up2: int = _opposite_dir(dir_to_low2)
							if not _low_exit_ok(n, low2.x, low2.y, dir_up2):
								continue

							seen2 += 1
							if rng.randi_range(1, seen2) == 1:
								picked_low_idx = low_idx2
								picked_dir_up = dir_up2

					if picked_low_idx == -1:
						break

					var lx2: int = picked_low_idx % n
					var lz2: int = int(float(picked_low_idx) / float(n))
					if try_place_low.call(lx2, lz2, picked_dir_up):
						var low_cid2: int = comp_id[picked_low_idx]
						has_in[low_cid2] = 1
						extras_left -= 1
						budget -= 1
					else:
						break

func _cell_corners(x: int, z: int) -> Vector4:
	var h := _cell_h(x, z)
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

			_add_quad(
				st, a, b, c, d,
				Vector2(float(x), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z + 1)) * uv_scale_top,
				Vector2(float(x), float(z + 1)) * uv_scale_top,
				terrain_color
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
				if not _has_ramp_bridge_x(n, x, z):
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
				if not _has_ramp_bridge_z(n, x, z):
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

func _spawn_ramps() -> void:
	if ramp_scene == null:
		return

	var n: int = max(2, cells_per_side)
	var want_levels: int = maxi(1, ramp_step_count)

	for z in range(n):
		for x in range(n):
			var low_idx: int = z * n + x
			var dir_up: int = _ramp_up_dir[low_idx]
			if dir_up == RAMP_NONE:
				continue

			var hi: Vector2i = _neighbor_of(x, z, dir_up)
			var hi_idx: int = hi.y * n + hi.x

			var low_h: float = _heights[low_idx]
			var high_h: float = _heights[hi_idx]
			var rise: float = high_h - low_h
			if rise <= 0.0:
				continue

			var inst: Node3D = ramp_scene.instantiate()
			add_child(inst)
			_ramp_nodes.append(inst)

			var px: float = _ox + (float(x) + 0.5) * _cell_size
			var pz: float = _oz + (float(z) + 0.5) * _cell_size
			inst.global_position = Vector3(px, low_h + ramp_y_epsilon, pz)
			inst.rotation.y = _dir_to_yaw(dir_up)

			var sx: float = _cell_size / maxf(0.0001, ramp_model_cell_size_m)
			var sz: float = _cell_size / maxf(0.0001, ramp_model_cell_size_m)

			var model_rise_total: float = maxf(0.0001, ramp_model_rise_m * float(want_levels))
			var sy: float = rise / model_rise_total

			inst.scale = Vector3(sx, sy, sz)

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
