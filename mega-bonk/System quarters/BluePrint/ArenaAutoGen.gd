# File: res://System quarters/BluePrint/ArenaAutoGen.gd
extends Node3D
class_name ArenaAutoGen

# Typed directions array to avoid Variant inference warnings (warnings treated as errors).
const DIRS4: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

@export var auto_generate: bool = true

@export var grid_w: int = 48
@export var grid_h: int = 48
@export_range(0.0, 1.0, 0.01) var fill_percent: float = 0.48
@export var smoothing_steps: int = 6

@export var ensure_connected: bool = true
@export var border: int = 1

@export var cell_size: float = 2.0
@export var floor_thickness: float = 0.25

@export var make_walls: bool = true
@export var wall_height: float = 3.0
@export var wall_thickness: float = 0.25

@export var use_random_seed: bool = true
@export var seed_value: int = 12345
@export var randomize_on_run: bool = false

@onready var floor_mmi: MultiMeshInstance3D = $"Arena/FloorTiles" as MultiMeshInstance3D
@onready var wall_mmi: MultiMeshInstance3D = $"Arena/WallTiles" as MultiMeshInstance3D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _map: PackedByteArray # 1 = floor, 0 = empty

func _ready() -> void:
	if floor_mmi == null or wall_mmi == null:
		push_error("ArenaAutoGen: Missing MultiMeshInstance3D nodes at Arena/FloorTiles and/or Arena/WallTiles")
		return

	if use_random_seed or randomize_on_run:
		_rng.randomize()
	else:
		_rng.seed = seed_value

	if auto_generate:
		generate()

func generate() -> void:
	_map = PackedByteArray()
	_map.resize(grid_w * grid_h)

	_fill_random()
	_apply_border_empty()

	for _i in range(smoothing_steps):
		_smooth_step()
		_apply_border_empty()

	if ensure_connected:
		_force_single_region_from_center()

	_build_floor_multimesh()

	if make_walls:
		_build_walls_multimesh()
	else:
		wall_mmi.multimesh = null

# -----------------------------
# Generation
# -----------------------------

func _fill_random() -> void:
	for y in range(grid_h):
		for x in range(grid_w):
			_map[_idx(x, y)] = 1 if _rng.randf() < fill_percent else 0

func _apply_border_empty() -> void:
	for y in range(grid_h):
		for x in range(grid_w):
			if x < border or y < border or x >= grid_w - border or y >= grid_h - border:
				_map[_idx(x, y)] = 0

func _smooth_step() -> void:
	var next: PackedByteArray = PackedByteArray()
	next.resize(grid_w * grid_h)

	for y in range(grid_h):
		for x in range(grid_w):
			var neighbor_count: int = _count_neighbors8(x, y)
			var here: int = _cell_get(x, y)

			if neighbor_count > 4:
				next[_idx(x, y)] = 1
			elif neighbor_count < 4:
				next[_idx(x, y)] = 0
			else:
				next[_idx(x, y)] = here

	_map = next

func _force_single_region_from_center() -> void:
	var start: Vector2i = Vector2i(int(grid_w / 2), int(grid_h / 2))

	if _cell_get(start.x, start.y) == 0:
		var found: bool = false
		for r in range(1, max(grid_w, grid_h)):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var p: Vector2i = start + Vector2i(dx, dy)
					if _in_bounds(p.x, p.y) and _cell_get(p.x, p.y) == 1:
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
	visited.resize(grid_w * grid_h)

	var q: Array[Vector2i] = [start]
	visited[_idx(start.x, start.y)] = 1

	# Head-index queue avoids pop_front() Variant inference.
	var head: int = 0
	while head < q.size():
		var p: Vector2i = q[head]
		head += 1

		for d in DIRS4:
			var n: Vector2i = p + d
			if _in_bounds(n.x, n.y) and _cell_get(n.x, n.y) == 1:
				var ii: int = _idx(n.x, n.y)
				if visited[ii] == 0:
					visited[ii] = 1
					q.push_back(n)

	for y in range(grid_h):
		for x in range(grid_w):
			var ii: int = _idx(x, y)
			if _map[ii] == 1 and visited[ii] == 0:
				_map[ii] = 0

# -----------------------------
# Meshing (MultiMesh)
# -----------------------------

func _build_floor_multimesh() -> void:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D

	var floor_mesh: BoxMesh = BoxMesh.new()
	floor_mesh.size = Vector3(cell_size, floor_thickness, cell_size)
	mm.mesh = floor_mesh

	var transforms: Array[Transform3D] = []

	for y in range(grid_h):
		for x in range(grid_w):
			if _cell_get(x, y) == 1:
				var pos: Vector3 = _cell_to_world_center(x, y)
				pos.y = floor_thickness * 0.5
				transforms.append(Transform3D(Basis.IDENTITY, pos))

	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])

	floor_mmi.multimesh = mm

func _build_walls_multimesh() -> void:
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

	mm.instance_count = transforms.size()
	for i in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])

	wall_mmi.multimesh = mm

func _wall_transform_for_edge(x: int, y: int, local_offset: Vector3, yaw: float) -> Transform3D:
	var center: Vector3 = _cell_to_world_center(x, y)
	var offset: Vector3 = Vector3(local_offset.x * cell_size, 0.0, local_offset.z * cell_size)
	var pos: Vector3 = center + offset
	pos.y = wall_height * 0.5
	var basis: Basis = Basis(Vector3.UP, yaw)
	return Transform3D(basis, pos)

# -----------------------------
# Helpers
# -----------------------------

func _cell_to_world_center(x: int, y: int) -> Vector3:
	var origin: Vector3 = Vector3(-(grid_w * cell_size) * 0.5, 0.0, -(grid_h * cell_size) * 0.5)
	return origin + Vector3((x + 0.5) * cell_size, 0.0, (y + 0.5) * cell_size)

func _idx(x: int, y: int) -> int:
	return y * grid_w + x

func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < grid_w and y < grid_h

# IMPORTANT: do NOT name this _get(), because Node has _get(property: StringName) -> Variant.
func _cell_get(x: int, y: int) -> int:
	if not _in_bounds(x, y):
		return 0
	return int(_map[_idx(x, y)])

func _count_neighbors8(x: int, y: int) -> int:
	var c: int = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			c += _cell_get(x + dx, y + dy)
	return c
