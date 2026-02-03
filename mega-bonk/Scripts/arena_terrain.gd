extends Node3D
class_name ArenaBlockyTerrain

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
@export var randomize_seed_on_start: bool = true
@export var randomize_seed_on_regen_key: bool = false
@export var print_seed: bool = true

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
@export var auto_fix_global_access: bool = true
@export_range(1, 64, 1) var global_fix_passes: int = 24

# -----------------------------
# Tunnels (separate mesh under the terrain shell)
# -----------------------------
@export var enable_tunnels: bool = true
@export_range(0, 6, 1) var tunnel_count: int = 2
@export_range(1, 3, 1) var tunnel_radius_cells: int = 1
@export_range(6, 128, 1) var tunnel_min_len_cells: int = 10
@export var tunnel_floor_y: float = -22.0
@export var tunnel_height: float = 8.0
@export_range(1, 8, 1) var tunnel_height_steps: int = 2
@export var tunnel_roof_clearance: float = 0.75
@export var tunnel_ramp_drop: float = 8.0
@export_range(4, 64, 1) var tunnel_ramp_max_steps: int = 16
@export var tunnel_turn_penalty: float = 3.0
@export_enum("Shaft", "Ramp") var tunnel_entrance_mode: int = 0
@export var tunnel_floor_clearance_from_box: float = 2.0
@export var tunnel_ceiling_clearance: float = 1.0
@export var tunnel_edge_clearance: float = 0.5
@export_range(0, 8, 1) var tunnel_extra_outpoints: int = 2
@export var tunnel_color: Color = Color(0.16, 0.18, 0.20, 1.0)
@export var tunnel_carve_surface_holes: bool = true
@export var tunnel_occluder_enabled: bool = true
@export var tunnel_occluder_y: float = -14.0
@export var tunnel_occluder_color: Color = Color(0.08, 0.08, 0.08, 1.0)

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
@export var use_rock_shader: bool = true
@export_range(1, 64, 1) var top_subdiv: int = 4
@export_range(1, 128, 1) var wall_subdiv: int = 8
@export var noise_top_tex: Texture2D
@export var noise_wall_tex: Texture2D
@export var noise_ramp_tex: Texture2D
@export var albedo_top_tex: Texture2D
@export var albedo_wall_tex: Texture2D
@export var albedo_ramp_tex: Texture2D
@export var normal_top_tex: Texture2D
@export var normal_wall_tex: Texture2D
@export var normal_ramp_tex: Texture2D
@export_range(0.0, 1.0, 0.01) var normal_strength: float = 0.85
@export_range(0.0, 2.0, 0.01) var disp_strength_top: float = 0.4
@export_range(0.0, 2.0, 0.01) var disp_strength_wall: float = 0.2
@export_range(0.0, 2.0, 0.01) var disp_strength_ramp: float = 0.3
@export var disp_scale_top: float = 0.06
@export var disp_scale_wall: float = 0.08
@export var disp_scale_ramp: float = 0.06
@export var tiles_per_cell: float = 1.0
@export_range(0.0, 1.0, 0.01) var tex_strength: float = 1.0
@export_range(0.0, 0.5, 0.01) var seam_lock_width: float = 0.18
@export_range(0.0, 0.5, 0.01) var seam_lock_soft: float = 0.06
@export var debug_vertex_colors: bool = false
@export var sun_height: float = 200.0
@export var enable_wall_decor: bool = true
@export var wall_decor_meshes: Array[Mesh] = []
@export var wall_decor_offset: float = 0.03
@export var wall_decor_seed: int = 1337
@export var wall_decor_min_height: float = 0.25
@export var wall_decor_skip_trapezoids: bool = false
@export var wall_decor_fit_to_face: bool = true
@export var wall_decor_max_scale: float = 3.0
@export var wall_decor_max_size: Vector2 = Vector2(0.0, 0.0)
@export_range(0.01, 2.0, 0.01) var wall_decor_depth_scale: float = 0.20
@export var wall_decor_flip_outward: bool = true
@export var wall_decor_min_world_y: float = -INF

@onready var mesh_instance: MeshInstance3D = get_node_or_null("TerrainBody/TerrainMesh")
@onready var collision_shape: CollisionShape3D = get_node_or_null("TerrainBody/TerrainCollision")

var _cell_size: float
var _ox: float
var _oz: float
var _heights: PackedFloat32Array  # one height per cell (cells_per_side * cells_per_side)
var _ramp_up_dir: PackedInt32Array
var _ramps_need_regen: bool = false
var _tunnel_mask: PackedByteArray
var _tunnel_hole_mask: PackedByteArray
var _tunnel_entrance_dir: PackedInt32Array
var _tunnel_floor_min_y: PackedFloat32Array
var _tunnel_floor_max_y: PackedFloat32Array
var _tunnel_ramp_dir: PackedByteArray
var _tunnel_mesh_instance: MeshInstance3D
var _tunnel_collision_shape: CollisionShape3D
var _tunnel_floor_resolved: float = 0.0
var _tunnel_ceil_resolved: float = 0.0
var _tunnel_base_floor_y: float = 0.0
var _tunnel_base_ceil_y: float = 0.0

const RAMP_NONE := -1
const RAMP_EAST := 0
const RAMP_WEST := 1
const RAMP_SOUTH := 2
const RAMP_NORTH := 3
const TUNNEL_DIR_NONE := 255
const SURF_TOP := 0.0
const SURF_WALL := 0.55
const SURF_RAMP := 0.8
const SURF_BOX := 1.0

class WallFace:
	var a: Vector3
	var b: Vector3
	var c: Vector3
	var d: Vector3
	var center: Vector3
	var normal: Vector3
	var width: float
	var height: float
	var is_trapezoid: bool
	var key: int

	func _init(
		a0: Vector3, b0: Vector3, c0: Vector3, d0: Vector3,
		center0: Vector3, n0: Vector3, w: float, h: float, trapezoid: bool, k: int
	) -> void:
		self.a = a0
		self.b = b0
		self.c = c0
		self.d = d0
		self.center = center0
		self.normal = n0
		self.width = w
		self.height = h
		self.is_trapezoid = trapezoid
		self.key = k

var _wall_faces: Array[WallFace] = []
var _wall_decor_root: Node3D = null

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

func _ramp_uv(s: float, t: float, ramp_dir: int) -> Vector2:
	match ramp_dir:
		RAMP_EAST:
			return Vector2(t, s)
		RAMP_WEST:
			return Vector2(t, 1.0 - s)
		RAMP_SOUTH:
			return Vector2(s, t)
		RAMP_NORTH:
			return Vector2(s, 1.0 - t)
		_:
			return Vector2(s, t)

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

const FIX_NONE := 0
const FIX_PLACED := 1
const FIX_LEVELS := 2

func _pick_root_idx_from_levels(n: int, levels: PackedInt32Array) -> int:
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

	return best_idx

func _can_move_edge(a_idx: int, b_idx: int, dir_a_to_b: int, want: int, levels: PackedInt32Array) -> bool:
	var da: int = levels[b_idx] - levels[a_idx]
	if da == 0:
		return true

	if abs(da) == want and _is_ramp_bridge(a_idx, b_idx, dir_a_to_b, want, levels):
		return true

	if da > 0:
		return da <= maxi(0, walk_up_steps_without_ramp)
	return (-da) <= maxi(0, walk_down_steps_without_ramp)

func _reach_from_root(n: int, root_idx: int, want: int, levels: PackedInt32Array) -> PackedByteArray:
	var seen: PackedByteArray = PackedByteArray()
	seen.resize(n * n)
	for i in range(n * n):
		seen[i] = 0

	var q: Array[int] = []
	q.append(root_idx)
	seen[root_idx] = 1

	var dirs: Array = [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]
	while q.size() > 0:
		var cur: int = int(q.pop_front())
		var cx: int = cur % n
		var cz: int = int(float(cur) / float(n))

		for d in dirs:
			var nb: Vector2i = _neighbor_of(cx, cz, d)
			if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
				continue
			var ni: int = nb.y * n + nb.x
			if seen[ni] != 0:
				continue
			if _can_move_edge(cur, ni, d, want, levels):
				seen[ni] = 1
				q.append(ni)

	return seen

