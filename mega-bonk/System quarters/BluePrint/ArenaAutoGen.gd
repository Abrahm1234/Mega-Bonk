extends Node3D
class_name ArenaAutoGen

const DIRS4: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

# Canonical masks for dual-grid rendering.
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

# Backward-compatible floor renderer (single multimesh) if variant nodes are not present.
@onready var floor_mmi: MultiMeshInstance3D = $"Arena/FloorTiles" as MultiMeshInstance3D
# Variant renderers (recommended): Arena/Floor_full, Floor_edge, Floor_corner, Floor_inverse_corner, Floor_checker.
@onready var floor_full_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Floor_full") as MultiMeshInstance3D
@onready var floor_edge_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Floor_edge") as MultiMeshInstance3D
@onready var floor_corner_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Floor_corner") as MultiMeshInstance3D
@onready var floor_inverse_corner_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Floor_inverse_corner") as MultiMeshInstance3D
@onready var floor_checker_mmi: MultiMeshInstance3D = get_node_or_null("Arena/Floor_checker") as MultiMeshInstance3D

@onready var wall_mmi: MultiMeshInstance3D = $"Arena/WallTiles" as MultiMeshInstance3D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Corner-point control grid (dual-grid input): 1 = filled, 0 = empty.
var _corners: PackedByteArray
# Derived tile occupancy from corners for floor/wall pass: 1 = occupied, 0 = empty.
var _tiles: PackedByteArray

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

	_fill_corners_random()
	_apply_corner_border_empty()

	for _i in range(smoothing_steps):
		_smooth_corners_step()
		_apply_corner_border_empty()

	if ensure_connected:
		_force_single_corner_region_from_center()

	_build_tiles_from_corners()
	_build_floor_multimeshes()

	if make_walls:
		_build_walls_multimesh()
	else:
		wall_mmi.multimesh = null

# -----------------------------
# Corner-grid generation
# -----------------------------

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

# -----------------------------
# Dual-grid conversion + meshing
# -----------------------------

func _build_tiles_from_corners() -> void:
	for y in range(grid_h):
		for x in range(grid_w):
			var mask: int = _mask_at_tile(x, y)
			_tiles[_tile_idx(x, y)] = 1 if _tile_filled_from_mask(mask) else 0

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

	var floor_mesh: BoxMesh = BoxMesh.new()
	floor_mesh.size = Vector3(cell_size, floor_thickness, cell_size)
	mm.mesh = floor_mesh

	var transforms: Array[Transform3D] = []

	for y in range(grid_h):
		for x in range(grid_w):
			if _tile_get(x, y) == 0:
				continue

			var pos: Vector3 = _tile_to_world_center(x, y)
			pos.y = floor_thickness * 0.5
			transforms.append(Transform3D(Basis.IDENTITY, pos))

	_assign_multimesh_transforms(mm, transforms)
	floor_mmi.multimesh = mm

func _build_floor_multimeshes_by_variant() -> void:
	var buckets: Dictionary = {
		"full": [],
		"edge": [],
		"corner": [],
		"inverse_corner": [],
		"checker": [],
	}

	for y in range(grid_h):
		for x in range(grid_w):
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
			var basis: Basis = Basis(Vector3.UP, yaw)
			var transforms: Array = buckets[variant_id] as Array
			transforms.append(Transform3D(basis, pos))

	_assign_variant_multimesh(floor_full_mmi, buckets["full"] as Array, _build_floor_variant_mesh("full"))
	_assign_variant_multimesh(floor_edge_mmi, buckets["edge"] as Array, _build_floor_variant_mesh("edge"))
	_assign_variant_multimesh(floor_corner_mmi, buckets["corner"] as Array, _build_floor_variant_mesh("corner"))
	_assign_variant_multimesh(floor_inverse_corner_mmi, buckets["inverse_corner"] as Array, _build_floor_variant_mesh("inverse_corner"))
	_assign_variant_multimesh(floor_checker_mmi, buckets["checker"] as Array, _build_floor_variant_mesh("checker"))

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
	var mesh: BoxMesh = BoxMesh.new()
	match variant_id:
		"edge":
			mesh.size = Vector3(cell_size, floor_thickness, cell_size * 0.5)
		"corner":
			mesh.size = Vector3(cell_size * 0.5, floor_thickness, cell_size * 0.5)
		"inverse_corner":
			mesh.size = Vector3(cell_size, floor_thickness, cell_size)
		"checker":
			mesh.size = Vector3(cell_size * 0.75, floor_thickness, cell_size * 0.75)
		_:
			mesh.size = Vector3(cell_size, floor_thickness, cell_size)
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
	var basis: Basis = Basis(Vector3.UP, yaw)
	return Transform3D(basis, pos)

