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
@export var tunnel_elevator_top_mesh: Mesh = null
@export var tunnel_elevator_top_y_offset: float = 0.02
@export var tunnel_elevator_min_separation_cells: int = 6
@export var tunnel_elevator_fit_margin: float = 0.92
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
@export var tunnel_floor_clearance_from_box: float = 2.0
@export var tunnel_ceiling_clearance: float = 1.0
@export var tunnel_edge_clearance: float = 0.5
@export_range(0, 8, 1) var tunnel_extra_outpoints: int = 2
@export var tunnel_color: Color = Color(0.16, 0.18, 0.20, 1.0)
@export var tunnel_carve_surface_holes: bool = false  # deprecated (surface cutouts removed)
@export var tunnel_occluder_enabled: bool = true
@export var tunnel_occluder_y: float = -14.0
@export var tunnel_occluder_color: Color = Color(0.08, 0.08, 0.08, 1.0)
@export var dbg_tunnels: bool = false
@export_range(0.0, 1.0, 0.01) var tunnel_shaft_decor_density: float = 1.0 # 0 disables shaft wall decor
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
@export_range(1, 64, 1) var top_subdiv: int = 0
@export_range(1, 128, 1) var wall_subdiv: int = 0
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
@export var wall_decor_fix_open_side: bool = true
@export var wall_decor_debug_open_side: bool = false
@export var wall_decor_open_side_epsilon: float = 0.05
@export var wall_decor_open_side_use_raycast: bool = true
@export_flags_3d_physics var wall_decor_open_side_raycast_mask: int = 0xFFFF_FFFF
@export_range(0.0, 1.0, 0.01) var wall_decor_max_abs_normal_y: float = 0.75
@export var wall_decor_debug_log: bool = false
@export var wall_decor_debug_verbose: bool = false
@export var wall_decor_debug_max_logs: int = 300
@export var wall_decor_debug_print_every: int = 50
@export var wall_decor_debug_dump_under_surface: bool = true
@export var wall_decor_debug_focus_fi: int = -1
@export var wall_decor_debug_cov_details: bool = false
@export var wall_decor_debug_invalid_samples: bool = false
@export var dbg_draw_rays: bool = false
@export var dbg_draw_rays_clear_on_generate: bool = true
@export var dbg_draw_rays_max: int = 3000
@export var dbg_draw_rays_depth_test: bool = true
@export var dbg_draw_rays_hit_markers: bool = true
@export var wall_decor_surface_only: bool = false
@export var wall_decor_surface_margin: float = 0.10
@export var wall_decor_surface_probe_radius_cells: float = 0.55
@export_range(0.0, 1.0, 0.05) var wall_decor_surface_probe_lateral_cells: float = 0.25
@export var wall_decor_seed: int = 1337
@export var wall_decor_min_height: float = 0.25
@export var wall_decor_skip_trapezoids: bool = false
@export var wall_decor_skip_occluder_caps: bool = true
@export var wall_decor_occluder_epsilon: float = 0.05
@export var wall_wedge_decor_skip_trapezoids: bool = false
@export var wall_wedge_decor_skip_occluder_caps: bool = true
@export var wall_wedge_decor_occluder_epsilon: float = 0.05
@export var wall_decor_fit_to_face: bool = true
@export var wall_decor_max_scale: float = 3.0
@export var wall_decor_max_size: Vector2 = Vector2(0.0, 0.0)
@export_range(0.01, 2.0, 0.01) var wall_decor_depth_scale: float = 0.20
@export var enable_wall_wedge_decor: bool = true
@export var wall_wedge_decor_meshes: Array[Mesh] = []
@export var wall_wedge_decor_meshes_left: Array[Mesh] = []
@export var wall_wedge_decor_meshes_right: Array[Mesh] = []
@export var wall_wedge_decor_enable_overhang_flip_180: bool = true
@export var wall_wedge_decor_seed: int = 1337
@export var wall_wedge_decor_offset: float = 0.02
@export var wall_wedge_decor_fit_to_face: bool = true
@export var wall_wedge_decor_max_scale: float = 0.0 # 0 = unlimited (recommended if meshes are authored at unit size)
@export var wall_wedge_decor_max_size: Vector2 = Vector2(0.0, 0.0)
@export var wall_wedge_decor_min_world_y: float = -INF
@export var wall_wedge_decor_flip_outward: bool = true
@export var wall_wedge_decor_flip_facing: bool = false
@export var wall_wedge_decor_attach_far_side: bool = false # attach mesh's Z-min (false) or Z-max (true) to the wall surface
@export var wall_wedge_decor_depth_scale: float = 1.0
@export var wall_wedge_decor_max_depth_cells: float = 0.0 # 0 = no clamp
@export var wall_decor_flip_outward: bool = true
@export var wall_decor_flip_facing: bool = false
@export var wall_decor_attach_far_side: bool = false # attach mesh's Z-min (false) or Z-max (true) to the wall surface
@export var wall_decor_min_world_y: float = -INF
@export var enable_floor_decor: bool = true
@export var floor_decor_meshes: Array[Mesh] = []
@export var floor_decor_seed: int = 24601
@export var floor_decor_offset: float = 0.01
@export var floor_decor_fit_to_cell: bool = true
@export var floor_decor_depth_scale: float = 0.20 # meters of thickness along the face normal
@export var floor_decor_max_depth_cells: float = 1.0 # clamp thickness to <= 1 cell if desired
@export var floor_decor_max_scale: float = 0.0
@export var floor_decor_min_world_y: float = -INF
@export var floor_decor_random_yaw_steps: int = 4
@export var floor_decor_mesh_normal_axis: int = 3 # 0=X, 1=Y, 2=Z (set -1 for auto)
@export var floor_decor_scale_in_xz: bool = true
@export var floor_decor_flip_facing: bool = true
@export_range(0.90, 1.10, 0.005) var floor_decor_fill_ratio: float = 1.0
@export var floor_decor_local_margin: float = 0.0

func _validate_property(property: Dictionary) -> void:
	if property.name == "wall_wedge_decor_meshes":
		if wall_wedge_decor_meshes_left.size() > 0 or wall_wedge_decor_meshes_right.size() > 0:
			property.usage = PROPERTY_USAGE_NO_EDITOR

@onready var mesh_instance: MeshInstance3D = get_node_or_null("TerrainBody/TerrainMesh")
@onready var collision_shape: CollisionShape3D = get_node_or_null("TerrainBody/TerrainCollision")
@onready var _dbg_rays_node: Node3D = get_node_or_null("DebugRays") as Node3D

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
var _tunnel_entrance_cells: Array[Vector2i] = []

var _wd_logs: int = 0
var _wd_face_i: int = 0
var _wd_raycast_sanity_done: bool = false

func _wd(msg: String) -> void:
	if not wall_decor_debug_log:
		return
	if _wd_logs >= wall_decor_debug_max_logs:
		return
	_wd_logs += 1
	print("[WALL_DECOR] ", msg)

func _wd_fi(fi: int, msg: String) -> void:
	if wall_decor_debug_focus_fi >= 0 and fi != wall_decor_debug_focus_fi:
		return
	_wd(msg)

func _dbg_tunnel(msg: String) -> void:
	if dbg_tunnels:
		print("[TUNNEL] ", msg)

func _wd_dbg_sample(fi: int, label: String, p: Vector3, h: float) -> void:
	if not wall_decor_debug_invalid_samples:
		return
	if wall_decor_debug_focus_fi >= 0 and fi != wall_decor_debug_focus_fi:
		return

	var n: int = max(2, cells_per_side)
	var max_x := _ox + _cell_size * float(n)
	var max_z := _oz + _cell_size * float(n)
	var fx := (p.x - _ox) / _cell_size
	var fz := (p.z - _oz) / _cell_size

	_wd_fi(fi, "%s p=(%.3f, %.3f, %.3f) h=%s in=%s fx=%.6f fz=%.6f ox=%.3f oz=%.3f max_x=%.3f max_z=%.3f cs=%.6f n=%d" % [
		label, p.x, p.y, p.z, str(h), str(_xz_in_bounds(p.x, p.z)),
		fx, fz, _ox, _oz, max_x, max_z, _cell_size, n
	])

func _fmt_v3(v: Vector3) -> String:
	return "(%.3f, %.3f, %.3f)" % [v.x, v.y, v.z]

