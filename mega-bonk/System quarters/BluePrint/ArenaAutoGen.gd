extends Node3D
class_name ArenaAutoGen

const DIRS4: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

const CANONICAL_EMPTY: int = 0b0000
const CANONICAL_FULL: int = 0b1111
const CANONICAL_CORNER: int = 0b0001
const CANONICAL_EDGE: int = 0b0011
const CANONICAL_INVERSE_CORNER: int = 0b0111
const CANONICAL_CHECKER: int = 0b0101

@export var auto_generate: bool = true

@export var grid_w: int = 48
@export var grid_h: int = 48
@export_range(0.0, 1.0, 0.01) var fill_percent: float = 0.48
@export var smoothing_steps: int = 6

@export var ensure_connected: bool = true
@export var border: int = 1

@export var cell_size: float = 8.0
@export var floor_thickness: float = 0.25

enum OriginMode { MIN_CORNER, CENTERED, CUSTOM_ANCHOR }
enum LayoutMode { LEGACY_CORNERS, DUAL_FROM_CELLS }

@export var origin_mode: OriginMode = OriginMode.CUSTOM_ANCHOR
@export var origin_offset: Vector3 = Vector3.ZERO
@export var origin_anchor_path: NodePath

@export var layout_mode: LayoutMode = LayoutMode.LEGACY_CORNERS

@export var bind_to_wire_grid: bool = false
@export var wire_grid_origin_path: NodePath
@export var wire_grid_bounds_mesh_path: NodePath
@export var bounds_override_origin: bool = false
@export var wire_grid_use_step_size_from_grid: bool = false
@export var use_grid_depth_for_h: bool = true
@export var show_bounds_debug: bool = false
@export var show_wire_grid: bool = true
@export var show_main_grid_overlay: bool = true
@export var show_dual_grid_overlay: bool = true
@export var show_dual_grid_points: bool = true
@export var main_grid_color: Color = Color(1.0, 0.55, 0.0, 1.0)
@export var dual_grid_color: Color = Color(0.2, 0.3, 1.0, 1.0)
@export var dual_point_color: Color = Color(0.2, 0.3, 1.0, 1.0)
@export_range(0.02, 0.5, 0.01) var dual_point_radius: float = 0.12
@export var wire_grid_y: float = 0.05
@export var wire_grid_draw_volume: bool = false
@export var wire_grid_height_cells: int = 48
@export var debug_grid_action: StringName = &"toggle_arena_grid"
@export var show_deformed_floor_mesh: bool = false
@export_range(0.0, 0.2, 0.01) var deformed_offset_fraction: float = 0.15

@export var make_walls: bool = true
@export var wall_height: float = 3.0
@export var wall_thickness: float = 0.25

@export var use_random_seed: bool = true
@export var seed_value: int = 12345
@export var randomize_on_run: bool = false

@export var use_pattern_stamping: bool = true
@export var pieces_replace_base_floor: bool = false
@export var piece_height_epsilon: float = 0.01
@export var checker_is_solid: bool = true

@export var mesh_full_variants: Array[Mesh] = []
@export var mesh_edge_variants: Array[Mesh] = []
@export var mesh_corner_variants: Array[Mesh] = []
@export var mesh_inverse_corner_variants: Array[Mesh] = []
@export var mesh_checker_variants: Array[Mesh] = []

@export var piece_mesh_3x3_full: Mesh
@export var piece_mesh_2x3_full: Mesh
@export var piece_mesh_2x2_full: Mesh
@export var piece_mesh_5x1_edge: Mesh
@export var piece_mesh_4x1_edge: Mesh
@export var piece_mesh_3x1_edge: Mesh
@export var piece_mesh_3x2_bay: Mesh
@export var piece_mesh_2x2_bay: Mesh
@export var piece_mesh_corner_cluster: Mesh

@onready var floor_mmi: MultiMeshInstance3D = $"Arena/FloorTiles" as MultiMeshInstance3D
@onready var floor_full_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Floor_full") as MultiMeshInstance3D
@onready var floor_edge_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Floor_edge") as MultiMeshInstance3D
@onready var floor_corner_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Floor_corner") as MultiMeshInstance3D
@onready var floor_inverse_corner_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Floor_inverse_corner") as MultiMeshInstance3D
@onready var floor_checker_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Floor_checker") as MultiMeshInstance3D

@onready var piece_3x3_full_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Piece_3x3_full") as MultiMeshInstance3D
@onready var piece_2x3_full_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Piece_2x3_full") as MultiMeshInstance3D
@onready var piece_2x2_full_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Piece_2x2_full") as MultiMeshInstance3D
@onready var piece_5x1_edge_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Piece_5x1_edge") as MultiMeshInstance3D
@onready var piece_4x1_edge_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Piece_4x1_edge") as MultiMeshInstance3D
@onready var piece_3x1_edge_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Piece_3x1_edge") as MultiMeshInstance3D
@onready var piece_3x2_bay_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Piece_3x2_bay") as MultiMeshInstance3D
@onready var piece_2x2_bay_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Piece_2x2_bay") as MultiMeshInstance3D
@onready var piece_corner_cluster_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Piece_corner_cluster") as MultiMeshInstance3D

@onready var wall_mmi: MultiMeshInstance3D = $"Arena/WallTiles" as MultiMeshInstance3D
@onready var wire_grid_main_mi: MeshInstance3D = get_node_or_null("ArenaWireGridMain") as MeshInstance3D
@onready var wire_grid_dual_mi: MeshInstance3D = get_node_or_null("ArenaWireGridDual") as MeshInstance3D
@onready var dual_points_mmi: MultiMeshInstance3D = get_node_or_null("ArenaDualGridPoints") as MultiMeshInstance3D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _corners: PackedByteArray
var _cells: PackedByteArray
var _tiles: PackedByteArray
var _occupied: PackedByteArray
var _piece_transforms: Dictionary = {}
var _wire_grid_main_material: StandardMaterial3D
var _wire_grid_dual_material: StandardMaterial3D
var _dual_points_material: StandardMaterial3D
var _deformed_floor_mi: MeshInstance3D
var _deformed_floor_material: StandardMaterial3D
var _deformed_noise_seed: int = 0
var _mesh_variant_seed: int = 0

func _ready() -> void:
	if wall_mmi == null:
		push_error("ArenaAutoGen: Missing MultiMeshInstance3D node at Arena/WallTiles")
		return

	if not _has_variant_floor_nodes() and floor_mmi == null:
		push_error("ArenaAutoGen: Missing floor renderer. Add Arena/FloorTiles or variant nodes Arena/Floor_*")
		return

	if use_random_seed or randomize_on_run:
		_rng.randomize()
		_deformed_noise_seed = int(_rng.randi())
		_mesh_variant_seed = int(_rng.randi())
	else:
		_rng.seed = seed_value
		_deformed_noise_seed = seed_value
		_mesh_variant_seed = seed_value

	_ensure_deformed_floor_node()

	if bind_to_wire_grid:
		call_deferred("_sync_and_generate_if_needed")
	else:
		_update_bounds_mesh_from_grid()
		_update_wire_grid_debug()
		_update_deformed_floor_visual()
		if auto_generate:
			generate()

func _sync_and_generate_if_needed() -> void:
	await get_tree().process_frame
	_sync_to_wire_grid()
	_update_bounds_mesh_from_grid()
	_update_wire_grid_debug()
	_update_deformed_floor_visual()
	if auto_generate:
		generate()