func _can_reach_root(n: int, root_idx: int, want: int, levels: PackedInt32Array) -> PackedByteArray:
	var good: PackedByteArray = PackedByteArray()
	good.resize(n * n)
	for i in range(n * n):
		good[i] = 0

	var q: Array[int] = []
	q.append(root_idx)
	good[root_idx] = 1

	var dirs: Array = [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]
	while q.size() > 0:
		var cur: int = int(q.pop_front())
		var cx: int = cur % n
		var cz: int = int(float(cur) / float(n))

		for d in dirs:
			var nb: Vector2i = _neighbor_of(cx, cz, d)
			if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
				continue
			var ni: int = nb.y * n + nb.x
			if good[ni] != 0:
				continue

			var dir_nb_to_cur: int = _opposite_dir(d)
			if _can_move_edge(ni, cur, dir_nb_to_cur, want, levels):
				good[ni] = 1
				q.append(ni)

	return good

func _ensure_global_accessibility(n: int, want: int, levels: PackedInt32Array, rng: RandomNumberGenerator) -> int:
	if not auto_fix_global_access:
		return FIX_NONE

	var flags: int = FIX_NONE
	var root_idx: int = _pick_root_idx_from_levels(n, levels)

	for _pass in range(global_fix_passes):
		var reach: PackedByteArray = _reach_from_root(n, root_idx, want, levels)
		var any_unreach: bool = false
		for i in range(n * n):
			if reach[i] == 0:
				any_unreach = true
				break

		if any_unreach:
			var cands: Array = []
			var dirs: Array = [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]

			for i in range(n * n):
				if reach[i] == 0:
					continue
				var x: int = i % n
				var z: int = int(float(i) / float(n))
				for d in dirs:
					var nb: Vector2i = _neighbor_of(x, z, d)
					if nb.x < 0 or nb.x >= n or nb.y < 0 or nb.y >= n:
						continue
					var j: int = nb.y * n + nb.x
					if reach[j] != 0:
						continue
					if levels[j] == levels[i] + want:
						cands.append([i, d])

			if not cands.is_empty():
				if _try_place_any_from_candidates(cands, n, levels, want, rng):
					flags |= FIX_PLACED
					_prune_ramps_strict()
					continue

			for i in range(n * n):
				if reach[i] == 0:
					levels[i] -= 1
			return flags | FIX_LEVELS

		var good: PackedByteArray = _can_reach_root(n, root_idx, want, levels)
		var reach2: PackedByteArray = _reach_from_root(n, root_idx, want, levels)
		var trap_cells: Array[int] = []
		for i in range(n * n):
			if reach2[i] != 0 and good[i] == 0:
				trap_cells.append(i)

		if trap_cells.is_empty():
			return flags

		var exit_cands: Array = []
		var dirs2: Array = [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]

		for i in trap_cells:
			var x2: int = i % n
			var z2: int = int(float(i) / float(n))
			for d2 in dirs2:
				var nb2: Vector2i = _neighbor_of(x2, z2, d2)
				if nb2.x < 0 or nb2.x >= n or nb2.y < 0 or nb2.y >= n:
					continue
				var j2: int = nb2.y * n + nb2.x
				if good[j2] != 0 and levels[j2] == levels[i] + want:
					exit_cands.append([i, d2])

		if not exit_cands.is_empty():
			if _try_place_any_from_candidates(exit_cands, n, levels, want, rng):
				flags |= FIX_PLACED
				_prune_ramps_strict()
				continue

		for i in trap_cells:
			levels[i] += 1
		return flags | FIX_LEVELS

	return flags

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
		push_error("ArenaBlockyTerrain: Expected nodes 'TerrainBody/TerrainMesh' and 'TerrainBody/TerrainCollision'.")
		return

	if use_rock_shader:
		var sm := ShaderMaterial.new()
		sm.shader = load("res://shaders/blocky_rock.gdshader")
		sm.set_shader_parameter("noise_top", noise_top_tex)
		sm.set_shader_parameter("noise_wall", noise_wall_tex)
		sm.set_shader_parameter("noise_ramp", noise_ramp_tex)
		sm.set_shader_parameter("disp_strength_top", disp_strength_top)
		sm.set_shader_parameter("disp_strength_wall", disp_strength_wall)
		sm.set_shader_parameter("disp_strength_ramp", disp_strength_ramp)
		sm.set_shader_parameter("disp_scale_top", disp_scale_top)
		sm.set_shader_parameter("disp_scale_wall", disp_scale_wall)
		sm.set_shader_parameter("disp_scale_ramp", disp_scale_ramp)
		sm.set_shader_parameter("albedo_top", albedo_top_tex)
		sm.set_shader_parameter("albedo_wall", albedo_wall_tex)
		sm.set_shader_parameter("albedo_ramp", albedo_ramp_tex)
		sm.set_shader_parameter("normal_top", normal_top_tex)
		sm.set_shader_parameter("normal_wall", normal_wall_tex)
		sm.set_shader_parameter("normal_ramp", normal_ramp_tex)
		sm.set_shader_parameter("normal_strength", normal_strength)
		sm.set_shader_parameter("seam_lock_width", seam_lock_width)
		sm.set_shader_parameter("seam_lock_soft", seam_lock_soft)
		sm.set_shader_parameter("debug_show_vertex_color", debug_vertex_colors)
		mesh_instance.material_override = sm
	else:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.material_override = mat

	_ensure_tunnel_nodes()

	if randomize_seed_on_start:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		noise_seed = rng.randi()

	if print_seed:
		print("Noise seed:", noise_seed)

	generate()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_R:
		if randomize_seed_on_regen_key:
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			noise_seed = rng.randi()
			if print_seed:
				print("Noise seed:", noise_seed)
		generate()

func generate() -> void:
	var n: int = max(2, cells_per_side)
	_cell_size = world_size_m / float(n)
	if use_rock_shader and mesh_instance != null:
		var sm := mesh_instance.material_override as ShaderMaterial
		if sm != null:
			sm.set_shader_parameter("cell_size", _cell_size)

	# Center the arena around (0,0) in XZ
	_ox = -world_size_m * 0.5
	_oz = -world_size_m * 0.5

	_generate_heights()
	_limit_neighbor_cliffs()
	_fill_pits()

	var rng := RandomNumberGenerator.new()
	rng.seed = int(noise_seed) ^ 0x9e3779b9

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

	_resolve_tunnel_layer(n)
	_generate_tunnels_layout(n, rng)

	_build_mesh_and_collision(n)
	_build_tunnel_mesh(n)
	print("Ramp slots:", _count_ramps())
	_sync_sun()

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

func _idx2(x: int, z: int, n: int) -> int:
	return z * n + x

func _in_bounds(x: int, z: int, n: int) -> bool:
	return x >= 0 and x < n and z >= 0 and z < n

