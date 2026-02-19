extends Node3D

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
@export var grid_y0: float = 0.0  # authoritative vertical grid origin (TerrainMesh local space)
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
@export var ramp_clearance_enabled: bool = true
@export_range(1, 2, 1) var ramp_clearance_radius: int = 1
@export var ramp_clearance_require_two_wide_exit: bool = true
@export_range(0, 8, 1) var ramp_clearance_max_fixes_per_ramp: int = 2
@export var ramp_clearance_lower_instead_of_remove: bool = true
@export var ramp_clearance_remove_conflicting_ramps: bool = true

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
@export_range(0.0, 1.0, 0.01) var normal_strength: float = 0.85
@export_range(0.0, 2.0, 0.01) var disp_strength_top: float = 0.4
@export_range(0.0, 2.0, 0.01) var disp_strength_wall: float = 0.2
@export_range(0.0, 2.0, 0.01) var disp_strength_ramp: float = 0.3
@export var disp_scale_top: float = 0.06
@export var disp_scale_wall: float = 0.08
@export var disp_scale_ramp: float = 0.06
@export var tiles_per_cell: float = 1.0
@export_range(0.0, 1.0, 0.01) var tex_strength: float = 1.0
@export var debug_vertex_colors: bool = false
@export var shader_clamp_to_cell: bool = true
@export_range(0.0, 2.0, 0.001) var shader_cell_margin_m: float = 0.02
@export var shader_snap_y_to_height_step: bool = false
@export_range(0.0, 1.0, 0.01) var shader_snap_y_strength: float = 1.0
@export var grid_debug_force_flat_material: bool = false
@export var grid_wire_flat_material_toggle_key: Key = KEY_F2
@export var sun_height: float = 200.0
@export var debug_menu_enabled: bool = true
@export var debug_menu_toggle_key: Key = KEY_F1
@export var debug_surface_labels_enabled: bool = false
@export var debug_cell_labels_enabled: bool = false
@export var debug_surface_labels_toggle_key: Key = KEY_F3
@export var debug_cell_labels_toggle_key: Key = KEY_F4
@export_range(8, 128, 1) var debug_surface_labels_font_size: int = 26
@export_range(0.0001, 0.05, 0.0001) var debug_surface_labels_pixel_size: float = 0.0025
@export_range(0.0, 2.0, 0.01) var debug_surface_labels_normal_offset: float = 0.18
@export_range(1.0, 10000.0, 1.0) var debug_surface_labels_max_distance: float = 2500.0
@export_range(-10.0, 10.0, 0.01) var debug_cell_labels_y_offset: float = 0.35
@export var debug_tag_colors_enabled: bool = false : set = _set_debug_tag_colors_enabled
@export var debug_floor_color: Color = Color(0.10, 1.00, 0.10, 1.0) : set = _set_debug_tag_color_any
@export var debug_wall_color: Color = Color(0.20, 0.55, 1.00, 1.0) : set = _set_debug_tag_color_any
@export var debug_ramp_color: Color = Color(1.00, 0.20, 0.20, 1.0) : set = _set_debug_tag_color_any
@export var debug_box_color: Color = Color(0.25, 0.25, 0.25, 1.0) : set = _set_debug_tag_color_any
@export_range(0.0, 5.0, 0.1) var debug_tag_emission: float = 0.0 : set = _set_debug_tag_color_any
@export var debug_tag_color_toggle_key: Key = KEY_F5

@onready var mesh_instance: MeshInstance3D = get_node_or_null("TerrainBody/TerrainMesh")
@onready var collision_shape: CollisionShape3D = get_node_or_null("TerrainBody/TerrainCollision")

var _cell_size: float
var _resolved_world_size: float
var _ox: float
var _oz: float
var _heights: PackedFloat32Array  # one height per cell (cells_per_side * cells_per_side)
var _ramp_up_dir: PackedInt32Array
var _ramps_need_regen: bool = false
var _tunnel_mask: PackedByteArray
var _tunnel_hole_mask: PackedByteArray
var _tunnel_mesh_instance: MeshInstance3D
var _tunnel_collision_shape: CollisionShape3D
var _tunnel_floor_resolved: float = 0.0
var _tunnel_ceil_resolved: float = 0.0
var _tunnel_base_floor_y: float = 0.0
var _tunnel_base_ceil_y: float = 0.0

# -----------------------------
# Grid / cell registry (2D XZ)
# -----------------------------
# The terrain is already generated on an implicit n×n cell grid.
# This registry makes that grid explicit so other systems can query:
#   - where a cell is,
#   - what tags/flags it has (ramp/tunnel/entrance/etc),
#   - what runtime objects are inside it (pickups, enemies, triggers, etc).
#
# IMPORTANT: This is a *logical* grid (XZ). Your terrain still uses heights/corners for Y.

const TAG_NONE: int = 0
const TAG_EDGE: int = 1 << 0
const TAG_RAMP: int = 1 << 1
const TAG_TUNNEL: int = 1 << 2
const TAG_SHAFT_ENTRANCE: int = 1 << 3
const TAG_SURFACE_HOLE: int = 1 << 4
const TAG_FLAT_SURFACE: int = 1 << 5

enum SurfaceKind { FLOOR, RAMP, WALL, TUNNEL_FLOOR, TUNNEL_WALL, TUNNEL_CEIL }
enum SurfaceSide { NONE = -1, N = 0, S = 1, E = 2, W = 3 }

var _grid_n: int = 0
var _grid_tags: PackedInt64Array = PackedInt64Array() # per-cell bitmask
var _grid_contents: Array = [] # Array[Array[Node]] per-cell contents
var _grid_object_to_cell: Dictionary = {} # Node -> int cell index
var _grid_object_tags: Dictionary = {} # Node -> int bitmask tags (optional per-object tags)
var _grid_wire_saved_disp_params: Dictionary = {} # int instance_id -> Dictionary[StringName, Variant]
var _surface_next_id: int = 1
var _surfaces: Array[Dictionary] = []
var _surface_by_id: Dictionary = {}
var _cell_surface_ids: Array = [] # Array[PackedInt32Array] per (x,z) cell

# Grid space transforms
# The grid and generated mesh are authored in the *TerrainMesh local space*.
# If TerrainBody/TerrainMesh nodes are moved/scaled in the scene, convert
# between world-space points and this local grid-space to avoid offsets.
var _grid_local_to_world: Transform3D = Transform3D.IDENTITY
var _grid_world_to_local: Transform3D = Transform3D.IDENTITY

# Debug wireframe for the grid (toggle with the '1' key).
# By default, the wireframe is depth-tested (occluded by terrain) so you only see lines on visible faces.
# You can optionally draw-through for alignment inspection.
@export var grid_wire_draw_through_geometry: bool = false
@export_range(0.0, 1.0, 0.01) var grid_wire_alpha: float = 0.28

# When using the rock shader, wall/ramp displacement can push faces outside exact cell bounds.
# For grid-alignment debugging, this option zeros wall/ramp displacement while the grid wire is visible.
@export var grid_wire_disable_side_displacement: bool = true
@export var grid_wire_disable_displacement_when_visible: bool = true  # disables disp_strength_* while grid is visible for perfect alignment
@export_range(0.0, 0.01, 0.0005) var grid_wire_surface_nudge: float = 0.0005

var _grid_wire_visible: bool = false
var _grid_wire_instance: MeshInstance3D
var _grid_wire_material: StandardMaterial3D
var _debug_tag_material: ShaderMaterial
var _debug_tag_saved_overrides: Dictionary = {} # int instance_id -> Material
var _grid_debug_flat_enabled: bool = false
var _grid_debug_saved_overrides: Dictionary = {} # int instance_id -> Material
var _debug_labels_root: Node3D
var _debug_ui_layer: CanvasLayer
var _debug_menu_panel: PanelContainer
var _debug_surface_checkbox: CheckBox
var _debug_cell_checkbox: CheckBox

func _quantize_y_to_grid(y: float) -> float:
	if height_step <= 0.0:
		return y
	var k := roundf((y - grid_y0) / height_step)
	return grid_y0 + k * height_step

func _resolve_vertical_grid_bounds() -> void:
	grid_y0 = _quantize_y_to_grid(grid_y0)
	outer_floor_height = minf(_quantize_y_to_grid(outer_floor_height), grid_y0)
	box_height = _quantize_y_to_grid(box_height)
	if box_height <= grid_y0:
		box_height = grid_y0 + maxf(0.001, height_step)

func _surface_min_y() -> float:
	return _level_to_h(SURFACE_MIN_LEVEL)

func _print_grid_contract() -> void:
	if _heights.is_empty():
		return
	var hmin := INF
	var hmax := -INF
	for h in _heights:
		hmin = minf(hmin, h)
		hmax = maxf(hmax, h)
	print("Grid contract y0=", grid_y0,
		" tunnel_floor=", _tunnel_floor_resolved,
		" tunnel_ceil=", _tunnel_ceil_resolved,
		" surface_min=", _surface_min_y(),
		" heights[min,max]=", hmin, ",", hmax)

func _grid_debug_collect_mesh_instances() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if mesh_instance != null and is_instance_valid(mesh_instance):
		out.append(mesh_instance)
	if _tunnel_mesh_instance != null and is_instance_valid(_tunnel_mesh_instance):
		out.append(_tunnel_mesh_instance)
	return out

func _grid_debug_get_flat_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	return m

func _apply_grid_debug_flat_material(enabled: bool) -> void:
	if enabled == _grid_debug_flat_enabled:
		return
	if enabled:
		_grid_debug_saved_overrides.clear()
		var flat_mat := _grid_debug_get_flat_material()
		for mi in _grid_debug_collect_mesh_instances():
			_grid_debug_saved_overrides[mi.get_instance_id()] = mi.material_override
			mi.material_override = flat_mat
	else:
		for mi in _grid_debug_collect_mesh_instances():
			var id := mi.get_instance_id()
			if _grid_debug_saved_overrides.has(id):
				mi.material_override = _grid_debug_saved_overrides[id]
		_grid_debug_saved_overrides.clear()
	_grid_debug_flat_enabled = enabled

func _grid_is_valid_cell(cell: Vector2i) -> bool:
	return _grid_n > 0 and cell.x >= 0 and cell.x < _grid_n and cell.y >= 0 and cell.y < _grid_n

func _grid_init(n: int) -> void:
	_grid_n = n
	var count := n * n

	if _grid_tags.size() != count:
		_grid_tags = PackedInt64Array()
		_grid_tags.resize(count)
	_grid_tags.fill(0)

	_grid_contents.clear()
	_grid_contents.resize(count)
	for i in range(count):
		_grid_contents[i] = []

	_grid_object_to_cell.clear()
	_grid_object_tags.clear()