func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action(debug_grid_action) and event.is_action_pressed(debug_grid_action):
		show_wire_grid = not show_wire_grid
		_update_wire_grid_debug()

func _sync_to_wire_grid() -> void:
	if not bind_to_wire_grid:
		return

	var grid_node: Node = get_node_or_null("/root/Grid")
	if grid_node != null:
		var step: Variant = grid_node.get("STEP_SIZE")
		if wire_grid_use_step_size_from_grid and step is Vector3:
			var step_x: float = (step as Vector3).x
			if step_x > 0.0001:
				cell_size = step_x

		var width_value: Variant = grid_node.get("grid_width")
		if width_value is int and int(width_value) > 0:
			grid_w = int(width_value)

		var h_key: String = "grid_depth" if use_grid_depth_for_h else "grid_height"
		var height_value: Variant = grid_node.get(h_key)
		if height_value is int and int(height_value) > 0:
			grid_h = int(height_value)

	var origin_node: Node = get_node_or_null(wire_grid_origin_path)
	if origin_node is Node3D:
		origin_mode = OriginMode.CUSTOM_ANCHOR
		origin_anchor_path = wire_grid_origin_path

	var bounds_node: Node = get_node_or_null(wire_grid_bounds_mesh_path)
	var bounds_mi: MeshInstance3D = _resolve_bounds_mesh(bounds_node)
	if bounds_mi != null and bounds_mi.mesh != null:
		var to_self: Transform3D = global_transform.affine_inverse() * bounds_mi.global_transform
		var aabb_self: AABB = _transform_aabb(bounds_mi.mesh.get_aabb(), to_self)
		var w_from_bounds: int = int(floor(aabb_self.size.x / max(cell_size, 0.0001)))
		var h_from_bounds: int = int(floor(aabb_self.size.z / max(cell_size, 0.0001)))
		if w_from_bounds > 0:
			grid_w = w_from_bounds
		if h_from_bounds > 0:
			grid_h = h_from_bounds

		if bounds_override_origin:
			origin_mode = OriginMode.MIN_CORNER
			origin_offset = Vector3(aabb_self.position.x, origin_offset.y, aabb_self.position.z)

func _resolve_bounds_mesh(node: Node) -> MeshInstance3D:
	if node == null:
		return null
	if node is MeshInstance3D:
		return node as MeshInstance3D
	var meshes: Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		return null
	return meshes[0] as MeshInstance3D

func _update_bounds_mesh_from_grid() -> void:
	var bounds_node: Node = get_node_or_null(wire_grid_bounds_mesh_path)
	var bounds_mi: MeshInstance3D = _resolve_bounds_mesh(bounds_node)
	if bounds_mi == null:
		return

	bounds_mi.visible = show_bounds_debug

	var sx: float = float(grid_w) * cell_size
	var sz: float = float(grid_h) * cell_size
	var box: BoxMesh = bounds_mi.mesh as BoxMesh
	if box != null:
		box.size = Vector3(sx, box.size.y, sz)

	if bounds_mi.get_parent() is Node3D and (bounds_mi.get_parent() as Node3D) == get_node_or_null("GridAnchor"):
		bounds_mi.position = Vector3(sx * 0.5, bounds_mi.position.y, sz * 0.5)

func _append_wire_grid_plane_lines(m: ImmediateMesh, w: int, h: int, step: float, gx: Transform3D, y: float, offset_x: float, offset_z: float) -> void:
	var max_x: float = float(w) * step
	var max_z: float = float(h) * step

	for x in range(w + 1):
		var px: float = float(x) * step + offset_x
		var a: Vector3 = gx * Vector3(px, 0.0, offset_z)
		var b: Vector3 = gx * Vector3(px, 0.0, max_z + offset_z)
		a.y += y
		b.y += y
		m.surface_add_vertex(a)
		m.surface_add_vertex(b)

	for z in range(h + 1):
		var pz: float = float(z) * step + offset_z
		var a2: Vector3 = gx * Vector3(offset_x, 0.0, pz)
		var b2: Vector3 = gx * Vector3(max_x + offset_x, 0.0, pz)
		a2.y += y
		b2.y += y
		m.surface_add_vertex(a2)
		m.surface_add_vertex(b2)

func _build_wire_grid_mesh_offset(w: int, h: int, step: float, gx: Transform3D, offset_x: float, offset_z: float) -> ImmediateMesh:
	var m: ImmediateMesh = ImmediateMesh.new()
	m.surface_begin(Mesh.PRIMITIVE_LINES)
	_append_wire_grid_plane_lines(m, w, h, step, gx, wire_grid_y, offset_x, offset_z)

	if offset_x == 0.0 and offset_z == 0.0 and wire_grid_draw_volume:
		var max_x: float = float(w) * step
		var max_z: float = float(h) * step
		var y: float = wire_grid_y
		var height: float = float(max(wire_grid_height_cells, 1)) * step
		for x in range(w + 1):
			var px2: float = float(x) * step
			var b0: Vector3 = gx * Vector3(px2, 0.0, 0.0)
			var b1: Vector3 = gx * Vector3(px2, 0.0, max_z)
			m.surface_add_vertex(b0 + Vector3(0.0, y, 0.0))
			m.surface_add_vertex(b0 + Vector3(0.0, y + height, 0.0))
			m.surface_add_vertex(b1 + Vector3(0.0, y, 0.0))
			m.surface_add_vertex(b1 + Vector3(0.0, y + height, 0.0))

		for z in range(h + 1):
			var pz2: float = float(z) * step
			var c0: Vector3 = gx * Vector3(0.0, 0.0, pz2)
			var c1: Vector3 = gx * Vector3(max_x, 0.0, pz2)
			m.surface_add_vertex(c0 + Vector3(0.0, y, 0.0))
			m.surface_add_vertex(c0 + Vector3(0.0, y + height, 0.0))
			m.surface_add_vertex(c1 + Vector3(0.0, y, 0.0))
			m.surface_add_vertex(c1 + Vector3(0.0, y + height, 0.0))

		var t00: Vector3 = gx * Vector3(0.0, 0.0, 0.0) + Vector3(0.0, y + height, 0.0)
		var t10: Vector3 = gx * Vector3(max_x, 0.0, 0.0) + Vector3(0.0, y + height, 0.0)
		var t11: Vector3 = gx * Vector3(max_x, 0.0, max_z) + Vector3(0.0, y + height, 0.0)
		var t01: Vector3 = gx * Vector3(0.0, 0.0, max_z) + Vector3(0.0, y + height, 0.0)
		m.surface_add_vertex(t00)
		m.surface_add_vertex(t10)
		m.surface_add_vertex(t10)
		m.surface_add_vertex(t11)
		m.surface_add_vertex(t11)
		m.surface_add_vertex(t01)
		m.surface_add_vertex(t01)
		m.surface_add_vertex(t00)

	m.surface_end()
	return m

