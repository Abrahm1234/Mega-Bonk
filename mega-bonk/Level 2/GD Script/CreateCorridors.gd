extends Node

@export var debug_mode: bool = false
var corridor_data: Array = []  # Collect corridor visualization data
var room_data: Array = []  # Collect room visualization data

# Create corridors from multiple start points to multiple end points
func create_corridors(start_point: Vector3, end_points: Array, placed_positions: Dictionary):
	if not start_point or not end_points:
		push_error("Start point and end_points must be non-empty.")
		return

	var step_size = resolve_step_size()

	# Define the bounding box of the grid for validation
	var grid_bounds = AABB(Vector3(0, 0, 0), Vector3(Grid.grid_width * step_size, Grid.grid_height * step_size, Grid.grid_depth * step_size))

	# Ensure start point is snapped
	var aligned_start = start_point.snapped(Vector3(step_size, step_size, step_size))

	if not grid_bounds.has_point(aligned_start):
		push_error("Start point is outside grid bounds:", aligned_start)
		return

	for end_point in end_points:
		if not end_point:
			if debug_mode:
				print("Invalid end point skipped.")
			continue

		# Ensure end point is snapped
		var aligned_end = end_point.snapped(Vector3(step_size, step_size, step_size))

		if not grid_bounds.has_point(aligned_end):
			if debug_mode:
				print("End point is outside grid bounds:", aligned_end)
			continue

		var path = Pathfinder.find_path(aligned_start, aligned_end)

		if not path or path.size() < 2:
			if debug_mode:
				print("No valid path found between:", aligned_start, "and", aligned_end)
			continue

		for i in range(path.size()):
			var current_position = path[i].snapped(Vector3(step_size, step_size, step_size))

			# Check if the current position is within bounds
			if not grid_bounds.has_point(current_position):
				if debug_mode:
					print("Path segment at", current_position, "is outside grid bounds.")
				continue

			if is_blue_cube_at_position(current_position, placed_positions):
				if debug_mode:
					print("Skipping red cube placement at:", current_position, "because a blue cube exists.")
				continue

			# Skip start and end points if inside blue cubes
			if (i == 0 or i == path.size() - 1) and is_blue_cube_at_position(current_position, placed_positions):
				if debug_mode:
					print("Skipping start/end point at", current_position, "because it's inside a blue cube.")
				continue

			place_corridor_segment(current_position, Vector3(step_size, step_size, step_size), placed_positions)

		# Force place the room at the end point
		force_place_room_cube(aligned_end, Vector3(step_size * 7, step_size * 7, step_size * 7), placed_positions)

	# Remove any red cubes inside blue cubes after corridor creation
	remove_red_cubes_inside_blue_cubes()


# Resolves the value of Grid.STEP_SIZE as a scalar
func resolve_step_size() -> float:
	return Grid.STEP_SIZE if typeof(Grid.STEP_SIZE) == TYPE_FLOAT else Grid.STEP_SIZE.x

# Check if a blue cube exists at a position
func is_blue_cube_at_position(position: Vector3, placed_positions: Dictionary) -> bool:
	var step_size = resolve_step_size()
	if placed_positions.has(position):
		var existing_size = placed_positions[position]
		return existing_size == Vector3(step_size * 7, step_size * 7, step_size * 7)
	return false

# Force place a large room cube at the MST point with transparency
func force_place_room_cube(position: Vector3, size: Vector3, placed_positions: Dictionary):
	var step_size = resolve_step_size()
	var adjusted_position = position.snapped(Vector3(step_size, step_size, step_size))
	Grid.mark_area(adjusted_position, size, Grid.GridState.ROOM)
	placed_positions[adjusted_position] = size
	# Append room data for visualization
	room_data.append({"position": adjusted_position, "size": size})
	if debug_mode:
		print("Placing room (blue cube) at MST point:", adjusted_position, "with size:", size)
	return adjusted_position

# Place a corridor segment ensuring no gaps
func place_corridor_segment(position: Vector3, size: Vector3, placed_positions: Dictionary):
	if not position:
		push_error("Invalid position passed to place_corridor_segment")
		return

	var step_size = resolve_step_size()
	var adjusted_position = position.snapped(Vector3(step_size, step_size, step_size))
	# Align with grid center (remove offset adjustment)
	var corrected_position = adjusted_position

	if not is_position_occupied(corrected_position, placed_positions):
		if debug_mode:
			print("Placing corridor segment at:", corrected_position, "with size:", size)
		mark_as_corridor(corrected_position, size, placed_positions)
		corridor_data.append({"position": corrected_position, "size": size})
	elif debug_mode:
		print("Skipped placing corridor at:", corrected_position, "- already occupied.")


# Check if a position is already occupied
func is_position_occupied(position: Vector3, placed_positions: Dictionary) -> bool:
	var occupied = placed_positions.has(position)
	if debug_mode and occupied:
		print("Position occupied:", position)
	return occupied

# Mark a position as a corridor
func mark_as_corridor(position: Vector3, size: Vector3, placed_positions: Dictionary):
	if Grid.is_within_bounds(position):
		if Grid.get_state(position) == Grid.GridState.EMPTY:
			if debug_mode:
				print("Marking corridor area at:", position, "with size:", size)
			Grid.mark_area(position, size, Grid.GridState.CORRIDOR)
			placed_positions[position] = size
		elif debug_mode:
			print("Skipped marking cell at:", position, "- already occupied or out of bounds.")

# Check and remove red cubes inside blue cubes
func remove_red_cubes_inside_blue_cubes():
	if debug_mode:
		print("Checking and removing red cubes inside blue cubes...")

	var step_size = resolve_step_size()
	var remaining_corridors = []

	for corridor in corridor_data:
		var corridor_position = corridor["position"].snapped(Vector3(step_size, step_size, step_size))
		var corridor_size = corridor["size"]
		var corridor_bounds = AABB(corridor_position - corridor_size / 2, corridor_size)

		var is_inside_any_blue_cube = false

		for room in room_data:
			var room_position = room["position"].snapped(Vector3(step_size, step_size, step_size))
			var room_size = room["size"]
			var room_bounds = AABB(room_position - room_size / 2, room_size)

			# Check for complete or partial intersection
			if room_bounds.intersects(corridor_bounds):
				if debug_mode:
					print("Red cube at", corridor_position, "intersects blue cube at", room_position)
				is_inside_any_blue_cube = true
				break

		if not is_inside_any_blue_cube:
			remaining_corridors.append(corridor)

	# Update corridor data to exclude removed cubes
	corridor_data = remaining_corridors
	if debug_mode:
		print("Remaining red cubes after removal:", corridor_data.size())


# Getter for room data
func get_room_data() -> Array:
	return room_data

# Getter for corridor data
func get_corridor_data() -> Array:
	return corridor_data
