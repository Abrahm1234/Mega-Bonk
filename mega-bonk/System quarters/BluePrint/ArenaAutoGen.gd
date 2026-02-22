# File: res://scripts/ArenaAutoGen.gd
extends Node3D
class_name ArenaAutoGen

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

@export var randomize_on_run: bool = false # set true if you want a new map each time you press Play

@onready var floor_mmi: MultiMeshInstance3D = $"Arena/FloorTiles"
@onready var wall_mmi: MultiMeshInstance3D = $"Arena/WallTiles"

var _rng := RandomNumberGenerator.new()
var _map: PackedByteArray # 1 = floor, 0 = empty

func _ready() -> void:
	if use_random_seed or randomize_on_run:
		_rng.randomize()
	else:
		_rng.seed = seed_value

	if auto_generate:
		generate()

# Public: call this from an editor button or debug key later
func generate() -> void:
	_map = PackedByteArray()
	_map.resize(grid_w * grid_h)

	_fill_random()
	_apply_border_empty()
	for i in smoothing_steps:
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
	for y in grid_h:
		for x in grid_w:
			_map[_idx(x, y)] = 1 if _rng.randf() < fill_percent else 0

func _apply_border_empty() -> void:
	# force outer border to empty so the arena doesn't touch the edges
	for y in grid_h:
		for x in grid_w:
			if x < border or y < border or x >= grid_w - border or y >= grid_h - border:
				_map[_idx(x, y)] = 0

func _smooth_step() -> void:
	var next := PackedByteArray()
	next.resize(grid_w * grid_h)

	for y in grid_h:
		for x in grid_w:
			var n := _count_neighbors8(x, y)
			var here := _get(x, y)
			# Typical CA rule: more neighbors => become/keep floor
			# Adjust thresholds to taste
			if n > 4:
				next[_idx(x, y)] = 1
			elif n < 4:
				next[_idx(x, y)] = 0
			else:
				next[_idx(x, y)] = here

	_map = next

func _force_single_region_from_center() -> void:
	# Keeps only the largest connected floor region reachable from (approx) center.
	# This avoids lots of tiny disconnected islands.
	var start := Vector2i(grid_w / 2, grid_h / 2)
	if _get(start.x, start.y) == 0:
		# find nearest floor to center
		var found := false
		for r in range(1, max(grid_w, grid_h)):
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var p := start + Vector2i(dx, dy)
					if _in_bounds(p.x, p.y) and _get(p.x, p.y) == 1:
						start = p
						found = true
						break
				if found: break
			if found: break
		if not found:
			# no floors at all
			return

	var visited := PackedByteArray()
	visited.resize(grid_w * grid_h)

	var q: Array[Vector2i] = [start]
	visited[_idx(start.x, start.y)] = 1

	while not q.is_empty():
		var p := q.pop_front()
		for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var n := p + d
			if _in_bounds(n.x, n.y) and _get(n.x, n.y) == 1:
				var ii := _idx(n.x, n.y)
				if visited[ii] == 0:
					visited[ii] = 1
					q.push_back(n)

	# delete all floor not visited
	for y in grid_h:
		for x in grid_w:
			var ii := _idx(x, y)
			if _map[ii] == 1 and visited[ii] == 0:
				_map[ii] = 0

# -----------------------------
# Meshing (MultiMesh)
# -----------------------------

func _build_floor_multimesh() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D

	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(cell_size, floor_thickness, cell_size)
	floor_mmi.mesh = floor_mesh

	var transforms: Array[Transform3D] = []
	transforms.resize(0)

	for y in grid_h:
		for x in grid_w:
			if _get(x, y) == 1:
				var pos := _cell_to_world_center(x, y)
				pos.y = floor_thickness * 0.5
				transforms.append(Transform3D(Basis.IDENTITY, pos))

	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])

	floor_mmi.multimesh = mm

func _build_walls_multimesh() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D

	var wall_mesh := BoxMesh.new()
	# We'll orient walls by scaling along X or Z per edge
	wall_mesh.size = Vector3(cell_size, wall_height, wall_thickness)
	wall_mmi.mesh = wall_mesh

	var transforms: Array[Transform3D] = []
	transforms.resize(0)

	# For each floor cell, add wall segments on edges that border empty
	for y in grid_h:
		for x in grid_w:
			if _get(x, y) == 0:
				continue

			# N edge (toward -Z)
			if _get(x, y - 1) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(0, 0, -0.5), 0.0))
			# S edge (+Z)
			if _get(x, y + 1) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(0, 0, 0.5), 0.0))
			# W edge (-X) rotate 90deg
			if _get(x - 1, y) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(-0.5, 0, 0), PI * 0.5))
			# E edge (+X)
			if _get(x + 1, y) == 0:
				transforms.append(_wall_transform_for_edge(x, y, Vector3(0.5, 0, 0), PI * 0.5))

	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])

	wall_mmi.multimesh = mm

func _wall_transform_for_edge(x: int, y: int, local_offset: Vector3, yaw: float) -> Transform3D:
	var center := _cell_to_world_center(x, y)
	# Move to edge center
	var offset := Vector3(local_offset.x * cell_size, 0.0, local_offset.z * cell_size)
	var pos := center + offset
	pos.y = wall_height * 0.5
	var basis := Basis(Vector3.UP, yaw)
	return Transform3D(basis, pos)

# -----------------------------
# Helpers
# -----------------------------

func _cell_to_world_center(x: int, y: int) -> Vector3:
	# Grid on X/Z plane
	var origin := Vector3(-(grid_w * cell_size) * 0.5, 0.0, -(grid_h * cell_size) * 0.5)
	return origin + Vector3((x + 0.5) * cell_size, 0.0, (y + 0.5) * cell_size)

func _idx(x: int, y: int) -> int:
	return y * grid_w + x

func _in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < grid_w and y < grid_h

func _get(x: int, y: int) -> int:
	if not _in_bounds(x, y):
		return 0
	return _map[_idx(x, y)]

func _count_neighbors8(x: int, y: int) -> int:
	var c := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			c += _get(x + dx, y + dy)
	return c