func _make_unshaded_mat(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	return mat

func _update_dual_grid_points() -> void:
	if dual_points_mmi == null:
		return

	dual_points_mmi.visible = show_wire_grid and show_dual_grid_points
	if not dual_points_mmi.visible:
		return

	var gx: Transform3D = _grid_xform_local()
	var sphere := SphereMesh.new()
	sphere.radius = dual_point_radius
	sphere.height = dual_point_radius * 2.0

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sphere
	mm.instance_count = grid_w * grid_h

	var i: int = 0
	for y in range(grid_h):
		for x in range(grid_w):
			var p := gx * Vector3((x + 0.5) * cell_size, 0.0, (y + 0.5) * cell_size)
			p.y += wire_grid_y
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
			i += 1

	dual_points_mmi.multimesh = mm
	if _dual_points_material == null:
		_dual_points_material = _make_unshaded_mat(dual_point_color)
	else:
		_dual_points_material.albedo_color = dual_point_color
	dual_points_mmi.material_override = _dual_points_material

func _update_wire_grid_debug() -> void:
	var gx: Transform3D = _grid_xform_local()

	if wire_grid_main_mi != null:
		wire_grid_main_mi.visible = show_wire_grid and show_main_grid_overlay
		if wire_grid_main_mi.visible:
			wire_grid_main_mi.mesh = _build_wire_grid_mesh_offset(grid_w, grid_h, cell_size, gx, 0.0, 0.0)
			if _wire_grid_main_material == null:
				_wire_grid_main_material = _make_unshaded_mat(main_grid_color)
			else:
				_wire_grid_main_material.albedo_color = main_grid_color
			wire_grid_main_mi.material_override = _wire_grid_main_material

	if wire_grid_dual_mi != null:
		wire_grid_dual_mi.visible = show_wire_grid and show_dual_grid_overlay
		if wire_grid_dual_mi.visible:
			var half: float = cell_size * 0.5
			wire_grid_dual_mi.mesh = _build_wire_grid_mesh_offset(grid_w, grid_h, cell_size, gx, half, half)
			if _wire_grid_dual_material == null:
				_wire_grid_dual_material = _make_unshaded_mat(dual_grid_color)
			else:
				_wire_grid_dual_material.albedo_color = dual_grid_color
			wire_grid_dual_mi.material_override = _wire_grid_dual_material

	_update_dual_grid_points()

func _ensure_deformed_floor_node() -> void:
	if _deformed_floor_mi != null:
		return

	var existing: Node = get_node_or_null("Arena/DeformedFloor")
	if existing is MeshInstance3D:
		_deformed_floor_mi = existing as MeshInstance3D
		return

	var legacy_existing: Node = get_node_or_null("Arena/RelaxedFloor")
	if legacy_existing is MeshInstance3D:
		_deformed_floor_mi = legacy_existing as MeshInstance3D
		_deformed_floor_mi.name = "DeformedFloor"
		return

	var arena_root: Node = get_node_or_null("Arena")
	if arena_root == null:
		return

	_deformed_floor_mi = MeshInstance3D.new()
	_deformed_floor_mi.name = "DeformedFloor"
	_deformed_floor_mi.visible = false
	arena_root.add_child(_deformed_floor_mi)

func _set_base_floor_visible(visible: bool) -> void:
	if floor_mmi != null:
		floor_mmi.visible = visible
	if floor_full_mmi != null:
		floor_full_mmi.visible = visible
	if floor_edge_mmi != null:
		floor_edge_mmi.visible = visible
	if floor_corner_mmi != null:
		floor_corner_mmi.visible = visible
	if floor_inverse_corner_mmi != null:
		floor_inverse_corner_mmi.visible = visible
	if floor_checker_mmi != null:
		floor_checker_mmi.visible = visible

func _deformed_hash01(x: int, y: int, axis: int) -> float:
	var seed_mix: int = _deformed_noise_seed
	var h: int = x * 73856093
	h ^= y * 19349663
	h ^= axis * 83492791
	h ^= seed_mix * 2654435761
	h &= 0x7fffffff
	return float(h) / 2147483647.0

func _build_jittered_corner_lattice() -> Array[Vector3]:
	var max_offset: float = min(max(deformed_offset_fraction, 0.0), 0.2) * cell_size
	var point_positions: Array[Vector3] = []
	point_positions.resize(_points_w() * _points_h())

	for py in range(_points_h()):
		for px in range(_points_w()):
			var p: Vector3 = _corner_to_world(px, py)
			var is_border: bool = px == 0 or py == 0 or px == _points_w() - 1 or py == _points_h() - 1
			var ox: float = 0.0
			var oz: float = 0.0
			if not is_border:
				ox = (_deformed_hash01(px, py, 0) * 2.0 - 1.0) * max_offset
				oz = (_deformed_hash01(px, py, 1) * 2.0 - 1.0) * max_offset
			point_positions[_corner_idx(px, py)] = p + Vector3(ox, floor_thickness, oz)

	return point_positions

func _rotate_uv_steps(uv: Vector2, steps: int) -> Vector2:
	match (steps & 3):
		1:
			return Vector2(uv.y, 1.0 - uv.x)
		2:
			return Vector2(1.0 - uv.x, 1.0 - uv.y)
		3:
			return Vector2(1.0 - uv.y, uv.x)
		_:
			return uv

func _bilerp_quad(p00: Vector3, p10: Vector3, p11: Vector3, p01: Vector3, uv: Vector2) -> Vector3:
	var a: Vector3 = p00.lerp(p10, uv.x)
	var b: Vector3 = p01.lerp(p11, uv.x)
	return a.lerp(b, uv.y)

func _add_deformed_mesh_surface(st: SurfaceTool, mesh: Mesh, quad: Array[Vector3], rotation_steps: int, up: Vector3) -> int:
	if mesh == null or quad.size() < 4:
		return 0

	var written: int = 0
	var p00: Vector3 = quad[0]
	var p10: Vector3 = quad[1]
	var p11: Vector3 = quad[2]
	var p01: Vector3 = quad[3]

	for s in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(s)
		if arrays.is_empty():
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if verts.is_empty():
			continue
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var aabb: AABB = mesh.get_aabb()
		var sx: float = max(aabb.size.x, 0.0001)
		var sy: float = max(aabb.size.y, 0.0001)
		var sz: float = max(aabb.size.z, 0.0001)

		if indices.is_empty():
			indices.resize(verts.size())
			for i in range(verts.size()):
				indices[i] = i

		for index in indices:
			if index < 0 or index >= verts.size():
				continue
			var v: Vector3 = verts[index]
			var uv_from_pos: Vector2 = Vector2((v.x - aabb.position.x) / sx, (v.z - aabb.position.z) / sz)
			uv_from_pos = _rotate_uv_steps(uv_from_pos, rotation_steps)
			var base_pos: Vector3 = _bilerp_quad(p00, p10, p11, p01, uv_from_pos)
			var y_t: float = (v.y - aabb.position.y) / sy
			var y_offset: float = (y_t - 1.0) * floor_thickness if aabb.size.y >= 0.001 else 0.0
			var out_pos: Vector3 = base_pos + up * y_offset

			var out_normal: Vector3 = Vector3.UP
			if not normals.is_empty() and index < normals.size():
				out_normal = normals[index]
				out_normal = (Basis(up, rotation_steps * PI * 0.5) * out_normal).normalized()

			var out_uv: Vector2 = uv_from_pos
			if not uvs.is_empty() and index < uvs.size():
				out_uv = uvs[index]

			st.set_normal(out_normal)
			st.set_uv(out_uv)
			st.add_vertex(out_pos)
			written += 1

	return written

func _build_deformed_floor_mesh() -> ArrayMesh:
	var point_positions: Array[Vector3] = _build_jittered_corner_lattice()
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertex_count: int = 0
	var grid_xform: Transform3D = _grid_xform_local()
	var up_dir: Vector3 = grid_xform.basis.y.normalized()
	if up_dir.length() < 0.001:
		up_dir = Vector3.UP

	for y in range(_render_h()):
		for x in range(_render_w()):
			if pieces_replace_base_floor and not _occupied.is_empty() and _occupied[_render_tile_idx(x, y)] != 0:
				continue

			var mask: int = _mask_at_render_tile(x, y)
			if mask == CANONICAL_EMPTY:
				continue

			var canonical: Dictionary = _canonicalize_mask(mask)
			var variant_id: String = str(canonical.get("variant_id", ""))
			if variant_id == "empty" or variant_id == "unknown":
				continue

			var mesh: Mesh = _build_floor_variant_mesh(variant_id, x, y)
			if mesh == null:
				continue
			var rotation_steps: int = int(canonical.get("rotation_steps", 0))

			var qx: int = x
			var qy: int = y
			if layout_mode == LayoutMode.DUAL_FROM_CELLS:
				qx += 1
				qy += 1
			var quad: Array[Vector3] = [
				point_positions[_corner_idx(qx, qy)],
				point_positions[_corner_idx(qx + 1, qy)],
				point_positions[_corner_idx(qx + 1, qy + 1)],
				point_positions[_corner_idx(qx, qy + 1)],
			]
			vertex_count += _add_deformed_mesh_surface(st, mesh, quad, rotation_steps, up_dir)

	if vertex_count == 0:
		return ArrayMesh.new()
	return st.commit() as ArrayMesh

func _update_deformed_floor_visual() -> void:
	_ensure_deformed_floor_node()
	if _deformed_floor_mi == null:
		return

	if not show_deformed_floor_mesh or not _has_render_tiles():
		_deformed_floor_mi.visible = false
		_deformed_floor_mi.mesh = null
		_set_base_floor_visible(true)
		return

	_deformed_floor_mi.mesh = _build_deformed_floor_mesh()
	if _deformed_floor_material == null:
		_deformed_floor_material = StandardMaterial3D.new()
		_deformed_floor_material.albedo_color = Color(0.85, 0.85, 0.85, 1.0)
		_deformed_floor_material.roughness = 1.0
	_deformed_floor_mi.material_override = _deformed_floor_material
	_deformed_floor_mi.visible = true
	_set_base_floor_visible(false)

func _transform_aabb(aabb: AABB, xform: Transform3D) -> AABB:
	var corners: Array[Vector3] = [
		xform * aabb.position,
		xform * (aabb.position + Vector3(aabb.size.x, 0.0, 0.0)),
		xform * (aabb.position + Vector3(0.0, aabb.size.y, 0.0)),
		xform * (aabb.position + Vector3(0.0, 0.0, aabb.size.z)),
		xform * (aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0)),
		xform * (aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z)),
		xform * (aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z)),
		xform * (aabb.position + aabb.size),
	]

	var min_v: Vector3 = corners[0]
	var max_v: Vector3 = corners[0]
	for c in corners:
		min_v = Vector3(min(min_v.x, c.x), min(min_v.y, c.y), min(min_v.z, c.z))
		max_v = Vector3(max(max_v.x, c.x), max(max_v.y, c.y), max(max_v.z, c.z))

	return AABB(min_v, max_v - min_v)