func grid_cell_id(x: int, z: int, n: int) -> int:
	return 1 + x + z * n

func grid_voxel_id(x: int, z: int, ly: int, n: int) -> int:
	return 1 + x + z * n + ly * n * n

func grid_y_to_level(y: float) -> int:
	return _h_to_level(y)

func grid_level_to_y(ly: int) -> float:
	return _level_to_h(ly)

func _surface_registry_reset(n: int) -> void:
	_surface_next_id = 1
	_surfaces.clear()
	_surface_by_id.clear()
	_cell_surface_ids.clear()
	_cell_surface_ids.resize(n * n)
	for i in range(n * n):
		var ids := PackedInt32Array()
		_cell_surface_ids[i] = ids

func _surface_key(cell: Vector2i, kind: int, side: int) -> String:
	var base := "C%04d" % grid_cell_id(cell.x, cell.y, _grid_n)
	match kind:
		SurfaceKind.FLOOR:
			return "%s_F" % base
		SurfaceKind.RAMP:
			return "%s_R" % base
		SurfaceKind.WALL:
			var suffix := "N"
			if side == SurfaceSide.S:
				suffix = "S"
			elif side == SurfaceSide.E:
				suffix = "E"
			elif side == SurfaceSide.W:
				suffix = "W"
			return "%s_W_%s" % [base, suffix]
		SurfaceKind.TUNNEL_FLOOR:
			return "%s_T_F" % base
		SurfaceKind.TUNNEL_WALL:
			var ws := "N"
			if side == SurfaceSide.S:
				ws = "S"
			elif side == SurfaceSide.E:
				ws = "E"
			elif side == SurfaceSide.W:
				ws = "W"
			return "%s_T_W_%s" % [base, ws]
		SurfaceKind.TUNNEL_CEIL:
			return "%s_T_C" % base
		_:
			return "%s_S" % base

func _register_surface(kind: int, cell_a: Vector2i, side_a: int, cell_b: Vector2i = Vector2i(-1, -1), side_b: int = SurfaceSide.NONE, verts: PackedVector3Array = PackedVector3Array(), normal: Vector3 = Vector3.ZERO, extra: Dictionary = {}) -> int:
	if _grid_n <= 0 or not _grid_is_valid_cell(cell_a):
		return -1
	var id := _surface_next_id
	_surface_next_id += 1
	var nrm := normal
	if nrm == Vector3.ZERO and verts.size() >= 3:
		nrm = Plane(verts[0], verts[1], verts[2]).normal
	var rec: Dictionary = {
		"id": id,
		"key": _surface_key(cell_a, kind, side_a),
		"kind": kind,
		"cell_a": cell_a,
		"side_a": side_a,
		"cell_b": cell_b,
		"side_b": side_b,
		"verts_local": verts,
		"normal_local": nrm,
		"extra": extra,
	}
	_surfaces.append(rec)
	_surface_by_id[id] = rec
	var ia := _idx2(cell_a.x, cell_a.y, _grid_n)
	var list_a: PackedInt32Array = _cell_surface_ids[ia]
	list_a.append(id)
	_cell_surface_ids[ia] = list_a
	if _grid_is_valid_cell(cell_b):
		var ib := _idx2(cell_b.x, cell_b.y, _grid_n)
		var list_b: PackedInt32Array = _cell_surface_ids[ib]
		list_b.append(id)
		_cell_surface_ids[ib] = list_b
	return id

func grid_get_cell_surfaces(cell: Vector2i) -> Array[Dictionary]:
	if not _grid_is_valid_cell(cell):
		return []
	var ids: PackedInt32Array = _cell_surface_ids[_idx2(cell.x, cell.y, _grid_n)]
	var out: Array[Dictionary] = []
	for id in ids:
		if _surface_by_id.has(id):
			out.append(_surface_by_id[id])
	return out

func grid_get_floor_or_ramp(cell: Vector2i) -> Dictionary:
	for s in grid_get_cell_surfaces(cell):
		if s["kind"] == SurfaceKind.FLOOR or s["kind"] == SurfaceKind.RAMP:
			return s
	return {}

