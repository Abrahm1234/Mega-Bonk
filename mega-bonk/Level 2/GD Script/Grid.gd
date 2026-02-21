extends Node

enum GridState { EMPTY, ROOM, CORRIDOR, WALL }

var grid_width: int
var grid_height: int
var grid_depth: int
var grid = []

# Step size (world units per cell). Must NOT be const.
var STEP_SIZE: Vector3 = Vector3(1, 1, 1)

func set_step_size(value: Vector3) -> void:
	STEP_SIZE = Vector3(
		max(0.0001, value.x),
		max(0.0001, value.y),
		max(0.0001, value.z)
	)

func initialize(_width: int, _height: int, _depth: int):
	grid_width = max(1, _width)
	grid_height = max(1, _height)
	grid_depth = max(1, _depth)

	grid.resize(grid_width)
	for x in range(grid_width):
		grid[x] = []
		for y in range(grid_height):
			grid[x].append([])
			for z in range(grid_depth):
				grid[x][y].append(GridState.EMPTY)

	print("Grid initialized (cells):", grid_width, grid_height, grid_depth, " step:", STEP_SIZE)

func is_within_bounds(position: Vector3) -> bool:
	return position.x >= 0 and position.x < grid_width * STEP_SIZE.x and \
		   position.y >= 0 and position.y < grid_height * STEP_SIZE.y and \
		   position.z >= 0 and position.z < grid_depth * STEP_SIZE.z

func _to_index(position: Vector3) -> Vector3i:
	var x_idx = int(floor(position.x / STEP_SIZE.x))
	var y_idx = int(floor(position.y / STEP_SIZE.y))
	var z_idx = int(floor(position.z / STEP_SIZE.z))
	return Vector3i(
		clamp(x_idx, 0, grid_width - 1),
		clamp(y_idx, 0, grid_height - 1),
		clamp(z_idx, 0, grid_depth - 1)
	)

func get_state(position: Vector3) -> GridState:
	if not is_within_bounds(position):
		return GridState.EMPTY
	var idx := _to_index(position)
	return grid[idx.x][idx.y][idx.z]

func mark_area(center: Vector3, size: Vector3, state: GridState):
	var half_size = size / 2
	var min_bounds = center - half_size
	var max_bounds = center + half_size

	var x0 = int(floor(min_bounds.x / STEP_SIZE.x))
	var y0 = int(floor(min_bounds.y / STEP_SIZE.y))
	var z0 = int(floor(min_bounds.z / STEP_SIZE.z))
	var x1 = int(ceil(max_bounds.x / STEP_SIZE.x))
	var y1 = int(ceil(max_bounds.y / STEP_SIZE.y))
	var z1 = int(ceil(max_bounds.z / STEP_SIZE.z))

	for x in range(x0, x1):
		for y in range(y0, y1):
			for z in range(z0, z1):
				if x >= 0 and x < grid_width and y >= 0 and y < grid_height and z >= 0 and z < grid_depth:
					grid[x][y][z] = state

func mark_as_corridor(position: Vector3):
	if is_within_bounds(position):
		var idx := _to_index(position)
		grid[idx.x][idx.y][idx.z] = GridState.CORRIDOR

func mark_as_room(position: Vector3, size: Vector3):
	mark_area(position, size, GridState.ROOM)

func mark_as_wall(position: Vector3):
	if is_within_bounds(position):
		var idx := _to_index(position)
		grid[idx.x][idx.y][idx.z] = GridState.WALL

func get_neighbors(position: Vector3) -> Array:
	var neighbors = []
	var offsets = [
		Vector3(STEP_SIZE.x, 0, 0), Vector3(-STEP_SIZE.x, 0, 0),
		Vector3(0, STEP_SIZE.y, 0), Vector3(0, -STEP_SIZE.y, 0),
		Vector3(0, 0, STEP_SIZE.z), Vector3(0, 0, -STEP_SIZE.z)
	]

	for offset in offsets:
		var neighbor_position = position + offset
		if is_within_bounds(neighbor_position):
			neighbors.append(neighbor_position)

	return neighbors

func debug_print_grid():
	for y in range(grid_height):
		print("Layer Y =", y)
		for x in range(grid_width):
			var row = []
			for z in range(grid_depth):
				row.append(grid[x][y][z])
			print(row)