func _face_min_y(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> float:
	return minf(minf(a.y, b.y), minf(c.y, d.y))

func _face_max_y(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> float:
	return maxf(maxf(a.y, b.y), maxf(c.y, d.y))

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
const _NEG_INF := -1.0e20

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
var _shaft_faces: Array[WallFace] = []
var _shaft_decor_root: Node3D = null
var _shaft_face_key_next: int = 1
var _shaft_decor_faces: int = 0
var _shaft_decor_instances: int = 0
var _floor_mesh_normal_axis_cache: Dictionary = {}
var _floor_mesh_cap_cache: Dictionary = {}

var _dbg_ramp_cells_emitted: int = 0
var _dbg_ramp_quads_added: int = 0


func _wall_face_min_world_y(f: WallFace) -> float:
	return min(min(f.a.y, f.b.y), min(f.c.y, f.d.y))

func _wall_face_max_world_y(f: WallFace) -> float:
	return max(max(f.a.y, f.b.y), max(f.c.y, f.d.y))

class FloorFace extends RefCounted:
	var a: Vector3
	var b: Vector3
	var c: Vector3
	var d: Vector3
	var center: Vector3
	var normal: Vector3
	var width: float
	var depth: float
	var key: int

	func _init(a0: Vector3, b0: Vector3, c0: Vector3, d0: Vector3, center0: Vector3, normal0: Vector3, width0: float, depth0: float, key0: int) -> void:
		a = a0
		b = b0
		c = c0
		d = d0
		center = center0
		normal = normal0
		width = width0
		depth = depth0
		key = key0

var _floor_faces: Array[FloorFace] = []
var _floor_decor_root: Node3D
var _floor_decor_instances: Array[MultiMeshInstance3D] = []

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
	var delta_ab: int = levels[b_idx] - levels[a_idx]
	if _ramp_up_dir[a_idx] == dir_a_to_b and delta_ab >= 1 and delta_ab <= want:
		return true
	var dir_b_to_a: int = _opposite_dir(dir_a_to_b)
	var delta_ba: int = levels[a_idx] - levels[b_idx]
	if _ramp_up_dir[b_idx] == dir_b_to_a and delta_ba >= 1 and delta_ba <= want:
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
	var rise_levels: int = up_lvl - down_lvl
	return rise_levels >= 1 and rise_levels <= want

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
	var rise_levels: int = levels[high_idx] - low_level
	if rise_levels < 1 or rise_levels > want_levels:
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

	if abs(da) <= want and _is_ramp_bridge(a_idx, b_idx, dir_a_to_b, want, levels):
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
					if levels[j] > levels[i] and levels[j] <= levels[i] + want:
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
				if good[j2] != 0 and levels[j2] > levels[i] and levels[j2] <= levels[i] + want:
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
	var low_lvl: int = _h_to_level(low_h)
	var high_lvl: int = _h_to_level(high_h)
	var rise_levels: int = high_lvl - low_lvl
	if rise_levels < 1 or rise_levels > want:
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

func _sync_debug_rays_settings() -> void:
	if _dbg_rays_node == null:
		return
	if _dbg_rays_node.has_method("set_enabled"):
		_dbg_rays_node.call("set_enabled", dbg_draw_rays)
	else:
		_dbg_rays_node.set("enabled", dbg_draw_rays)
	_dbg_rays_node.set("max_rays", dbg_draw_rays_max)
	_dbg_rays_node.set("depth_test", dbg_draw_rays_depth_test)
	_dbg_rays_node.set("show_hit_markers", dbg_draw_rays_hit_markers)
	if _dbg_rays_node.has_method("_rebuild"):
		_dbg_rays_node.call("_rebuild")

func _ensure_debug_rays_node() -> void:
	if _dbg_rays_node != null:
		return

	var node := Node3D.new()
	node.name = "DebugRays"
	var script := load("res://Scripts/debug_rays_3d.gd") as Script
	if script == null:
		push_warning("ArenaBlockyTerrain: Debug rays script not found at res://Scripts/debug_rays_3d.gd")
		return
	node.set_script(script)
	add_child(node)
	_dbg_rays_node = node

func _dbg_add_ray(from: Vector3, to: Vector3, hit: Dictionary) -> void:
	if not dbg_draw_rays or _dbg_rays_node == null:
		return

	var c: Color = Color(0, 1, 0, 0.85)
	var hp: Variant = null
	var end := to
	if not hit.is_empty():
		hp = hit.get("position", null)
		if hp != null:
			end = hp
		c = Color(1, 0, 0, 0.85)

	_dbg_rays_node.call("add_ray", from, end, c, hp)

func _raycast_dbg(from: Vector3, to: Vector3, mask: int, exclude: Array = [], collide_areas: bool = false) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = mask
	q.exclude = exclude
	q.collide_with_bodies = true
	q.collide_with_areas = collide_areas
	q.hit_from_inside = true
	q.hit_back_faces = true
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	_dbg_add_ray(from, to, hit)
	return hit

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

	_ensure_debug_rays_node()
	_sync_debug_rays_settings()
	generate()

func _unhandled_input(e: InputEvent) -> void:
	var toggle := false

	if e is InputEventKey and e.pressed and e.keycode == KEY_F9:
		toggle = true
	elif InputMap.has_action(&"toggle_debug_rays") and e.is_action_pressed(&"toggle_debug_rays"):
		toggle = true

	if toggle:
		dbg_draw_rays = not dbg_draw_rays
		_sync_debug_rays_settings()
		if dbg_draw_rays and dbg_draw_rays_clear_on_generate and _dbg_rays_node != null:
			_dbg_rays_node.call("clear")
		return
	if e is InputEventKey and e.pressed and e.keycode == KEY_R:
		if randomize_seed_on_regen_key:
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			noise_seed = rng.randi()
			if print_seed:
				print("Noise seed:", noise_seed)
		generate()

func generate() -> void:
	if dbg_draw_rays_clear_on_generate and _dbg_rays_node != null:
		_dbg_rays_node.call("clear")
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
	_build_tunnel_elevator_tops(n)
	print("Ramp slots:", _count_ramps(), " ramp_cells_emitted:", _dbg_ramp_cells_emitted, " ramp_quads_added:", _dbg_ramp_quads_added)
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
			var roof: float = minf(minf(c.x, c.y), minf(c.z, c.w))
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

func _tunnel_stamp_entrance_ramp(n: int, entrance: Vector2i) -> Vector2i:
	# Shaft-only: no surface cutouts, no downward ramps.
	# Mark the entrance cell as the top-of-shaft so we can place the elevator tile/mesh there.
	var idx := entrance.y * n + entrance.x
	if _tunnel_hole_mask.size() == n * n:
		_tunnel_hole_mask[idx] = 1
	return entrance

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

func _entrance_far_enough(e: Vector2i, existing: Array[Vector2i], min_sep_cells: int) -> bool:
	var min_sep2 := min_sep_cells * min_sep_cells
	for a in existing:
		var dx := a.x - e.x
		var dz := a.y - e.y
		if dx * dx + dz * dz < min_sep2:
			return false
	return true

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


		var min_sep := tunnel_elevator_min_separation_cells

		if built == 0 and _entrance_far_enough(a, entrances, min_sep):
			entrances.append(a)
		if _entrance_far_enough(b, entrances, min_sep):
			entrances.append(b)

		built += 1

	if entrances.is_empty():
		return

	var endpoints: Array[Vector2i] = []
	_tunnel_entrance_cells.clear()
	for entrance in entrances:
		var ei: int = _idx2(entrance.x, entrance.y, n)
		var entrance_is_flat: bool = (_ramp_up_dir[ei] == RAMP_NONE)
		_dbg_tunnel("candidate entrance=%s ei=%d passable=%s up=%d" % [str(entrance), ei, str(passable[ei] != 0), _ramp_up_dir[ei]])
		if not entrance_is_flat:
			_dbg_tunnel("SKIP entrance on ramp: cell=%s ei=%d up=%d" % [str(entrance), ei, _ramp_up_dir[ei]])
			continue

		var top_cell: Vector2i = _tunnel_stamp_entrance_ramp(n, entrance)
		endpoints.append(top_cell)
		_tunnel_entrance_cells.append(top_cell)

	for i in range(1, endpoints.size()):
		var path: Array[Vector2i] = _a_star(n, endpoints[i - 1], endpoints[i], _tunnel_base_ceil_y)
		for p in path:
			var idx_path: int = _idx2(p.x, p.y, n)
			_tunnel_mask[idx_path] = 1
			_tunnel_ramp_dir[idx_path] = TUNNEL_DIR_NONE
			_tunnel_set_flat_cell(idx_path, _tunnel_base_floor_y)
			tunnel_cells.append(idx_path)

	if dbg_tunnels:
		var hole_count: int = 0
		var tunnel_cell_count: int = 0
		for v in _tunnel_hole_mask:
			if v != 0:
				hole_count += 1
		for v in _tunnel_mask:
			if v != 0:
				tunnel_cell_count += 1
		_dbg_tunnel("done: entrances=%d holes=%d tunnel_cells=%d" % [_tunnel_entrance_cells.size(), hole_count, tunnel_cell_count])

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
				var rise_levels: int = abs(dh)
				if rise_levels < 1 or rise_levels > want_levels:
					continue

				var low_cid: int
				var high_cid: int
				var low_idx: int
				var dir_up: int

				if dh > 0:
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
	_floor_faces.clear()
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
	var dbg_wall_added: int = 0
	var dbg_top_skipped: int = 0
	var dbg_hole_on_ramp_cleared: int = 0
	_dbg_ramp_cells_emitted = 0
	_dbg_ramp_quads_added = 0
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
					if _ramp_up_dir[hole_idx] == RAMP_NONE:
						skip_top = true
						dbg_top_skipped += 1
					else:
						_tunnel_hole_mask[hole_idx] = 0
						dbg_hole_on_ramp_cleared += 1
						push_warning("Tunnel hole attempted on ramp cell; cleared. i=%d x=%d z=%d" % [hole_idx, x, z])

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
				if is_ramp:
					_dbg_ramp_cells_emitted += 1
					var sdiv_dbg: int = maxi(1, top_subdiv)
					_dbg_ramp_quads_added += sdiv_dbg * sdiv_dbg

	if enable_tunnels and tunnel_occluder_enabled:
		var occluder_col := tunnel_occluder_color
		occluder_col.a = SURF_WALL
		for z in range(n):
			for x in range(n):
				var idx_occluder: int = z * n + x
				if _tunnel_hole_mask.size() == n * n and (_tunnel_hole_mask[idx_occluder] != 0 or (_tunnel_mask.size() == n * n and _tunnel_mask[idx_occluder] != 0)):
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
						var mean_a: float = (a_e.x + a_e.y) * 0.5
						var mean_b: float = (b_w.x + b_w.y) * 0.5
						var normal_pos_x: bool = mean_a > mean_b
						_add_wall_x_between(
							st, x1, z0, z1, bot0, bot1, top0, top1, uv_scale_wall, wall_subdiv, normal_pos_x
						)
						dbg_wall_added += 1
			if z + 1 < n:
				var idx_c: int = z * n + x
				var idx_d: int = (z + 1) * n + x
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
						var mean_a: float = (a_s.x + a_s.y) * 0.5
						var mean_c: float = (c_n.x + c_n.y) * 0.5
						var normal_pos_z: bool = mean_a > mean_c
						_add_wall_z_between(
							st, x0, x1, z1, bot0z, bot1z, top0z, top1z, uv_scale_wall, wall_subdiv, normal_pos_z
						)
						dbg_wall_added += 1
	# Container walls (keeps everything “inside a box”)
	_add_box_walls(st, outer_floor_height, box_height, uv_scale_wall)

	if build_ceiling:
		_add_ceiling(st, box_height, uv_scale_top)

	if dbg_tunnels:
		print("[MESH] top_skipped=", dbg_top_skipped, " walls_added=", dbg_wall_added, " hole_on_ramp_cleared=", dbg_hole_on_ramp_cleared)

	st.generate_normals()
	st.generate_tangents()
	var mesh: ArrayMesh = st.commit()
	mesh_instance.mesh = mesh
	collision_shape.shape = mesh.create_trimesh_shape()
	if wall_decor_open_side_use_raycast:
		call_deferred("_rebuild_wall_decor_after_physics")
	else:
		_rebuild_wall_decor()
	_rebuild_floor_decor()

func _rebuild_wall_decor_after_physics() -> void:
	await get_tree().physics_frame
	_rebuild_wall_decor()

func _ensure_wall_decor_root() -> void:
	if _wall_decor_root != null and is_instance_valid(_wall_decor_root):
		return
	_wall_decor_root = get_node_or_null("WallDecor") as Node3D
	if _wall_decor_root == null:
		_wall_decor_root = Node3D.new()
		_wall_decor_root.name = "WallDecor"
		add_child(_wall_decor_root)

func _ensure_floor_decor_root() -> void:
	if _floor_decor_root != null and is_instance_valid(_floor_decor_root):
		return
	_floor_decor_root = get_node_or_null("FloorDecor") as Node3D
	if _floor_decor_root == null:
		_floor_decor_root = Node3D.new()
		_floor_decor_root.name = "FloorDecor"
		add_child(_floor_decor_root)

func _ensure_shaft_decor_root() -> void:
	if _shaft_decor_root != null and is_instance_valid(_shaft_decor_root):
		return
	var terrain_body: Node = get_node_or_null("TerrainBody")
	if terrain_body == null:
		return
	_shaft_decor_root = terrain_body.get_node_or_null("ShaftDecor") as Node3D
	if _shaft_decor_root == null:
		_shaft_decor_root = Node3D.new()
		_shaft_decor_root.name = "ShaftDecor"
		terrain_body.add_child(_shaft_decor_root)

func _clear_floor_decor() -> void:
	if _floor_decor_root != null and is_instance_valid(_floor_decor_root):
		for child: Node in _floor_decor_root.get_children():
			child.queue_free()
	_floor_decor_instances.clear()

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

func _basis_from_outward(outward: Vector3) -> Basis:
	var z_axis: Vector3 = outward.normalized()
	var x_axis: Vector3 = Vector3.UP.cross(z_axis)
	if x_axis.length() < 0.0001:
		x_axis = Vector3.RIGHT
	else:
		x_axis = x_axis.normalized()
	var y_axis: Vector3 = z_axis.cross(x_axis).normalized()
	return Basis(x_axis, y_axis, z_axis)

func _sample_surface_y(world_x: float, world_z: float) -> float:
	var n: int = max(2, cells_per_side)
	var fx: float = (world_x - _ox) / _cell_size
	var fz: float = (world_z - _oz) / _cell_size
	if fx < 0.0 or fx > float(n) or fz < 0.0 or fz > float(n):
		return _NEG_INF
	var ix: int = clampi(int(floor(fx)), 0, n - 1)
	var iz: int = clampi(int(floor(fz)), 0, n - 1)
	var tx: float = clampf(fx - float(ix), 0.0, 1.0)
	var tz: float = clampf(fz - float(iz), 0.0, 1.0)

	var corners: Vector4 = _cell_corners(ix, iz)
	var y0: float = lerpf(corners.x, corners.y, tx)
	var y1: float = lerpf(corners.z, corners.w, tx)
	return lerpf(y0, y1, tz)

func _xz_in_bounds(x: float, z: float) -> bool:
	var n: int = max(2, cells_per_side)
	var max_x := _ox + _cell_size * float(n)
	var max_z := _oz + _cell_size * float(n)
	var eps := 1e-3
	return (x >= _ox - eps and x <= max_x + eps and z >= _oz - eps and z <= max_z + eps)

func _sample_surface_y_open(x: float, z: float) -> float:
	var n: int = max(2, cells_per_side)
	var max_x := _ox + _cell_size * float(n)
	var max_z := _oz + _cell_size * float(n)
	var eps := 1e-3

	# Truly outside: return invalid
	if x < _ox - eps or x > max_x + eps or z < _oz - eps or z > max_z + eps:
		return _NEG_INF

	# Inside (or tiny float overshoot): clamp to full mesh bounds
	var cx := clampf(x, _ox, max_x)
	var cz := clampf(z, _oz, max_z)
	return _sample_surface_y(cx, cz)

func _sample_top_surface_y(x: float, z: float, hint_dir: Vector3 = Vector3.ZERO) -> float:
	# We want the TOPMOST surface at (x,z). Wall centers often lie on cell boundaries,
	# so sample both sides and take the max to avoid picking the lower neighbor.
	var e: float = _cell_size * 0.02

	var d := Vector3(hint_dir.x, 0.0, hint_dir.z)
	if d.length_squared() > 1e-8:
		d = d.normalized()
		var a: float = _sample_surface_y_open(x + d.x * e, z + d.z * e)
		var b: float = _sample_surface_y_open(x - d.x * e, z - d.z * e)
		return maxf(a, b)

	# Fallback: small cross pattern and take max.
	var s0: float = _sample_surface_y_open(x, z)
	var s1: float = _sample_surface_y_open(x + e, z)
	var s2: float = _sample_surface_y_open(x - e, z)
	var s3: float = _sample_surface_y_open(x, z + e)
	var s4: float = _sample_surface_y_open(x, z - e)
	return maxf(s0, maxf(maxf(s1, s2), maxf(s3, s4)))

func _sample_top_surface_y_wide(
	x: float,
	z: float,
	hint_dir: Vector3 = Vector3.ZERO,
	use_min: bool = false
) -> float:
	var r: float = _cell_size * wall_decor_surface_probe_lateral_cells
	var dirs: Array[Vector3] = [
		Vector3(1, 0, 0), Vector3(-1, 0, 0),
		Vector3(0, 0, 1), Vector3(0, 0, -1),
		Vector3(1, 0, 1).normalized(), Vector3(1, 0, -1).normalized(),
		Vector3(-1, 0, 1).normalized(), Vector3(-1, 0, -1).normalized(),
	]

	var agg: float = INF if use_min else _NEG_INF
	var any_valid: bool = false

	for d: Vector3 in dirs:
		var y := _sample_top_surface_y(x + d.x * r, z + d.z * r, hint_dir)
		if y <= _NEG_INF * 0.5:
			continue
		any_valid = true
		if use_min:
			agg = minf(agg, y)
		else:
			agg = maxf(agg, y)

	# Fallback if everything was invalid (edge/outside grid).
	if not any_valid:
		return _sample_surface_y_open(x, z)

	return agg

func _wd_surface_only_ceiling_y_at(p: Vector3) -> float:
	# Use max aggregation so any nearby top surface counts as overhead terrain.
	return _sample_top_surface_y_wide(p.x, p.z, Vector3.ZERO, false)


func _wall_face_covered_both_sides(center: Vector3, top_y: float, dir_h: Vector3) -> Dictionary:
	var dir := dir_h
	dir.y = 0.0
	if dir.length() < 0.001:
		dir = Vector3.FORWARD
	else:
		dir = dir.normalized()

	var probe: float = maxf(
		wall_decor_open_side_epsilon + 0.001,
		_cell_size * wall_decor_surface_probe_radius_cells
	)

	var p_f := Vector3(center.x + dir.x * probe, center.y, center.z + dir.z * probe)
	var p_b := Vector3(center.x - dir.x * probe, center.y, center.z - dir.z * probe)

	var h_f: float = _sample_top_surface_y_wide(p_f.x, p_f.z, dir, true)
	var h_b: float = _sample_top_surface_y_wide(p_b.x, p_b.z, -dir, true)

	var valid_f := (h_f > _NEG_INF * 0.5)
	var valid_b := (h_b > _NEG_INF * 0.5)

	var margin: float = wall_decor_surface_margin
	var cover_f: bool = valid_f and (h_f > top_y + margin)
	var cover_b: bool = valid_b and (h_b > top_y + margin)

	return {
		"covered": cover_f and cover_b,
		"cover_f": cover_f, "cover_b": cover_b,
		"h_f": h_f, "h_b": h_b,
		"valid_f": valid_f, "valid_b": valid_b,
		"probe": probe, "margin": margin
	}

func _wall_decor_open_side_effective_raycast_mask() -> int:
	if wall_decor_open_side_raycast_mask != -1 and wall_decor_open_side_raycast_mask != 0xFFFF_FFFF:
		return wall_decor_open_side_raycast_mask

	var terrain_body: Node = get_node_or_null("TerrainBody")
	if terrain_body is CollisionObject3D:
		var terrain_collision := terrain_body as CollisionObject3D
		if terrain_collision.collision_layer != 0:
			return terrain_collision.collision_layer

	return wall_decor_open_side_raycast_mask

func _is_open_air_ray(from: Vector3, to: Vector3) -> bool:
	var hit := _raycast_dbg(from, to, _wall_decor_open_side_effective_raycast_mask(), [], false)
	return hit.is_empty()

func _sort_vec3_y_desc(a: Vector3, b: Vector3) -> bool:
	return a.y > b.y

func _axis_min3(v: Vector3) -> int:
	if v.x <= v.y and v.x <= v.z:
		return 0
	if v.y <= v.x and v.y <= v.z:
		return 1
	return 2

func _infer_floor_mesh_normal_axis(mesh: Mesh) -> int:
	# Goal: infer which LOCAL axis is the mesh's 'up' (its cap normal).
	# Prefer Y when the mesh is clearly a thin slab (typical floor tile),
	# otherwise fall back to area-weighted dominant normals (robust for spiky meshes).
	var aabb := mesh.get_aabb()
	var abs_size := Vector3(absf(aabb.size.x), absf(aabb.size.y), absf(aabb.size.z))
	var maxv := maxf(abs_size.x, maxf(abs_size.y, abs_size.z))
	if maxv <= 0.000001:
		return 1
	var min_axis := _axis_min3(abs_size)
	var minv := minf(abs_size.x, minf(abs_size.y, abs_size.z))
	var thin_ratio := minv / maxv
	# Only trust "thin axis" when it is the Y axis and very thin.
	# This prevents choosing X/Z on long skinny meshes where the thin axis is NOT the cap normal.
	if min_axis == 1 and thin_ratio <= 0.20:
		return 1
	return _dominant_normal_axis_for_mesh(mesh)

func _dominant_normal_axis_for_mesh(mesh: Mesh) -> int:
	# Area-weighted accumulation of ABS(normal) to find the predominant axis.
	# Bias toward Y when it is close to the top contender (helps floor meshes that also have side walls).
	var sum := Vector3.ZERO
	if mesh.get_surface_count() == 0:
		return 1
	for si in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(si)
		if arrays.is_empty():
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if verts.is_empty() or norms.is_empty() or idx.is_empty():
			continue
		for i in range(0, idx.size(), 3):
			var i0 := int(idx[i])
			var i1 := int(idx[i + 1])
			var i2 := int(idx[i + 2])
			var p0: Vector3 = verts[i0]
			var p1: Vector3 = verts[i1]
			var p2: Vector3 = verts[i2]
			var area := ((p1 - p0).cross(p2 - p0)).length() * 0.5
			if area <= 0.0000001:
				continue
			var n: Vector3 = (Vector3(norms[i0]) + Vector3(norms[i1]) + Vector3(norms[i2])) * (1.0 / 3.0)
			sum += Vector3(absf(n.x), absf(n.y), absf(n.z)) * area
	if sum.length() <= 0.000001:
		return 1
	var best := maxf(sum.x, maxf(sum.y, sum.z))
	# If Y is within ~8% of the best axis, pick Y.
	if sum.y >= best * 0.92:
		return 1
	# Otherwise pick the max axis.
	if sum.x >= sum.z:
		return 0
	return 2

func _mesh_cap_extents(mesh: Mesh, normal_axis: int, axis0: int, axis1: int, use_top: bool) -> Dictionary:
	# Robustly estimate the planar bounds of the top/bottom cap.
	# This is used to scale decor so the *visible cap* fills the cell, even if the mesh has beveled sides
	# or a wider underside. We avoid latching onto tiny outlier spikes by sampling a band near the cap.
	var out: Dictionary = {
		"valid": false,
		"size_w": 0.0,
		"size_d": 0.0,
		"center_w": 0.0,
		"center_d": 0.0,
		"plane_n": 0.0,
	}
	if mesh == null:
		return out

	# Cache per mesh + axis + cap side.
	var key := str(mesh.get_rid().get_id()) + ":" + str(normal_axis) + ":" + str(axis0) + ":" + str(axis1) + ":" + ("t" if use_top else "b")
	if _floor_mesh_cap_cache.has(key):
		return _floor_mesh_cap_cache[key]

	var verts: PackedVector3Array
	if mesh.get_surface_count() > 0:
		var arrays := mesh.surface_get_arrays(0)
		verts = arrays[Mesh.ARRAY_VERTEX]
	else:
		verts = PackedVector3Array()

	if verts.size() < 3:
		_floor_mesh_cap_cache[key] = out
		return out

	# Find min/max along the normal axis.
	var min_n := INF
	var max_n := -INF
	for p in verts:
		var nval := float(p[normal_axis])
		min_n = minf(min_n, nval)
		max_n = maxf(max_n, nval)

	var thickness := max_n - min_n
	# Sample a band near the cap instead of the single extreme plane.
	# This avoids tiny outlier spikes selecting a near-zero cap, which would explode scaling.
	var band := maxf(0.002, thickness * 0.06)  # 6% of thickness, min 2mm

	var lo: float = (max_n - band) if use_top else min_n
	var hi: float = max_n if use_top else (min_n + band)

	var min0 := INF
	var max0 := -INF
	var min1 := INF
	var max1 := -INF
	var found := 0

	for p in verts:
		var nval := float(p[normal_axis])
		if use_top:
			if nval < lo:
				continue
		else:
			if nval > hi:
				continue

		var a0 := float(p[axis0])
		var a1 := float(p[axis1])
		min0 = minf(min0, a0)
		max0 = maxf(max0, a0)
		min1 = minf(min1, a1)
		max1 = maxf(max1, a1)
		found += 1

	# Need enough points to represent an actual cap.
	if found < 3:
		_floor_mesh_cap_cache[key] = out
		return out

	var size_w := max0 - min0
	var size_d := max1 - min1

	# Reject pathological caps (near-zero planar size).
	if size_w <= 0.001 or size_d <= 0.001:
		_floor_mesh_cap_cache[key] = out
		return out

	out["valid"] = true
	out["size_w"] = size_w
	out["size_d"] = size_d
	out["center_w"] = (min0 + max0) * 0.5
	out["center_d"] = (min1 + max1) * 0.5
	# Anchor to the true extreme plane so the cap sits flush.
	out["plane_n"] = max_n if use_top else min_n

	_floor_mesh_cap_cache[key] = out
	return out


func _plane_axes_from_normal_axis(n_axis: int) -> PackedInt32Array:
	var axes := PackedInt32Array()
	for i in [0, 1, 2]:
		if i != n_axis:
			axes.append(i)
	return axes

func _safe_dim(x: float) -> float:
	return maxf(0.0001, absf(x))

func _pick_open_side_outward(face: WallFace) -> Vector3:
	var n := face.normal
	n.y = 0.0
	if n.length_squared() < 1e-8:
		return Vector3.FORWARD
	n = n.normalized()

	var probe: float = maxf(0.25, _cell_size * wall_decor_surface_probe_radius_cells)
	var center := face.center

	# Optional raycast (will only be meaningful if physics has the colliders registered this frame)
	if wall_decor_open_side_use_raycast:
		var eps := 0.05
		var open_f := _is_open_air_ray(center + n * eps, center + n * probe)
		var open_b := _is_open_air_ray(center - n * eps, center - n * probe)
		if open_f != open_b:
			return n if open_f else -n

	# Height fallback (use MIN-sampled top surface on each side)
	var p_plus := center + n * probe
	var p_minus := center - n * probe
	var h_plus := _sample_top_surface_y_wide(p_plus.x, p_plus.z, n, true)
	var h_minus := _sample_top_surface_y_wide(p_minus.x, p_minus.z, -n, true)

	# If one side has no surface at all, treat it as open
	if h_plus <= _NEG_INF * 0.5 and h_minus > _NEG_INF * 0.5:
		return n
	if h_minus <= _NEG_INF * 0.5 and h_plus > _NEG_INF * 0.5:
		return -n

	# If essentially equal, prefer pointing away from arena center (stable tie-break)
	if absf(h_plus - h_minus) < wall_decor_open_side_epsilon:
		var side: float = float(max(2, cells_per_side)) * _cell_size
		var map_center := Vector3(_ox + side * 0.5, center.y, _oz + side * 0.5)
		var to_center := map_center - center
		to_center.y = 0.0
		if to_center.length_squared() > 1e-8 and n.dot(to_center) > 0.0:
			return -n
		return n

	return n if h_plus < h_minus else -n

func _capture_floor_face(a: Vector3, b: Vector3, c: Vector3, d: Vector3, key: int) -> void:
	var n: Vector3 = (b - a).cross(d - a)
	if n.length() < 0.000001:
		return
	n = n.normalized()
	if n.y < 0.0:
		n = -n

	var center: Vector3 = (a + b + c + d) * 0.25
	if center.y < floor_decor_min_world_y:
		return

	var width: float = (b - a).length()
	var depth: float = (d - a).length()
	_floor_faces.append(FloorFace.new(a, b, c, d, center, n, width, depth, key))

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

func _get_arena_center_approx() -> Vector3:
	return global_position + Vector3(_ox + world_size_m * 0.5, 0.0, _oz + world_size_m * 0.5)

func _capture_wall_face(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	if not (enable_wall_decor or enable_wall_wedge_decor):
		return

	_wd_face_i += 1
	var fi: int = _wd_face_i

	var pts: Array[Vector3] = [a, b, c, d]
	pts.sort_custom(func(p: Vector3, q: Vector3) -> bool: return p.y < q.y)

	var lo0: Vector3 = pts[0]
	var lo1: Vector3 = pts[1]
	var hi0: Vector3 = pts[2]
	var hi1: Vector3 = pts[3]

	var lo0_xz := Vector2(lo0.x, lo0.z)
	var d0 := lo0_xz.distance_squared_to(Vector2(hi0.x, hi0.z))
	var d1 := lo0_xz.distance_squared_to(Vector2(hi1.x, hi1.z))

	var e0_lo := lo0
	var e0_hi: Vector3
	var e1_lo := lo1
	var e1_hi: Vector3

	if d0 <= d1:
		e0_hi = hi0
		e1_hi = hi1
	else:
		e0_hi = hi1
		e1_hi = hi0

	var span := (e1_lo - e0_lo)
	span.y = 0.0
	if span.length_squared() < 1e-10:
		span = (e1_hi - e0_hi)
		span.y = 0.0

	if span.length_squared() > 1e-10:
		var u := span.normalized()
		if e1_lo.dot(u) < e0_lo.dot(u):
			var tlo := e0_lo
			e0_lo = e1_lo
			e1_lo = tlo
			var thi := e0_hi
			e0_hi = e1_hi
			e1_hi = thi

	var aa := e0_lo
	var bb := e1_lo
	var cc := e1_hi
	var dd := e0_hi

	var uvec := bb - aa
	var vvec := dd - aa
	var n := uvec.cross(vvec)
	if n.length_squared() < 1e-10:
		return
	n = n.normalized()

	var center := (aa + bb + cc + dd) * 0.25
	var dir_h := Vector3(n.x, 0.0, n.z)
	if dir_h.length_squared() < 1e-8:
		if wall_decor_debug_verbose:
			_wd("SKIP fi=%d DEGENERATE_DIR center=%s n=%s" % [fi, _fmt_v3(center), _fmt_v3(n)])
		return
	dir_h = dir_h.normalized()

	var top_y: float = maxf(maxf(a.y, b.y), maxf(c.y, d.y))
	var bot_y: float = minf(minf(a.y, b.y), minf(c.y, d.y))
	var cov := _wall_face_covered_both_sides(center, top_y, dir_h)
	var below_surface: bool = false
	var h_side: float = _NEG_INF
	var p_side: Vector3 = Vector3.ZERO

	if wall_decor_debug_verbose and (fi % maxi(1, wall_decor_debug_print_every) == 0):
		_wd("CAP fi=%d center=%s n=%s top=%.3f bot=%.3f h_f=%.3f h_b=%.3f below_both=%s" % [fi, _fmt_v3(center), _fmt_v3(n), top_y, bot_y, float(cov["h_f"]), float(cov["h_b"]), str(bool(cov["covered"]))])

	# ---- NEW: keep only wall-ish faces for decor, and orient toward open air ----
	# Skip near-horizontal quads that can accidentally get captured as "walls".
	if abs(n.y) > wall_decor_max_abs_normal_y:
		if wall_decor_debug_verbose:
			_wd("SKIP fi=%d NEAR_HORIZONTAL n=%s" % [fi, _fmt_v3(n)])
		return

	var open_sy_f: float = INF
	var open_sy_b: float = INF
	if wall_decor_fix_open_side:
		# Open-side direction for decor placement (robust for large cell sizes).
		var dir := Vector3(n.x, 0.0, n.z)
		if dir.length_squared() > 1e-8:
			dir = dir.normalized()

			# IMPORTANT: probe must cross into the neighboring column.
			var probe := maxf(wall_decor_open_side_epsilon + 0.001, _cell_size * wall_decor_surface_probe_radius_cells)
			var chosen := "TIE"
			var cover_f: bool = bool(cov["cover_f"])
			var cover_b: bool = bool(cov["cover_b"])

			# Prefer uncovered side when only one side is covered.
			if cover_f and not cover_b:
				n = -dir
				chosen = "BACK"
			elif cover_b and not cover_f:
				n = dir
				chosen = "FWD"
			elif wall_decor_open_side_use_raycast:
				var eps: float = wall_decor_open_side_epsilon
				var f_from := center + dir * eps
				var b_from := center - dir * eps
				var open_f := _is_open_air_ray(f_from, f_from + dir * probe)
				var open_b := _is_open_air_ray(b_from, b_from - dir * probe)
				if wall_decor_debug_open_side:
					var extra := ""
					if wall_decor_debug_verbose:
						var to_f := f_from + dir * probe
						var to_b := b_from - dir * probe
						extra = " from_f=%s to_f=%s from_b=%s to_b=%s" % [_fmt_v3(f_from), _fmt_v3(to_f), _fmt_v3(b_from), _fmt_v3(to_b)]
					_wd("OPEN_RAY fi=%d dir=%s probe=%.3f open_f=%s open_b=%s mask=%d%s" % [fi, _fmt_v3(dir), probe, str(open_f), str(open_b), _wall_decor_open_side_effective_raycast_mask(), extra])

				if open_f and not open_b:
					n = dir
					chosen = "FWD"
				elif open_b and not open_f:
					n = -dir
					chosen = "BACK"
				else:
					# Raycast tie (both open or both blocked): fallback to height sampling.
					var h_f := _sample_top_surface_y_wide(center.x + dir.x * probe, center.z + dir.z * probe, dir, true)
					var h_b := _sample_top_surface_y_wide(center.x - dir.x * probe, center.z - dir.z * probe, -dir, true)
					open_sy_f = h_f
					open_sy_b = h_b
					n = dir if h_f < h_b else -dir
					chosen = "FWD" if h_f < h_b else "BACK"
					if wall_decor_debug_verbose and (fi % maxi(1, wall_decor_debug_print_every) == 0):
						_wd("OPEN_RAY_FALLBACK fi=%d h_f=%.3f h_b=%.3f chosen=%s" % [fi, h_f, h_b, chosen])
			else:
				var sy_f := _sample_top_surface_y_wide(center.x + dir.x * probe, center.z + dir.z * probe, dir, true)
				var sy_b := _sample_top_surface_y_wide(center.x - dir.x * probe, center.z - dir.z * probe, -dir, true)
				open_sy_f = sy_f
				open_sy_b = sy_b

				# Open side tends to have LOWER surface height (or -INF out of bounds).
				if sy_f < sy_b - 0.001:
					n = dir
					chosen = "FWD"
				elif sy_b < sy_f - 0.001:
					n = -dir
					chosen = "BACK"
				else:
					# Tie-break: choose the direction that points away from map center in XZ.
					var away := Vector3(center.x, 0.0, center.z).dot(dir) >= 0.0
					n = dir if away else -dir
					chosen = "FWD" if away else "BACK"

				if wall_decor_debug_verbose and (fi % maxi(1, wall_decor_debug_print_every) == 0):
					_wd("OPEN fi=%d dir=%s probe=%.3f h_f=%.3f h_b=%.3f chosen=%s" % [fi, _fmt_v3(dir), probe, sy_f, sy_b, chosen])
	# ---- END NEW ----

	if wall_decor_surface_only:
		p_side = center + n * (wall_decor_open_side_epsilon + 0.001)
		h_side = _wd_surface_only_ceiling_y_at(p_side)

		var p_center: Vector3 = center
		var h_center: float = _wd_surface_only_ceiling_y_at(p_center)

		# If either sample is invalid but the point is in bounds, dump why.
		if h_side <= _NEG_INF * 0.5 and _xz_in_bounds(p_side.x, p_side.z):
			_wd_dbg_sample(fi, "SURF_SIDE_INVALID", p_side, h_side)
		if h_center <= _NEG_INF * 0.5 and _xz_in_bounds(p_center.x, p_center.z):
			_wd_dbg_sample(fi, "SURF_CENTER_INVALID", p_center, h_center)

		var h_ceiling: float = maxf(h_side, h_center)
		below_surface = h_ceiling > top_y + wall_decor_surface_margin

		if wall_decor_debug_cov_details:
			_wd_fi(fi, "SURF_ONLY fi=%d top=%.3f h_side=%s h_center=%s h_ceiling=%s margin=%.3f below=%s p_side=%s n=%s" % [fi, top_y, str(h_side), str(h_center), str(h_ceiling), wall_decor_surface_margin, str(below_surface), str(p_side), str(n)])

	if below_surface:
		if wall_decor_debug_dump_under_surface:
			var h_center_dbg: float = _wd_surface_only_ceiling_y_at(center)
			_wd("SKIP fi=%d SURF_ONLY_CEILING top=%.3f h_side=%.3f h_center=%.3f h_f=%.3f h_b=%.3f probe=%.3f margin=%.3f p_side=%s center=%s n=%s" % [fi, top_y, h_side, h_center_dbg, float(cov["h_f"]), float(cov["h_b"]), float(cov["probe"]), float(cov["margin"]), _fmt_v3(p_side), _fmt_v3(center), _fmt_v3(n)])
		return

	if wall_decor_debug_verbose and (fi % maxi(1, wall_decor_debug_print_every) == 0):
		_wd("OUT fi=%d outward_final=%s offset=%.3f" % [fi, _fmt_v3(n), wall_decor_offset])

	if wall_decor_debug_log:
		var should_log := fi % maxi(wall_decor_debug_print_every, 1) == 0
		if wall_decor_debug_dump_under_surface and below_surface:
			should_log = true
		if should_log:
			var msg := "center=%s normal=%s y=[%.3f..%.3f] h_f=%.3f h_b=%.3f sy_f=%.3f sy_b=%.3f" % [
				_fmt_v3(center),
				_fmt_v3(n),
				bot_y,
				top_y,
				float(cov["h_f"]),
				float(cov["h_b"]),
				open_sy_f,
				open_sy_b
			]
			_wd(msg)

	var edge0 := dd - aa
	var edge1 := cc - bb
	var h0 := edge0.length()
	var h1 := edge1.length()
	var is_trap := absf(h0 - h1) > 0.01

	if maxf(h0, h1) < wall_decor_min_height:
		return

	var width := (bb - aa).length()
	var height := maxf(h0, h1)
	var key: int = _hash_wall_face(center, n)

	_wall_faces.append(WallFace.new(aa, bb, cc, dd, center, n, width, height, is_trap, key))

func _split_trapezoid_wall_face_for_decor(face: WallFace) -> Array:
	if not face.is_trapezoid:
		return [face, null]

	var e0_lo: Vector3 = face.a
	var e0_hi: Vector3 = face.d
	if e0_hi.y < e0_lo.y:
		var tmp := e0_lo
		e0_lo = e0_hi
		e0_hi = tmp

	var e1_lo: Vector3 = face.b
	var e1_hi: Vector3 = face.c
	if e1_hi.y < e1_lo.y:
		var tmp2 := e1_lo
		e1_lo = e1_hi
		e1_hi = tmp2

	var h0: float = (e0_hi - e0_lo).length()
	var h1: float = (e1_hi - e1_lo).length()
	var min_h: float = minf(h0, h1)

	if absf(h0 - h1) < 0.0001:
		return [face, null]

	var t0: float = clampf(min_h / maxf(h0, 0.0001), 0.0, 1.0)
	var t1: float = clampf(min_h / maxf(h1, 0.0001), 0.0, 1.0)

	var p0 := e0_lo.lerp(e0_hi, t0)
	var p1 := e1_lo.lerp(e1_hi, t1)

	var ra := e0_lo
	var rb := e1_lo
	var rc := p1
	var rd := p0

	var rcenter := (ra + rb + rc + rd) * 0.25
	var ru := rb - ra
	var rv := rd - ra
	var rn := face.normal
	var rwidth := ru.length()
	var rheight: float = maxf((rd - ra).length(), (rc - rb).length())
	var rkey := face.key ^ 0x51ED_0A11

	var rect_face := WallFace.new(ra, rb, rc, rd, rcenter, rn, rwidth, rheight, false, rkey)
	rect_face.normal = face.normal

	var wa := p0
	var wb := p1
	var wc := e1_hi
	var wd := e0_hi

	var wcenter: Vector3
	if wa == wd:
		wcenter = (wa + wb + wc) / 3.0
	elif wb == wc:
		wcenter = (wa + wb + wd) / 3.0
	else:
		wcenter = (wa + wb + wc + wd) * 0.25
	var wu := wb - wa
	var wv := wd - wa
	var wn := face.normal
	var wwidth := wu.length()
	var wheight: float = maxf((wd - wa).length(), (wc - wb).length())
	var wkey := face.key ^ 0xA7D3_19C3

	var wedge_face := WallFace.new(wa, wb, wc, wd, wcenter, wn, wwidth, wheight, true, wkey)
	wedge_face.normal = face.normal

	return [rect_face, wedge_face]

func _decor_global_aabb(pad: float = 2.0) -> AABB:
	var n: int = max(2, cells_per_side)
	var side := float(n) * _cell_size
	var half := side * 0.5
	var y0 := outer_floor_height
	var y1 := box_height
	return AABB(
		Vector3(-half - pad, y0 - pad, -half - pad),
		Vector3(side + pad * 2.0, (y1 - y0) + pad * 2.0, side + pad * 2.0)
	)

func _rebuild_wall_decor() -> void:
	var has_rect_decor: bool = enable_wall_decor and not wall_decor_meshes.is_empty()
	var wedge_meshes_left: Array[Mesh] = wall_wedge_decor_meshes_left
	var wedge_meshes_right: Array[Mesh] = wall_wedge_decor_meshes_right
	if wedge_meshes_left.is_empty() and not wall_wedge_decor_meshes.is_empty():
		wedge_meshes_left = wall_wedge_decor_meshes
	if wedge_meshes_right.is_empty() and not wall_wedge_decor_meshes.is_empty():
		wedge_meshes_right = wall_wedge_decor_meshes
	var wedge_variant_count: int = mini(wedge_meshes_left.size(), wedge_meshes_right.size())
	var has_wedge_decor: bool = enable_wall_wedge_decor and wedge_variant_count > 0
	if not has_rect_decor and not has_wedge_decor:
		if _wall_decor_root != null and is_instance_valid(_wall_decor_root):
			for child: Node in _wall_decor_root.get_children():
				child.queue_free()
		return

	_ensure_wall_decor_root()


	if wall_decor_debug_cov_details and not _wd_raycast_sanity_done:
		_wd_raycast_sanity_done = true

		var a := Vector3(0.0, 10000.0, 0.0)
		var b := Vector3(0.0, -10000.0, 0.0)
		var hit := _raycast_dbg(a, b, _wall_decor_open_side_effective_raycast_mask(), [], false)
		_wd("[WALL_DECOR] RAY_SANITY mask=%d hit=%s pos=%s collider=%s" % [_wall_decor_open_side_effective_raycast_mask(), str(not hit.is_empty()), str(hit.get("position", Vector3.ZERO)), str(hit.get("collider", null))])

	for child: Node in _wall_decor_root.get_children():
		child.queue_free()

	var rect_variant_count: int = wall_decor_meshes.size()
	var decor_aabb := _decor_global_aabb(4.0)

	var rect_counts: Array[int] = []
	rect_counts.resize(rect_variant_count)
	for i: int in range(rect_variant_count):
		rect_counts[i] = 0

	var wedge_counts_left: Array[int] = []
	var wedge_counts_right: Array[int] = []
	wedge_counts_left.resize(wedge_variant_count)
	wedge_counts_right.resize(wedge_variant_count)
	for i2: int in range(wedge_variant_count):
		wedge_counts_left[i2] = 0
		wedge_counts_right[i2] = 0

	var rect_faces: Array[WallFace] = []
	var wedge_faces: Array[WallFace] = []
	var dbg_wedge_total: int = 0
	var dbg_wedge_kept: int = 0
	var dbg_wedge_skip_trap: int = 0
	var dbg_wedge_skip_null_or_short: int = 0
	var dbg_wedge_skip_occluder_count: int = 0
	var dbg_wedge_skip_surface_count: int = 0
	var dbg_wedge_skip_allow_count: int = 0
	var dbg_wedge_skip_occluder_place: int = 0
	var dbg_wedge_skip_surface_place: int = 0
	var dbg_wedge_skip_allow_place: int = 0
	var dbg_wedge_skip_under_surface_place: int = 0
	var dbg_wedge_skip_variant_place: int = 0
	var dbg_rect_skip_surface_count: int = 0
	var dbg_rect_skip_surface_place: int = 0
	var trap_count: int = 0
	for face in _wall_faces:
		if face.is_trapezoid:
			trap_count += 1
			var parts := _split_trapezoid_wall_face_for_decor(face)
			var rect: WallFace = parts[0]
			var wedge: WallFace = parts[1]

			# Wall decor routing:
			if wall_decor_skip_trapezoids:
				# Keep only the rectangular under-ramp portion.
				if rect != null and rect.height >= wall_decor_min_height:
					rect_faces.append(rect)
			else:
				# Legacy/debug path: allow full trapezoid in wall decor.
				rect_faces.append(face)

			# Wedge decor routing:
			if wedge == null or wedge.height <= 0.0005:
				dbg_wedge_skip_null_or_short += 1
			elif wall_wedge_decor_skip_trapezoids:
				dbg_wedge_skip_trap += 1
			else:
				wedge_faces.append(wedge)
		else:
			rect_faces.append(face)
	print(
		"wall_faces:", _wall_faces.size(),
		" trapezoids:", trap_count,
		" rect_faces:", rect_faces.size(),
		" wedge_faces:", wedge_faces.size(),
		" wall_skip_trap:", wall_decor_skip_trapezoids,
		" wedge_skip_trap:", wall_wedge_decor_skip_trapezoids
	)
	if wall_decor_surface_only:
		_wd("[WD] surface_only active (rect skip counters populated in count/place passes)")

	if has_rect_decor:
		for f: WallFace in rect_faces:
			if wall_decor_skip_occluder_caps:
				if _wall_face_min_world_y(f) <= tunnel_occluder_y + wall_decor_occluder_epsilon:
					continue
			if _wall_face_min_world_y(f) < wall_decor_min_world_y:
				continue
			if wall_decor_max_size.x > 0.0 and f.width > wall_decor_max_size.x:
				continue
			if wall_decor_max_size.y > 0.0 and f.height > wall_decor_max_size.y:
				continue
			if wall_decor_surface_only:
				var max_y_count: float = _wall_face_max_world_y(f)
				if max_y_count > outer_floor_height + wall_decor_surface_margin:
					var cov_count := _wall_face_covered_both_sides(f.center, max_y_count, f.normal)
					if bool(cov_count["covered"]):
						dbg_rect_skip_surface_count += 1
						continue
			var idx: int = (f.key + wall_decor_seed) % rect_variant_count
			rect_counts[idx] += 1

	if has_wedge_decor:
		for wf: WallFace in wedge_faces:
			dbg_wedge_total += 1
			var place_outward_count: Vector3 = _wall_place_outward(wf).normalized()
			if wall_wedge_decor_flip_outward:
				place_outward_count = -place_outward_count
			if wall_wedge_decor_skip_occluder_caps:
				if _wall_face_min_world_y(wf) <= tunnel_occluder_y + wall_wedge_decor_occluder_epsilon:
					dbg_wedge_skip_occluder_count += 1
					continue # COUNT_PASS: SKIP_OCCLUDER_CAP
			if wall_decor_surface_only:
				var top_y := _wall_face_max_world_y(wf)
				var outward := place_outward_count

				var eps := maxf(wall_decor_open_side_epsilon, 0.001)
				var p_side := wf.center + outward * (eps + 0.001)

				var h_side := _wd_surface_only_ceiling_y_at(p_side)
				var h_center := _wd_surface_only_ceiling_y_at(wf.center)
				var h_ceiling := maxf(h_side, h_center)

				if h_ceiling > top_y + wall_decor_surface_margin:
					dbg_wedge_skip_surface_count += 1
					continue # COUNT_PASS: SKIP_SURFACE_ONLY
			if not _allow_wedge_decor_face(wf):
				dbg_wedge_skip_allow_count += 1
				continue # COUNT_PASS: SKIP_NOT_ALLOWED
			var widx: int = absi(wf.key + wall_wedge_decor_seed) % wedge_variant_count
			if _wedge_is_right_side_outward(wf, place_outward_count):
				wedge_counts_right[widx] += 1
			else:
				wedge_counts_left[widx] += 1

	var rect_mmi_by_variant: Array[MultiMeshInstance3D] = []
	rect_mmi_by_variant.resize(rect_variant_count)

	var rect_aabb_by_variant: Array[AABB] = []
	rect_aabb_by_variant.resize(rect_variant_count)

	for v: int in range(rect_variant_count):
		if rect_counts[v] <= 0:
			rect_mmi_by_variant[v] = null
			continue

		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = wall_decor_meshes[v]
		mm.instance_count = rect_counts[v]

		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.custom_aabb = decor_aabb

		_wall_decor_root.add_child(mmi)
		rect_mmi_by_variant[v] = mmi
		rect_aabb_by_variant[v] = wall_decor_meshes[v].get_aabb()

	var wedge_mmi_left_by_variant: Array[MultiMeshInstance3D] = []
	var wedge_mmi_right_by_variant: Array[MultiMeshInstance3D] = []
	wedge_mmi_left_by_variant.resize(wedge_variant_count)
	wedge_mmi_right_by_variant.resize(wedge_variant_count)

	var wedge_aabb_left_by_variant: Array[AABB] = []
	var wedge_aabb_right_by_variant: Array[AABB] = []
	wedge_aabb_left_by_variant.resize(wedge_variant_count)
	wedge_aabb_right_by_variant.resize(wedge_variant_count)

	for wv: int in range(wedge_variant_count):
		if wedge_counts_left[wv] > 0:
			var wmm_left: MultiMesh = MultiMesh.new()
			wmm_left.transform_format = MultiMesh.TRANSFORM_3D
			wmm_left.mesh = wedge_meshes_left[wv]
			wmm_left.instance_count = wedge_counts_left[wv]

			var wmmi_left: MultiMeshInstance3D = MultiMeshInstance3D.new()
			wmmi_left.multimesh = wmm_left
			wmmi_left.custom_aabb = decor_aabb

			_wall_decor_root.add_child(wmmi_left)
			wedge_mmi_left_by_variant[wv] = wmmi_left
			wedge_aabb_left_by_variant[wv] = wedge_meshes_left[wv].get_aabb()
		else:
			wedge_mmi_left_by_variant[wv] = null

		if wedge_counts_right[wv] > 0:
			var wmm_right: MultiMesh = MultiMesh.new()
			wmm_right.transform_format = MultiMesh.TRANSFORM_3D
			wmm_right.mesh = wedge_meshes_right[wv]
			wmm_right.instance_count = wedge_counts_right[wv]

			var wmmi_right: MultiMeshInstance3D = MultiMeshInstance3D.new()
			wmmi_right.multimesh = wmm_right
			wmmi_right.custom_aabb = decor_aabb

			_wall_decor_root.add_child(wmmi_right)
			wedge_mmi_right_by_variant[wv] = wmmi_right
			wedge_aabb_right_by_variant[wv] = wedge_meshes_right[wv].get_aabb()
		else:
			wedge_mmi_right_by_variant[wv] = null

	var rect_write_i: Array[int] = []
	rect_write_i.resize(rect_variant_count)
	for v2: int in range(rect_variant_count):
		rect_write_i[v2] = 0

	var wedge_write_left_i: Array[int] = []
	var wedge_write_right_i: Array[int] = []
	wedge_write_left_i.resize(wedge_variant_count)
	wedge_write_right_i.resize(wedge_variant_count)
	for wv2: int in range(wedge_variant_count):
		wedge_write_left_i[wv2] = 0
		wedge_write_right_i[wv2] = 0

	var total_rect_instances: int = 0
	for count in rect_counts:
		total_rect_instances += count
	if has_rect_decor and total_rect_instances <= 0:
		push_warning("Wall decor: 0 rectangular instances after filtering. Check max size.")

	var total_wedge_instances: int = 0
	for wvi: int in range(wedge_variant_count):
		total_wedge_instances += wedge_counts_left[wvi] + wedge_counts_right[wvi]
	if has_wedge_decor and total_wedge_instances <= 0:
		push_warning("Wall decor: 0 wedge instances after filtering. Check max size.")

	if has_rect_decor:
		var placement_fi: int = 0
		for f2: WallFace in rect_faces:
			placement_fi += 1
			if wall_decor_skip_occluder_caps:
				if _wall_face_min_world_y(f2) <= tunnel_occluder_y + wall_decor_occluder_epsilon:
					continue
			if _wall_face_min_world_y(f2) < wall_decor_min_world_y:
				continue
			if wall_decor_max_size.x > 0.0 and f2.width > wall_decor_max_size.x:
				continue
			if wall_decor_max_size.y > 0.0 and f2.height > wall_decor_max_size.y:
				continue
			var vsel: int = (f2.key + wall_decor_seed) % rect_variant_count
			var mmi2: MultiMeshInstance3D = rect_mmi_by_variant[vsel]
			if mmi2 == null:
				continue

			var aabb: AABB = rect_aabb_by_variant[vsel]
			var xf: Transform3D = _decor_transform_for_face(f2, aabb, wall_decor_offset)
			var outward := _wall_place_outward(f2)
			var top_y: float = maxf(maxf(f2.a.y, f2.b.y), maxf(f2.c.y, f2.d.y))
			var cov_p := _wall_face_covered_both_sides(f2.center, top_y, outward)
			var under_now: bool = bool(cov_p["covered"])

			# --- extra under-map diagnostics ---
			if wall_decor_debug_dump_under_surface and wall_decor_debug_cov_details:
				# local surface directly above this wall face (independent of outward choice)
				var h_here := _sample_top_surface_y_wide(f2.center.x, f2.center.z, Vector3.ZERO, true)
				var under_local := (h_here > top_y + wall_decor_surface_margin)

				if under_local and not under_now:
					var n_dir := f2.normal
					n_dir.y = 0.0
					if n_dir.length() < 0.001:
						n_dir = outward
					else:
						n_dir = n_dir.normalized()

					var cov_n := _wall_face_covered_both_sides(f2.center, top_y, n_dir)

					_wd_fi(placement_fi,
						"UNDER_LOCAL_BUT_NOT_COVERED fi=%d top=%.3f h_here=%.3f depth=%.3f center=%s "
						% [placement_fi, top_y, h_here, (h_here - top_y), _fmt_v3(f2.center)]
						+ "outward=%s cov_out(covered=%s hf=%.3f hb=%.3f valid_f=%s valid_b=%s) "
						% [_fmt_v3(outward), str(under_now), float(cov_p["h_f"]), float(cov_p["h_b"]), str(cov_p["valid_f"]), str(cov_p["valid_b"])]
						+ "cov_norm(covered=%s hf=%.3f hb=%.3f valid_f=%s valid_b=%s) n=%s"
						% [str(cov_n["covered"]), float(cov_n["h_f"]), float(cov_n["h_b"]), str(cov_n["valid_f"]), str(cov_n["valid_b"]), _fmt_v3(f2.normal)]
					)
			# --- end diagnostics ---

			if wall_decor_surface_only and top_y > outer_floor_height + wall_decor_surface_margin and under_now:
				dbg_rect_skip_surface_place += 1
				_wd("SKIP PLACED_UNDER fi=%d top=%.3f h_f=%.3f h_b=%.3f probe=%.3f margin=%.3f center=%s n=%s" % [placement_fi, top_y, float(cov_p["h_f"]), float(cov_p["h_b"]), float(cov_p["probe"]), float(cov_p["margin"]), _fmt_v3(f2.center), _fmt_v3(f2.normal)])
				continue

			var wi: int = rect_write_i[vsel]
			mmi2.multimesh.set_instance_transform(wi, xf)
			rect_write_i[vsel] = wi + 1

	if has_wedge_decor:
		var wedge_place_fi: int = 0
		for wf2: WallFace in wedge_faces:
			wedge_place_fi += 1
			var place_outward: Vector3 = _wall_place_outward(wf2).normalized()
			if wall_wedge_decor_flip_outward:
				place_outward = -place_outward
			if wall_wedge_decor_skip_occluder_caps:
				if _wall_face_min_world_y(wf2) <= tunnel_occluder_y + wall_wedge_decor_occluder_epsilon:
					dbg_wedge_skip_occluder_place += 1
					continue # PLACE_PASS: SKIP_OCCLUDER_CAP
			if wall_decor_surface_only:
				var top_y := _wall_face_max_world_y(wf2)
				var outward := place_outward

				var eps := maxf(wall_decor_open_side_epsilon, 0.001)
				var p_side := wf2.center + outward * (eps + 0.001)

				var h_side := _wd_surface_only_ceiling_y_at(p_side)
				var h_center := _wd_surface_only_ceiling_y_at(wf2.center)
				var h_ceiling := maxf(h_side, h_center)

				if h_ceiling > top_y + wall_decor_surface_margin:
					dbg_wedge_skip_surface_place += 1
					continue # PLACE_PASS: SKIP_SURFACE_ONLY
			if not _allow_wedge_decor_face(wf2):
				dbg_wedge_skip_allow_place += 1
				continue # PLACE_PASS: SKIP_NOT_ALLOWED
			var wsel: int = absi(wf2.key + wall_wedge_decor_seed) % wedge_variant_count
			var side_is_right: bool = _wedge_is_right_side_outward(wf2, place_outward)
			var wmmi2: MultiMeshInstance3D = wedge_mmi_right_by_variant[wsel] if side_is_right else wedge_mmi_left_by_variant[wsel]
			if wmmi2 == null:
				dbg_wedge_skip_variant_place += 1
				continue # PLACE_PASS: SKIP_NO_VARIANT_MM

			var waabb: AABB = wedge_aabb_right_by_variant[wsel] if side_is_right else wedge_aabb_left_by_variant[wsel]
			var overhang_flip_180: bool = wall_wedge_decor_enable_overhang_flip_180 and wf2.is_trapezoid
			if wall_decor_debug_verbose and (wall_decor_debug_focus_fi < 0 or wall_decor_debug_focus_fi == wedge_place_fi):
				var n_cells_dbg: int = max(2, cells_per_side)
				var probe_step_dbg: float = _cell_size * 0.25
				var c_in_dbg: Vector2i = _world_to_cell_xz(wf2.center - place_outward * probe_step_dbg, n_cells_dbg)
				var c_out_dbg: Vector2i = _world_to_cell_xz(wf2.center + place_outward * probe_step_dbg, n_cells_dbg)
				var ramp_in_dbg: bool = _cell_is_ramp(c_in_dbg.x, c_in_dbg.y, n_cells_dbg)
				var ramp_out_dbg: bool = _cell_is_ramp(c_out_dbg.x, c_out_dbg.y, n_cells_dbg)
				_wd("[WEDGE] fi=%d key=%d center=%s place_outward=%s side=%s flip_outward=%s attach_far=%s flip_facing=%s overhang_flip_180=%s ramp_in/out=%s/%s c_in=%s c_out=%s a=%s b=%s c=%s d=%s" % [wedge_place_fi, wf2.key, _fmt_v3(wf2.center), _fmt_v3(place_outward), ("R" if side_is_right else "L"), str(wall_wedge_decor_flip_outward), str(wall_wedge_decor_attach_far_side), str(wall_wedge_decor_flip_facing), str(overhang_flip_180), str(ramp_in_dbg), str(ramp_out_dbg), str(c_in_dbg), str(c_out_dbg), _fmt_v3(wf2.a), _fmt_v3(wf2.b), _fmt_v3(wf2.c), _fmt_v3(wf2.d)])
			var under_floor_margin: float = maxf(0.25, height_step * 0.25)
			if wf2.center.y < outer_floor_height - under_floor_margin:
				dbg_wedge_skip_under_surface_place += 1
				continue
			var wxf: Transform3D = _decor_transform_for_wedge_face(wf2, waabb, place_outward, wall_wedge_decor_offset, wall_wedge_decor_attach_far_side, overhang_flip_180)

			var wwi: int = wedge_write_right_i[wsel] if side_is_right else wedge_write_left_i[wsel]
			wmmi2.multimesh.set_instance_transform(wwi, wxf)
			if side_is_right:
				wedge_write_right_i[wsel] = wwi + 1
			else:
				wedge_write_left_i[wsel] = wwi + 1
			dbg_wedge_kept += 1


	if has_rect_decor:
		for v3: int in range(rect_variant_count):
			var rect_mmi: MultiMeshInstance3D = rect_mmi_by_variant[v3]
			if rect_mmi == null:
				continue
			rect_mmi.multimesh.visible_instance_count = rect_write_i[v3]

	if has_wedge_decor:
		for wv3: int in range(wedge_variant_count):
			var wedge_mmi_left: MultiMeshInstance3D = wedge_mmi_left_by_variant[wv3]
			if wedge_mmi_left != null:
				wedge_mmi_left.multimesh.visible_instance_count = wedge_write_left_i[wv3]
			var wedge_mmi_right: MultiMeshInstance3D = wedge_mmi_right_by_variant[wv3]
			if wedge_mmi_right != null:
				wedge_mmi_right.multimesh.visible_instance_count = wedge_write_right_i[wv3]
		print("wedge_dbg total=%d kept=%d skip_trap=%d skip_null_or_short=%d count(occluder=%d,surface=%d,allow=%d) place(occluder=%d,surface=%d,allow=%d,under=%d,variant=%d)" % [
			dbg_wedge_total,
			dbg_wedge_kept,
			dbg_wedge_skip_trap,
			dbg_wedge_skip_null_or_short,
			dbg_wedge_skip_occluder_count,
			dbg_wedge_skip_surface_count,
			dbg_wedge_skip_allow_count,
			dbg_wedge_skip_occluder_place,
			dbg_wedge_skip_surface_place,
			dbg_wedge_skip_allow_place,
			dbg_wedge_skip_under_surface_place,
			dbg_wedge_skip_variant_place
		])

func _wedge_is_right_side(wf: WallFace) -> bool:
	var avg_left: float = 0.5 * (wf.a.y + wf.d.y)
	var avg_right: float = 0.5 * (wf.b.y + wf.c.y)
	return avg_right > avg_left

func _wedge_is_right_side_outward(wf: WallFace, outward: Vector3) -> bool:
	var z: Vector3 = Vector3(outward.x, 0.0, outward.z)
	if z.length_squared() < 1e-8:
		z = Vector3(wf.normal.x, 0.0, wf.normal.z)
	if z.length_squared() < 1e-8:
		return _wedge_is_right_side(wf)
	z = z.normalized()

	var right: Vector3 = Vector3.UP.cross(z)
	if right.length_squared() < 1e-8:
		return _wedge_is_right_side(wf)
	right = right.normalized()

	var center: Vector3 = wf.center
	var verts: Array[Vector3] = [wf.a, wf.b, wf.c, wf.d]

	var tmin: float = INF
	var tmax: float = -INF
	for v in verts:
		var t: float = (v - center).dot(right)
		tmin = minf(tmin, t)
		tmax = maxf(tmax, t)

	var ext: float = tmax - tmin
	if ext < 1e-4:
		return _wedge_is_right_side(wf)

	var band: float = ext * 0.25
	var y_lo: float = 0.0
	var y_hi: float = 0.0
	var n_lo: int = 0
	var n_hi: int = 0

	for v2 in verts:
		var t2: float = (v2 - center).dot(right)
		if t2 <= tmin + band:
			y_lo += v2.y
			n_lo += 1
		if t2 >= tmax - band:
			y_hi += v2.y
			n_hi += 1

	if n_lo == 0 or n_hi == 0:
		return _wedge_is_right_side(wf)

	y_lo /= float(n_lo)
	y_hi /= float(n_hi)
	return y_hi > y_lo

func _world_to_cell_xz(p: Vector3, n: int) -> Vector2i:
	var cx: int = int(floor((p.x - _ox) / _cell_size))
	var cz: int = int(floor((p.z - _oz) / _cell_size))
	cx = clamp(cx, 0, n - 1)
	cz = clamp(cz, 0, n - 1)
	return Vector2i(cx, cz)

func _cell_is_ramp(cx: int, cz: int, n: int) -> bool:
	if not _in_bounds(cx, cz, n):
		return false
	if _ramp_up_dir.size() != n * n:
		return false
	return _ramp_up_dir[_idx2(cx, cz, n)] != RAMP_NONE

func _allow_wedge_decor_face(face: WallFace) -> bool:
	# Note: wedge decor filtering must rely on wedge-specific settings only.
	if _wall_face_min_world_y(face) < wall_wedge_decor_min_world_y:
		return false
	if wall_wedge_decor_max_size.x > 0.0 and face.width > wall_wedge_decor_max_size.x:
		return false
	if wall_wedge_decor_max_size.y > 0.0 and face.height > wall_wedge_decor_max_size.y:
		return false
	return true

func _wall_place_outward(face: WallFace) -> Vector3:
	var outward: Vector3 = face.normal
	outward.y = 0.0
	if outward.length_squared() < 1e-8:
		outward = Vector3.FORWARD
	outward = outward.normalized()
	if wall_decor_fix_open_side:
		var top_y: float = maxf(maxf(face.a.y, face.b.y), maxf(face.c.y, face.d.y))
		var cov := _wall_face_covered_both_sides(face.center, top_y, outward)
		var cover_f: bool = bool(cov["cover_f"])
		var cover_b: bool = bool(cov["cover_b"])
		if cover_f and not cover_b:
			outward = -outward
		elif cover_b and not cover_f:
			outward = outward
		else:
			outward = _pick_open_side_outward(face)
	return outward

func _rebuild_shaft_wall_decor() -> void:
	_shaft_decor_faces = 0
	_shaft_decor_instances = 0

	var has_decor: bool = enable_wall_decor and not wall_decor_meshes.is_empty() and tunnel_shaft_decor_density > 0.0
	if not has_decor:
		if _shaft_decor_root != null and is_instance_valid(_shaft_decor_root):
			for child: Node in _shaft_decor_root.get_children():
				child.queue_free()
		return

	_ensure_shaft_decor_root()
	if _shaft_decor_root == null or not is_instance_valid(_shaft_decor_root):
		return

	for child: Node in _shaft_decor_root.get_children():
		child.queue_free()

	if _shaft_faces.is_empty():
		return

	var variant_count: int = wall_decor_meshes.size()
	var counts: Array[int] = []
	counts.resize(variant_count)
	for i: int in range(variant_count):
		counts[i] = 0

	# Even spacing along the shaft: density maps to a vertical step in cell-sized segments.
	var dens: float = clampf(tunnel_shaft_decor_density, 0.0, 1.0)
	var step: int = 1
	if dens > 0.0:
		step = max(1, int(round(1.0 / dens)))

	# First pass: count how many instances each mesh variant will need.
	for f: WallFace in _shaft_faces:
		var outward: Vector3 = _wall_place_outward(f)
		var side_idx: int = 0
		if absf(outward.x) > absf(outward.z):
			side_idx = 0 if outward.x > 0.0 else 1
		else:
			side_idx = 2 if outward.z > 0.0 else 3
		var y_idx: int = int(floor((f.center.y - tunnel_floor_y) / maxf(_cell_size, 0.001) + 0.5))
		if ((y_idx + side_idx) % step) != 0:
			continue

		_shaft_decor_faces += 1
		var idx: int = (f.key + wall_decor_seed) % variant_count
		counts[idx] += 1

	var mmi_by_variant: Array[MultiMeshInstance3D] = []
	mmi_by_variant.resize(variant_count)

	var aabb_by_variant: Array[AABB] = []
	aabb_by_variant.resize(variant_count)

	var decor_aabb := _decor_global_aabb(4.0)

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
		mmi.custom_aabb = decor_aabb

		_shaft_decor_root.add_child(mmi)
		mmi_by_variant[v] = mmi
		aabb_by_variant[v] = wall_decor_meshes[v].get_aabb()

	var write_i: Array[int] = []
	write_i.resize(variant_count)
	for v2: int in range(variant_count):
		write_i[v2] = 0

	# Second pass: write transforms.
	for f2: WallFace in _shaft_faces:
		var outward2: Vector3 = _wall_place_outward(f2)
		var side_idx2: int = 0
		if absf(outward2.x) > absf(outward2.z):
			side_idx2 = 0 if outward2.x > 0.0 else 1
		else:
			side_idx2 = 2 if outward2.z > 0.0 else 3
		var y_idx2: int = int(floor((f2.center.y - tunnel_floor_y) / maxf(_cell_size, 0.001) + 0.5))
		if ((y_idx2 + side_idx2) % step) != 0:
			continue

		var idx2: int = (f2.key + wall_decor_seed) % variant_count
		var mmi2 := mmi_by_variant[idx2]
		if mmi2 == null:
			continue

		var aabb: AABB = aabb_by_variant[idx2]
		var xf: Transform3D = _decor_transform_for_face_with_outward(f2, aabb, wall_decor_offset, f2.normal)

		var mm2: MultiMesh = mmi2.multimesh
		var wi: int = write_i[idx2]
		mm2.set_instance_transform(wi, xf)
		write_i[idx2] = wi + 1
		_shaft_decor_instances += 1

	if dbg_tunnels:
		_dbg_tunnel("shaft_decor_faces=%d shaft_decor_instances=%d" % [_shaft_decor_faces, _shaft_decor_instances])


func _decor_transform_for_face(face: WallFace, aabb: AABB, outward_offset: float) -> Transform3D:
	var outward: Vector3 = _wall_place_outward(face)

	var place_dir := outward
	var fwd_dir := place_dir
	if wall_decor_flip_facing:
		fwd_dir = -fwd_dir

	var rot: Basis = _basis_from_outward(fwd_dir)

	var attach_far: bool = wall_decor_attach_far_side
	if wall_decor_flip_facing:
		rot = Basis(Vector3.UP, PI) * rot
		attach_far = not attach_far

	var ref_w: float = max(aabb.size.x, 0.001)
	var ref_h: float = max(aabb.size.y, 0.001)
	var sx: float = 1.0
	var sy: float = 1.0
	if wall_decor_fit_to_face:
		sx = max(face.width / ref_w, 0.1)
		sy = max(face.height / ref_h, 0.1)
		if wall_decor_max_scale > 0.0:
			sx = min(sx, wall_decor_max_scale)
			sy = min(sy, wall_decor_max_scale)
	var sz: float = wall_decor_depth_scale

	var decor_basis := Basis(rot.x * sx, rot.y * sy, rot.z * sz)

	var center_x: float = aabb.position.x + aabb.size.x * 0.5
	var center_y: float = aabb.position.y + aabb.size.y * 0.5
	var z_min: float = aabb.position.z
	var z_max: float = aabb.position.z + aabb.size.z
	var attach_z: float = z_max if attach_far else z_min
	var anchor_local := Vector3(center_x, center_y, attach_z)

	var target_world: Vector3 = face.center + place_dir * outward_offset
	var origin: Vector3 = target_world - (decor_basis * anchor_local)
	return Transform3D(decor_basis, origin)

func _decor_transform_for_wedge_face(face: WallFace, aabb: AABB, place_outward: Vector3, outward_offset: float, attach_far_in: bool, overhang_flip_180: bool = false) -> Transform3D:
	var outward: Vector3 = place_outward
	outward.y = 0.0
	if outward.length_squared() < 1e-8:
		outward = Vector3(face.normal.x, 0.0, face.normal.z)
		if outward.length_squared() < 1e-8:
			outward = Vector3.FORWARD
	outward = outward.normalized()

	# Build a stable frame:
	# z_dir = outward (horizontal), x_dir = horizontal perpendicular to outward, y_dir orthonormal.
	var z_dir: Vector3 = outward
	z_dir.y = 0.0
	if z_dir.length_squared() < 1e-8:
		z_dir = Vector3(face.normal.x, 0.0, face.normal.z)
	if z_dir.length_squared() < 1e-8:
		z_dir = Vector3.FORWARD
	z_dir = z_dir.normalized()

	var x_dir: Vector3 = Vector3.UP.cross(z_dir)
	if x_dir.length_squared() < 1e-8:
		x_dir = Vector3.RIGHT
	x_dir = x_dir.normalized()

	var y_dir: Vector3 = z_dir.cross(x_dir).normalized()
	x_dir = y_dir.cross(z_dir).normalized()

	var rot: Basis = Basis(x_dir, y_dir, z_dir).orthonormalized()

	var attach_far: bool = attach_far_in
	var yaw_flip: bool = wall_wedge_decor_flip_facing
	if overhang_flip_180:
		yaw_flip = !yaw_flip

	var ref_w: float = max(aabb.size.x, 0.001)
	var ref_h: float = max(aabb.size.y, 0.001)
	var sx: float = 1.0
	var sy: float = 1.0
	if wall_wedge_decor_fit_to_face:
		sx = max(face.width / ref_w, 0.1)
		sy = max(face.height / ref_h, 0.1)
		if wall_wedge_decor_max_scale > 0.0:
			sx = min(sx, wall_wedge_decor_max_scale)
			sy = min(sy, wall_wedge_decor_max_scale)
	# Depth (thickness) along the outward axis (mesh local Z).
	var sz: float = wall_wedge_decor_depth_scale
	if wall_wedge_decor_max_depth_cells > 0.0:
		var max_world: float = _cell_size * wall_wedge_decor_max_depth_cells
		var ref_z: float = maxf(aabb.size.z, 0.001)
		var max_scale: float = max_world / ref_z
		sz = minf(sz, max_scale)
	sz = maxf(sz, 0.001)

	var decor_basis := Basis(rot.x * sx, rot.y * sy, rot.z * sz)
	if yaw_flip:
		decor_basis = Basis(Vector3.UP, PI) * decor_basis
		attach_far = !attach_far

	var center_x: float = aabb.position.x + aabb.size.x * 0.5
	var center_y: float = aabb.position.y + aabb.size.y * 0.5
	var z_min: float = aabb.position.z
	var z_max: float = aabb.position.z + aabb.size.z
	var attach_z: float = z_max if attach_far else z_min
	var anchor_local := Vector3(center_x, center_y, attach_z)

	var target_world: Vector3 = face.center + outward * outward_offset
	var origin: Vector3 = target_world - (decor_basis * anchor_local)
	return Transform3D(decor_basis, origin)

func _decor_transform_for_face_with_outward(face: WallFace, aabb: AABB, outward_offset: float, outward: Vector3) -> Transform3D:
	# Like _decor_transform_for_face(), but uses an explicit outward direction
	# (used for shaft interiors where we want decor to face inward).
	var place_dir := outward
	place_dir.y = 0.0
	if place_dir.length_squared() < 1e-8:
		place_dir = Vector3(face.normal.x, 0.0, face.normal.z)
	if place_dir.length_squared() < 1e-8:
		place_dir = Vector3.FORWARD
	place_dir = place_dir.normalized()

	var fwd_dir := place_dir
	if wall_decor_flip_facing:
		fwd_dir = -fwd_dir

	var rot: Basis = _basis_from_outward(fwd_dir)

	var attach_far: bool = wall_decor_attach_far_side
	if wall_decor_flip_facing:
		rot = Basis(Vector3.UP, PI) * rot
		attach_far = not attach_far

	var ref_w: float = max(aabb.size.x, 0.001)
	var ref_h: float = max(aabb.size.y, 0.001)
	var sx: float = 1.0
	var sy: float = 1.0
	if wall_decor_fit_to_face:
		sx = max(face.width / ref_w, 0.1)
		sy = max(face.height / ref_h, 0.1)
		if wall_decor_max_scale > 0.0:
			sx = min(sx, wall_decor_max_scale)
			sy = min(sy, wall_decor_max_scale)
	var sz: float = wall_decor_depth_scale

	var decor_basis := Basis(rot.x * sx, rot.y * sy, rot.z * sz)

	var center_x: float = aabb.position.x + aabb.size.x * 0.5
	var center_y: float = aabb.position.y + aabb.size.y * 0.5
	var z_min: float = aabb.position.z
	var z_max: float = aabb.position.z + aabb.size.z
	var attach_z: float = z_max if attach_far else z_min
	var anchor_local := Vector3(center_x, center_y, attach_z)

	var target_world: Vector3 = face.center + place_dir * outward_offset
	var origin: Vector3 = target_world - (decor_basis * anchor_local)
	return Transform3D(decor_basis, origin)


func _dominant_plane_axes(normal_axis: int) -> PackedInt32Array:
	# Returns the two axis indices that form the plane perpendicular to normal_axis.
	match normal_axis:
		0:
			return PackedInt32Array([1, 2])
		1:
			return PackedInt32Array([0, 2])
		2:
			return PackedInt32Array([0, 1])
		_:
			return PackedInt32Array([0, 2])

func _floor_transform_for_face(face: FloorFace, mesh: Mesh) -> Transform3D:
	if mesh == null:
		return Transform3D()

	var aabb: AABB = mesh.get_aabb()
	var edge_u: Vector3 = face.b - face.a
	var edge_v: Vector3 = face.d - face.a
	var u: Vector3 = edge_u.normalized()
	# Surface normal (always biased upward so "above" is consistent)
	var face_n: Vector3 = edge_u.cross(edge_v).normalized()
	if face_n.y < 0.0:
		face_n = -face_n
	var v: Vector3 = face_n.cross(u).normalized()
	u = v.cross(face_n).normalized()

	# Deterministic random yaw per-cell (for variety)
	var yaw: float = 0.0
	if floor_decor_random_yaw_steps > 0:
		var n_cells: int = max(2, cells_per_side)
		var cx: int = int(face.key) % n_cells
		var cz: int = int(face.key) / n_cells
		var h: int = (cx * 73856093) ^ (cz * 19349663) ^ int(floor_decor_seed * 83492791)
		h = (h ^ (h >> 13)) * 1274126177
		var steps: int = max(1, floor_decor_random_yaw_steps)
		var step: int = absi(h) % steps
		yaw = float(step) * (TAU / float(steps))
	if absf(yaw) > 0.00001:
		u = u.rotated(face_n, yaw)
		v = v.rotated(face_n, yaw)

	# Determine which mesh axis is the plane normal (thin axis)
	var axis_thin: int = 1
	var thx: float = absf(aabb.size.x)
	var thy: float = absf(aabb.size.y)
	var thz: float = absf(aabb.size.z)
	var min_th: float = minf(thx, minf(thy, thz))

	# Only accept "thin Y" if it's clearly the minimum.
	# If everything is similar, fall back to "dominant normal" inference.
	var thin_ratio_xy: float = (thy + 1e-6) / (thx + 1e-6)
	var thin_ratio_zy: float = (thy + 1e-6) / (thz + 1e-6)
	if thy <= min_th * 1.05 and thin_ratio_xy < 0.6 and thin_ratio_zy < 0.6:
		axis_thin = 1
	elif thx <= min_th * 1.05:
		axis_thin = 0
	elif thz <= min_th * 1.05:
		axis_thin = 2
	else:
		# Fallback: use dominant normal from geometry; bias toward Y to avoid sideways scaling.
		# If the face is close to flat, prefer Y.
		if absf(face_n.y) >= 0.75:
			axis_thin = 1
		else:
			# Pick the axis most aligned with the face normal.
			var an: Vector3 = Vector3(absf(face_n.x), absf(face_n.y), absf(face_n.z))
			if an.x >= an.y and an.x >= an.z:
				axis_thin = 0
			elif an.z >= an.y:
				axis_thin = 2
			else:
				axis_thin = 1

	# Optional override: which mesh axis represents the mesh normal.
	# Useful for Blender-authored planes where normal is +Z.
	if floor_decor_mesh_normal_axis >= 0 and floor_decor_mesh_normal_axis <= 2:
		axis_thin = floor_decor_mesh_normal_axis
	var normal_axis: int = axis_thin
	var plane_axes: PackedInt32Array = _dominant_plane_axes(normal_axis)
	var axis0: int = plane_axes[0]
	var axis1: int = plane_axes[1]

	# Pick which local axes map to u/v by matching aspect ratios
	var face_w: float = edge_u.length()
	var face_d: float = edge_v.length()
	if floor_decor_scale_in_xz:
		# Use horizontal footprint lengths so ramps don't inflate scale
		face_w = Vector2(edge_u.x, edge_u.z).length()
		face_d = Vector2(edge_v.x, edge_v.z).length()
	if floor_decor_fit_to_cell:
		face_w = _cell_size
		face_d = _cell_size
	var long_face: float = maxf(face_w, face_d)
	var short_face: float = maxf(0.0001, minf(face_w, face_d))
	var face_ratio: float = long_face / short_face
	var a0: float = absf(aabb.size[axis0])
	var a1: float = absf(aabb.size[axis1])
	if a0 < 0.0001 or a1 < 0.0001:
		# degenerate, default mapping
		pass
	var a_long: float = maxf(a0, a1)
	var a_short: float = maxf(0.0001, minf(a0, a1))
	var a_ratio: float = a_long / a_short
	var swap_axes: bool = false
	# If ratios are closer when swapped, swap.
	var diff_keep: float = absf(face_ratio - a_ratio)
	var diff_swap: float = absf(face_ratio - (1.0 / a_ratio))
	if diff_swap + 1e-6 < diff_keep:
		swap_axes = true

	var width_axis: int = axis0 if not swap_axes else axis1
	var depth_axis: int = axis1 if not swap_axes else axis0

	# Build basis columns (map chosen local axes to u/v/normal)
	var cols: Array = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var basis_n: Vector3 = face_n
	if floor_decor_flip_facing:
		# Flip the mesh's "up" axis relative to the surface normal, but keep placement "above" using face_n.
		v = -v
		basis_n = -basis_n
	cols[normal_axis] = basis_n
	cols[width_axis] = u
	cols[depth_axis] = v
	var local_basis := Basis(cols[0], cols[1], cols[2])
	# Ensure right-handed basis
	if local_basis.determinant() < 0.0:
		cols[depth_axis] = -cols[depth_axis]
		local_basis = Basis(cols[0], cols[1], cols[2])

	# Determine which side should sit on the surface.
	# If mesh +normal points with face normal, use the mesh min cap; otherwise use the max cap.
	var mesh_up_dot: float = basis_n.dot(face_n)
	var use_bottom_cap: bool = mesh_up_dot > 0.0

	# Compute cap bounds near the extreme planes along normal_axis
	var eps: float = 1e-4
	var min_n: float = aabb.position[normal_axis]
	var max_n: float = aabb.position[normal_axis] + aabb.size[normal_axis]
	var band: float = maxf(absf(aabb.size[normal_axis]) * 0.10, 0.002)
	var cap_top := {"valid": false, "min0": 0.0, "max0": 0.0, "min1": 0.0, "max1": 0.0, "plane_n": max_n}
	var cap_bottom := {"valid": false, "min0": 0.0, "max0": 0.0, "min1": 0.0, "max1": 0.0, "plane_n": min_n}

	var arrays: Array = mesh.surface_get_arrays(0)
	if arrays.size() > 0:
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		# top cap band
		var tmin0: float = 1e20
		var tmax0: float = -1e20
		var tmin1: float = 1e20
		var tmax1: float = -1e20
		var tc: int = 0
		# bottom cap band
		var bmin0: float = 1e20
		var bmax0: float = -1e20
		var bmin1: float = 1e20
		var bmax1: float = -1e20
		var bc: int = 0
		for p in verts:
			var pn: float = p[normal_axis]
			if pn >= max_n - band - eps:
				var p0: float = p[axis0]
				var p1: float = p[axis1]
				tmin0 = minf(tmin0, p0)
				tmax0 = maxf(tmax0, p0)
				tmin1 = minf(tmin1, p1)
				tmax1 = maxf(tmax1, p1)
				tc += 1
			if pn <= min_n + band + eps:
				var q0: float = p[axis0]
				var q1: float = p[axis1]
				bmin0 = minf(bmin0, q0)
				bmax0 = maxf(bmax0, q0)
				bmin1 = minf(bmin1, q1)
				bmax1 = maxf(bmax1, q1)
				bc += 1
		if tc >= 8 and tmax0 > tmin0 + eps and tmax1 > tmin1 + eps:
			cap_top.valid = true
			cap_top.min0 = tmin0
			cap_top.max0 = tmax0
			cap_top.min1 = tmin1
			cap_top.max1 = tmax1
		if bc >= 8 and bmax0 > bmin0 + eps and bmax1 > bmin1 + eps:
			cap_bottom.valid = true
			cap_bottom.min0 = bmin0
			cap_bottom.max0 = bmax0
			cap_bottom.min1 = bmin1
			cap_bottom.max1 = bmax1

	var cap_anchor: Dictionary = cap_bottom if use_bottom_cap else cap_top
	var _cap_other: Dictionary = cap_top if use_bottom_cap else cap_bottom

	# Trim margins from the mesh footprint (optional)
	var margin: float = maxf(0.0, floor_decor_local_margin)

	# Size and center used for scaling in the plane.
	# When fitting to cell, prefer the full AABB footprint so beveled edges still reach the cell borders.
	var size_w: float
	var size_d: float
	var anchor: Vector3 = aabb.position + aabb.size * 0.5
	if floor_decor_fit_to_cell:
		size_w = _safe_dim(aabb.size[width_axis] - 2.0 * margin)
		size_d = _safe_dim(aabb.size[depth_axis] - 2.0 * margin)
	else:
		var use_cap_for_size: bool = cap_anchor.has("valid") and bool(cap_anchor.valid)
		if use_cap_for_size:
			var cap_w: float = maxf(eps, absf(float(cap_anchor.max0) - float(cap_anchor.min0)) - 2.0 * margin)
			var cap_d: float = maxf(eps, absf(float(cap_anchor.max1) - float(cap_anchor.min1)) - 2.0 * margin)
			# reject pathological spikes (cap way smaller than AABB plane)
			var aabb_w: float = maxf(eps, absf(aabb.size[axis0]) - 2.0 * margin)
			var aabb_d: float = maxf(eps, absf(aabb.size[axis1]) - 2.0 * margin)
			var cap_area: float = cap_w * cap_d
			var aabb_area: float = aabb_w * aabb_d
			if cap_area < aabb_area * 0.12:
				use_cap_for_size = false
			if use_cap_for_size:
				# Map cap extents into chosen width/depth axes
				if width_axis == axis0:
					size_w = cap_w
					size_d = cap_d
				else:
					size_w = cap_d
					size_d = cap_w
				# center on cap
				var cap_c0: float = (float(cap_anchor.min0) + float(cap_anchor.max0)) * 0.5
				var cap_c1: float = (float(cap_anchor.min1) + float(cap_anchor.max1)) * 0.5
				var cap_center: Vector3 = aabb.position + aabb.size * 0.5
				cap_center[axis0] = cap_c0
				cap_center[axis1] = cap_c1
				anchor[width_axis] = cap_center[width_axis]
				anchor[depth_axis] = cap_center[depth_axis]
		if not use_cap_for_size:
			size_w = _safe_dim(aabb.size[width_axis] - 2.0 * margin)
			size_d = _safe_dim(aabb.size[depth_axis] - 2.0 * margin)

	# Determine anchor plane along the normal axis.
	# Prefer cap anchor if valid; otherwise use the AABB extreme that corresponds to the surface side.
	if cap_anchor.has("valid") and bool(cap_anchor.valid):
		anchor[normal_axis] = float(cap_anchor.plane_n)
	else:
		if use_bottom_cap:
			anchor[normal_axis] = aabb.position[normal_axis]
		else:
			anchor[normal_axis] = aabb.position[normal_axis] + aabb.size[normal_axis]

	# Apply fill ratio and optional cap
	var fill: float = maxf(0.001, floor_decor_fill_ratio)
	var sx: float = (face_w / size_w) * fill
	var sd: float = (face_d / size_d) * fill
	if floor_decor_max_scale > 0.0:
		if sx > floor_decor_max_scale:
			sx = floor_decor_max_scale
		if sd > floor_decor_max_scale:
			sd = floor_decor_max_scale
	if not floor_decor_fit_to_cell:
		# keep uniform scale for non-cell-fitted decals
		var s: float = minf(sx, sd)
		sx = s
		sd = s

	# Scale in local space; include thickness along the surface normal axis.
	var scale_vec := Vector3.ONE
	scale_vec[width_axis] = sx
	scale_vec[depth_axis] = sd
	var sz: float = maxf(0.001, floor_decor_depth_scale)
	if floor_decor_fit_to_cell:
		var max_sz: float = maxf(0.001, _cell_size) * maxf(0.001, floor_decor_max_depth_cells)
		sz = minf(sz, max_sz)
	scale_vec[normal_axis] = sz
	var basis_scaled := local_basis
	basis_scaled.x = basis_scaled.x * scale_vec.x
	basis_scaled.y = basis_scaled.y * scale_vec.y
	basis_scaled.z = basis_scaled.z * scale_vec.z

	# Place ABOVE the surface consistently (use face_n, not the possibly flipped basis normal)
	var pos: Vector3 = face.center + face_n * floor_decor_offset
	var origin: Vector3 = pos - basis_scaled * anchor
	return Transform3D(basis_scaled, origin)
func _rebuild_floor_decor() -> void:
	_clear_floor_decor()

	if not enable_floor_decor:
		return
	if floor_decor_meshes.is_empty():
		return
	if _floor_faces.is_empty():
		return

	_ensure_floor_decor_root()

	var buckets: Array[Array] = []
	buckets.resize(floor_decor_meshes.size())
	for i in range(buckets.size()):
		buckets[i] = []

	for face in _floor_faces:
		var pick: int = int(abs(face.key ^ floor_decor_seed)) % floor_decor_meshes.size()
		buckets[pick].append(face)

	for i in range(floor_decor_meshes.size()):
		var faces_i: Array = buckets[i]
		if faces_i.is_empty():
			continue

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = faces_i.size()
		mm.mesh = floor_decor_meshes[i]

		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		_floor_decor_root.add_child(inst)
		_floor_decor_instances.append(inst)

		for j in range(faces_i.size()):
			var f: FloorFace = faces_i[j]
			mm.set_instance_transform(j, _floor_transform_for_face(f, floor_decor_meshes[i]))

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


func _add_shaft_walls_segmented(
	st: SurfaceTool,
	x0: float, x1: float, z0: float, z1: float,
	y_top: float, y_bot: float,
	segment_h: float,
	uv_scale: float,
	color: Color
) -> void:
	if y_top <= y_bot + 0.001:
		return

	var seg: float = maxf(0.25, segment_h)
	var y0: float = y_top

	while y0 > y_bot + 0.001:
		var y1: float = maxf(y_bot, y0 - seg)
		var h: float = maxf(0.001, y0 - y1)

		# North (z0) inward +Z
		_add_quad(
			st,
			Vector3(x1, y0, z0),
			Vector3(x0, y0, z0),
			Vector3(x0, y1, z0),
			Vector3(x1, y1, z0),
			Vector2(0, y0 * uv_scale), Vector2(1, y0 * uv_scale),
			Vector2(1, y1 * uv_scale), Vector2(0, y1 * uv_scale),
			color
		)
		_shaft_faces.append(WallFace.new(
			Vector3(x1, y0, z0), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0),
			Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, z0),
			Vector3(0.0, 0.0, 1.0),
			absf(x1 - x0), h,
			false,
			_shaft_face_key_next
		))
		_shaft_face_key_next += 1

		# South (z1) inward -Z
		_add_quad(
			st,
			Vector3(x0, y0, z1),
			Vector3(x1, y0, z1),
			Vector3(x1, y1, z1),
			Vector3(x0, y1, z1),
			Vector2(0, y0 * uv_scale), Vector2(1, y0 * uv_scale),
			Vector2(1, y1 * uv_scale), Vector2(0, y1 * uv_scale),
			color
		)
		_shaft_faces.append(WallFace.new(
			Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1),
			Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, z1),
			Vector3(0.0, 0.0, -1.0),
			absf(x1 - x0), h,
			false,
			_shaft_face_key_next
		))
		_shaft_face_key_next += 1

		# West (x0) inward +X
		_add_quad(
			st,
			Vector3(x0, y0, z0),
			Vector3(x0, y0, z1),
			Vector3(x0, y1, z1),
			Vector3(x0, y1, z0),
			Vector2(0, y0 * uv_scale), Vector2(1, y0 * uv_scale),
			Vector2(1, y1 * uv_scale), Vector2(0, y1 * uv_scale),
			color
		)
		_shaft_faces.append(WallFace.new(
			Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0),
			Vector3(x0, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
			Vector3(1.0, 0.0, 0.0),
			absf(z1 - z0), h,
			false,
			_shaft_face_key_next
		))
		_shaft_face_key_next += 1

		# East (x1) inward -X
		_add_quad(
			st,
			Vector3(x1, y0, z1),
			Vector3(x1, y0, z0),
			Vector3(x1, y1, z0),
			Vector3(x1, y1, z1),
			Vector2(0, y0 * uv_scale), Vector2(1, y0 * uv_scale),
			Vector2(1, y1 * uv_scale), Vector2(0, y1 * uv_scale),
			color
		)
		_shaft_faces.append(WallFace.new(
			Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1),
			Vector3(x1, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
			Vector3(-1.0, 0.0, 0.0),
			absf(z1 - z0), h,
			false,
			_shaft_face_key_next
		))
		_shaft_face_key_next += 1

		y0 = y1


