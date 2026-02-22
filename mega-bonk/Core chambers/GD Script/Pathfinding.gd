extends Node

# Main function to find a path from start to goal
func find_path(start: Vector3, goal: Vector3) -> Array:
	return a_star_pathfind(start, goal)

# A* Pathfinding algorithm
func a_star_pathfind(start: Vector3, goal: Vector3) -> Array:
	# Snap start and goal to grid alignment
	var start_pos = start.snapped(Grid.STEP_SIZE)
	var goal_pos = goal.snapped(Grid.STEP_SIZE)

	if not Grid.is_within_bounds(start_pos) or not Grid.is_within_bounds(goal_pos):
		push_error("Start or goal position is out of bounds.")
		print("Start:", start, "Goal:", goal)
		return []

	print("Starting pathfinding from", start_pos, "to", goal_pos)

	# Initialization
	var open_list = PriorityQueue.new()
	var closed_list = {}
	var came_from = {}
	var g_costs = {}
	var f_costs = {}

	open_list.enqueue(start_pos, 0)
	g_costs[start_pos] = 0
	f_costs[start_pos] = heuristic(start_pos, goal_pos)

	# Main loop
	while not open_list.is_empty():
		var current = open_list.dequeue()

		if current == goal_pos:
			print("Path found from", start_pos, "to", goal_pos)
			return reconstruct_path(came_from, current)

		closed_list[current] = true

		# Process neighbors
		for neighbor in get_neighbors(current):
			if neighbor in closed_list:
				continue

			var tentative_g = g_costs[current] + current.distance_to(neighbor)

			if not open_list.contains(neighbor) or tentative_g < g_costs.get(neighbor, INF):
				came_from[neighbor] = current
				g_costs[neighbor] = tentative_g
				f_costs[neighbor] = tentative_g + heuristic(neighbor, goal_pos)

				if not open_list.contains(neighbor):
					open_list.enqueue(neighbor, f_costs[neighbor])

	push_error("No path found between:", start_pos, "and", goal_pos)
	return []

# Heuristic function to estimate the cost from node to goal
func heuristic(node: Vector3, goal: Vector3) -> float:
	# Manhattan distance heuristic
	return abs(node.x - goal.x) + abs(node.y - goal.y) + abs(node.z - goal.z)

# Reconstruct the path from the goal to the start
func reconstruct_path(came_from: Dictionary, current: Vector3) -> Array:
	var path = []
	while current in came_from:
		path.insert(0, current.snapped(Grid.STEP_SIZE))  # Snap positions to grid
		current = came_from[current]
	path.insert(0, current.snapped(Grid.STEP_SIZE))  # Include starting position
	return path

# Retrieve neighbors of the current node with appropriate step size
func get_neighbors(position: Vector3) -> Array:
	var neighbors = []
	var offsets = [
		Vector3(Grid.STEP_SIZE.x, 0, 0), Vector3(-Grid.STEP_SIZE.x, 0, 0),
		Vector3(0, Grid.STEP_SIZE.y, 0), Vector3(0, -Grid.STEP_SIZE.y, 0),
		Vector3(0, 0, Grid.STEP_SIZE.z), Vector3(0, 0, -Grid.STEP_SIZE.z)
	]

	for offset in offsets:
		var neighbor_position = (position + offset).snapped(Grid.STEP_SIZE)

		if Grid.is_within_bounds(neighbor_position):
			neighbors.append(neighbor_position)

	return neighbors
