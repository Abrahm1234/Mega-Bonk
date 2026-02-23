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

@export var cell_size: float = 2.0
@export var floor_thickness: float = 0.25

enum OriginMode { MIN_CORNER, CENTERED, CUSTOM_ANCHOR }

@export var origin_mode: OriginMode = OriginMode.CUSTOM_ANCHOR
@export var origin_offset: Vector3 = Vector3.ZERO
@export var origin_anchor_path: NodePath

@export var make_walls: bool = true
@export var wall_height: float = 3.0
@export var wall_thickness: float = 0.25

@export var use_random_seed: bool = true
@export var seed_value: int = 12345
@export var randomize_on_run: bool = false

@export var use_pattern_stamping: bool = true
@export var pieces_replace_base_floor: bool = false
@export var piece_height_epsilon: float = 0.01

@export var mesh_full: Mesh
@export var mesh_edge: Mesh
@export var mesh_corner: Mesh
@export var mesh_inverse_corner: Mesh
@export var mesh_checker: Mesh

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

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _corners: PackedByteArray
var _tiles: PackedByteArray
var _occupied: PackedByteArray
var _piece_transforms: Dictionary = {}

func _ready() -> void:
	if wall_mmi == null:
		push_error("ArenaAutoGen: Missing MultiMeshInstance3D node at Arena/WallTiles")
		return

	if not _has_variant_floor_nodes() and floor_mmi == null:
		push_error("ArenaAutoGen: Missing floor renderer. Add Arena/FloorTiles or variant nodes Arena/Floor_*")
		return

	if use_random_seed or randomize_on_run:
		_rng.randomize()
	else:
		_rng.seed = seed_value

	if auto_generate:
		generate()

func generate() -> void:
	if grid_w <= 0 or grid_h <= 0:
		push_error("ArenaAutoGen: grid_w and grid_h must be > 0")
		return

	_corners = PackedByteArray()
	_corners.resize(_points_w() * _points_h())

	_tiles = PackedByteArray()
	_tiles.resize(grid_w * grid_h)

	_occupied = PackedByteArray()
	_occupied.resize(grid_w * grid_h)

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

	patterns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)

	for pattern in patterns:
		var size: Vector2i = pattern.get("size", Vector2i.ONE)
		for y in range(grid_h - size.y + 1):
			for x in range(grid_w - size.x + 1):
				if _pattern_matches_at(pattern, x, y):
					_mark_pattern_occupied(size, x, y)
					var pid: String = str(pattern.get("id", ""))
					if not _piece_transforms.has(pid):
						continue
					var t: Array = _piece_transforms[pid] as Array
					var rot_steps: int = int(pattern.get("rot_steps", 0))
					var yaw: float = rot_steps * PI * 0.5
					var mesh: Mesh = _build_piece_mesh(pid)
					var desired: Vector3 = _piece_desired_size(size)
					var pos: Vector3 = _pattern_anchor_to_world(x, y, size)
					pos.y += piece_height_epsilon
					t.append(_fit_mesh_transform(mesh, desired, yaw, pos))

	_build_piece_multimeshes()

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

func _mark_pattern_occupied(size: Vector2i, x: int, y: int) -> void:
	for py in range(size.y):
		for px in range(size.x):
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
	mm.mesh = _build_floor_variant_mesh("full")
	var transforms: Array[Transform3D] = []
	for y in range(grid_h):
		for x in range(grid_w):
			if _tile_get(x, y) == 0 or (pieces_replace_base_floor and _occupied[_tile_idx(x, y)] != 0):
				continue
			var pos: Vector3 = _tile_to_world_center(x, y)
			pos.y = floor_thickness * 0.5
			transforms.append(Transform3D(Basis.IDENTITY, pos))
	_assign_multimesh_transforms(mm, transforms)
	floor_mmi.multimesh = mm