func _build_tunnel_elevator_tops(n: int) -> void:
	# Places a mesh on the surface cell that has a tunnel shaft beneath it.
	# This mesh is intended to be animated as an elevator later.

	if tunnel_elevator_top_mesh == null:
		return
	var terrain_body: Node = get_node_or_null("TerrainBody")
	if terrain_body == null:
		return

	# Cleanup previous instances.
	for c in terrain_body.get_children():
		if c is Node and StringName(c.name).begins_with("TunnelElevatorTop_"):
			c.queue_free()

	if _tunnel_entrance_cells.is_empty():
		return

	# Local helpers.
	var _idx := func(cx: int, cz: int) -> int:
		return _idx2(cx, cz, n)


	var candidates: Array[Vector2i] = _tunnel_entrance_cells.duplicate()
	if candidates.is_empty():
		return

	# Place instances.
	var aabb := tunnel_elevator_top_mesh.get_aabb()
	var size := aabb.size
	if size.x <= 0.001 or size.y <= 0.001 or size.z <= 0.001:
		return

	# Uniform scale to fit within a single cell footprint (prevents overhang / ramp blocking).
	var target_xz: float = _cell_size * clamp(tunnel_elevator_fit_margin, 0.1, 1.0)
	var s_uniform: float = min(target_xz / size.x, target_xz / size.z)
	var basis := Basis.IDENTITY.scaled(Vector3(s_uniform, s_uniform, s_uniform))

	for k in range(candidates.size()):
		var cell := candidates[k]

		var idx_e: int = int(_idx.call(cell.x, cell.y))

		var cx := _ox + float(cell.x) * _cell_size + _cell_size * 0.5
		var cz := _oz + float(cell.y) * _cell_size + _cell_size * 0.5
		var y := _heights[idx_e] + tunnel_elevator_top_y_offset
		var target := Vector3(cx, y, cz)

		# Anchor mesh to its bottom-center so it sits on the surface.
		var anchor_local := Vector3(aabb.position.x + size.x * 0.5, aabb.position.y, aabb.position.z + size.z * 0.5)
		var origin := target - (basis * anchor_local)

		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.name = "TunnelElevatorTop_%d" % k
		mi.mesh = tunnel_elevator_top_mesh
		mi.transform = Transform3D(basis, origin)
		terrain_body.add_child(mi)