func grid_get_walls(cell: Vector2i, side: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in grid_get_cell_surfaces(cell):
		if s["kind"] != SurfaceKind.WALL:
			continue
		if (s["cell_a"] == cell and s["side_a"] == side) or (s["cell_b"] == cell and s["side_b"] == side):
			out.append(s)
	return out


func grid_register_object(node: Node, world_pos: Vector3, object_tags: int = 0) -> bool:
	if node == null or _grid_n <= 0:
		return false
	var cell := grid_world_to_cell(world_pos)
	if not _grid_is_valid_cell(cell):
		return false
	var idx := _idx2(cell.x, cell.y, _grid_n)
	if _grid_object_to_cell.has(node):
		grid_move_object(node, world_pos)
		if object_tags != 0:
			_grid_object_tags[node] = object_tags
		return true
	_grid_contents[idx].append(node)
	_grid_object_to_cell[node] = idx
	if object_tags != 0:
		_grid_object_tags[node] = object_tags
	return true

func grid_move_object(node: Node, world_pos: Vector3) -> bool:
	if node == null or not _grid_object_to_cell.has(node) or _grid_n <= 0:
		return false
	var new_cell := grid_world_to_cell(world_pos)
	if not _grid_is_valid_cell(new_cell):
		return false
	var old_idx: int = int(_grid_object_to_cell[node])
	var new_idx := _idx2(new_cell.x, new_cell.y, _grid_n)
	if old_idx == new_idx:
		return true
	_grid_contents[old_idx].erase(node)
	_grid_contents[new_idx].append(node)
	_grid_object_to_cell[node] = new_idx
	return true

func grid_unregister_object(node: Node) -> void:
	if node == null or not _grid_object_to_cell.has(node):
		return
	var idx: int = int(_grid_object_to_cell[node])
	_grid_contents[idx].erase(node)
	_grid_object_to_cell.erase(node)
	_grid_object_tags.erase(node)

func _grid_refresh_space_xforms() -> void:
	# Cache transforms used by the grid API.
	# Grid-space == TerrainMesh local space (the same space vertices are authored in).
	if mesh_instance != null and is_instance_valid(mesh_instance):
		_grid_local_to_world = mesh_instance.global_transform
	else:
		_grid_local_to_world = global_transform
	_grid_world_to_local = _grid_local_to_world.affine_inverse()

func _grid_rebuild_tags(n: int) -> void:
	if _grid_n != n or _grid_tags.size() != n * n:
		_grid_init(n)

	for z in range(n):
		for x in range(n):
			var i := _idx2(x, z, n)
			var t: int = 0

			if x == 0 or x == n - 1 or z == 0 or z == n - 1:
				t |= TAG_EDGE

			if _ramp_up_dir.size() == n * n and _ramp_up_dir[i] != 0:
				t |= TAG_RAMP

			if _tunnel_mask.size() == n * n and _tunnel_mask[i] != 0:
				t |= TAG_TUNNEL

			# Entrance cells are the only ones that should punch a hole in the surface.
			if _tunnel_hole_mask.size() == n * n and _tunnel_hole_mask[i] != 0:
				t |= TAG_SHAFT_ENTRANCE
				t |= TAG_SURFACE_HOLE

			if (t & (TAG_RAMP | TAG_SURFACE_HOLE)) == 0:
				t |= TAG_FLAT_SURFACE

			_grid_tags[i] = t

func grid_world_to_cell(p: Vector3) -> Vector2i:
	# Convert a *world-space* point into a grid cell (XZ).
	# Important: terrain/grid are authored in TerrainMesh local space, so convert first.
	var lp := _grid_world_to_local * p
	var x := int(floor((lp.x - _ox) / _cell_size))
	var z := int(floor((lp.z - _oz) / _cell_size))
	x = clampi(x, 0, _grid_n - 1)
	z = clampi(z, 0, _grid_n - 1)
	return Vector2i(x, z)


func grid_cell_to_world_center(cell: Vector2i) -> Vector3:
	# Returns the *world-space* center point of a cell at Y=0 in grid local space.
	if not _grid_is_valid_cell(cell):
		return Vector3.ZERO
	var lx := _ox + (float(cell.x) + 0.5) * _cell_size
	var lz := _oz + (float(cell.y) + 0.5) * _cell_size
	return _grid_local_to_world * Vector3(lx, 0.0, lz)


func grid_cell_world_rect(cell: Vector2i) -> Rect2:
	# Returns a world-space XZ Rect2 AABB for the cell footprint.
	# If the terrain node is transformed, this returns the axis-aligned bounds of the transformed cell.
	if not _grid_is_valid_cell(cell):
		return Rect2()
	var x0 := _ox + float(cell.x) * _cell_size
	var z0 := _oz + float(cell.y) * _cell_size
	var x1 := x0 + _cell_size
	var z1 := z0 + _cell_size
	var p00 := _grid_local_to_world * Vector3(x0, 0.0, z0)
	var p10 := _grid_local_to_world * Vector3(x1, 0.0, z0)
	var p01 := _grid_local_to_world * Vector3(x0, 0.0, z1)
	var p11 := _grid_local_to_world * Vector3(x1, 0.0, z1)
	var min_x: float = minf(minf(p00.x, p10.x), minf(p01.x, p11.x))
	var max_x: float = maxf(maxf(p00.x, p10.x), maxf(p01.x, p11.x))
	var min_z: float = minf(minf(p00.z, p10.z), minf(p01.z, p11.z))
	var max_z: float = maxf(maxf(p00.z, p10.z), maxf(p01.z, p11.z))
	return Rect2(Vector2(min_x, min_z), Vector2(max_x - min_x, max_z - min_z))


func grid_cell_world_aabb(cell: Vector2i, y_min: float = NAN, y_max: float = NAN) -> AABB:
	# Returns a world-space AABB for the cell column. If y_min/y_max are omitted, uses outer_floor_height..box_height.
	# Note: if the terrain node is rotated, this returns the axis-aligned bounds of the rotated cell column.
	if not _grid_is_valid_cell(cell):
		return AABB()
	var x0 := _ox + float(cell.x) * _cell_size
	var z0 := _oz + float(cell.y) * _cell_size
	var x1 := x0 + _cell_size
	var z1 := z0 + _cell_size
	var lo := y_min
	var hi := y_max
	if is_nan(lo):
		lo = outer_floor_height
	if is_nan(hi):
		hi = box_height
	var corners: Array[Vector3] = [
		Vector3(x0, lo, z0), Vector3(x1, lo, z0), Vector3(x0, lo, z1), Vector3(x1, lo, z1),
		Vector3(x0, hi, z0), Vector3(x1, hi, z0), Vector3(x0, hi, z1), Vector3(x1, hi, z1),
	]
	var w0: Vector3 = _grid_local_to_world * corners[0]
	var min_v: Vector3 = w0
	var max_v: Vector3 = w0
	for c: Vector3 in corners:
		var w: Vector3 = _grid_local_to_world * c
		min_v.x = minf(min_v.x, w.x)
		min_v.y = minf(min_v.y, w.y)
		min_v.z = minf(min_v.z, w.z)
		max_v.x = maxf(max_v.x, w.x)
		max_v.y = maxf(max_v.y, w.y)
		max_v.z = maxf(max_v.z, w.z)
	return AABB(min_v, max_v - min_v)


func _ensure_debug_labels_root() -> void:
	if _debug_labels_root != null and is_instance_valid(_debug_labels_root):
		return
	var parent: Node = null
	if mesh_instance != null and is_instance_valid(mesh_instance):
		parent = mesh_instance
	else:
		parent = self
	_debug_labels_root = Node3D.new()
	_debug_labels_root.name = "DebugSurfaceLabels"
	parent.add_child(_debug_labels_root)

func _clear_debug_labels() -> void:
	if _debug_labels_root == null or not is_instance_valid(_debug_labels_root):
		return
	for c in _debug_labels_root.get_children():
		c.queue_free()

func _surface_kind_short(kind: int) -> String:
	match kind:
		SurfaceKind.FLOOR:
			return "F"
		SurfaceKind.RAMP:
			return "R"
		SurfaceKind.WALL:
			return "W"
		SurfaceKind.TUNNEL_FLOOR:
			return "TF"
		SurfaceKind.TUNNEL_WALL:
			return "TW"
		SurfaceKind.TUNNEL_CEIL:
			return "TC"
		_:
			return "S"

func _surface_side_short(side: int) -> String:
	match side:
		SurfaceSide.N:
			return "N"
		SurfaceSide.S:
			return "S"
		SurfaceSide.E:
			return "E"
		SurfaceSide.W:
			return "W"
		_:
			return "-"

func _surface_label_text(srec: Dictionary) -> String:
	var kind: int = int(srec.get("kind", -1))
	var sid: int = int(srec.get("id", -1))
	var cell_a: Vector2i = srec.get("cell_a", Vector2i(-1, -1))
	var base := "%s#%d C%04d" % [_surface_kind_short(kind), sid, grid_cell_id(cell_a.x, cell_a.y, _grid_n)]
	var extra: Dictionary = srec.get("extra", {})
	if kind == SurfaceKind.RAMP:
		base += " L%d D%d" % [int(extra.get("floor_level", 0)), int(extra.get("ramp_dir", -1))]
	elif kind == SurfaceKind.WALL or kind == SurfaceKind.TUNNEL_WALL:
		var s0 := _surface_side_short(int(srec.get("side_a", SurfaceSide.NONE)))
		var y0 := int(extra.get("y0_level", 0))
		var y1 := int(extra.get("y1_level", 0))
		var cell_b: Vector2i = srec.get("cell_b", Vector2i(-1, -1))
		if _grid_is_valid_cell(cell_b):
			var s1 := _surface_side_short(int(srec.get("side_b", SurfaceSide.NONE)))
			base += "%s|C%04d%s L%d-%d" % [s0, grid_cell_id(cell_b.x, cell_b.y, _grid_n), s1, y0, y1]
		else:
			base += "%s L%d-%d" % [s0, y0, y1]
	elif extra.has("floor_level"):
		base += " L%d" % int(extra.get("floor_level", 0))
	elif extra.has("level"):
		base += " L%d" % int(extra.get("level", 0))
	return base

func _surface_label_pos_local(srec: Dictionary) -> Vector3:
	var verts: PackedVector3Array = srec.get("verts_local", PackedVector3Array())
	if verts.is_empty():
		return Vector3.ZERO
	var sum := Vector3.ZERO
	for v in verts:
		sum += v
	var center := sum / float(verts.size())
	var nrm: Vector3 = srec.get("normal_local", Vector3.UP)
	if nrm.length_squared() <= 1e-8:
		nrm = Vector3.UP
	return center + nrm.normalized() * debug_surface_labels_normal_offset

func _add_debug_label(text: String, local_pos: Vector3, color: Color) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam != null and debug_surface_labels_max_distance > 0.0:
		var world_pos: Vector3 = _grid_local_to_world * local_pos
		if world_pos.distance_to(cam.global_position) > debug_surface_labels_max_distance:
			return
	var l := Label3D.new()
	l.text = text
	l.font_size = debug_surface_labels_font_size
	l.pixel_size = debug_surface_labels_pixel_size
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = local_pos
	_debug_labels_root.add_child(l)

func _rebuild_debug_labels() -> void:
	_ensure_debug_labels_root()
	_clear_debug_labels()
	if not debug_surface_labels_enabled and not debug_cell_labels_enabled:
		return

	if debug_cell_labels_enabled and _grid_n > 0:
		for z in range(_grid_n):
			for x in range(_grid_n):
				var txt := "C%04d" % grid_cell_id(x, z, _grid_n)
				var pos := Vector3(
					_ox + (float(x) + 0.5) * _cell_size,
					grid_y0 + debug_cell_labels_y_offset,
					_oz + (float(z) + 0.5) * _cell_size
				)
				_add_debug_label(txt, pos, Color(0.55, 0.95, 0.55, 1.0))

	if debug_surface_labels_enabled:
		for srec in _surfaces:
			_add_debug_label(_surface_label_text(srec), _surface_label_pos_local(srec), Color(1.0, 0.95, 0.35, 1.0))

func _on_debug_surface_labels_toggled(toggled: bool) -> void:
	debug_surface_labels_enabled = toggled
	_rebuild_debug_labels()

func _on_debug_cell_labels_toggled(toggled: bool) -> void:
	debug_cell_labels_enabled = toggled
	_rebuild_debug_labels()

func _ensure_debug_menu() -> void:
	if not debug_menu_enabled:
		return
	if _debug_ui_layer != null and is_instance_valid(_debug_ui_layer):
		return
	_debug_ui_layer = CanvasLayer.new()
	_debug_ui_layer.name = "DebugMenu"
	add_child(_debug_ui_layer)

	_debug_menu_panel = PanelContainer.new()
	_debug_menu_panel.name = "Panel"
	_debug_menu_panel.visible = false
	_debug_menu_panel.offset_left = 14
	_debug_menu_panel.offset_top = 14
	_debug_menu_panel.offset_right = 280
	_debug_menu_panel.offset_bottom = 180
	_debug_ui_layer.add_child(_debug_menu_panel)

	var vb := VBoxContainer.new()
	_debug_menu_panel.add_child(vb)

	var title := Label.new()
	title.text = "Arena Debug"
	vb.add_child(title)

	var hint := Label.new()
	hint.text = "F1 menu | 1 wire | F2 flat | F3 surf | F4 cells | R regen"
	vb.add_child(hint)

	_debug_surface_checkbox = CheckBox.new()
	_debug_surface_checkbox.text = "Surface labels (F3)"
	_debug_surface_checkbox.button_pressed = debug_surface_labels_enabled
	_debug_surface_checkbox.toggled.connect(_on_debug_surface_labels_toggled)
	vb.add_child(_debug_surface_checkbox)

	_debug_cell_checkbox = CheckBox.new()
	_debug_cell_checkbox.text = "Cell labels (F4)"
	_debug_cell_checkbox.button_pressed = debug_cell_labels_enabled
	_debug_cell_checkbox.toggled.connect(_on_debug_cell_labels_toggled)
	vb.add_child(_debug_cell_checkbox)

func _toggle_debug_menu() -> void:
	if not debug_menu_enabled:
		return
	_ensure_debug_menu()
	if _debug_menu_panel != null and is_instance_valid(_debug_menu_panel):
		_debug_menu_panel.visible = not _debug_menu_panel.visible

func _toggle_surface_labels() -> void:
	debug_surface_labels_enabled = not debug_surface_labels_enabled
	if _debug_surface_checkbox != null and is_instance_valid(_debug_surface_checkbox):
		_debug_surface_checkbox.button_pressed = debug_surface_labels_enabled
	_rebuild_debug_labels()

func _toggle_cell_labels() -> void:
	debug_cell_labels_enabled = not debug_cell_labels_enabled
	if _debug_cell_checkbox != null and is_instance_valid(_debug_cell_checkbox):
		_debug_cell_checkbox.button_pressed = debug_cell_labels_enabled
	_rebuild_debug_labels()

func _set_debug_tag_colors_enabled(v: bool) -> void:
	debug_tag_colors_enabled = v
	_apply_debug_tag_colors()

func _set_debug_tag_color_any(_v: Variant) -> void:
	_apply_debug_tag_colors()

func _ensure_debug_tag_material() -> ShaderMaterial:
	if _debug_tag_material != null and is_instance_valid(_debug_tag_material):
		return _debug_tag_material
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/debug_tag_colors.gdshader")
	_debug_tag_material = sm
	return _debug_tag_material

func _set_debug_tag_override(mi: MeshInstance3D, enabled: bool, mat: ShaderMaterial) -> void:
	if mi == null or not is_instance_valid(mi):
		return
	var id := mi.get_instance_id()
	if enabled:
		if not _debug_tag_saved_overrides.has(id):
			_debug_tag_saved_overrides[id] = mi.material_override
		mi.material_override = mat
		return
	if _debug_tag_saved_overrides.has(id):
		mi.material_override = _debug_tag_saved_overrides[id]
		_debug_tag_saved_overrides.erase(id)

func _apply_debug_tag_colors() -> void:
	var debug_mat: ShaderMaterial = null
	if debug_tag_colors_enabled:
		debug_mat = _ensure_debug_tag_material()
		if debug_mat != null:
			debug_mat.set_shader_parameter("debug_floor_color", debug_floor_color)
			debug_mat.set_shader_parameter("debug_wall_color", debug_wall_color)
			debug_mat.set_shader_parameter("debug_ramp_color", debug_ramp_color)
			debug_mat.set_shader_parameter("debug_box_color", debug_box_color)
			debug_mat.set_shader_parameter("debug_tag_emission", debug_tag_emission)

	for mi in _grid_debug_collect_mesh_instances():
		_set_debug_tag_override(mi, debug_tag_colors_enabled, debug_mat)

	for sm in _grid_wire_collect_shader_materials():
		if sm.get_shader_parameter("debug_show_tag_colors") != null:
			sm.set_shader_parameter("debug_show_tag_colors", debug_tag_colors_enabled)
		if sm.get_shader_parameter("debug_floor_color") != null:
			sm.set_shader_parameter("debug_floor_color", debug_floor_color)
		if sm.get_shader_parameter("debug_wall_color") != null:
			sm.set_shader_parameter("debug_wall_color", debug_wall_color)
		if sm.get_shader_parameter("debug_ramp_color") != null:
			sm.set_shader_parameter("debug_ramp_color", debug_ramp_color)
		if sm.get_shader_parameter("debug_box_color") != null:
			sm.set_shader_parameter("debug_box_color", debug_box_color)
		if sm.get_shader_parameter("debug_tag_emission") != null:
			sm.set_shader_parameter("debug_tag_emission", debug_tag_emission)

# -----------------------------
# Grid wireframe visualization
# -----------------------------
func _ensure_grid_wire_node() -> void:
	if _grid_wire_instance != null and is_instance_valid(_grid_wire_instance):
		return
	# Attach the wireframe to the same local space as the generated mesh so there is zero offset.
	# (If TerrainMesh is translated/scaled in the scene, the wire follows automatically.)
	var parent: Node = null
	if mesh_instance != null and is_instance_valid(mesh_instance):
		parent = mesh_instance
	else:
		parent = get_node_or_null('TerrainBody')
		if parent == null:
			parent = self
	_grid_wire_instance = MeshInstance3D.new()
	_grid_wire_instance.name = 'GridWireframe'
	_grid_wire_instance.visible = false
	_grid_wire_instance.transform = Transform3D.IDENTITY
	parent.add_child(_grid_wire_instance)

func _grid_wire_get_material() -> Material:
	if _grid_wire_material == null:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.render_priority = 127
		_grid_wire_material = m

	# Always refresh runtime-tweakable settings.
	_grid_wire_material.albedo_color = Color(1.0, 1.0, 1.0, clampf(grid_wire_alpha, 0.0, 1.0))
	_grid_wire_material.no_depth_test = grid_wire_draw_through_geometry
	if grid_wire_draw_through_geometry:
		# Legacy behavior: keep the overlay visible through everything.
		_grid_wire_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_grid_wire_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	else:
		# Debug behavior: respect scene depth so wire hidden behind terrain, including
		# surfaces that use alpha materials (depth prepass writes depth first).
		_grid_wire_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		_grid_wire_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	return _grid_wire_material

func _grid_wire_collect_from_mesh_instance(mi: MeshInstance3D, seen: Dictionary, result: Array[ShaderMaterial]) -> void:
	if mi == null or not is_instance_valid(mi):
		return

	var override_sm := mi.material_override as ShaderMaterial
	if override_sm != null:
		var id_override := override_sm.get_instance_id()
		if not seen.has(id_override):
			seen[id_override] = true
			result.append(override_sm)

	var mesh: Mesh = mi.mesh
	if mesh == null:
		return

	for si in range(mesh.get_surface_count()):
		var sm := mi.get_active_material(si) as ShaderMaterial
		if sm == null:
			continue
		var id_surface := sm.get_instance_id()
		if seen.has(id_surface):
			continue
		seen[id_surface] = true
		result.append(sm)

func _grid_wire_collect_shader_materials() -> Array[ShaderMaterial]:
	var result: Array[ShaderMaterial] = []
	var seen := {}
	_grid_wire_collect_from_mesh_instance(mesh_instance, seen, result)
	_grid_wire_collect_from_mesh_instance(_tunnel_mesh_instance, seen, result)
	return result

func _grid_wire_capture_disp_params(sm: ShaderMaterial) -> void:
	var mat_id := sm.get_instance_id()
	if _grid_wire_saved_disp_params.has(mat_id):
		return
	var names := [
		StringName("disp_strength_top"),
		StringName("disp_strength_wall"),
		StringName("disp_strength_ramp"),
	]
	var saved_for_mat := {}
	for p in names:
		var v: Variant = sm.get_shader_parameter(p)
		if v != null:
			saved_for_mat[p] = v
	if saved_for_mat.size() > 0:
		_grid_wire_saved_disp_params[mat_id] = saved_for_mat

func _grid_wire_restore_disp_params(sm: ShaderMaterial) -> void:
	var mat_id := sm.get_instance_id()
	if not _grid_wire_saved_disp_params.has(mat_id):
		return
	var saved_for_mat: Dictionary = _grid_wire_saved_disp_params[mat_id]
	for p in saved_for_mat.keys():
		sm.set_shader_parameter(p, saved_for_mat[p])
	_grid_wire_saved_disp_params.erase(mat_id)

func _grid_wire_apply_debug_fit(enabled: bool) -> void:
	# When the 3D grid is visible, disable vertex displacement so the rendered terrain and
	# the wire overlay share the exact same cell-aligned geometry (no visual drift/offset).
	var shader_materials := _grid_wire_collect_shader_materials()
	if shader_materials.is_empty():
		return
	var disable := enabled and (grid_wire_disable_displacement_when_visible or grid_wire_disable_side_displacement)
	for sm in shader_materials:
		if disable:
			_grid_wire_capture_disp_params(sm)
			if sm.get_shader_parameter("disp_strength_top") != null:
				sm.set_shader_parameter("disp_strength_top", 0.0)
			if sm.get_shader_parameter("disp_strength_wall") != null:
				sm.set_shader_parameter("disp_strength_wall", 0.0)
			if sm.get_shader_parameter("disp_strength_ramp") != null:
				sm.set_shader_parameter("disp_strength_ramp", 0.0)
			if sm.get_shader_parameter("debug_disable_side_disp") != null:
				sm.set_shader_parameter("debug_disable_side_disp", true)
		else:
			# Restore whatever each material had before the grid was enabled.
			_grid_wire_restore_disp_params(sm)
			if sm.get_shader_parameter("debug_disable_side_disp") != null:
				sm.set_shader_parameter("debug_disable_side_disp", false)

func _grid_wire_set_visible(enabled: bool) -> void:
	_grid_wire_visible = enabled
	_ensure_grid_wire_node()
	_grid_wire_instance.visible = _grid_wire_visible
	_grid_wire_apply_debug_fit(_grid_wire_visible)
	if _grid_wire_visible:
		_grid_wire_rebuild_mesh()

func _toggle_grid_wireframe() -> void:
	_grid_wire_set_visible(not _grid_wire_visible)

func _grid_wire_rebuild_mesh() -> void:
	if not _grid_wire_visible:
		return
	if _grid_n <= 0 or _cell_size <= 0.0:
		return
	_ensure_grid_wire_node()

	var n := _grid_n # grid is n x n cells
	var w := _resolved_world_size
	if w <= 0.0:
		w = _cell_size * float(n)
	var x0 := _ox
	var z0 := _oz
	var x1 := _ox + w
	var z1 := _oz + w
	var y0 := grid_y0
	var y1 := box_height
	var nudge := maxf(0.0, grid_wire_surface_nudge)
	var nx0 := x0 + nudge
	var nz0 := z0 + nudge
	var nx1 := x1 - nudge
	var nz1 := z1 - nudge
	if nx0 > nx1:
		nx0 = (x0 + x1) * 0.5
		nx1 = nx0
	if nz0 > nz1:
		nz0 = (z0 + z1) * 0.5
		nz1 = nz0

	# Draw a full 3D lattice so every voxel cell is outlined along X, Y, and Z.
	var y_step := height_step
	if y_step <= 0.0:
		y_step = _cell_size
	if y_step <= 0.0:
		y_step = 1.0
	var y_span := maxf(0.0, y1 - y0)
	var y_slices: int = ceili(y_span / y_step)
	if y_slices < 1:
		y_slices = 1

	# Hard cap for overlay density; if clamped, recompute step so the last slice lands on y1.
	var max_slices := 256
	if y_slices > max_slices:
		y_slices = max_slices
		y_step = y_span / float(y_slices)

	var im := ImmediateMesh.new() # PRIMITIVE_LINES
	im.surface_begin(Mesh.PRIMITIVE_LINES, _grid_wire_get_material())

	# Vertical lines at each grid intersection (Y axis).
	for zi in range(n + 1):
		var z := z0 + float(zi) * _cell_size
		for xi in range(n + 1):
			var x := x0 + float(xi) * _cell_size
			var xn := clampf(x, nx0, nx1)
			var zn := clampf(z, nz0, nz1)
			im.surface_add_vertex(Vector3(xn, y0 + nudge, zn))
			im.surface_add_vertex(Vector3(xn, y1 - nudge, zn))

	# Horizontal lattice at every Y slice (X and Z axes).
	for yi in range(y_slices + 1):
		var y := y0 + float(yi) * y_step
		if yi == y_slices:
			y = y1

		# X lines (vary X, fixed Z).
		for zi in range(n + 1):
			var z := z0 + float(zi) * _cell_size
			var zn := clampf(z, nz0, nz1)
			im.surface_add_vertex(Vector3(nx0, y, zn))
			im.surface_add_vertex(Vector3(nx1, y, zn))

		# Z lines (vary Z, fixed X).
		for xi in range(n + 1):
			var x := x0 + float(xi) * _cell_size
			var xn := clampf(x, nx0, nx1)
			im.surface_add_vertex(Vector3(xn, y, nz0))
			im.surface_add_vertex(Vector3(xn, y, nz1))

	im.surface_end()
	_grid_wire_instance.mesh = im

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
const SURF_TOP := 0.0
const SURF_WALL := 0.55
const SURF_RAMP := 0.8
const SURF_BOX := 1.0
const _NEG_INF := -1.0e20
const TUNNEL_FLOOR_LEVEL := 0
const TUNNEL_HEIGHT_LEVELS := 1
const SURFACE_MIN_LEVEL := 2


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

func _cell_idx(x: int, z: int, n: int) -> int:
	return z * n + x

func _ramp_front_is_blocking(cell: Vector2i, n: int, high_lvl: int, allow_up: int, low_idx: int, levels: PackedInt32Array) -> bool:
	if cell.x < 0 or cell.x >= n or cell.y < 0 or cell.y >= n:
		return true
	var idx: int = _cell_idx(cell.x, cell.y, n)
	if idx == low_idx:
		return false
	if levels[idx] > high_lvl + allow_up:
		return true
	if ramp_clearance_remove_conflicting_ramps and _ramp_up_dir[idx] != RAMP_NONE and _ramp_up_dir[idx] != _ramp_up_dir[low_idx]:
		return true
	return false

func _apply_ramp_clearance(n: int, _want: int, levels: PackedInt32Array) -> int:
	if not ramp_clearance_enabled:
		return FIX_NONE
	if ramp_clearance_radius != 1:
		# current implementation is 3x3 around ramp top; keep setting for future expansion.
		pass

	var flags: int = FIX_NONE
	var allow_up: int = maxi(0, walk_up_steps_without_ramp)
	var max_fixes: int = maxi(0, ramp_clearance_max_fixes_per_ramp)
	var changed: bool = true
	var guard: int = 0

	while changed and guard < 3:
		guard += 1
		changed = false
		for low_idx in range(n * n):
			var dir_up: int = _ramp_up_dir[low_idx]
			if dir_up == RAMP_NONE:
				continue
			var low_x: int = low_idx % n
			var low_z: int = int(float(low_idx) / float(n))
			var high: Vector2i = _neighbor_of(low_x, low_z, dir_up)
			if high.x < 0 or high.x >= n or high.y < 0 or high.y >= n:
				continue
			var high_idx: int = _cell_idx(high.x, high.y, n)
			var high_lvl: int = levels[high_idx]
			var dirs: Array[int] = _perp_dirs(dir_up)
			var left: Vector2i = _neighbor_of(high.x, high.y, dirs[0])
			var right: Vector2i = _neighbor_of(high.x, high.y, dirs[1])
			var front: Array[Vector2i] = [left, high, right]
			var fixes_used: int = 0

			for ci in [0, 2]:
				var c: Vector2i = front[ci]
				if c.x < 0 or c.x >= n or c.y < 0 or c.y >= n:
					continue
				var idx: int = _cell_idx(c.x, c.y, n)
				if levels[idx] > high_lvl + allow_up:
					if ramp_clearance_lower_instead_of_remove and fixes_used < max_fixes:
						levels[idx] = high_lvl + allow_up
						flags |= FIX_LEVELS
						fixes_used += 1
						changed = true
				if ramp_clearance_remove_conflicting_ramps and _ramp_up_dir[idx] != RAMP_NONE and _ramp_up_dir[idx] != dir_up and fixes_used < max_fixes:
					_ramp_up_dir[idx] = RAMP_NONE
					flags |= FIX_PLACED
					fixes_used += 1
					changed = true

			var ok_l: bool = not _ramp_front_is_blocking(left, n, high_lvl, allow_up, low_idx, levels)
			var ok_m: bool = true
			var ok_r: bool = not _ramp_front_is_blocking(right, n, high_lvl, allow_up, low_idx, levels)
			var two_wide_ok: bool = (ok_l and ok_m) or (ok_m and ok_r)
			if ramp_clearance_require_two_wide_exit and not two_wide_ok:
				for c in [left, right]:
					if fixes_used >= max_fixes:
						break
					if c.x < 0 or c.x >= n or c.y < 0 or c.y >= n:
						continue
					var idx2: int = _cell_idx(c.x, c.y, n)
					if levels[idx2] > high_lvl + allow_up and ramp_clearance_lower_instead_of_remove:
						levels[idx2] = high_lvl + allow_up
						flags |= FIX_LEVELS
						fixes_used += 1
						changed = true
					elif ramp_clearance_remove_conflicting_ramps and _ramp_up_dir[idx2] != RAMP_NONE and _ramp_up_dir[idx2] != dir_up:
						_ramp_up_dir[idx2] = RAMP_NONE
						flags |= FIX_PLACED
						fixes_used += 1
						changed = true

				ok_l = not _ramp_front_is_blocking(left, n, high_lvl, allow_up, low_idx, levels)
				ok_r = not _ramp_front_is_blocking(right, n, high_lvl, allow_up, low_idx, levels)
				two_wide_ok = (ok_l and ok_m) or (ok_m and ok_r)
				if not two_wide_ok:
					_ramp_up_dir[low_idx] = RAMP_NONE
					flags |= FIX_PLACED
					changed = true

	if flags != FIX_NONE:
		_prune_ramps_strict()
	return flags

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

func _ready() -> void:
	if mesh_instance == null or collision_shape == null:
		push_error("ArenaBlockyTerrain: Expected nodes 'TerrainBody/TerrainMesh' and 'TerrainBody/TerrainCollision'.")
		return

	if use_rock_shader:
		var sm := ShaderMaterial.new()
		sm.shader = load("res://shaders/blocky_rock.gdshader")
		sm.set_shader_parameter("disp_strength_top", disp_strength_top)
		sm.set_shader_parameter("disp_strength_wall", disp_strength_wall)
		sm.set_shader_parameter("disp_strength_ramp", disp_strength_ramp)
		sm.set_shader_parameter("disp_scale_top", disp_scale_top)
		sm.set_shader_parameter("disp_scale_wall", disp_scale_wall)
		sm.set_shader_parameter("disp_scale_ramp", disp_scale_ramp)
		sm.set_shader_parameter("normal_strength", normal_strength)
		sm.set_shader_parameter("debug_show_vertex_color", debug_vertex_colors)
		sm.set_shader_parameter("debug_show_tag_colors", debug_tag_colors_enabled)
		sm.set_shader_parameter("debug_floor_color", debug_floor_color)
		sm.set_shader_parameter("debug_wall_color", debug_wall_color)
		sm.set_shader_parameter("debug_ramp_color", debug_ramp_color)
		sm.set_shader_parameter("debug_box_color", debug_box_color)
		sm.set_shader_parameter("debug_tag_emission", debug_tag_emission)
		sm.set_shader_parameter("debug_disable_side_disp", false)
		sm.set_shader_parameter("seam_lock_use_world_cell", false)
		sm.set_shader_parameter("grid_origin_xz", Vector2(0.0, 0.0))
		sm.set_shader_parameter("clamp_to_cell", shader_clamp_to_cell)
		sm.set_shader_parameter("cell_margin_m", shader_cell_margin_m)
		sm.set_shader_parameter("snap_y_to_height_step", shader_snap_y_to_height_step)
		sm.set_shader_parameter("height_step", height_step)
		sm.set_shader_parameter("snap_y_strength", shader_snap_y_strength)
		sm.set_shader_parameter("grid_y_min", grid_y0)
		sm.set_shader_parameter("grid_y_max", box_height)
		mesh_instance.material_override = sm
	else:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.material_override = mat

	_ensure_tunnel_nodes()
	_apply_grid_debug_flat_material(grid_debug_force_flat_material)
	_grid_refresh_space_xforms()
	_ensure_grid_wire_node()
	_grid_wire_set_visible(false)
	_ensure_debug_menu()
	_apply_debug_tag_colors()
	_rebuild_debug_labels()

	if randomize_seed_on_start:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		noise_seed = rng.randi()

	if print_seed:
		print("Noise seed:", noise_seed)

	generate()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_1 or e.keycode == KEY_KP_1:
			_toggle_grid_wireframe()
			return

		if e.keycode == debug_menu_toggle_key:
			_toggle_debug_menu()
			return

		if e.keycode == grid_wire_flat_material_toggle_key:
			grid_debug_force_flat_material = not grid_debug_force_flat_material
			_apply_grid_debug_flat_material(grid_debug_force_flat_material)
			return

		if e.keycode == debug_surface_labels_toggle_key:
			_toggle_surface_labels()
			return

		if e.keycode == debug_cell_labels_toggle_key:
			_toggle_cell_labels()
			return

		if e.keycode == debug_tag_color_toggle_key:
			debug_tag_colors_enabled = not debug_tag_colors_enabled
			_apply_debug_tag_colors()
			return

		if e.keycode == KEY_R:
			if randomize_seed_on_regen_key:
				var rng := RandomNumberGenerator.new()
				rng.randomize()
				noise_seed = rng.randi()
				if print_seed:
					print('Noise seed:', noise_seed)
			generate()

func generate() -> void:
	_resolve_vertical_grid_bounds()
	_apply_grid_debug_flat_material(grid_debug_force_flat_material)
	var n: int = max(2, cells_per_side)
	_cell_size = world_size_m / float(n)
	if use_rock_shader and mesh_instance != null:
		var sm := mesh_instance.material_override as ShaderMaterial
		if sm != null:
			sm.set_shader_parameter("cell_size", _cell_size)

	# Center the arena around (0,0) in XZ.
	# Use the resolved grid width (n * cell_size) so every generated cell fits the grid exactly.
	_resolved_world_size = _cell_size * float(n)
	_ox = -_resolved_world_size * 0.5
	_oz = -_resolved_world_size * 0.5

	# Refresh grid-space transforms (handles TerrainMesh/TerrainBody transforms).
	_grid_refresh_space_xforms()

	# Keep shader seam-lock origin aligned to generated cell-space origin.
	for sm in _grid_wire_collect_shader_materials():
		if sm.get_shader_parameter("cell_size") != null:
			sm.set_shader_parameter("cell_size", _cell_size)
		if sm.get_shader_parameter("grid_origin_xz") != null:
			sm.set_shader_parameter("grid_origin_xz", Vector2(_ox, _oz))
		if sm.get_shader_parameter("seam_lock_use_world_cell") != null:
			sm.set_shader_parameter("seam_lock_use_world_cell", false)
		if sm.get_shader_parameter("clamp_to_cell") != null:
			sm.set_shader_parameter("clamp_to_cell", shader_clamp_to_cell)
		if sm.get_shader_parameter("cell_margin_m") != null:
			sm.set_shader_parameter("cell_margin_m", shader_cell_margin_m)
		if sm.get_shader_parameter("snap_y_to_height_step") != null:
			sm.set_shader_parameter("snap_y_to_height_step", shader_snap_y_to_height_step)
		if sm.get_shader_parameter("height_step") != null:
			sm.set_shader_parameter("height_step", height_step)
		if sm.get_shader_parameter("snap_y_strength") != null:
			sm.set_shader_parameter("snap_y_strength", shader_snap_y_strength)
		if sm.get_shader_parameter("debug_show_tag_colors") != null:
			sm.set_shader_parameter("debug_show_tag_colors", debug_tag_colors_enabled)
		if sm.get_shader_parameter("debug_floor_color") != null:
			sm.set_shader_parameter("debug_floor_color", debug_floor_color)
		if sm.get_shader_parameter("debug_wall_color") != null:
			sm.set_shader_parameter("debug_wall_color", debug_wall_color)
		if sm.get_shader_parameter("debug_ramp_color") != null:
			sm.set_shader_parameter("debug_ramp_color", debug_ramp_color)
		if sm.get_shader_parameter("debug_box_color") != null:
			sm.set_shader_parameter("debug_box_color", debug_box_color)
		if sm.get_shader_parameter("debug_tag_emission") != null:
			sm.set_shader_parameter("debug_tag_emission", debug_tag_emission)
		if sm.get_shader_parameter("grid_y_min") != null:
			sm.set_shader_parameter("grid_y_min", grid_y0)
		if sm.get_shader_parameter("grid_y_max") != null:
			sm.set_shader_parameter("grid_y_max", box_height)

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
	_grid_init(n)
	_grid_rebuild_tags(n)
	_surface_registry_reset(n)
	if _grid_wire_visible:
		_grid_wire_rebuild_mesh()

	_build_mesh_and_collision(n)
	_build_tunnel_mesh(n)
	print("Ramp slots:", _count_ramps())
	_print_grid_contract()
	_sync_sun()
	_apply_debug_tag_colors()
	_rebuild_debug_labels()

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

	var half_w: float = _resolved_world_size * 0.5
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
			h = clampf(h, maxf(min_height, _surface_min_y()), minf(max_height, box_height - 0.5))
			h = _quantize(h, height_step)

			_heights[z * n + x] = h

func _quantize(h: float, step: float) -> float:
	if step <= 0.0:
		return h
	var k := roundf((h - grid_y0) / step)
	return grid_y0 + k * step

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

	_tunnel_mask.fill(0)
	_tunnel_hole_mask.fill(0)

func _tunnel_flat_corners(y: float) -> Vector4:
	return Vector4(y, y, y, y)

func _resolve_tunnel_layer(n: int) -> void:
	var floor_y: float = _level_to_h(TUNNEL_FLOOR_LEVEL)
	var ceil_y: float = _level_to_h(TUNNEL_FLOOR_LEVEL + TUNNEL_HEIGHT_LEVELS)

	var roof_min: float = INF
	for z in range(n):
		for x in range(n):
			var c := _cell_corners(x, z)
			var roof: float = minf(minf(c.x, c.y), minf(c.z, c.w))
			roof_min = minf(roof_min, roof)

	var max_ceiling: float = roof_min - tunnel_ceiling_clearance
	if ceil_y > max_ceiling:
		ceil_y = max_ceiling
		floor_y = minf(floor_y, ceil_y - maxf(0.5, height_step))

	_tunnel_floor_resolved = floor_y
	_tunnel_ceil_resolved = ceil_y
	_tunnel_base_floor_y = floor_y
	_tunnel_base_ceil_y = ceil_y

func _tunnel_cell_passable(x: int, z: int, n: int, _ceil_y: float) -> bool:
	# Keep tunnels/shafts away from the outer box walls so surface shafts can have 4 rim walls.
	if x <= 0 or z <= 0 or x >= n - 1 or z >= n - 1:
		return false

	# Never place tunnels/shafts on ramp cells (shafts only; no ramp entrances).
	if enable_ramps and _ramp_up_dir.size() == n * n:
		var idx: int = _idx2(x, z, n)
		if _ramp_up_dir[idx] != RAMP_NONE:
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

func _tunnel_stamp_entrance_shaft(entrance_idx: int) -> void:
	if entrance_idx < 0 or entrance_idx >= _tunnel_mask.size():
		return
	_tunnel_mask[entrance_idx] = 1

func _choose_tunnel_base_depth(_n: int, _entrances: Array[Vector2i]) -> void:
	_tunnel_base_floor_y = _tunnel_floor_resolved
	_tunnel_base_ceil_y = _tunnel_ceil_resolved

func _a_star(n: int, start: Vector2i, goal: Vector2i, ceil_y: float) -> Array[Vector2i]:
	if start == goal:
		return [start]

	# If either endpoint violates the tunnel/shaft constraints, abort.
	if not _tunnel_cell_passable(start.x, start.y, n, ceil_y):
		return []
	if not _tunnel_cell_passable(goal.x, goal.y, n, ceil_y):
		return []

	var open: Array[Vector2i] = [start]
	var came_from: Dictionary = {}
	var g: Dictionary = {start: 0.0}
	var f: Dictionary = {start: float(abs(start.x - goal.x) + abs(start.y - goal.y))}

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

		var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for d in dirs:
			var nb: Vector2i = current + d
			if not _in_bounds(nb.x, nb.y, n):
				continue
			# Enforce the same constraints as entrance selection (no ramp cells / no outer rim).
			if not _tunnel_cell_passable(nb.x, nb.y, n, ceil_y):
				continue
			if not _edge_is_open_at_ceil(n, current, nb, ceil_y):
				continue

			var tentative: float = g.get(current, 1.0e20) + 1.0
			if tentative < g.get(nb, 1.0e20):
				came_from[nb] = current
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

	# Prevent multiple adjacent/diagonal surface holes (this is the most common cause of “hole bleed”
	# and missing shaft side walls).
	var tries: int = 0
	var built: int = 0
	var tunnel_cells: Array[int] = []
	var entrances: Array[Vector2i] = []
	var min_chebyshev_sep: int = 1  # <=1 means adjacent/diagonal; disallow

	while built < tunnel_count and tries < tunnel_count * 24:
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

		# Enforce entrance spacing so we never mark adjacent cells as holes.
		var ok: bool = true
		var candidate_entrances: Array[Vector2i] = [b]
		if built == 0:
			candidate_entrances.push_front(a)
		for c in candidate_entrances:
			for e in entrances:
				if maxi(abs(e.x - c.x), abs(e.y - c.y)) <= min_chebyshev_sep:
					ok = false
					break
			if not ok:
				break
		if not ok:
			continue

		if built == 0:
			entrances.append(a)
		entrances.append(b)

		built += 1

	if entrances.is_empty():
		return

	var endpoints: Array[Vector2i] = []
	var entrance_set := {}
	for entrance in entrances:
		var entrance_idx: int = _idx2(entrance.x, entrance.y, n)
		_tunnel_stamp_entrance_shaft(entrance_idx)
		endpoints.append(entrance)
		entrance_set[entrance_idx] = true

	for i in range(1, endpoints.size()):
		var path: Array[Vector2i] = _a_star(n, endpoints[i - 1], endpoints[i], _tunnel_base_ceil_y)
		for p in path:
			var idx_path: int = _idx2(p.x, p.y, n)
			_tunnel_mask[idx_path] = 1
			tunnel_cells.append(idx_path)

	# Carve exactly one surface cell per shaft entrance (no adjacency, no radius expansion).
	if tunnel_carve_surface_holes:
		_tunnel_hole_mask.fill(0)
		for k in entrance_set.keys():
			var idx: int = int(k)
			if idx >= 0 and idx < _tunnel_hole_mask.size():
				_tunnel_hole_mask[idx] = 1

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
	return int(roundf((h - grid_y0) / maxf(0.0001, height_step)))

func _level_to_h(level: int) -> float:
	return grid_y0 + float(level) * height_step

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
		h = clampf(h, maxf(min_height, _surface_min_y()), minf(max_height, box_height - 0.5))
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

	var clearance_flags: int = _apply_ramp_clearance(n, want_levels, levels)
	if (clearance_flags & FIX_LEVELS) != 0:
		_apply_levels_to_heights(n, levels)
	if clearance_flags != FIX_NONE:
		var post_flags: int = _ensure_global_accessibility(n, want_levels, levels, rng)
		if (post_flags & FIX_LEVELS) != 0:
			_apply_levels_to_heights(n, levels)
			_limit_neighbor_cliffs()
			_fill_pits()
			_ramps_need_regen = true
			return
		elif (post_flags & FIX_PLACED) != 0:
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
				var hole_touches_x_edge: bool = false
				if enable_tunnels and tunnel_carve_surface_holes and _tunnel_hole_mask.size() == n * n:
					hole_touches_x_edge = _tunnel_hole_mask[idx_a] != 0 or _tunnel_hole_mask[idx_b] != 0
				if ramps_openings and not hole_touches_x_edge and _is_ramp_bridge(idx_a, idx_b, RAMP_EAST, want_levels, levels):
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
							st, x1, z0, z1, bot0, bot1, top0, top1, uv_scale_wall, normal_pos_x,
							Vector2i(x, z), Vector2i(x + 1, z)
							)

			if z + 1 < n:
				var idx_c: int = z * n + x
				var idx_d: int = (z + 1) * n + x
				var hole_touches_z_edge: bool = false
				if enable_tunnels and tunnel_carve_surface_holes and _tunnel_hole_mask.size() == n * n:
					hole_touches_z_edge = _tunnel_hole_mask[idx_c] != 0 or _tunnel_hole_mask[idx_d] != 0
				if ramps_openings and not hole_touches_z_edge and _is_ramp_bridge(idx_c, idx_d, RAMP_SOUTH, want_levels, levels):
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
							st, x0, x1, z1, bot0z, bot1z, top0z, top1z, uv_scale_wall, normal_pos_z,
							Vector2i(x, z), Vector2i(x, z + 1)
							)

	# Container walls (keeps everything “inside a box”)
	_add_box_walls(st, outer_floor_height, box_height, uv_scale_wall)

	if build_ceiling:
		_add_ceiling(st, box_height, uv_scale_top)

	st.generate_normals()
	st.generate_tangents()
	var mesh: ArrayMesh = st.commit()
	mesh_instance.mesh = mesh
	_validate_mesh_bounds(mesh, "terrain")
	collision_shape.shape = mesh.create_trimesh_shape()