func generate() -> void:
	if grid_w <= 0 or grid_h <= 0:
		push_error("ArenaAutoGen: grid_w and grid_h must be > 0")
		return

	if layout_mode == LayoutMode.DUAL_FROM_CELLS and (grid_w <= 1 or grid_h <= 1):
		push_error("ArenaAutoGen: Need grid_w and grid_h >= 2 for dual grid layout")
		return

	if layout_mode == LayoutMode.DUAL_FROM_CELLS:
		_cells = PackedByteArray()
		_cells.resize(grid_w * grid_h)
		_fill_cells_random()
		_apply_cell_border_empty()

		for _i in range(smoothing_steps):
			_smooth_cells_step()
			_apply_cell_border_empty()

		_corners = PackedByteArray()
		_corners.resize(_points_w() * _points_h())
		_tiles = PackedByteArray()
		_tiles.resize(0)
		_occupied = PackedByteArray()
		_occupied.resize(_render_w() * _render_h())

		_build_floor_multimeshes()
		if make_walls:
			_build_walls_from_cells()
		else:
			wall_mmi.multimesh = null

		_update_bounds_mesh_from_grid()
		_update_wire_grid_debug()
		_update_deformed_floor_visual()
		return

	_corners = PackedByteArray()
	_corners.resize(_points_w() * _points_h())

	_tiles = PackedByteArray()
	_tiles.resize(grid_w * grid_h)

	_occupied = PackedByteArray()
	_occupied.resize(_render_w() * _render_h())

	_fill_corners_random()
	_apply_corner_border_empty()

	for _i in range(smoothing_steps):
		_smooth_corners_step()
		_apply_corner_border_empty()

	if ensure_connected:
		_force_single_corner_region_from_center()

	_build_tiles_from_corners()
	_run_pattern_stamping()
	_build_floor_multimeshes()

	if make_walls:
		_build_walls_multimesh()
	else:
		wall_mmi.multimesh = null

	_update_bounds_mesh_from_grid()
	_update_wire_grid_debug()
	_update_deformed_floor_visual()

func _fill_corners_random() -> void:
	for y in range(_points_h()):
		for x in range(_points_w()):
			_corners[_corner_idx(x, y)] = 1 if _rng.randf() < fill_percent else 0

func _apply_corner_border_empty() -> void:
	for y in range(_points_h()):
		for x in range(_points_w()):
			if x < border or y < border or x >= _points_w() - border or y >= _points_h() - border:
				_corners[_corner_idx(x, y)] = 0

func _smooth_corners_step() -> void:
	var next: PackedByteArray = PackedByteArray()
	next.resize(_points_w() * _points_h())

	for y in range(_points_h()):
		for x in range(_points_w()):
			var neighbor_count: int = _count_corner_neighbors8(x, y)
			var here: int = _corner_get(x, y)
			if neighbor_count > 4:
				next[_corner_idx(x, y)] = 1
			elif neighbor_count < 4:
				next[_corner_idx(x, y)] = 0
			else:
				next[_corner_idx(x, y)] = here

	_corners = next

func _force_single_corner_region_from_center() -> void:
	var start: Vector2i = Vector2i(int(_points_w() / 2), int(_points_h() / 2))
	if _corner_get(start.x, start.y) == 0:
		var found: bool = false
		for r in range(1, max(_points_w(), _points_h())):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var p: Vector2i = start + Vector2i(dx, dy)
					if _corner_in_bounds(p.x, p.y) and _corner_get(p.x, p.y) == 1:
						start = p
						found = true
						break
				if found:
					break
			if found:
				break
		if not found:
			return

	var visited: PackedByteArray = PackedByteArray()
	visited.resize(_points_w() * _points_h())
	var q: Array[Vector2i] = [start]
	visited[_corner_idx(start.x, start.y)] = 1

	var head: int = 0
	while head < q.size():
		var p: Vector2i = q[head]
		head += 1
		for d in DIRS4:
			var n: Vector2i = p + d
			if _corner_in_bounds(n.x, n.y) and _corner_get(n.x, n.y) == 1:
				var ii: int = _corner_idx(n.x, n.y)
				if visited[ii] == 0:
					visited[ii] = 1
					q.push_back(n)

	for y in range(_points_h()):
		for x in range(_points_w()):
			var ii: int = _corner_idx(x, y)
			if _corners[ii] == 1 and visited[ii] == 0:
				_corners[ii] = 0