func _build_floor_multimeshes_by_variant() -> void:
	var buckets: Dictionary = {"full": [], "edge": [], "corner": [], "inverse_corner": [], "checker": []}
	var mesh_by_variant: Dictionary = {
		"full": _build_floor_variant_mesh("full"),
		"edge": _build_floor_variant_mesh("edge"),
		"corner": _build_floor_variant_mesh("corner"),
		"inverse_corner": _build_floor_variant_mesh("inverse_corner"),
		"checker": _build_floor_variant_mesh("checker"),
	}
	var desired: Vector3 = Vector3(cell_size, floor_thickness, cell_size)

	for y in range(grid_h):
		for x in range(grid_w):
			if pieces_replace_base_floor and _occupied[_tile_idx(x, y)] != 0:
				continue
			var mask: int = _mask_at_tile(x, y)
			if mask == CANONICAL_EMPTY:
				continue
			var canonical: Dictionary = _canonicalize_mask(mask)
			var variant_id: String = str(canonical.get("variant_id", ""))
			if not buckets.has(variant_id):
				continue
			var rotation_steps: int = int(canonical.get("rotation_steps", 0))
			var pos: Vector3 = _tile_to_world_center(x, y)
			pos.y = floor_thickness * 0.5
			var yaw: float = rotation_steps * PI * 0.5
			var mesh: Mesh = mesh_by_variant[variant_id] as Mesh
			var transforms: Array = buckets[variant_id] as Array
			transforms.append(_fit_mesh_transform(mesh, desired, yaw, pos))

	_assign_variant_multimesh(floor_full_mmi, buckets["full"] as Array, mesh_by_variant["full"] as Mesh)
	_assign_variant_multimesh(floor_edge_mmi, buckets["edge"] as Array, mesh_by_variant["edge"] as Mesh)
	_assign_variant_multimesh(floor_corner_mmi, buckets["corner"] as Array, mesh_by_variant["corner"] as Mesh)
	_assign_variant_multimesh(floor_inverse_corner_mmi, buckets["inverse_corner"] as Array, mesh_by_variant["inverse_corner"] as Mesh)
	_assign_variant_multimesh(floor_checker_mmi, buckets["checker"] as Array, mesh_by_variant["checker"] as Mesh)

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

func _build_floor_variant_mesh(variant_id: String) -> Mesh:
	match variant_id:
		"full":
			if mesh_full != null:
				return mesh_full
		"edge":
			if mesh_edge != null:
				return mesh_edge
		"corner":
			if mesh_corner != null:
				return mesh_corner
		"inverse_corner":
			if mesh_inverse_corner != null:
				return mesh_inverse_corner
		"checker":
			if mesh_checker != null:
				return mesh_checker

	var mesh: BoxMesh = BoxMesh.new()
	match variant_id:
		"edge": mesh.size = Vector3(cell_size, floor_thickness, cell_size * 0.5)
		"corner": mesh.size = Vector3(cell_size * 0.5, floor_thickness, cell_size * 0.5)
		"inverse_corner": mesh.size = Vector3(cell_size, floor_thickness, cell_size)
		"checker": mesh.size = Vector3(cell_size * 0.75, floor_thickness, cell_size * 0.75)
		_: mesh.size = Vector3(cell_size, floor_thickness, cell_size)
	return mesh

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
			return false
		_:
			return true


func _piece_desired_size(size: Vector2i) -> Vector3:
	return Vector3(float(size.x) * cell_size, floor_thickness, float(size.y) * cell_size)

func _fit_mesh_transform(mesh: Mesh, desired_size: Vector3, yaw: float, world_pos: Vector3) -> Transform3D:
	if mesh == null:
		return Transform3D(Basis(Vector3.UP, yaw), world_pos)

	var aabb: AABB = mesh.get_aabb()
	var sx: float = max(aabb.size.x, 0.0001)
	var sy: float = max(aabb.size.y, 0.0001)
	var sz: float = max(aabb.size.z, 0.0001)
	var scale: Vector3 = Vector3(desired_size.x / sx, desired_size.y / sy, desired_size.z / sz)
	var basis: Basis = Basis(Vector3.UP, yaw).scaled(scale)
	var center: Vector3 = aabb.position + aabb.size * 0.5
	var corrected_pos: Vector3 = world_pos + basis * (-center)
	return Transform3D(basis, corrected_pos)

func _grid_base_world() -> Vector3:
	var base: Vector3 = Vector3.ZERO
	match origin_mode:
		OriginMode.MIN_CORNER: base = Vector3.ZERO
		OriginMode.CENTERED: base = Vector3(-(grid_w * cell_size) * 0.5, 0.0, -(grid_h * cell_size) * 0.5)
		OriginMode.CUSTOM_ANCHOR:
			var a: Node = get_node_or_null(origin_anchor_path)
			if a is Node3D:
				base = to_local((a as Node3D).global_position)
	return base + origin_offset

func _corner_to_world(x: int, y: int) -> Vector3:
	return _grid_base_world() + Vector3(x * cell_size, 0.0, y * cell_size)

func _tile_to_world_center(x: int, y: int) -> Vector3:
	return _grid_base_world() + Vector3((x + 0.5) * cell_size, 0.0, (y + 0.5) * cell_size)

func _tile_to_world_center_f(xf: float, yf: float) -> Vector3:
	return _grid_base_world() + Vector3((xf + 0.5) * cell_size, 0.0, (yf + 0.5) * cell_size)

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