func _shuffle_dirs(rng: RandomNumberGenerator, dirs: Array[int]) -> void:
	for i in range(dirs.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = dirs[i]
		dirs[i] = dirs[j]
		dirs[j] = tmp

func _pick_edgeish_cell(n: int, rng: RandomNumberGenerator) -> Vector2i:
	var side: int = rng.randi_range(0, 3)
	var p := Vector2i(1, 1)
	match side:
		0:
			p = Vector2i(rng.randi_range(1, n - 2), 0)
		1:
			p = Vector2i(rng.randi_range(1, n - 2), n - 1)
		2:
			p = Vector2i(0, rng.randi_range(1, n - 2))
		3:
			p = Vector2i(n - 1, rng.randi_range(1, n - 2))

	if p.x == 0:
		p.x = 1
	if p.x == n - 1:
		p.x = n - 2
	if p.y == 0:
		p.y = 1
	if p.y == n - 1:
		p.y = n - 2
	return p

func _pick_passable_edgeish_cell(n: int, rng: RandomNumberGenerator, passable: PackedByteArray) -> Vector2i:
	for _i in range(32):
		var p := _pick_edgeish_cell(n, rng)
		if passable[_idx2(p.x, p.y, n)] != 0:
			return p

	for i in range(n * n):
		if passable[i] != 0:
			return Vector2i(i % n, int(float(i) / float(n)))

	return Vector2i(1, 1)

func _bfs_path(start: Vector2i, goal: Vector2i, n: int, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var start_i: int = _idx2(start.x, start.y, n)
	var goal_i: int = _idx2(goal.x, goal.y, n)

	var came := PackedInt32Array()
	came.resize(n * n)
	for i in range(n * n):
		came[i] = -1

	var q: Array[int] = []
	q.append(start_i)
	came[start_i] = start_i

	var dirs: Array[int] = [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]

	while q.size() > 0:
		var cur: int = int(q.pop_front())
		if cur == goal_i:
			break

		var cx: int = cur % n
		var cz: int = int(float(cur) / float(n))

		_shuffle_dirs(rng, dirs)
		for d in dirs:
			var nb: Vector2i = _neighbor_of(cx, cz, d)
			if not _in_bounds(nb.x, nb.y, n):
				continue
			var ni: int = _idx2(nb.x, nb.y, n)
			if came[ni] != -1:
				continue
			came[ni] = cur
			q.append(ni)

	if came[goal_i] == -1:
		return []

	var path: Array[Vector2i] = []
	var cur2: int = goal_i
	while cur2 != start_i:
		path.append(Vector2i(cur2 % n, int(float(cur2) / float(n))))
		cur2 = came[cur2]
	path.append(start)
	path.reverse()
	return path

func _tunnel_arrays_resize(n: int) -> void:
	var count: int = n * n
	_tunnel_mask.resize(count)
	_tunnel_hole_mask.resize(count)
	_tunnel_entrance_dir.resize(count)
	_tunnel_floor_min_y.resize(count)
	_tunnel_floor_max_y.resize(count)
	_tunnel_ramp_dir.resize(count)

	for i in range(count):
		_tunnel_mask[i] = 0
		_tunnel_hole_mask[i] = 0
		_tunnel_entrance_dir[i] = RAMP_NONE
		_tunnel_floor_min_y[i] = 0.0
		_tunnel_floor_max_y[i] = 0.0
		_tunnel_ramp_dir[i] = TUNNEL_DIR_NONE

func _tunnel_flat_corners(y: float) -> Vector4:
	return Vector4(y, y, y, y)

func _resolve_tunnel_layer(n: int) -> void:
	var min_floor: float = outer_floor_height + tunnel_floor_clearance_from_box
	var floor_y: float = maxf(min_floor, tunnel_floor_y)
	var ceil_y: float = floor_y + maxf(1.0, tunnel_height)

	var roof_min: float = INF
	for z in range(n):
		for x in range(n):
			var c := _cell_corners(x, z)
			var roof: float = min(min(c.x, c.y), min(c.z, c.w))
			roof_min = minf(roof_min, roof)

	var max_ceiling: float = roof_min - tunnel_ceiling_clearance
	var desired_h: float = maxf(0.5, float(tunnel_height_steps) * height_step)
	if ceil_y > max_ceiling:
		ceil_y = max_ceiling
		floor_y = ceil_y - maxf(1.0, tunnel_height)
		floor_y = maxf(floor_y, min_floor)

	var max_h: float = maxf(0.5, max_ceiling - floor_y)
	var h: float = clampf(desired_h, 0.5, max_h)
	ceil_y = floor_y + h

	_tunnel_floor_resolved = floor_y
	_tunnel_ceil_resolved = ceil_y
	_tunnel_base_floor_y = floor_y
	_tunnel_base_ceil_y = ceil_y

func _tunnel_cell_passable(x: int, z: int, n: int, _ceil_y: float) -> bool:
	if x <= 0 or z <= 0 or x >= n - 1 or z >= n - 1:
		return false
	return true

func _edge_is_open_at_ceil(n: int, a: Vector2i, b: Vector2i, ceil_y: float) -> bool:
	var ia: int = _idx2(a.x, a.y, n)
	var ib: int = _idx2(b.x, b.y, n)
	var ha: float = _heights[ia]
	var hb: float = _heights[ib]
	if absf(ha - hb) < 0.001:
		return true

	var wall_bottom: float = minf(ha, hb)
	return ceil_y <= (wall_bottom - tunnel_roof_clearance)

func _pick_entrance_dir(n: int, entrance: Vector2i) -> int:
	var center := Vector2i(n >> 1, n >> 1)
	var best_dir: int = RAMP_EAST
	var best_score: float = -1.0e20

	var e_idx: int = _idx2(entrance.x, entrance.y, n)
	var h0: float = _heights[e_idx]

	for dir in [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]:
		var p := entrance
		var ok := true
		for _i in range(tunnel_ramp_max_steps + 2):
			p = _neighbor_of(p.x, p.y, dir)
			if not _in_bounds(p.x, p.y, n):
				ok = false
				break
		if not ok:
			continue

		var nb: Vector2i = _neighbor_of(entrance.x, entrance.y, dir)
		var nb_idx: int = _idx2(nb.x, nb.y, n)
		var h1: float = _heights[nb_idx]

		var to_center := Vector2(center - entrance)
		var dvec := Vector2(nb - entrance)
		var dotc: float = to_center.dot(dvec)

		var score: float = 0.0
		if h1 <= h0:
			score += 10.0
		if absf(h1 - h0) < 0.001:
			score += 10.0
		score += dotc * 0.05

		if score > best_score:
			best_score = score
			best_dir = dir

	return best_dir

func _choose_tunnel_base_depth(_n: int, _entrances: Array[Vector2i]) -> void:
	var thickness: float = _tunnel_ceil_resolved - _tunnel_floor_resolved
	_tunnel_base_floor_y = outer_floor_height + tunnel_floor_clearance_from_box
	_tunnel_base_ceil_y = _tunnel_base_floor_y + thickness
	_tunnel_floor_resolved = _tunnel_base_floor_y
	_tunnel_ceil_resolved = _tunnel_base_ceil_y

func _tunnel_edge_blocked(x: int, z: int, dir: int, n: int, _levels: PackedInt32Array, _ceil_y: float) -> bool:
	var nb: Vector2i = _neighbor_of(x, z, dir)
	if not _in_bounds(nb.x, nb.y, n):
		return true
	return false

func _bfs_tunnel_path(
	start: Vector2i,
	goal: Vector2i,
	n: int,
	passable: PackedByteArray,
	levels: PackedInt32Array,
	ceil_y: float,
	rng: RandomNumberGenerator
) -> Array[Vector2i]:
	var start_i: int = _idx2(start.x, start.y, n)
	var goal_i: int = _idx2(goal.x, goal.y, n)

	if passable[start_i] == 0 or passable[goal_i] == 0:
		return []

	var came := PackedInt32Array()
	came.resize(n * n)
	for i in range(n * n):
		came[i] = -1

	var q: Array[int] = []
	q.append(start_i)
	came[start_i] = start_i

	var dirs: Array[int] = [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]

	while q.size() > 0:
		var cur: int = int(q.pop_front())
		if cur == goal_i:
			break

		var cx: int = cur % n
		var cz: int = int(float(cur) / float(n))

		_shuffle_dirs(rng, dirs)
		for d in dirs:
			if _tunnel_edge_blocked(cx, cz, d, n, levels, ceil_y):
				continue
			var nb: Vector2i = _neighbor_of(cx, cz, d)
			if not _in_bounds(nb.x, nb.y, n):
				continue
			var ni: int = _idx2(nb.x, nb.y, n)
			if passable[ni] == 0 or came[ni] != -1:
				continue
			came[ni] = cur
			q.append(ni)

	if came[goal_i] == -1:
		return []

	var path: Array[Vector2i] = []
	var cur2: int = goal_i
	while cur2 != start_i:
		path.append(Vector2i(cur2 % n, int(float(cur2) / float(n))))
		cur2 = came[cur2]
	path.append(start)
	path.reverse()
	return path

func _mark_tunnel_cell(x: int, z: int, n: int) -> void:
	var i: int = _idx2(x, z, n)
	_tunnel_mask[i] = 1
	_tunnel_floor_min_y[i] = _tunnel_base_floor_y
	_tunnel_floor_max_y[i] = _tunnel_base_floor_y
	_tunnel_ramp_dir[i] = TUNNEL_DIR_NONE

func _tunnel_set_flat_cell(idx: int, y: float) -> void:
	_tunnel_floor_min_y[idx] = y
	_tunnel_floor_max_y[idx] = y
	_tunnel_ramp_dir[idx] = TUNNEL_DIR_NONE

func _tunnel_stamp_entrance_ramp(n: int, entrance: Vector2i, dir: int) -> Vector2i:
	var e_idx: int = _idx2(entrance.x, entrance.y, n)
	if tunnel_entrance_mode == 0:
		_tunnel_mask[e_idx] = 1
		if tunnel_carve_surface_holes:
			_tunnel_hole_mask[e_idx] = 1
		_tunnel_set_flat_cell(e_idx, _tunnel_base_floor_y)
		_tunnel_ramp_dir[e_idx] = TUNNEL_DIR_NONE
		return entrance
	var start_floor: float = _heights[e_idx] - 0.5

	var cur := entrance
	var hi: float = start_floor
	var lo: float = hi - tunnel_ramp_drop

	_tunnel_mask[e_idx] = 1
	if tunnel_carve_surface_holes:
		_tunnel_hole_mask[e_idx] = 1

	_tunnel_ramp_dir[e_idx] = dir
	_tunnel_floor_max_y[e_idx] = hi
	_tunnel_floor_min_y[e_idx] = lo

	for _step in range(tunnel_ramp_max_steps):
		if lo <= _tunnel_base_floor_y + 0.001:
			break

		var nb: Vector2i = _neighbor_of(cur.x, cur.y, dir)
		if not _in_bounds(nb.x, nb.y, n):
			break

		var mi: int = _idx2(nb.x, nb.y, n)
		_tunnel_mask[mi] = 1
		_tunnel_ramp_dir[mi] = dir

		hi -= tunnel_ramp_drop
		lo -= tunnel_ramp_drop
		_tunnel_floor_max_y[mi] = hi
		_tunnel_floor_min_y[mi] = lo

		if tunnel_carve_surface_holes:
			_tunnel_hole_mask[mi] = 1

		cur = nb

	var end_idx: int = _idx2(cur.x, cur.y, n)
	_tunnel_set_flat_cell(end_idx, _tunnel_base_floor_y)
	_tunnel_ramp_dir[end_idx] = TUNNEL_DIR_NONE
	return cur

func _tunnel_corner_floors(idx: int, _n: int) -> PackedFloat32Array:
	var f := PackedFloat32Array([
		_tunnel_base_floor_y,
		_tunnel_base_floor_y,
		_tunnel_base_floor_y,
		_tunnel_base_floor_y
	])

	var dir: int = int(_tunnel_ramp_dir[idx])
	if dir == TUNNEL_DIR_NONE:
		return f

	var hi: float = _tunnel_floor_max_y[idx]
	var lo: float = _tunnel_floor_min_y[idx]

	match dir:
		RAMP_EAST:
			f[0] = hi
			f[3] = hi
			f[1] = lo
			f[2] = lo
		RAMP_WEST:
			f[0] = lo
			f[3] = lo
			f[1] = hi
			f[2] = hi
		RAMP_SOUTH:
			f[0] = hi
			f[1] = hi
			f[2] = lo
			f[3] = lo
		RAMP_NORTH:
			f[0] = lo
			f[1] = lo
			f[2] = hi
			f[3] = hi

	return f

func _tunnel_ceil_edge_pair(idx: int, edge: int, tunnel_height_y: float) -> Vector2:
	var floors: PackedFloat32Array = _tunnel_corner_floors(idx, 0)
	var c := Vector4(
		floors[0] + tunnel_height_y,
		floors[1] + tunnel_height_y,
		floors[2] + tunnel_height_y,
		floors[3] + tunnel_height_y
	)
	return _edge_pair(c, edge)

func _a_star(n: int, start: Vector2i, goal: Vector2i, ceil_y: float) -> Array[Vector2i]:
	if start == goal:
		return [start]

	var open: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g: Dictionary = {start: 0.0}
	var f: Dictionary = {start: float(abs(start.x - goal.x) + abs(start.y - goal.y))}
	var last_dir: Dictionary = {}

	while open.size() > 0:
		var best_i: int = 0
		var best_f: float = f.get(open[0], 1.0e20)
		for i in range(1, open.size()):
			var p := open[i]
			var fp: float = f.get(p, 1.0e20)
			if fp < best_f:
				best_f = fp
				best_i = i

		var current: Vector2i = open.pop_at(best_i)
		if current == goal:
			var out: Array[Vector2i] = [current]
			while came_from.has(current):
				current = came_from[current]
				out.push_back(current)
			out.reverse()
			return out

		for dir in [RAMP_EAST, RAMP_WEST, RAMP_SOUTH, RAMP_NORTH]:
			var nb: Vector2i = _neighbor_of(current.x, current.y, dir)
			if not _in_bounds(nb.x, nb.y, n):
				continue
			if not _edge_is_open_at_ceil(n, current, nb, ceil_y):
				continue

			var tentative: float = g.get(current, 1.0e20) + 1.0
			if last_dir.has(current) and int(last_dir[current]) != dir:
				tentative += tunnel_turn_penalty

			if tentative < g.get(nb, 1.0e20):
				came_from[nb] = current
				last_dir[nb] = dir
				g[nb] = tentative
				var h: float = float(abs(nb.x - goal.x) + abs(nb.y - goal.y))
				f[nb] = tentative + h
				if not open.has(nb):
					open.append(nb)

	return []

func _generate_tunnels_layout(n: int, rng: RandomNumberGenerator) -> void:
	_tunnel_arrays_resize(n)

	if not enable_tunnels or tunnel_count <= 0:
		return

	_choose_tunnel_base_depth(n, [])

	var passable := PackedByteArray()
	passable.resize(n * n)
	for z in range(n):
		for x in range(n):
			var idx: int = _idx2(x, z, n)
			passable[idx] = 1 if _tunnel_cell_passable(x, z, n, _tunnel_base_ceil_y) else 0

	var tries: int = 0
	var built: int = 0
	var tunnel_cells: Array[int] = []
	var entrances: Array[Vector2i] = []

	while built < tunnel_count and tries < tunnel_count * 12:
		tries += 1

		var a: Vector2i
		var b: Vector2i
		if built == 0 or tunnel_cells.is_empty():
			a = _pick_passable_edgeish_cell(n, rng, passable)
		else:
			var pick_idx: int = tunnel_cells[rng.randi_range(0, tunnel_cells.size() - 1)]
			a = Vector2i(pick_idx % n, int(float(pick_idx) / float(n)))
		b = _pick_passable_edgeish_cell(n, rng, passable)

		var manhattan: int = abs(a.x - b.x) + abs(a.y - b.y)
		if manhattan < maxi(6, n - 2):
			continue

		var a_idx: int = _idx2(a.x, a.y, n)
		var b_idx: int = _idx2(b.x, b.y, n)

		if built == 0:
			entrances.append(a)
		entrances.append(b)

		built += 1

	if entrances.is_empty():
		return

	var endpoints: Array[Vector2i] = []
	for entrance in entrances:
		var dir: int = RAMP_EAST
		if tunnel_entrance_mode == 1:
			dir = _pick_entrance_dir(n, entrance)
		endpoints.append(_tunnel_stamp_entrance_ramp(n, entrance, dir))

	for i in range(1, endpoints.size()):
		var path: Array[Vector2i] = _a_star(n, endpoints[i - 1], endpoints[i], _tunnel_base_ceil_y)
		for p in path:
			var idx_path: int = _idx2(p.x, p.y, n)
			_tunnel_mask[idx_path] = 1
			_tunnel_ramp_dir[idx_path] = TUNNEL_DIR_NONE
			_tunnel_set_flat_cell(idx_path, _tunnel_base_floor_y)
			tunnel_cells.append(idx_path)

func _dir_from_to(a: Vector2i, b: Vector2i) -> int:
	var dx: int = b.x - a.x
	var dz: int = b.y - a.y
	if dx == 1 and dz == 0:
		return RAMP_EAST
	if dx == -1 and dz == 0:
		return RAMP_WEST
	if dx == 0 and dz == 1:
		return RAMP_SOUTH
	if dx == 0 and dz == -1:
		return RAMP_NORTH
	return RAMP_EAST

func _ensure_tunnel_nodes() -> void:
	var terrain_body: Node = get_node_or_null("TerrainBody")
	if terrain_body == null:
		return

	var tunnel_body: StaticBody3D = terrain_body.get_node_or_null("TunnelBody") as StaticBody3D
	if tunnel_body == null:
		tunnel_body = StaticBody3D.new()
		tunnel_body.name = "TunnelBody"
		terrain_body.add_child(tunnel_body)
		if terrain_body is CollisionObject3D:
			var terrain_collision := terrain_body as CollisionObject3D
			tunnel_body.collision_layer = terrain_collision.collision_layer
			tunnel_body.collision_mask = terrain_collision.collision_mask

	_tunnel_mesh_instance = tunnel_body.get_node_or_null("TunnelMesh") as MeshInstance3D
	if _tunnel_mesh_instance == null:
		_tunnel_mesh_instance = MeshInstance3D.new()
		_tunnel_mesh_instance.name = "TunnelMesh"
		tunnel_body.add_child(_tunnel_mesh_instance)

	_tunnel_collision_shape = tunnel_body.get_node_or_null("TunnelCollision") as CollisionShape3D
	if _tunnel_collision_shape == null:
		_tunnel_collision_shape = CollisionShape3D.new()
		_tunnel_collision_shape.name = "TunnelCollision"
		tunnel_body.add_child(_tunnel_collision_shape)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_tunnel_mesh_instance.material_override = mat

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

	var fix_flags: int = _ensure_global_accessibility(n, want_levels, levels, rng)
	if (fix_flags & FIX_LEVELS) != 0:
		_apply_levels_to_heights(n, levels)
		_limit_neighbor_cliffs()
		_fill_pits()
		_ramps_need_regen = true
		return
	elif (fix_flags & FIX_PLACED) != 0:
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
			comp_max_nb[i] = -(1 << 30)

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
func _build_mesh_and_collision(n: int) -> void:
	n = max(2, n)
	_wall_faces.clear()
	var tunnel_ceil_y: float = _tunnel_ceil_resolved
	if tunnel_ceil_y == 0.0:
		tunnel_ceil_y = tunnel_floor_y + tunnel_height

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_uv2(Vector2.ZERO)

	var uv_scale_top: float = tiles_per_cell
	var uv_scale_wall: float = tiles_per_cell
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

			var skip_top: bool = false
			if enable_tunnels and tunnel_carve_surface_holes:
				var hole_idx: int = z * n + x
				if _tunnel_hole_mask.size() == n * n and _tunnel_hole_mask[hole_idx] != 0:
					skip_top = true

			var c0 := _cell_corners(x, z)

			var idx: int = z * n + x
			var is_ramp: bool = enable_ramps and _ramp_up_dir[idx] != RAMP_NONE
			var top_col: Color = ramp_color if is_ramp else terrain_color
			top_col.a = SURF_RAMP if is_ramp else SURF_TOP

			if not skip_top:
				_add_cell_top_grid(
					st,
					x, z,
					x0, x1, z0, z1,
					c0,
					top_subdiv,
					uv_scale_top,
					top_col
				)

	if enable_tunnels and tunnel_occluder_enabled:
		var occluder_col := tunnel_occluder_color
		occluder_col.a = SURF_WALL
		for z in range(n):
			for x in range(n):
				var idx_occluder: int = z * n + x
				if tunnel_carve_surface_holes and _tunnel_hole_mask.size() == n * n and (_tunnel_hole_mask[idx_occluder] != 0 or _tunnel_mask[idx_occluder] != 0):
					continue
				var x0o: float = _ox + float(x) * _cell_size
				var x1o: float = x0o + _cell_size
				var z0o: float = _oz + float(z) * _cell_size
				var z1o: float = z0o + _cell_size
				_add_quad(
					st,
					Vector3(x0o, tunnel_occluder_y, z0o),
					Vector3(x1o, tunnel_occluder_y, z0o),
					Vector3(x1o, tunnel_occluder_y, z1o),
					Vector3(x0o, tunnel_occluder_y, z1o),
					Vector2(0, 0) * uv_scale_top, Vector2(1, 0) * uv_scale_top, Vector2(1, 1) * uv_scale_top, Vector2(0, 1) * uv_scale_top,
					occluder_col
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
				if enable_tunnels and tunnel_carve_surface_holes:
					var a_is_hole: bool = _tunnel_hole_mask.size() == n * n and _tunnel_hole_mask[idx_a] != 0
					var b_is_hole: bool = _tunnel_hole_mask.size() == n * n and _tunnel_hole_mask[idx_b] != 0
					if a_is_hole or b_is_hole:
						# Rim wall from terrain surface down to tunnel ceiling (instead of skipping hole-adjacent walls)
						if a_is_hole and b_is_hole:
							continue
						var cB: Vector4 = _cell_corners(x + 1, z)
						var a_e: Vector2 = _edge_pair(cA, 0)
						var b_w: Vector2 = _edge_pair(cB, 1)
						var top0: float = maxf(a_e.x, b_w.x)
						var top1: float = maxf(a_e.y, b_w.y)
						var hole_idx: int = idx_a if a_is_hole else idx_b
						var hole_edge: int = 0 if a_is_hole else 1
						var ceil_pair: Vector2 = _tunnel_ceil_edge_pair(hole_idx, hole_edge, tunnel_ceil_y - _tunnel_floor_resolved)
						if top0 > ceil_pair.x + eps or top1 > ceil_pair.y + eps:
							if b_is_hole:
								# Face into the +X cell (the hole is in cell B)
								_add_wall_x_between(st, x1, z0, z1, ceil_pair.x, ceil_pair.y, top0, top1, uv_scale_wall, wall_subdiv)
							else:
								# Face into the -X cell (the hole is in cell A) by flipping z order
								_add_wall_x_between(st, x1, z1, z0, ceil_pair.y, ceil_pair.x, top1, top0, uv_scale_wall, wall_subdiv)
						continue
				if ramps_openings and _is_ramp_bridge(idx_a, idx_b, RAMP_EAST, want_levels, levels):
					pass
				else:
					var cB := _cell_corners(x + 1, z)
					var a_e := _edge_pair(cA, 0)
					var b_w := _edge_pair(cB, 1)

					var top0 := maxf(a_e.x, b_w.x)
					var top1 := maxf(a_e.y, b_w.y)
					var bot0 := minf(a_e.x, b_w.x)
					var bot1 := minf(a_e.y, b_w.y)

					if (top0 - bot0) > eps or (top1 - bot1) > eps:
						_add_wall_x_between(
							st, x1, z0, z1, bot0, bot1, top0, top1, uv_scale_wall, wall_subdiv
						)

			if z + 1 < n:
				var idx_c: int = z * n + x
				var idx_d: int = (z + 1) * n + x
				if enable_tunnels and tunnel_carve_surface_holes:
					var c_is_hole: bool = _tunnel_hole_mask.size() == n * n and _tunnel_hole_mask[idx_c] != 0
					var d_is_hole: bool = _tunnel_hole_mask.size() == n * n and _tunnel_hole_mask[idx_d] != 0
					if c_is_hole or d_is_hole:
						# Rim wall from terrain surface down to tunnel ceiling (instead of skipping hole-adjacent walls)
						if c_is_hole and d_is_hole:
							continue
						var cC: Vector4 = _cell_corners(x, z + 1)
						var a_s: Vector2 = _edge_pair(cA, 3)
						var c_n: Vector2 = _edge_pair(cC, 2)
						var top0z: float = maxf(a_s.x, c_n.x)
						var top1z: float = maxf(a_s.y, c_n.y)
						var hole_idx_z: int = idx_c if c_is_hole else idx_d
						var hole_edge_z: int = 3 if c_is_hole else 2
						var ceil_pair_z: Vector2 = _tunnel_ceil_edge_pair(hole_idx_z, hole_edge_z, tunnel_ceil_y - _tunnel_floor_resolved)
						if top0z > ceil_pair_z.x + eps or top1z > ceil_pair_z.y + eps:
							if d_is_hole:
								# Face into the +Z cell (the hole is in cell D)
								_add_wall_z_between(st, z1, x0, x1, ceil_pair_z.x, ceil_pair_z.y, top0z, top1z, uv_scale_wall, wall_subdiv)
							else:
								# Face into the -Z cell (the hole is in cell C) by flipping x order
								_add_wall_z_between(st, z1, x1, x0, ceil_pair_z.y, ceil_pair_z.x, top1z, top0z, uv_scale_wall, wall_subdiv)
						continue
				if ramps_openings and _is_ramp_bridge(idx_c, idx_d, RAMP_SOUTH, want_levels, levels):
					pass
				else:
					var cC := _cell_corners(x, z + 1)
					var a_s := _edge_pair(cA, 3)
					var c_n := _edge_pair(cC, 2)

					var top0z := maxf(a_s.x, c_n.x)
					var top1z := maxf(a_s.y, c_n.y)
					var bot0z := minf(a_s.x, c_n.x)
					var bot1z := minf(a_s.y, c_n.y)

					if (top0z - bot0z) > eps or (top1z - bot1z) > eps:
						_add_wall_z_between(
							st, z1, x0, x1, bot0z, bot1z, top0z, top1z, uv_scale_wall, wall_subdiv
						)

	# Container walls (keeps everything “inside a box”)
	_add_box_walls(st, outer_floor_height, box_height, uv_scale_wall)

	if build_ceiling:
		_add_ceiling(st, box_height, uv_scale_top)

	st.generate_normals()
	st.generate_tangents()
	var mesh: ArrayMesh = st.commit()
	mesh_instance.mesh = mesh
	collision_shape.shape = mesh.create_trimesh_shape()
	_rebuild_wall_decor()

func _ensure_wall_decor_root() -> void:
	if _wall_decor_root != null and is_instance_valid(_wall_decor_root):
		return
	_wall_decor_root = get_node_or_null("WallDecor") as Node3D
	if _wall_decor_root == null:
		_wall_decor_root = Node3D.new()
		_wall_decor_root.name = "WallDecor"
		add_child(_wall_decor_root)

func _basis_from_face(face: WallFace) -> Basis:
	var n: Vector3 = face.normal
	n.y = 0.0
	if n.length() < 0.0001:
		n = face.normal.normalized()
	else:
		n = n.normalized()

	if wall_decor_flip_outward:
		n = -n

	var u: Vector3 = Vector3.UP.cross(n)
	if u.length() < 0.0001:
		u = Vector3.RIGHT
	else:
		u = u.normalized()

	var v: Vector3 = n.cross(u).normalized()
	return Basis(u, v, n)

func _is_trapezoid(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> bool:
	return ((a + d) - (b + c)).length() > 0.001

func _hash_wall_face(center: Vector3, n: Vector3) -> int:
	var qx: int = int(floor(center.x * 10.0))
	var qy: int = int(floor(center.y * 10.0))
	var qz: int = int(floor(center.z * 10.0))

	var dir: int = 0
	if absf(n.x) > absf(n.z):
		dir = 1 if n.x > 0.0 else 2
	else:
		dir = 3 if n.z > 0.0 else 4

	var h: int = (qx * 73856093) ^ (qy * 19349663) ^ (qz * 83492791) ^ (dir * 2654435761)
	if h < 0:
		h = -h
	return h

func _capture_wall_face(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	if not enable_wall_decor:
		return

	var edge_u: Vector3 = b - a
	var edge_v: Vector3 = d - a
	var n: Vector3 = edge_u.cross(edge_v)
	var nlen: float = n.length()
	if nlen < 0.0001:
		return
	n /= nlen

	var width: float = edge_u.length()
	var h0: float = (a - d).length()
	var h1: float = (b - c).length()
	var height: float = max(h0, h1)

	if height < wall_decor_min_height:
		return

	var center: Vector3 = (a + b + c + d) * 0.25
	var trapezoid: bool = _is_trapezoid(a, b, c, d)
	var key: int = _hash_wall_face(center, n)
	_wall_faces.append(WallFace.new(a, b, c, d, center, n, width, height, trapezoid, key))

func _rebuild_wall_decor() -> void:
	if not enable_wall_decor or wall_decor_meshes.is_empty():
		if _wall_decor_root != null and is_instance_valid(_wall_decor_root):
			for child: Node in _wall_decor_root.get_children():
				child.queue_free()
		return

	_ensure_wall_decor_root()

	for child: Node in _wall_decor_root.get_children():
		child.queue_free()

	var variant_count: int = wall_decor_meshes.size()

	var counts: Array[int] = []
	counts.resize(variant_count)
	for i: int in range(variant_count):
		counts[i] = 0

	var faces_for_decor: Array[WallFace] = []
	faces_for_decor.assign(_wall_faces)
	var trap_count: int = 0
	for face in _wall_faces:
		if face.is_trapezoid:
			trap_count += 1
	print(
		"wall_decor_meshes:", wall_decor_meshes.size(),
		" wall_faces:", _wall_faces.size(),
		" trapezoids:", trap_count,
		" skip_trap:", wall_decor_skip_trapezoids,
		" max_size:", wall_decor_max_size
	)

	for f: WallFace in faces_for_decor:
		if f.center.y < wall_decor_min_world_y:
			continue
		if wall_decor_skip_trapezoids and f.is_trapezoid:
			continue
		if wall_decor_max_size.x > 0.0 and f.width > wall_decor_max_size.x:
			continue
		if wall_decor_max_size.y > 0.0 and f.height > wall_decor_max_size.y:
			continue
		var idx: int = (f.key + wall_decor_seed) % variant_count
		counts[idx] += 1

	var mmi_by_variant: Array[MultiMeshInstance3D] = []
	mmi_by_variant.resize(variant_count)

	var aabb_by_variant: Array[AABB] = []
	aabb_by_variant.resize(variant_count)

	for v: int in range(variant_count):
		if counts[v] <= 0:
			mmi_by_variant[v] = null
			continue

		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = wall_decor_meshes[v]
		mm.instance_count = counts[v]

		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.multimesh = mm

		_wall_decor_root.add_child(mmi)
		mmi_by_variant[v] = mmi
		aabb_by_variant[v] = wall_decor_meshes[v].get_aabb()

	var write_i: Array[int] = []
	write_i.resize(variant_count)
	for v2: int in range(variant_count):
		write_i[v2] = 0

	var total_instances: int = 0
	for count in counts:
		total_instances += count
	if total_instances <= 0:
		push_warning("Wall decor: 0 instances after filtering. Check max size or trapezoid skip.")
		return

	for f2: WallFace in faces_for_decor:
		if f2.center.y < wall_decor_min_world_y:
			continue
		if wall_decor_skip_trapezoids and f2.is_trapezoid:
			continue
		if wall_decor_max_size.x > 0.0 and f2.width > wall_decor_max_size.x:
			continue
		if wall_decor_max_size.y > 0.0 and f2.height > wall_decor_max_size.y:
			continue
		var vsel: int = (f2.key + wall_decor_seed) % variant_count
		var mmi2: MultiMeshInstance3D = mmi_by_variant[vsel]
		if mmi2 == null:
			continue

		var aabb: AABB = aabb_by_variant[vsel]
		var xf: Transform3D = _decor_transform_for_face(f2, aabb, wall_decor_offset)

		var wi: int = write_i[vsel]
		mmi2.multimesh.set_instance_transform(wi, xf)
		write_i[vsel] = wi + 1

func _decor_transform_for_face(face: WallFace, aabb: AABB, outward_offset: float) -> Transform3D:
	var rot: Basis = _basis_from_face(face)

	var ref_w: float = max(aabb.size.x, 0.001)
	var ref_h: float = max(aabb.size.y, 0.001)
	var sx: float = 1.0
	var sy: float = 1.0
	if wall_decor_fit_to_face:
		sx = clamp(face.width / ref_w, 0.1, wall_decor_max_scale)
		sy = clamp(face.height / ref_h, 0.1, wall_decor_max_scale)
	var sz: float = wall_decor_depth_scale

	var aabb_center_x: float = aabb.position.x + aabb.size.x * 0.5
	var aabb_center_y: float = aabb.position.y + aabb.size.y * 0.5
	var attach_z: float = aabb.position.z
	if wall_decor_flip_outward:
		attach_z = aabb.position.z + aabb.size.z

	var local_correction := Vector3(-aabb_center_x * sx, -aabb_center_y * sy, -attach_z * sz)
	var world_correction := rot * local_correction

	var decor_basis := Basis(rot.x * sx, rot.y * sy, rot.z * sz)

	var outward: Vector3 = rot.z.normalized()
	var pos: Vector3 = face.center + outward * outward_offset + world_correction
	return Transform3D(decor_basis, pos)

func _add_wall_x_colored(st: SurfaceTool, x_edge: float, z0: float, z1: float, y_top0: float, y_top1: float, y_bot: float, uv_scale: float, color: Color) -> void:
	if (maxf(y_top0, y_top1) - y_bot) <= 0.001:
		return
	var a := Vector3(x_edge, y_top0, z0)
	var b := Vector3(x_edge, y_top1, z1)
	var c := Vector3(x_edge, y_bot, z1)
	var d := Vector3(x_edge, y_bot, z0)
	_add_quad(st, a, b, c, d,
		Vector2(0, y_top0 * uv_scale), Vector2(1, y_top1 * uv_scale),
		Vector2(1, y_bot * uv_scale), Vector2(0, y_bot * uv_scale),
		color
	)

func _add_wall_z_colored(st: SurfaceTool, z_edge: float, x0: float, x1: float, y_top0: float, y_top1: float, y_bot: float, uv_scale: float, color: Color) -> void:
	if (maxf(y_top0, y_top1) - y_bot) <= 0.001:
		return
	var a := Vector3(x0, y_top0, z_edge)
	var b := Vector3(x1, y_top1, z_edge)
	var c := Vector3(x1, y_bot, z_edge)
	var d := Vector3(x0, y_bot, z_edge)
	_add_quad(st, a, b, c, d,
		Vector2(0, y_top0 * uv_scale), Vector2(1, y_top1 * uv_scale),
		Vector2(1, y_bot * uv_scale), Vector2(0, y_bot * uv_scale),
		color
	)

func _build_tunnel_mesh(n: int) -> void:
	_ensure_tunnel_nodes()
	if _tunnel_mesh_instance == null or _tunnel_collision_shape == null:
		return

	if not enable_tunnels or _tunnel_mask.size() != n * n:
		_tunnel_mesh_instance.mesh = null
		_tunnel_collision_shape.shape = null
		return

	var floor_y: float = _tunnel_floor_resolved
	var ceil_y: float = _tunnel_ceil_resolved
	if floor_y == 0.0 or ceil_y == 0.0:
		floor_y = tunnel_floor_y
		ceil_y = tunnel_floor_y + maxf(1.0, tunnel_height)
	var tunnel_height_y: float = maxf(0.5, ceil_y - floor_y)
	var uv_scale: float = 0.08

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for z in range(n):
		for x in range(n):
			var idx: int = _idx2(x, z, n)
			if _tunnel_mask[idx] == 0:
				continue

			var x0: float = _ox + float(x) * _cell_size
			var x1: float = x0 + _cell_size
			var z0: float = _oz + float(z) * _cell_size
			var z1: float = z0 + _cell_size

			var is_entrance: bool = tunnel_carve_surface_holes and _tunnel_hole_mask.size() == n * n and _tunnel_hole_mask[idx] != 0

			var has_w: bool = false
			var has_e: bool = false
			var has_n: bool = false
			var has_s: bool = false

			var floors: PackedFloat32Array = _tunnel_corner_floors(idx, n)
			var c00: float = floors[0] + tunnel_height_y
			var c10: float = floors[1] + tunnel_height_y
			var c11: float = floors[2] + tunnel_height_y
			var c01: float = floors[3] + tunnel_height_y

			_add_quad(
				st,
				Vector3(x0, floors[0], z0),
				Vector3(x1, floors[1], z0),
				Vector3(x1, floors[2], z1),
				Vector3(x0, floors[3], z1),
				Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
				tunnel_color
			)

			if not is_entrance:
				_add_quad(
					st,
					Vector3(x0, c01, z1),
					Vector3(x1, c11, z1),
					Vector3(x1, c10, z0),
					Vector3(x0, c00, z0),
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)

			if x > 0 and _tunnel_mask[_idx2(x - 1, z, n)] != 0:
				var nb_floors_w: PackedFloat32Array = _tunnel_corner_floors(_idx2(x - 1, z, n), n)
				var edge_a_w: Vector2 = _edge_pair(Vector4(floors[0], floors[1], floors[2], floors[3]), 1)
				var edge_b_w: Vector2 = _edge_pair(Vector4(nb_floors_w[0], nb_floors_w[1], nb_floors_w[2], nb_floors_w[3]), 0)
				has_w = _edges_match(edge_a_w, edge_b_w)

			if not has_w:
				_add_quad(
					st,
					Vector3(x0, floors[0], z0),
					Vector3(x0, floors[3], z1),
					Vector3(x0, c01, z1),
					Vector3(x0, c00, z0),
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
			if x < n - 1 and _tunnel_mask[_idx2(x + 1, z, n)] != 0:
				var nb_floors_e: PackedFloat32Array = _tunnel_corner_floors(_idx2(x + 1, z, n), n)
				var edge_a_e: Vector2 = _edge_pair(Vector4(floors[0], floors[1], floors[2], floors[3]), 0)
				var edge_b_e: Vector2 = _edge_pair(Vector4(nb_floors_e[0], nb_floors_e[1], nb_floors_e[2], nb_floors_e[3]), 1)
				has_e = _edges_match(edge_a_e, edge_b_e)

			if not has_e:
				_add_quad(
					st,
					Vector3(x1, floors[2], z1),
					Vector3(x1, floors[1], z0),
					Vector3(x1, c10, z0),
					Vector3(x1, c11, z1),
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
			if z > 0 and _tunnel_mask[_idx2(x, z - 1, n)] != 0:
				var nb_floors_n: PackedFloat32Array = _tunnel_corner_floors(_idx2(x, z - 1, n), n)
				var edge_a_n: Vector2 = _edge_pair(Vector4(floors[0], floors[1], floors[2], floors[3]), 2)
				var edge_b_n: Vector2 = _edge_pair(Vector4(nb_floors_n[0], nb_floors_n[1], nb_floors_n[2], nb_floors_n[3]), 3)
				has_n = _edges_match(edge_a_n, edge_b_n)

			if not has_n:
				_add_quad(
					st,
					Vector3(x1, floors[1], z0),
					Vector3(x0, floors[0], z0),
					Vector3(x0, c00, z0),
					Vector3(x1, c10, z0),
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
			if z < n - 1 and _tunnel_mask[_idx2(x, z + 1, n)] != 0:
				var nb_floors_s: PackedFloat32Array = _tunnel_corner_floors(_idx2(x, z + 1, n), n)
				var edge_a_s: Vector2 = _edge_pair(Vector4(floors[0], floors[1], floors[2], floors[3]), 3)
				var edge_b_s: Vector2 = _edge_pair(Vector4(nb_floors_s[0], nb_floors_s[1], nb_floors_s[2], nb_floors_s[3]), 2)
				has_s = _edges_match(edge_a_s, edge_b_s)

			if not has_s:
				_add_quad(
					st,
					Vector3(x0, floors[3], z1),
					Vector3(x1, floors[2], z1),
					Vector3(x1, c11, z1),
					Vector3(x0, c01, z1),
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)

			# Shaft rim walls are generated by the terrain mesh (_build_mesh_and_collision),
			# so we do not add extra surface-to-ceiling liners here (avoids double walls / z-fighting).

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_tunnel_mesh_instance.mesh = mesh
	_tunnel_collision_shape.shape = mesh.create_trimesh_shape()

func _sync_sun() -> void:
	var sun := get_node_or_null("SUN") as DirectionalLight3D
	if sun == null:
		return

	var center := global_position + Vector3(_ox + world_size_m * 0.5, 0.0, _oz + world_size_m * 0.5)
	sun.global_position = center + Vector3(0.0, sun_height, 0.0)
	sun.look_at(center, Vector3.UP)

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
	var bc := box_color
	bc.a = SURF_BOX
	_add_quad(st, a, b, c, d, u0, u1, u2, u3, bc)

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

	var bc := box_color
	bc.a = SURF_BOX
	# Order affects normals; culling is disabled, but keep consistent anyway.
	if outward:
		_add_quad(st, b, a, d, c,
			Vector2(0, a.y * uv_scale), Vector2(1, b.y * uv_scale),
			Vector2(1, top_y * uv_scale), Vector2(0, top_y * uv_scale),
			bc
		)
	else:
		_add_quad(st, a, b, c, d,
			Vector2(0, a.y * uv_scale), Vector2(1, b.y * uv_scale),
			Vector2(1, top_y * uv_scale), Vector2(0, top_y * uv_scale),
			bc
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
	var bc := box_color
	bc.a = SURF_BOX
	_add_quad(st, a, d, c, b, u0, u1, u2, u3, bc)

# -----------------------------
# Terrain wall helpers (between unequal cells)
# -----------------------------
func _add_wall_x_between(st: SurfaceTool, x_edge: float, z0: float, z1: float,
	low0: float, low1: float, high0: float, high1: float, uv_scale: float, subdiv: int) -> void:
	var eps: float = 0.0005
	var d0: float = absf(high0 - low0)
	var d1: float = absf(high1 - low1)
	if d0 <= eps and d1 <= eps:
		return

	var a := Vector3(x_edge, high0, z0)
	var b := Vector3(x_edge, high1, z1)
	var c := Vector3(x_edge, low1, z1)
	var d := Vector3(x_edge, low0, z0)
	var wall_col := terrain_color
	wall_col.a = SURF_WALL
	var ua := Vector2(0.0, 1.0)
	var ub := Vector2(1.0, 1.0)
	var uc := Vector2(1.0, 0.0)
	var ud := Vector2(0.0, 0.0)
	ua.x *= uv_scale
	ub.x *= uv_scale
	uc.x *= uv_scale
	ud.x *= uv_scale
	_capture_wall_face(a, b, c, d)

	if d0 > eps and d1 > eps:
		if subdiv > 1:
			_add_quad_grid(st, a, b, c, d,
				ua, ub, uc, ud,
				subdiv, subdiv,
				wall_col
			)
		else:
			_add_quad_uv2(st, a, b, c, d,
				ua, ub, uc, ud,
				Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
				wall_col
			)
		return

	st.set_color(wall_col)
	st.set_uv(ua); st.set_uv2(Vector2(0, 0)); st.add_vertex(a)
	st.set_uv(ub); st.set_uv2(Vector2(1, 0)); st.add_vertex(b)
	st.set_uv(uc); st.set_uv2(Vector2(1, 1)); st.add_vertex(c)

	st.set_color(wall_col)
	st.set_uv(ua); st.set_uv2(Vector2(0, 0)); st.add_vertex(a)
	st.set_uv(uc); st.set_uv2(Vector2(1, 1)); st.add_vertex(c)
	st.set_uv(ud); st.set_uv2(Vector2(0, 1)); st.add_vertex(d)

func _add_wall_z_between(st: SurfaceTool, z_edge: float, x0: float, x1: float,
	low0: float, low1: float, high0: float, high1: float, uv_scale: float, subdiv: int) -> void:
	var eps: float = 0.0005
	var d0: float = absf(high0 - low0)
	var d1: float = absf(high1 - low1)
	if d0 <= eps and d1 <= eps:
		return

	var a := Vector3(x0, high0, z_edge)
	var b := Vector3(x1, high1, z_edge)
	var c := Vector3(x1, low1, z_edge)
	var d := Vector3(x0, low0, z_edge)
	var wall_col := terrain_color
	wall_col.a = SURF_WALL
	var ua := Vector2(0.0, 1.0)
	var ub := Vector2(1.0, 1.0)
	var uc := Vector2(1.0, 0.0)
	var ud := Vector2(0.0, 0.0)
	ua.x *= uv_scale
	ub.x *= uv_scale
	uc.x *= uv_scale
	ud.x *= uv_scale
	_capture_wall_face(a, b, c, d)

	if d0 > eps and d1 > eps:
		if subdiv > 1:
			_add_quad_grid(st, a, b, c, d,
				ua, ub, uc, ud,
				subdiv, subdiv,
				wall_col
			)
		else:
			_add_quad_uv2(st, a, b, c, d,
				ua, ub, uc, ud,
				Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
				wall_col
			)
		return

	st.set_color(wall_col)
	st.set_uv(ua); st.set_uv2(Vector2(0, 0)); st.add_vertex(a)
	st.set_uv(ub); st.set_uv2(Vector2(1, 0)); st.add_vertex(b)
	st.set_uv(uc); st.set_uv2(Vector2(1, 1)); st.add_vertex(c)

	st.set_color(wall_col)
	st.set_uv(ua); st.set_uv2(Vector2(0, 0)); st.add_vertex(a)
	st.set_uv(uc); st.set_uv2(Vector2(1, 1)); st.add_vertex(c)
	st.set_uv(ud); st.set_uv2(Vector2(0, 1)); st.add_vertex(d)

# -----------------------------
# Quad writer
# -----------------------------
func _bilinear_height(h00: float, h10: float, h11: float, h01: float, s: float, t: float) -> float:
	return lerpf(lerpf(h00, h10, s), lerpf(h01, h11, s), t)

func _add_quad_grid(
	st: SurfaceTool,
	a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2,
	sub_u: int, sub_v: int,
	color: Color
) -> void:
	var su: int = maxi(1, sub_u)
	var sv: int = maxi(1, sub_v)

	for vy in range(sv):
		var t0 := float(vy) / float(sv)
		var t1 := float(vy + 1) / float(sv)

		for ux in range(su):
			var s0 := float(ux) / float(su)
			var s1 := float(ux + 1) / float(su)

			var p00 := (a.lerp(b, s0)).lerp(d.lerp(c, s0), t0)
			var p10 := (a.lerp(b, s1)).lerp(d.lerp(c, s1), t0)
			var p11 := (a.lerp(b, s1)).lerp(d.lerp(c, s1), t1)
			var p01 := (a.lerp(b, s0)).lerp(d.lerp(c, s0), t1)

			var uv00 := (ua.lerp(ub, s0)).lerp(ud.lerp(uc, s0), t0)
			var uv10 := (ua.lerp(ub, s1)).lerp(ud.lerp(uc, s1), t0)
			var uv11 := (ua.lerp(ub, s1)).lerp(ud.lerp(uc, s1), t1)
			var uv01 := (ua.lerp(ub, s0)).lerp(ud.lerp(uc, s0), t1)

			_add_quad_uv2(
				st,
				p00, p10, p11, p01,
				uv00, uv10, uv11, uv01,
				Vector2(s0, t0), Vector2(s1, t0), Vector2(s1, t1), Vector2(s0, t1),
				color
			)

func _add_cell_top_grid(
	st: SurfaceTool,
	cell_x: int, cell_z: int,
	x0: float, x1: float, z0: float, z1: float,
	corners: Vector4,
	subdiv: int,
	uv_scale: float,
	color: Color
) -> void:
	var sdiv: int = maxi(1, subdiv)

	var h00 := corners.x
	var h10 := corners.y
	var h11 := corners.z
	var h01 := corners.w
	var idx: int = cell_z * max(2, cells_per_side) + cell_x
	var ramp_dir: int = _ramp_up_dir[idx] if idx < _ramp_up_dir.size() else RAMP_NONE
	var is_ramp: bool = ramp_dir != RAMP_NONE

	for iz in range(sdiv):
		var t0 := float(iz) / float(sdiv)
		var t1 := float(iz + 1) / float(sdiv)

		var pz0 := lerpf(z0, z1, t0)
		var pz1 := lerpf(z0, z1, t1)

		for ix in range(sdiv):
			var s0 := float(ix) / float(sdiv)
			var s1 := float(ix + 1) / float(sdiv)

			var px0 := lerpf(x0, x1, s0)
			var px1 := lerpf(x0, x1, s1)

			var y00 := _bilinear_height(h00, h10, h11, h01, s0, t0)
			var y10 := _bilinear_height(h00, h10, h11, h01, s1, t0)
			var y11 := _bilinear_height(h00, h10, h11, h01, s1, t1)
			var y01 := _bilinear_height(h00, h10, h11, h01, s0, t1)

			var a := Vector3(px0, y00, pz0)
			var b := Vector3(px1, y10, pz0)
			var c := Vector3(px1, y11, pz1)
			var d := Vector3(px0, y01, pz1)

			var ua := _ramp_uv(s0, t0, ramp_dir) if is_ramp else Vector2(s0, t0)
			var ub := _ramp_uv(s1, t0, ramp_dir) if is_ramp else Vector2(s1, t0)
			var uc := _ramp_uv(s1, t1, ramp_dir) if is_ramp else Vector2(s1, t1)
			var ud := _ramp_uv(s0, t1, ramp_dir) if is_ramp else Vector2(s0, t1)
			ua *= uv_scale
			ub *= uv_scale
			uc *= uv_scale
			ud *= uv_scale

			_add_quad_uv2(
				st,
				a, b, c, d,
				ua, ub, uc, ud,
				Vector2(s0, t0), Vector2(s1, t0), Vector2(s1, t1), Vector2(s0, t1),
				color
			)

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

func _add_quad_uv2(
	st: SurfaceTool,
	a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2,
	ua2: Vector2, ub2: Vector2, uc2: Vector2, ud2: Vector2,
	color: Color
) -> void:
	st.set_color(color); st.set_uv(ua); st.set_uv2(ua2); st.add_vertex(a)
	st.set_color(color); st.set_uv(ub); st.set_uv2(ub2); st.add_vertex(b)
	st.set_color(color); st.set_uv(uc); st.set_uv2(uc2); st.add_vertex(c)

	st.set_color(color); st.set_uv(ua); st.set_uv2(ua2); st.add_vertex(a)
	st.set_color(color); st.set_uv(uc); st.set_uv2(uc2); st.add_vertex(c)
	st.set_color(color); st.set_uv(ud); st.set_uv2(ud2); st.add_vertex(d)