func _assign_multimesh_transforms(mm: MultiMesh, transforms: Array[Transform3D]) -> void:
	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])

# -----------------------------
# Dual-mask helpers
# -----------------------------

func _mask_at_tile(x: int, y: int) -> int:
	var tl: int = _corner_get(x, y)
	var tr: int = _corner_get(x + 1, y)
	var br: int = _corner_get(x + 1, y + 1)
	var bl: int = _corner_get(x, y + 1)
	return _mask_from_corners(tl, tr, br, bl)

func _mask_from_corners(tl: int, tr: int, br: int, bl: int) -> int:
	return (tl << 0) | (tr << 1) | (br << 2) | (bl << 3)

func _rot90(mask: int) -> int:
	var tl: int = (mask >> 0) & 1
	var tr: int = (mask >> 1) & 1
	var br: int = (mask >> 2) & 1
	var bl: int = (mask >> 3) & 1
	# after 90°: TL<-BL, TR<-TL, BR<-TR, BL<-BR
	return (bl << 0) | (tl << 1) | (tr << 2) | (br << 3)

func _canonicalize_mask(mask: int) -> Dictionary:
	var rotated: int = mask
	for steps in range(4):
		if rotated == CANONICAL_EMPTY:
			return {"variant_id": "empty", "rotation_steps": steps}
		if rotated == CANONICAL_FULL:
			return {"variant_id": "full", "rotation_steps": steps}
		if rotated == CANONICAL_CORNER:
			return {"variant_id": "corner", "rotation_steps": steps}
		if rotated == CANONICAL_EDGE:
			return {"variant_id": "edge", "rotation_steps": steps}
		if rotated == CANONICAL_INVERSE_CORNER:
			return {"variant_id": "inverse_corner", "rotation_steps": steps}
		if rotated == CANONICAL_CHECKER:
			return {"variant_id": "checker", "rotation_steps": steps}
		rotated = _rot90(rotated)
	return {"variant_id": "unknown", "rotation_steps": 0}

func _tile_filled_from_mask(mask: int) -> bool:
	# In dual-grid mode, any non-empty mask contributes geometry.
	return mask != CANONICAL_EMPTY

# -----------------------------
# Position + indexing helpers
# -----------------------------

func _grid_base_world() -> Vector3:
	var base: Vector3 = Vector3.ZERO

	match origin_mode:
		OriginMode.MIN_CORNER:
			base = Vector3.ZERO
		OriginMode.CENTERED:
			base = Vector3(-(grid_w * cell_size) * 0.5, 0.0, -(grid_h * cell_size) * 0.5)
		OriginMode.CUSTOM_ANCHOR:
			var a: Node = get_node_or_null(origin_anchor_path)
			if a is Node3D:
				base = to_local((a as Node3D).global_position)
			else:
				base = Vector3.ZERO

	return base + origin_offset

func _corner_to_world(x: int, y: int) -> Vector3:
	var base: Vector3 = _grid_base_world()
	return base + Vector3(x * cell_size, 0.0, y * cell_size)

func _tile_to_world_center(x: int, y: int) -> Vector3:
	var base: Vector3 = _grid_base_world()
	return base + Vector3((x + 0.5) * cell_size, 0.0, (y + 0.5) * cell_size)

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