func _build_tiles_from_corners() -> void:
	for y in range(grid_h):
		for x in range(grid_w):
			var mask: int = _mask_at_tile(x, y)
			_tiles[_tile_idx(x, y)] = 1 if _tile_filled_from_mask(mask) else 0

func _run_pattern_stamping() -> void:
	var patterns: Array[Dictionary] = PatternPieces.get_default_patterns()
	_piece_transforms = {}
	for pattern in patterns:
		var pid: String = str(pattern.get("id", ""))
		if pid != "" and not _piece_transforms.has(pid):
			_piece_transforms[pid] = []

	_occupied.fill(0)

	if not use_pattern_stamping:
		_build_piece_multimeshes()
		return

	var patterns_by_priority: Dictionary = {}
	var priority_levels: Array[int] = []
	for pattern in patterns:
		var priority: int = int(pattern.get("priority", 0))
		if not patterns_by_priority.has(priority):
			patterns_by_priority[priority] = []
			priority_levels.append(priority)
		var bucket: Array = patterns_by_priority[priority] as Array
		bucket.append(pattern)

	priority_levels.sort()
	priority_levels.reverse()

	var recent_by_family: Dictionary = {}

	for priority in priority_levels:
		var band_patterns: Array = patterns_by_priority.get(priority, []) as Array
		var candidates: Array[Dictionary] = []

		for pattern_raw in band_patterns:
			var pattern: Dictionary = pattern_raw as Dictionary
			var size: Vector2i = pattern.get("size", Vector2i.ONE)
			for y in range(grid_h - size.y + 1):
				for x in range(grid_w - size.x + 1):
					if not _pattern_matches_at(pattern, x, y):
						continue
					if not _pattern_cooldown_allows(pattern, x, y, recent_by_family):
						continue
					candidates.append({
						"pattern": pattern,
						"x": x,
						"y": y,
						"weight": max(float(pattern.get("weight", 1.0)), 0.0),
					})

		while not candidates.is_empty():
			var chosen_index: int = _pick_weighted_candidate_index(candidates)
			if chosen_index < 0:
				break

			var chosen: Dictionary = candidates[chosen_index]
			var pattern: Dictionary = chosen.get("pattern", {}) as Dictionary
			var x: int = int(chosen.get("x", 0))
			var y: int = int(chosen.get("y", 0))
			var size: Vector2i = pattern.get("size", Vector2i.ONE)

			candidates.remove_at(chosen_index)

			if not _pattern_matches_at(pattern, x, y):
				continue
			if not _pattern_cooldown_allows(pattern, x, y, recent_by_family):
				continue

			var pid: String = str(pattern.get("id", ""))
			if not _piece_transforms.has(pid):
				continue
			if not _can_render_piece(pid):
				continue

			_mark_pattern_occupied(pattern, x, y)
			_record_pattern_cooldown(pattern, x, y, recent_by_family)

			var t: Array = _piece_transforms[pid] as Array
			var rot_steps: int = int(pattern.get("rot_steps", 0))
			var yaw: float = rot_steps * PI * 0.5
			var mesh: Mesh = _build_piece_mesh(pid)
			var desired: Vector3 = _piece_desired_size(size)
			var pos: Vector3 = _pattern_anchor_to_world(x, y, size)
			pos.y += piece_height_epsilon
			t.append(_fit_mesh_transform(mesh, desired, yaw, pos))

			var remaining: Array[Dictionary] = []
			for candidate in candidates:
				var cd: Dictionary = candidate as Dictionary
				var cp: Dictionary = cd.get("pattern", {}) as Dictionary
				var cx: int = int(cd.get("x", 0))
				var cy: int = int(cd.get("y", 0))
				if _pattern_matches_at(cp, cx, cy) and _pattern_cooldown_allows(cp, cx, cy, recent_by_family):
					remaining.append(cd)
			candidates = remaining

	_build_piece_multimeshes()

func _pick_weighted_candidate_index(candidates: Array[Dictionary]) -> int:
	if candidates.is_empty():
		return -1

	var total_weight: float = 0.0
	for c in candidates:
		total_weight += max(float(c.get("weight", 0.0)), 0.0)

	if total_weight <= 0.0001:
		return _rng.randi_range(0, candidates.size() - 1)

	var roll: float = _rng.randf() * total_weight
	for i in range(candidates.size()):
		roll -= max(float(candidates[i].get("weight", 0.0)), 0.0)
		if roll <= 0.0:
			return i

	return candidates.size() - 1

func _pattern_anchor_tile(x: int, y: int, size: Vector2i) -> Vector2:
	var ax: float = float(x) + float(size.x) * 0.5
	var ay: float = float(y) + float(size.y) * 0.5
	return Vector2(ax, ay)

func _pattern_cooldown_allows(pattern: Dictionary, x: int, y: int, recent_by_family: Dictionary) -> bool:
	var radius: float = float(pattern.get("cooldown_radius", 0.0))
	if radius <= 0.0:
		return true

	var family: String = str(pattern.get("cooldown_family", pattern.get("id", "")))
	if family == "" or not recent_by_family.has(family):
		return true

	var size: Vector2i = pattern.get("size", Vector2i.ONE)
	var anchor: Vector2 = _pattern_anchor_tile(x, y, size)
	var anchors: Array = recent_by_family[family] as Array
	for a in anchors:
		var prev: Vector2 = a as Vector2
		if anchor.distance_to(prev) < radius:
			return false
	return true

func _record_pattern_cooldown(pattern: Dictionary, x: int, y: int, recent_by_family: Dictionary) -> void:
	var radius: float = float(pattern.get("cooldown_radius", 0.0))
	if radius <= 0.0:
		return

	var family: String = str(pattern.get("cooldown_family", pattern.get("id", "")))
	if family == "":
		return

	if not recent_by_family.has(family):
		recent_by_family[family] = []

	var size: Vector2i = pattern.get("size", Vector2i.ONE)
	var anchor: Vector2 = _pattern_anchor_tile(x, y, size)
	var anchors: Array = recent_by_family[family] as Array
	anchors.append(anchor)

func _pattern_matches_at(pattern: Dictionary, x: int, y: int) -> bool:
	var size: Vector2i = pattern["size"]
	var required: Array = pattern["required"]
	for py in range(size.y):
		var row: Array = required[py] as Array
		for px in range(size.x):
			var tx: int = x + px
			var ty: int = y + py
			if _tile_get(tx, ty) == 0:
				return false
			if _occupied[_tile_idx(tx, ty)] != 0:
				return false
			var needed: String = str(row[px])
			if needed == "*":
				continue
			if _variant_at_tile(tx, ty) != needed:
				return false
	return true

func _mark_pattern_occupied(pattern: Dictionary, x: int, y: int) -> void:
	var size: Vector2i = pattern.get("size", Vector2i.ONE)
	var occupy: Array = pattern.get("occupy", pattern.get("required", []))
	for py in range(size.y):
		if py >= occupy.size():
			continue
		var row: Array = occupy[py] as Array
		for px in range(size.x):
			if px >= row.size():
				continue
			if str(row[px]) == "0":
				continue
			_occupied[_tile_idx(x + px, y + py)] = 1