func _validate_mesh_bounds(mesh: ArrayMesh, label: String) -> void:
	if mesh == null:
		return
	if mesh.get_surface_count() <= 0:
		return
	var arrays := mesh.surface_get_arrays(0)
	if arrays.is_empty():
		return
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if vertices.is_empty():
		return
	var min_x := _ox
	var max_x := _ox + _resolved_world_size
	var min_z := _oz
	var max_z := _oz + _resolved_world_size
	var max_over_y := 0.0
	var max_under_y := 0.0
	var max_snap_err := 0.0
	for v in vertices:
		max_over_y = maxf(max_over_y, v.y - box_height)
		max_under_y = maxf(max_under_y, outer_floor_height - v.y)
		max_snap_err = maxf(max_snap_err, absf(v.y - _quantize_y_to_grid(v.y)))
		if v.x < min_x - 0.01 or v.x > max_x + 0.01 or v.z < min_z - 0.01 or v.z > max_z + 0.01:
			push_warning("%s mesh vertex outside XZ bounds: %s" % [label, str(v)])
			break
	if max_over_y > 0.001 or max_under_y > 0.001 or max_snap_err > 0.001:
		push_warning("%s bounds check: over_y=%.4f under_y=%.4f snap_err=%.4f" % [label, max_over_y, max_under_y, max_snap_err])

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