func _build_tunnel_mesh(n: int) -> void:
	_shaft_faces.clear()
	_shaft_face_key_next = 1
	_ensure_tunnel_nodes()
	if _tunnel_mesh_instance == null or _tunnel_collision_shape == null:
		return

	if not enable_tunnels or _tunnel_mask.size() != n * n:
		_tunnel_mesh_instance.mesh = null
		_tunnel_collision_shape.shape = null
		if _shaft_decor_root != null and is_instance_valid(_shaft_decor_root):
			for child: Node in _shaft_decor_root.get_children():
				child.queue_free()
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

			var is_entrance: bool = _tunnel_hole_mask.size() == n * n and _tunnel_hole_mask[idx] != 0

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

			if is_entrance:
				# Surface top Y (entrances are forced to be flat in layout stamping).
				var y_surface: float = float(_heights[idx])
				# Tunnel ceiling at this cell.
				var y_tunnel_ceil: float = maxf(maxf(c00, c10), maxf(c11, c01))
				# Segment height: prefer 1x1-ish tiles (vertical ~= horizontal).
				var seg_h: float = minf(_cell_size, height_step * float(tunnel_height_steps))
				_add_shaft_walls_segmented(
					st,
					x0, x1, z0, z1,
					y_surface, y_tunnel_ceil,
					seg_h,
					uv_scale,
					tunnel_color
				)

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_tunnel_mesh_instance.mesh = mesh
	_tunnel_collision_shape.shape = mesh.create_trimesh_shape()
	_rebuild_shaft_wall_decor()

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
	low0: float, low1: float, high0: float, high1: float, uv_scale: float, subdiv: int,
	normal_pos_x: bool, capture_decor: bool = true) -> void:
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
	if not normal_pos_x:
		var tmp: Vector3 = a
		a = b
		b = tmp
		tmp = c
		c = d
		d = tmp
	if capture_decor:
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

func _add_wall_z_between(st: SurfaceTool, x0: float, x1: float, z_edge: float,
	low0: float, low1: float, high0: float, high1: float, uv_scale: float, subdiv: int,
	normal_pos_z: bool, capture_decor: bool = true) -> void:
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
	if normal_pos_z:
		var tmp: Vector3 = a
		a = b
		b = tmp
		tmp = c
		c = d
		d = tmp
	if capture_decor:
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
	if enable_floor_decor and not floor_decor_meshes.is_empty():
		var f_a := Vector3(x0, h00, z0)
		var f_b := Vector3(x1, h10, z0)
		var f_c := Vector3(x1, h11, z1)
		var f_d := Vector3(x0, h01, z1)
		var key: int = _idx2(cell_x, cell_z, max(2, cells_per_side))
		_capture_floor_face(f_a, f_b, f_c, f_d, key)

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