func _pattern_anchor_to_world(x: int, y: int, size: Vector2i) -> Vector3:
	var cx: float = float(x) + (float(size.x) - 1.0) * 0.5
	var cy: float = float(y) + (float(size.y) - 1.0) * 0.5
	var center: Vector3 = _tile_to_world_center_f(cx, cy)
	center.y = floor_thickness * 0.5
	return center

func _build_floor_multimeshes() -> void:
	if _has_variant_floor_nodes():
		_build_floor_multimeshes_by_variant()
		if floor_mmi != null:
			floor_mmi.multimesh = null
		return
	_build_floor_multimesh_legacy()

func _build_floor_multimesh_legacy() -> void:
	if floor_mmi == null:
		return
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var mesh: Mesh = _build_floor_variant_mesh("full", 0, 0)
	mm.mesh = mesh
	var desired: Vector3 = Vector3(cell_size, floor_thickness, cell_size)
	var transforms: Array[Transform3D] = []
	for y in range(_render_h()):
		for x in range(_render_w()):
			if not _render_tile_filled(x, y):
				continue
			if pieces_replace_base_floor and not _occupied.is_empty() and _occupied[_render_tile_idx(x, y)] != 0:
				continue
			var pos: Vector3 = _render_tile_to_world_center(x, y)
			pos.y = floor_thickness * 0.5
			transforms.append(_fit_mesh_transform(mesh, desired, 0.0, pos))
	_assign_multimesh_transforms(mm, transforms)
	floor_mmi.multimesh = mm

func _build_floor_multimeshes_by_variant() -> void:
	var mesh_transform_buckets: Dictionary = {
		"full": {},
		"edge": {},
		"corner": {},
		"inverse_corner": {},
		"checker": {},
	}
	var desired: Vector3 = Vector3(cell_size, floor_thickness, cell_size)

	for y in range(_render_h()):
		for x in range(_render_w()):
			if pieces_replace_base_floor and not _occupied.is_empty() and _occupied[_render_tile_idx(x, y)] != 0:
				continue
			var mask: int = _mask_at_render_tile(x, y)
			if mask == CANONICAL_EMPTY:
				continue
			var canonical: Dictionary = _canonicalize_mask(mask)
			var variant_id: String = str(canonical.get("variant_id", ""))
			if not mesh_transform_buckets.has(variant_id):
				continue
			var rotation_steps: int = int(canonical.get("rotation_steps", 0))
			var pos: Vector3 = _render_tile_to_world_center(x, y)
			pos.y = floor_thickness * 0.5
			var yaw: float = rotation_steps * PI * 0.5
			var mesh: Mesh = _build_floor_variant_mesh(variant_id, x, y)
			var variant_bucket: Dictionary = mesh_transform_buckets[variant_id] as Dictionary
			if not variant_bucket.has(mesh):
				variant_bucket[mesh] = []
			var transforms: Array = variant_bucket[mesh] as Array
			transforms.append(_fit_mesh_transform(mesh, desired, yaw, pos))

	_assign_variant_mesh_group(floor_full_mmi, mesh_transform_buckets["full"] as Dictionary)
	_assign_variant_mesh_group(floor_edge_mmi, mesh_transform_buckets["edge"] as Dictionary)
	_assign_variant_mesh_group(floor_corner_mmi, mesh_transform_buckets["corner"] as Dictionary)
	_assign_variant_mesh_group(floor_inverse_corner_mmi, mesh_transform_buckets["inverse_corner"] as Dictionary)
	_assign_variant_mesh_group(floor_checker_mmi, mesh_transform_buckets["checker"] as Dictionary)

func _build_piece_multimeshes() -> void:
	_assign_piece_multimesh(piece_3x3_full_mmi, "piece_3x3_full")
	_assign_piece_multimesh(piece_2x3_full_mmi, "piece_2x3_full")
	_assign_piece_multimesh(piece_2x2_full_mmi, "piece_2x2_full")
	_assign_piece_multimesh(piece_5x1_edge_mmi, "piece_5x1_edge")
	_assign_piece_multimesh(piece_4x1_edge_mmi, "piece_4x1_edge")
	_assign_piece_multimesh(piece_3x1_edge_mmi, "piece_3x1_edge")
	_assign_piece_multimesh(piece_3x2_bay_mmi, "piece_3x2_bay")
	_assign_piece_multimesh(piece_2x2_bay_mmi, "piece_2x2_bay")
	_assign_piece_multimesh(piece_corner_cluster_mmi, "piece_corner_cluster")

func _piece_target_for_id(piece_id: String) -> MultiMeshInstance3D:
	match piece_id:
		"piece_3x3_full":
			return piece_3x3_full_mmi
		"piece_2x3_full":
			return piece_2x3_full_mmi
		"piece_2x2_full":
			return piece_2x2_full_mmi
		"piece_5x1_edge":
			return piece_5x1_edge_mmi
		"piece_4x1_edge":
			return piece_4x1_edge_mmi
		"piece_3x1_edge":
			return piece_3x1_edge_mmi
		"piece_3x2_bay":
			return piece_3x2_bay_mmi
		"piece_2x2_bay":
			return piece_2x2_bay_mmi
		"piece_corner_cluster":
			return piece_corner_cluster_mmi
	return null

func _can_render_piece(piece_id: String) -> bool:
	return _piece_target_for_id(piece_id) != null and _build_piece_mesh(piece_id) != null

func _assign_piece_multimesh(target: MultiMeshInstance3D, piece_id: String) -> void:
	var transforms: Array = _piece_transforms.get(piece_id, []) as Array
	_assign_variant_multimesh(target, transforms, _build_piece_mesh(piece_id))

func _build_piece_mesh(piece_id: String) -> Mesh:
	match piece_id:
		"piece_3x3_full":
			if piece_mesh_3x3_full != null:
				return piece_mesh_3x3_full
			var m00: BoxMesh = BoxMesh.new(); m00.size = Vector3(cell_size * 3.0, floor_thickness, cell_size * 3.0); return m00
		"piece_2x3_full":
			if piece_mesh_2x3_full != null:
				return piece_mesh_2x3_full
			var m01: BoxMesh = BoxMesh.new(); m01.size = Vector3(cell_size * 2.0, floor_thickness, cell_size * 3.0); return m01
		"piece_2x2_full":
			if piece_mesh_2x2_full != null:
				return piece_mesh_2x2_full
			var m0: BoxMesh = BoxMesh.new(); m0.size = Vector3(cell_size * 2.0, floor_thickness, cell_size * 2.0); return m0
		"piece_5x1_edge":
			if piece_mesh_5x1_edge != null:
				return piece_mesh_5x1_edge
			var m50: BoxMesh = BoxMesh.new(); m50.size = Vector3(cell_size * 5.0, floor_thickness, cell_size); return m50
		"piece_4x1_edge":
			if piece_mesh_4x1_edge != null:
				return piece_mesh_4x1_edge
			var m40: BoxMesh = BoxMesh.new(); m40.size = Vector3(cell_size * 4.0, floor_thickness, cell_size); return m40
		"piece_3x1_edge":
			if piece_mesh_3x1_edge != null:
				return piece_mesh_3x1_edge
			var m1: BoxMesh = BoxMesh.new(); m1.size = Vector3(cell_size * 3.0, floor_thickness, cell_size); return m1
		"piece_3x2_bay":
			if piece_mesh_3x2_bay != null:
				return piece_mesh_3x2_bay
			var m32: BoxMesh = BoxMesh.new(); m32.size = Vector3(cell_size * 3.0, floor_thickness, cell_size * 2.0); return m32
		"piece_corner_cluster":
			if piece_mesh_corner_cluster != null:
				return piece_mesh_corner_cluster
			var mcc: BoxMesh = BoxMesh.new(); mcc.size = Vector3(cell_size * 2.0, floor_thickness, cell_size * 2.0); return mcc
		_:
			if piece_mesh_2x2_bay != null:
				return piece_mesh_2x2_bay
			var m2: BoxMesh = BoxMesh.new(); m2.size = Vector3(cell_size * 2.0, floor_thickness, cell_size * 2.0); return m2