func _sort_vec3_y_desc(a: Vector3, b: Vector3) -> bool:
	return a.y > b.y

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
			var cell := Vector2i(x, z)

			var has_w: bool = false
			var has_e: bool = false
			var has_n: bool = false
			var has_s: bool = false

			var floors := PackedFloat32Array([floor_y, floor_y, floor_y, floor_y])
			var c00: float = floors[0] + tunnel_height_y
			var c10: float = floors[1] + tunnel_height_y
			var c11: float = floors[2] + tunnel_height_y
			var c01: float = floors[3] + tunnel_height_y

			var tf_a := Vector3(x0, floors[0], z0)
			var tf_b := Vector3(x1, floors[1], z0)
			var tf_c := Vector3(x1, floors[2], z1)
			var tf_d := Vector3(x0, floors[3], z1)
			_add_quad(
				st,
				tf_a,
				tf_b,
				tf_c,
				tf_d,
				Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
				tunnel_color
			)
			_register_surface(SurfaceKind.TUNNEL_FLOOR, cell, SurfaceSide.NONE, Vector2i(-1, -1), SurfaceSide.NONE, PackedVector3Array([tf_a, tf_b, tf_c, tf_d]), Vector3.UP, {"level": grid_y_to_level(floor_y)})

			if not is_entrance:
				var tc_a := Vector3(x0, c01, z1)
				var tc_b := Vector3(x1, c11, z1)
				var tc_c := Vector3(x1, c10, z0)
				var tc_d := Vector3(x0, c00, z0)
				_add_quad(
					st,
					tc_a,
					tc_b,
					tc_c,
					tc_d,
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
				_register_surface(SurfaceKind.TUNNEL_CEIL, cell, SurfaceSide.NONE, Vector2i(-1, -1), SurfaceSide.NONE, PackedVector3Array([tc_a, tc_b, tc_c, tc_d]), Vector3.DOWN, {"level": grid_y_to_level(ceil_y)})
			else:
				var surf: Vector4 = _cell_corners(x, z)
				# West wall
				var tw_a := Vector3(x0, floors[0], z0)
				var tw_b := Vector3(x0, floors[3], z1)
				var tw_c := Vector3(x0, surf.w, z1)
				var tw_d := Vector3(x0, surf.x, z0)
				_add_quad(
					st,
					tw_a,
					tw_b,
					tw_c,
					tw_d,
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
				_register_surface(SurfaceKind.TUNNEL_WALL, cell, SurfaceSide.W, Vector2i(-1, -1), SurfaceSide.NONE, PackedVector3Array([tw_a, tw_b, tw_c, tw_d]), Vector3.LEFT, {"y0_level": grid_y_to_level(floor_y), "y1_level": grid_y_to_level(surf.x)})
				# East wall
				var te_a := Vector3(x1, floors[2], z1)
				var te_b := Vector3(x1, floors[1], z0)
				var te_c := Vector3(x1, surf.y, z0)
				var te_d := Vector3(x1, surf.z, z1)
				_add_quad(
					st,
					te_a,
					te_b,
					te_c,
					te_d,
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
				_register_surface(SurfaceKind.TUNNEL_WALL, cell, SurfaceSide.E, Vector2i(-1, -1), SurfaceSide.NONE, PackedVector3Array([te_a, te_b, te_c, te_d]), Vector3.RIGHT, {"y0_level": grid_y_to_level(floor_y), "y1_level": grid_y_to_level(surf.y)})
				# North wall
				var tn_a := Vector3(x1, floors[1], z0)
				var tn_b := Vector3(x0, floors[0], z0)
				var tn_c := Vector3(x0, surf.x, z0)
				var tn_d := Vector3(x1, surf.y, z0)
				_add_quad(
					st,
					tn_a,
					tn_b,
					tn_c,
					tn_d,
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
				_register_surface(SurfaceKind.TUNNEL_WALL, cell, SurfaceSide.N, Vector2i(-1, -1), SurfaceSide.NONE, PackedVector3Array([tn_a, tn_b, tn_c, tn_d]), Vector3.BACK, {"y0_level": grid_y_to_level(floor_y), "y1_level": grid_y_to_level(surf.x)})
				# South wall
				var ts_a := Vector3(x0, floors[3], z1)
				var ts_b := Vector3(x1, floors[2], z1)
				var ts_c := Vector3(x1, surf.z, z1)
				var ts_d := Vector3(x0, surf.w, z1)
				_add_quad(
					st,
					ts_a,
					ts_b,
					ts_c,
					ts_d,
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
				_register_surface(SurfaceKind.TUNNEL_WALL, cell, SurfaceSide.S, Vector2i(-1, -1), SurfaceSide.NONE, PackedVector3Array([ts_a, ts_b, ts_c, ts_d]), Vector3.FORWARD, {"y0_level": grid_y_to_level(floor_y), "y1_level": grid_y_to_level(surf.z)})
				continue

			if x > 0 and _tunnel_mask[_idx2(x - 1, z, n)] != 0:
				var nb_floors_w: PackedFloat32Array = PackedFloat32Array([floor_y, floor_y, floor_y, floor_y])
				var edge_a_w: Vector2 = _edge_pair(Vector4(floors[0], floors[1], floors[2], floors[3]), 1)
				var edge_b_w: Vector2 = _edge_pair(Vector4(nb_floors_w[0], nb_floors_w[1], nb_floors_w[2], nb_floors_w[3]), 0)
				has_w = _edges_match(edge_a_w, edge_b_w)

			if not has_w:
				var w_a := Vector3(x0, floors[0], z0)
				var w_b := Vector3(x0, floors[3], z1)
				var w_c := Vector3(x0, c01, z1)
				var w_d := Vector3(x0, c00, z0)
				_add_quad(
					st,
					w_a,
					w_b,
					w_c,
					w_d,
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
				_register_surface(SurfaceKind.TUNNEL_WALL, cell, SurfaceSide.W, Vector2i(-1, -1), SurfaceSide.NONE, PackedVector3Array([w_a, w_b, w_c, w_d]), Vector3.LEFT, {"y0_level": grid_y_to_level(floor_y), "y1_level": grid_y_to_level(ceil_y)})
			if x < n - 1 and _tunnel_mask[_idx2(x + 1, z, n)] != 0:
				var nb_floors_e: PackedFloat32Array = PackedFloat32Array([floor_y, floor_y, floor_y, floor_y])
				var edge_a_e: Vector2 = _edge_pair(Vector4(floors[0], floors[1], floors[2], floors[3]), 0)
				var edge_b_e: Vector2 = _edge_pair(Vector4(nb_floors_e[0], nb_floors_e[1], nb_floors_e[2], nb_floors_e[3]), 1)
				has_e = _edges_match(edge_a_e, edge_b_e)

			if not has_e:
				var e_a := Vector3(x1, floors[2], z1)
				var e_b := Vector3(x1, floors[1], z0)
				var e_c := Vector3(x1, c10, z0)
				var e_d := Vector3(x1, c11, z1)
				_add_quad(
					st,
					e_a,
					e_b,
					e_c,
					e_d,
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
				_register_surface(SurfaceKind.TUNNEL_WALL, cell, SurfaceSide.E, Vector2i(-1, -1), SurfaceSide.NONE, PackedVector3Array([e_a, e_b, e_c, e_d]), Vector3.RIGHT, {"y0_level": grid_y_to_level(floor_y), "y1_level": grid_y_to_level(ceil_y)})
			if z > 0 and _tunnel_mask[_idx2(x, z - 1, n)] != 0:
				var nb_floors_n: PackedFloat32Array = PackedFloat32Array([floor_y, floor_y, floor_y, floor_y])
				var edge_a_n: Vector2 = _edge_pair(Vector4(floors[0], floors[1], floors[2], floors[3]), 2)
				var edge_b_n: Vector2 = _edge_pair(Vector4(nb_floors_n[0], nb_floors_n[1], nb_floors_n[2], nb_floors_n[3]), 3)
				has_n = _edges_match(edge_a_n, edge_b_n)

			if not has_n:
				var n_a := Vector3(x1, floors[1], z0)
				var n_b := Vector3(x0, floors[0], z0)
				var n_c := Vector3(x0, c00, z0)
				var n_d := Vector3(x1, c10, z0)
				_add_quad(
					st,
					n_a,
					n_b,
					n_c,
					n_d,
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
				_register_surface(SurfaceKind.TUNNEL_WALL, cell, SurfaceSide.N, Vector2i(-1, -1), SurfaceSide.NONE, PackedVector3Array([n_a, n_b, n_c, n_d]), Vector3.BACK, {"y0_level": grid_y_to_level(floor_y), "y1_level": grid_y_to_level(ceil_y)})
			if z < n - 1 and _tunnel_mask[_idx2(x, z + 1, n)] != 0:
				var nb_floors_s: PackedFloat32Array = PackedFloat32Array([floor_y, floor_y, floor_y, floor_y])
				var edge_a_s: Vector2 = _edge_pair(Vector4(floors[0], floors[1], floors[2], floors[3]), 3)
				var edge_b_s: Vector2 = _edge_pair(Vector4(nb_floors_s[0], nb_floors_s[1], nb_floors_s[2], nb_floors_s[3]), 2)
				has_s = _edges_match(edge_a_s, edge_b_s)

			if not has_s:
				var s_a := Vector3(x0, floors[3], z1)
				var s_b := Vector3(x1, floors[2], z1)
				var s_c := Vector3(x1, c11, z1)
				var s_d := Vector3(x0, c01, z1)
				_add_quad(
					st,
					s_a,
					s_b,
					s_c,
					s_d,
					Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale,
					tunnel_color
				)
				_register_surface(SurfaceKind.TUNNEL_WALL, cell, SurfaceSide.S, Vector2i(-1, -1), SurfaceSide.NONE, PackedVector3Array([s_a, s_b, s_c, s_d]), Vector3.FORWARD, {"y0_level": grid_y_to_level(floor_y), "y1_level": grid_y_to_level(ceil_y)})


	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	_tunnel_mesh_instance.mesh = mesh
	_tunnel_collision_shape.shape = mesh.create_trimesh_shape()

func _sync_sun() -> void:
	var sun := get_node_or_null("SUN") as DirectionalLight3D
	if sun == null:
		return

	var center := global_position + Vector3(_ox + _resolved_world_size * 0.5, 0.0, _oz + _resolved_world_size * 0.5)
	sun.global_position = center + Vector3(0.0, sun_height, 0.0)
	sun.look_at(center, Vector3.UP)

# -----------------------------
# Container primitives
# -----------------------------
func _add_floor(st: SurfaceTool, y: float, uv_scale: float) -> void:
	var a := Vector3(_ox, y, _oz)
	var b := Vector3(_ox + _resolved_world_size, y, _oz)
	var c := Vector3(_ox + _resolved_world_size, y, _oz + _resolved_world_size)
	var d := Vector3(_ox, y, _oz + _resolved_world_size)
	var u0 := Vector2(0.0, 0.0) * uv_scale
	var u1 := Vector2(1.0, 0.0) * uv_scale
	var u2 := Vector2(1.0, 1.0) * uv_scale
	var u3 := Vector2(0.0, 1.0) * uv_scale
	var bc := box_color
	bc.a = SURF_BOX
	_add_quad(st, a, b, c, d, u0, u1, u2, u3, bc)

func _add_box_walls(st: SurfaceTool, y0: float, y1: float, uv_scale: float) -> void:
	# West wall (x = _ox)
	_add_box_wall_plane(st, Vector3(_ox, y0, _oz), Vector3(_ox, y0, _oz + _resolved_world_size), y1, uv_scale, true)
	# East wall (x = _ox + _resolved_world_size)
	_add_box_wall_plane(st, Vector3(_ox + _resolved_world_size, y0, _oz + _resolved_world_size), Vector3(_ox + _resolved_world_size, y0, _oz), y1, uv_scale, true)
	# North wall (z = _oz)
	_add_box_wall_plane(st, Vector3(_ox + _resolved_world_size, y0, _oz), Vector3(_ox, y0, _oz), y1, uv_scale, true)
	# South wall (z = _oz + _resolved_world_size)
	_add_box_wall_plane(st, Vector3(_ox, y0, _oz + _resolved_world_size), Vector3(_ox + _resolved_world_size, y0, _oz + _resolved_world_size), y1, uv_scale, true)

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
	var b := Vector3(_ox + _resolved_world_size, y, _oz)
	var c := Vector3(_ox + _resolved_world_size, y, _oz + _resolved_world_size)
	var d := Vector3(_ox, y, _oz + _resolved_world_size)
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
func _emit_vertical_face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2, vcol: Color, eps: float = 0.0005) -> void:
	var left_h: float = absf(a.y - d.y)
	var right_h: float = absf(b.y - c.y)
	if left_h > eps and right_h > eps:
		_add_quad_uv2(st, a, b, c, d,
			ua, ub, uc, ud,
			Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
			vcol
		)
		return
	if left_h > eps:
		st.set_color(vcol)
		st.set_uv(ua); st.set_uv2(Vector2(0, 0)); st.add_vertex(a)
		st.set_uv(uc); st.set_uv2(Vector2(1, 1)); st.add_vertex(c)
		st.set_uv(ud); st.set_uv2(Vector2(0, 1)); st.add_vertex(d)
		return
	if right_h > eps:
		st.set_color(vcol)
		st.set_uv(ua); st.set_uv2(Vector2(0, 0)); st.add_vertex(a)
		st.set_uv(ub); st.set_uv2(Vector2(1, 0)); st.add_vertex(b)
		st.set_uv(uc); st.set_uv2(Vector2(1, 1)); st.add_vertex(c)

func _add_wall_x_between(st: SurfaceTool, x_edge: float, z0: float, z1: float,
	low0: float, low1: float, high0: float, high1: float, uv_scale: float,
	normal_pos_x: bool, cell_a: Vector2i = Vector2i(-1, -1), cell_b: Vector2i = Vector2i(-1, -1)) -> void:
	var eps: float = 0.0005
	var d0: float = absf(high0 - low0)
	var d1: float = absf(high1 - low1)
	if d0 <= eps and d1 <= eps:
		return

	var side_a := SurfaceSide.E
	var side_b := SurfaceSide.W
	var y_split: float = minf(high0, high1)
	var ua := Vector2(0.0, 1.0 * uv_scale)
	var ub := Vector2(1.0 * uv_scale, 1.0 * uv_scale)
	var uc := Vector2(1.0 * uv_scale, 0.0)
	var ud := Vector2(0.0, 0.0)

	# Rectangular wall piece (always tagged WALL)
	if y_split > minf(low0, low1) + eps:
		var wa := Vector3(x_edge, y_split, z0)
		var wb := Vector3(x_edge, y_split, z1)
		var wc := Vector3(x_edge, low1, z1)
		var wd := Vector3(x_edge, low0, z0)
		if not normal_pos_x:
			var tmpw: Vector3 = wa
			wa = wb
			wb = tmpw
			tmpw = wc
			wc = wd
			wd = tmpw
		_register_surface(SurfaceKind.WALL, cell_a, side_a, cell_b, side_b, PackedVector3Array([wa, wb, wc, wd]), Vector3.ZERO, {"y0_level": grid_y_to_level(minf(low0, low1)), "y1_level": grid_y_to_level(y_split)})
		var wall_col := terrain_color
		wall_col.a = SURF_WALL
		_emit_vertical_face(st, wa, wb, wc, wd, ua, ub, uc, ud, wall_col, eps)

	# Trapezoid cap piece (separate from WALL, tagged as RAMP)
	if absf(high0 - high1) > eps:
		var ca := Vector3(x_edge, high0, z0)
		var cb := Vector3(x_edge, high1, z1)
		var cc := Vector3(x_edge, y_split, z1)
		var cd := Vector3(x_edge, y_split, z0)
		if not normal_pos_x:
			var tmpc: Vector3 = ca
			ca = cb
			cb = tmpc
			tmpc = cc
			cc = cd
			cd = tmpc
		_register_surface(SurfaceKind.RAMP, cell_a, side_a, cell_b, side_b, PackedVector3Array([ca, cb, cc, cd]), Vector3.ZERO, {"y0_level": grid_y_to_level(y_split), "y1_level": grid_y_to_level(maxf(high0, high1))})
		var cap_col := terrain_color
		cap_col.a = SURF_RAMP
		_emit_vertical_face(st, ca, cb, cc, cd, ua, ub, uc, ud, cap_col, eps)

func _add_wall_z_between(st: SurfaceTool, x0: float, x1: float, z_edge: float,
	low0: float, low1: float, high0: float, high1: float, uv_scale: float,
	normal_pos_z: bool, cell_a: Vector2i = Vector2i(-1, -1), cell_b: Vector2i = Vector2i(-1, -1)) -> void:
	var eps: float = 0.0005
	var d0: float = absf(high0 - low0)
	var d1: float = absf(high1 - low1)
	if d0 <= eps and d1 <= eps:
		return

	var side_a := SurfaceSide.S
	var side_b := SurfaceSide.N
	var y_split: float = minf(high0, high1)
	var ua := Vector2(0.0, 1.0 * uv_scale)
	var ub := Vector2(1.0 * uv_scale, 1.0 * uv_scale)
	var uc := Vector2(1.0 * uv_scale, 0.0)
	var ud := Vector2(0.0, 0.0)

	# Rectangular wall piece (always tagged WALL)
	if y_split > minf(low0, low1) + eps:
		var wa := Vector3(x0, y_split, z_edge)
		var wb := Vector3(x1, y_split, z_edge)
		var wc := Vector3(x1, low1, z_edge)
		var wd := Vector3(x0, low0, z_edge)
		if normal_pos_z:
			var tmpw: Vector3 = wa
			wa = wb
			wb = tmpw
			tmpw = wc
			wc = wd
			wd = tmpw
		_register_surface(SurfaceKind.WALL, cell_a, side_a, cell_b, side_b, PackedVector3Array([wa, wb, wc, wd]), Vector3.ZERO, {"y0_level": grid_y_to_level(minf(low0, low1)), "y1_level": grid_y_to_level(y_split)})
		var wall_col := terrain_color
		wall_col.a = SURF_WALL
		_emit_vertical_face(st, wa, wb, wc, wd, ua, ub, uc, ud, wall_col, eps)

	# Trapezoid cap piece (separate from WALL, tagged as RAMP)
	if absf(high0 - high1) > eps:
		var ca := Vector3(x0, high0, z_edge)
		var cb := Vector3(x1, high1, z_edge)
		var cc := Vector3(x1, y_split, z_edge)
		var cd := Vector3(x0, y_split, z_edge)
		if normal_pos_z:
			var tmpc: Vector3 = ca
			ca = cb
			cb = tmpc
			tmpc = cc
			cc = cd
			cd = tmpc
		_register_surface(SurfaceKind.RAMP, cell_a, side_a, cell_b, side_b, PackedVector3Array([ca, cb, cc, cd]), Vector3.ZERO, {"y0_level": grid_y_to_level(y_split), "y1_level": grid_y_to_level(maxf(high0, high1))})
		var cap_col := terrain_color
		cap_col.a = SURF_RAMP
		_emit_vertical_face(st, ca, cb, cc, cd, ua, ub, uc, ud, cap_col, eps)

# -----------------------------
# Quad writer
# -----------------------------
func _add_cell_top_grid(
	st: SurfaceTool,
	cell_x: int, cell_z: int,
	x0: float, x1: float, z0: float, z1: float,
	corners: Vector4,
	uv_scale: float,
	color: Color
) -> void:
	var h00 := corners.x
	var h10 := corners.y
	var h11 := corners.z
	var h01 := corners.w
	var idx: int = cell_z * max(2, cells_per_side) + cell_x
	var ramp_dir: int = _ramp_up_dir[idx] if idx < _ramp_up_dir.size() else RAMP_NONE
	var is_ramp: bool = ramp_dir != RAMP_NONE

	var a := Vector3(x0, h00, z0)
	var b := Vector3(x1, h10, z0)
	var c := Vector3(x1, h11, z1)
	var d := Vector3(x0, h01, z1)

	var ua := _ramp_uv(0.0, 0.0, ramp_dir) if is_ramp else Vector2(0.0, 0.0)
	var ub := _ramp_uv(1.0, 0.0, ramp_dir) if is_ramp else Vector2(1.0, 0.0)
	var uc := _ramp_uv(1.0, 1.0, ramp_dir) if is_ramp else Vector2(1.0, 1.0)
	var ud := _ramp_uv(0.0, 1.0, ramp_dir) if is_ramp else Vector2(0.0, 1.0)

	ua *= uv_scale
	ub *= uv_scale
	uc *= uv_scale
	ud *= uv_scale

	var verts := PackedVector3Array([a, b, c, d])
	var floor_level := grid_y_to_level((h00 + h10 + h11 + h01) * 0.25)
	if is_ramp:
		_register_surface(SurfaceKind.RAMP, Vector2i(cell_x, cell_z), SurfaceSide.NONE, Vector2i(-1, -1), SurfaceSide.NONE, verts, Vector3.ZERO, {"floor_level": floor_level, "ramp_dir": ramp_dir})
	else:
		_register_surface(SurfaceKind.FLOOR, Vector2i(cell_x, cell_z), SurfaceSide.NONE, Vector2i(-1, -1), SurfaceSide.NONE, verts, Vector3.UP, {"floor_level": floor_level})

	_add_quad_uv2(
		st,
		a, b, c, d,
		ua, ub, uc, ud,
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
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
