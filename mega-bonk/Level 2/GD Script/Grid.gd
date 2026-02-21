extends Node

enum GridState { EMPTY, ROOM, CORRIDOR, WALL }

var grid_width: int
var grid_height: int
var grid_depth: int
var grid = []

# Fixed step size for the grid
const STEP_SIZE: Vector3 = Vector3(1, 1, 1)

func initialize(_width: int, _height: int, _depth: int):
	grid_width = int(ceil(_width / STEP_SIZE.x))
	grid_height = int(ceil(_height / STEP_SIZE.y))
	grid_depth = int(ceil(_depth / STEP_SIZE.z))

	grid.resize(grid_width)
	for x in range(grid_width):
		grid[x] = []
		for y in range(grid_height):
			grid[x].append([])
			for z in range(grid_depth):
				grid[x][y].append(GridState.EMPTY)

	print("Grid initialized with dimensions: width =", grid_width, ", height =", grid_height, ", depth =", grid_depth)

func is_within_bounds(position: Vector3) -> bool:
	return position.x >= 0 and position.x < grid_width * STEP_SIZE.x and \
		   position.y >= 0 and position.y < grid_height * STEP_SIZE.y and \
		   position.z >= 0 and position.z < grid_depth * STEP_SIZE.z

func get_state(position: Vector3) -> GridState:
	if not is_within_bounds(position):
		return GridState.EMPTY

	var x_idx = int(round(position.x / STEP_SIZE.x))
	var y_idx = int(round(position.y / STEP_SIZE.y))
	var z_idx = int(round(position.z / STEP_SIZE.z))

	# Clamp indices to valid ranges
	x_idx = clamp(x_idx, 0, grid_width - 1)
	y_idx = clamp(y_idx, 0, grid_height - 1)
	z_idx = clamp(z_idx, 0, grid_depth - 1)

	return grid[x_idx][y_idx][z_idx]

func mark_area(start: Vector3, size: Vector3, state: GridState):
	var half_size = size / 2
	var min_bounds = start - half_size
	var max_bounds = start + half_size

	for x in range(int(floor(min_bounds.x / STEP_SIZE.x)), int(ceil(max_bounds.x / STEP_SIZE.x))):
		for y in range(int(floor(min_bounds.y / STEP_SIZE.y)), int(ceil(max_bounds.y / STEP_SIZE.y))):
			for z in range(int(floor(min_bounds.z / STEP_SIZE.z)), int(ceil(max_bounds.z / STEP_SIZE.z))):
				if x >= 0 and x < grid_width and y >= 0 and y < grid_height and z >= 0 and z < grid_depth:
					grid[x][y][z] = state

func mark_as_corridor(position: Vector3):
	if is_within_bounds(position):
		var x_idx = int(round(position.x / STEP_SIZE.x))
		var y_idx = int(round(position.y / STEP_SIZE.y))
		var z_idx = int(round(position.z / STEP_SIZE.z))
		if x_idx >= 0 and x_idx < grid_width and y_idx >= 0 and y_idx < grid_height and z_idx >= 0 and z_idx < grid_depth:
			grid[x_idx][y_idx][z_idx] = GridState.CORRIDOR

func mark_as_room(position: Vector3, size: Vector3):
	mark_area(position, size, GridState.ROOM)

func mark_as_wall(position: Vector3):
	if is_within_bounds(position):
		var x_idx = int(round(position.x / STEP_SIZE.x))
		var y_idx = int(round(position.y / STEP_SIZE.y))
		var z_idx = int(round(position.z / STEP_SIZE.z))
		if x_idx >= 0 and x_idx < grid_width and y_idx >= 0 and y_idx < grid_height and z_idx >= 0 and z_idx < grid_depth:
			grid[x_idx][y_idx][z_idx] = GridState.WALL

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