func _assign_variant_multimesh(target: MultiMeshInstance3D, transforms_raw: Array, mesh: Mesh) -> void:
	if target == null:
		return
	if transforms_raw.is_empty():
		target.multimesh = null
		return
	var transforms: Array[Transform3D] = []
	for t in transforms_raw:
		transforms.append(t as Transform3D)
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	_assign_multimesh_transforms(mm, transforms)
	target.multimesh = mm

func _variant_mesh_array(variant_id: String) -> Array[Mesh]:
	match variant_id:
		"full":
			return mesh_full_variants
		"edge":
			return mesh_edge_variants
		"corner":
			return mesh_corner_variants
		"inverse_corner":
			return mesh_inverse_corner_variants
		"checker":
			return mesh_checker_variants
	return []

func _variant_index_for_tile(variant_id: String, x: int, y: int, count: int) -> int:
	if count <= 1:
		return 0
	var h: int = x * 73856093
	h ^= y * 19349663
	h ^= _mesh_variant_seed * 83492791
	h ^= variant_id.hash()
	h &= 0x7fffffff
	return h % count

func _build_floor_variant_mesh(variant_id: String, x: int, y: int) -> Mesh:
	var variants: Array[Mesh] = _variant_mesh_array(variant_id)
	if not variants.is_empty():
		var idx: int = _variant_index_for_tile(variant_id, x, y, variants.size())
		var selected: Mesh = variants[idx]
		if selected != null:
			return selected
		for fallback in variants:
			if fallback != null:
				return fallback

	var mesh: BoxMesh = BoxMesh.new()
	match variant_id:
		"edge": mesh.size = Vector3(cell_size, floor_thickness, cell_size * 0.5)
		"corner": mesh.size = Vector3(cell_size * 0.5, floor_thickness, cell_size * 0.5)
		"inverse_corner": mesh.size = Vector3(cell_size, floor_thickness, cell_size)
		"checker": mesh.size = Vector3(cell_size * 0.75, floor_thickness, cell_size * 0.75)
		_: mesh.size = Vector3(cell_size, floor_thickness, cell_size)
	return mesh

func _assign_variant_mesh_group(target: MultiMeshInstance3D, mesh_to_transforms: Dictionary) -> void:
	if target == null:
		return
	if mesh_to_transforms.is_empty():
		target.multimesh = null
		return
	
	for child in target.get_children():
		if child is MultiMeshInstance3D and str((child as Node).name).begins_with("Variant_"):
			(child as Node).queue_free()

	var meshes: Array = mesh_to_transforms.keys()
	for i in range(meshes.size()):
		var mesh: Mesh = meshes[i] as Mesh
		var transforms: Array = mesh_to_transforms[mesh] as Array
		if i == 0:
			_assign_variant_multimesh(target, transforms, mesh)
			continue
		var extra: MultiMeshInstance3D = MultiMeshInstance3D.new()
		extra.name = "Variant_%d" % i
		extra.multimesh = null
		target.add_child(extra)
		_assign_variant_multimesh(extra, transforms, mesh)

func _build_walls_multimesh() -> void:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var wall_mesh: BoxMesh = BoxMesh.new()
	wall_mesh.size = Vector3(cell_size, wall_height, wall_thickness)
	mm.mesh = wall_mesh
	var transforms: Array[Transform3D] = []
	for y in range(grid_h):
		for x in range(grid_w):
			if _tile_get(x, y) == 0:
				continue
			if _tile_get(x, y - 1) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(0, 0, -0.5), 0.0))
			if _tile_get(x, y + 1) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(0, 0, 0.5), 0.0))
			if _tile_get(x - 1, y) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(-0.5, 0, 0), PI * 0.5))
			if _tile_get(x + 1, y) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(0.5, 0, 0), PI * 0.5))
	_assign_multimesh_transforms(mm, transforms)
	wall_mmi.multimesh = mm

func _build_walls_from_cells() -> void:
	if wall_mmi == null:
		return
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var wall_mesh: BoxMesh = BoxMesh.new()
	wall_mesh.size = Vector3(cell_size, wall_height, wall_thickness)
	mm.mesh = wall_mesh
	var transforms: Array[Transform3D] = []
	for y in range(grid_h):
		for x in range(grid_w):
			if _cell_get(x, y) == 0:
				continue
			if _cell_get(x, y - 1) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(0, 0, -0.5), 0.0))
			if _cell_get(x, y + 1) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(0, 0, 0.5), 0.0))
			if _cell_get(x - 1, y) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(-0.5, 0, 0), PI * 0.5))
			if _cell_get(x + 1, y) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(0.5, 0, 0), PI * 0.5))
	_assign_multimesh_transforms(mm, transforms)
	wall_mmi.multimesh = mm


func _wall_transform_for_edge(x: int, y: int, local_offset: Vector3, yaw: float) -> Transform3D:
	var center: Vector3 = _tile_to_world_center(x, y)
	var offset: Vector3 = Vector3(local_offset.x * cell_size, 0.0, local_offset.z * cell_size)
	var pos: Vector3 = center + offset
	pos.y = wall_height * 0.5
	return Transform3D(Basis(Vector3.UP, yaw), pos)

func _assign_multimesh_transforms(mm: MultiMesh, transforms: Array[Transform3D]) -> void:
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])

func _dual_w() -> int:
	return max(grid_w - 1, 0)

func _dual_h() -> int:
	return max(grid_h - 1, 0)

func _render_w() -> int:
	return _dual_w() if layout_mode == LayoutMode.DUAL_FROM_CELLS else grid_w

func _render_h() -> int:
	return _dual_h() if layout_mode == LayoutMode.DUAL_FROM_CELLS else grid_h

func _render_tile_idx(x: int, y: int) -> int:
	return y * _render_w() + x

func _render_tile_to_world_center(x: int, y: int) -> Vector3:
	if layout_mode == LayoutMode.DUAL_FROM_CELLS:
		return _corner_to_world(x + 1, y + 1)
	return _tile_to_world_center(x, y)

func _mask_at_dual_tile(x: int, y: int) -> int:
	var tl: int = _cell_get(x, y)
	var tr: int = _cell_get(x + 1, y)
	var br: int = _cell_get(x + 1, y + 1)
	var bl: int = _cell_get(x, y + 1)
	return _mask_from_corners(tl, tr, br, bl)

func _mask_at_render_tile(x: int, y: int) -> int:
	return _mask_at_dual_tile(x, y) if layout_mode == LayoutMode.DUAL_FROM_CELLS else _mask_at_tile(x, y)

func _render_tile_filled(x: int, y: int) -> bool:
	var mask: int = _mask_at_render_tile(x, y)
	if mask == CANONICAL_EMPTY:
		return false
	return _tile_filled_from_mask(mask)

func _has_render_tiles() -> bool:
	return _render_w() > 0 and _render_h() > 0

func _mask_at_tile(x: int, y: int) -> int:
	return _mask_from_corners(_corner_get(x, y), _corner_get(x + 1, y), _corner_get(x + 1, y + 1), _corner_get(x, y + 1))

func _mask_from_corners(tl: int, tr: int, br: int, bl: int) -> int:
	return (tl << 0) | (tr << 1) | (br << 2) | (bl << 3)

func _rot90(mask: int) -> int:
	var tl: int = (mask >> 0) & 1
	var tr: int = (mask >> 1) & 1
	var br: int = (mask >> 2) & 1
	var bl: int = (mask >> 3) & 1
	return (bl << 0) | (tl << 1) | (tr << 2) | (br << 3)

func _canonicalize_mask(mask: int) -> Dictionary:
	var rotated: int = mask
	for steps in range(4):
		if rotated == CANONICAL_EMPTY: return {"variant_id": "empty", "rotation_steps": steps}
		if rotated == CANONICAL_FULL: return {"variant_id": "full", "rotation_steps": steps}
		if rotated == CANONICAL_CORNER: return {"variant_id": "corner", "rotation_steps": steps}
		if rotated == CANONICAL_EDGE: return {"variant_id": "edge", "rotation_steps": steps}
		if rotated == CANONICAL_INVERSE_CORNER: return {"variant_id": "inverse_corner", "rotation_steps": steps}
		if rotated == CANONICAL_CHECKER: return {"variant_id": "checker", "rotation_steps": steps}
		rotated = _rot90(rotated)
	return {"variant_id": "unknown", "rotation_steps": 0}

func _variant_at_tile(x: int, y: int) -> String:
	var mask: int = _mask_at_tile(x, y)
	if mask == CANONICAL_EMPTY:
		return "empty"
	return str(_canonicalize_mask(mask).get("variant_id", "unknown"))

func _tile_filled_from_mask(mask: int) -> bool:
	match mask:
		CANONICAL_EMPTY:
			return false
		CANONICAL_CHECKER:
			return checker_is_solid
		_:
			return true


func _piece_desired_size(size: Vector2i) -> Vector3:
	return Vector3(float(size.x) * cell_size, floor_thickness, float(size.y) * cell_size)

func _fit_mesh_transform(mesh: Mesh, desired_size: Vector3, yaw: float, world_pos: Vector3) -> Transform3D:
	var rot_steps: int = int(round(yaw / (PI * 0.5))) & 3
	var snapped_yaw: float = rot_steps * PI * 0.5

	if mesh == null:
		return Transform3D(Basis(Vector3.UP, snapped_yaw), world_pos)

	var aabb: AABB = mesh.get_aabb()
	var desired: Vector3 = desired_size
	if (rot_steps & 1) == 1:
		desired = Vector3(desired_size.z, desired_size.y, desired_size.x)

	var sx: float = max(aabb.size.x, 0.0001)
	var sy: float = max(aabb.size.y, 0.0001)
	var sz: float = max(aabb.size.z, 0.0001)
	var scale: Vector3 = Vector3(desired.x / sx, desired.y / sy, desired.z / sz)
	if aabb.size.y < 0.001:
		scale.y = 1.0

	var basis: Basis = Basis(Vector3.UP, snapped_yaw).scaled(scale)
	var center: Vector3 = aabb.position + aabb.size * 0.5
	var corrected_pos: Vector3 = world_pos + basis * (-center)
	return Transform3D(basis, corrected_pos)

func _grid_xform_local() -> Transform3D:
	match origin_mode:
		OriginMode.MIN_CORNER:
			return Transform3D(Basis.IDENTITY, origin_offset)
		OriginMode.CENTERED:
			var centered_origin: Vector3 = Vector3(-(grid_w * cell_size) * 0.5, 0.0, -(grid_h * cell_size) * 0.5)
			return Transform3D(Basis.IDENTITY, centered_origin + origin_offset)
		OriginMode.CUSTOM_ANCHOR:
			var a: Node = get_node_or_null(origin_anchor_path)
			if a is Node3D:
				var anchor_local: Transform3D = global_transform.affine_inverse() * (a as Node3D).global_transform
				return Transform3D(anchor_local.basis, anchor_local.origin + anchor_local.basis * origin_offset)
	return Transform3D(Basis.IDENTITY, origin_offset)

func _corner_to_world(x: int, y: int) -> Vector3:
	var grid_xform: Transform3D = _grid_xform_local()
	return grid_xform * Vector3(x * cell_size, 0.0, y * cell_size)

func _tile_to_world_center(x: int, y: int) -> Vector3:
	var grid_xform: Transform3D = _grid_xform_local()
	return grid_xform * Vector3((x + 0.5) * cell_size, 0.0, (y + 0.5) * cell_size)

func _tile_to_world_center_f(xf: float, yf: float) -> Vector3:
	var grid_xform: Transform3D = _grid_xform_local()
	return grid_xform * Vector3((xf + 0.5) * cell_size, 0.0, (yf + 0.5) * cell_size)

func _cell_idx(x: int, y: int) -> int:
	return y * grid_w + x

func _cell_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < grid_w and y < grid_h

func _cell_get(x: int, y: int) -> int:
	if not _cell_in_bounds(x, y):
		return 0
	if _cells.is_empty():
		return 0
	return int(_cells[_cell_idx(x, y)])

func _fill_cells_random() -> void:
	for y in range(grid_h):
		for x in range(grid_w):
			_cells[_cell_idx(x, y)] = 1 if _rng.randf() < fill_percent else 0

func _apply_cell_border_empty() -> void:
	for y in range(grid_h):
		for x in range(grid_w):
			if x < border or y < border or x >= grid_w - border or y >= grid_h - border:
				_cells[_cell_idx(x, y)] = 0

func _count_cell_neighbors8(x: int, y: int) -> int:
	var c: int = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			c += _cell_get(x + dx, y + dy)
	return c

func _smooth_cells_step() -> void:
	var next: PackedByteArray = PackedByteArray()
	next.resize(grid_w * grid_h)

	for y in range(grid_h):
		for x in range(grid_w):
			var n: int = _count_cell_neighbors8(x, y)
			var here: int = _cell_get(x, y)
			if n > 4:
				next[_cell_idx(x, y)] = 1
			elif n < 4:
				next[_cell_idx(x, y)] = 0
			else:
				next[_cell_idx(x, y)] = here

	_cells = next

func _points_w() -> int:
	return grid_w + 1

func _points_h() -> int:
	return grid_h + 1

func _tile_idx(x: int, y: int) -> int:
	return y * grid_w + x

func _corner_idx(x: int, y: int) -> int:
	return y * _points_w() + x

func _tile_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < grid_w and y < grid_h

func _corner_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < _points_w() and y < _points_h()

func _tile_get(x: int, y: int) -> int:
	if not _tile_in_bounds(x, y):
		return 0
	return int(_tiles[_tile_idx(x, y)])

func _corner_get(x: int, y: int) -> int:
	if not _corner_in_bounds(x, y):
		return 0
	return int(_corners[_corner_idx(x, y)])

func _count_corner_neighbors8(x: int, y: int) -> int:
	var c: int = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			c += _corner_get(x + dx, y + dy)
	return c

func _has_variant_floor_nodes() -> bool:
	return floor_full_mmi != null and floor_edge_mmi != null and floor_corner_mmi != null and floor_inverse_corner_mmi != null and floor_checker_mmi != null
