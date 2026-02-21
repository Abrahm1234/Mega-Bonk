extends Node

@export var max_pathway_length: float = 20.0  # Maximum allowed length for pathways
@export var debug_mode: bool = false  # Debug mode for detailed analysis

var edges = []  # All edges from Delaunay triangulation
var mst_edges = []  # MST edges
var potential_pathways = []  # Generated pathways
var mst_edge_set = {}  # MST edges as a set for quick lookup
var _random: RandomNumberGenerator = RandomNumberGenerator.new()  # Random number generator

func _ready():
	if Grid == null or Pathfinder == null:
		push_error("Grid or Pathfinder is not initialized.")
		return

	# Convert MST edges to a set for quick checks
	mst_edge_set.clear()
	for edge in mst_edges:
		mst_edge_set[edge] = true

	# Generate potential pathways
	potential_pathways = generate_potential_pathways(edges, mst_edges)

	if debug_mode:
		debug_output()

# Generate additional pathways and return them
func get_additional_pathways(all_edges: Array, current_mst_edges: Array, max_paths: int, chance: float) -> Array:
	edges = all_edges
	mst_edges = current_mst_edges
	mst_edge_set.clear()
	for edge in mst_edges:
		mst_edge_set[edge] = true

	var additional_pathways = []
	var pathways_generated = 0

	for edge in edges:
		if mst_edge_set.has(edge):
			continue  # Skip MST edges

		if pathways_generated >= max_paths:
			break

		var point1 = edge[0]
		var point2 = edge[1]
		var pathway_length = point1.distance_to(point2)

		if pathway_length > max_pathway_length:
			continue

		if _random.randf() < chance:
			var path = Pathfinder.find_path_a_star(
				point1.snapped(Vector3(1, 1, 1)),
				point2.snapped(Vector3(1, 1, 1)),
				[]
			)

			if path.size() > 0 and not is_redundant_pathway(path):
				additional_pathways.append(path)
				pathways_generated += 1
				if debug_mode:
					print("Added pathway from", path[0], "to", path[path.size() - 1])

	return additional_pathways

# Generate potential pathways using a second pathfinder
func generate_potential_pathways(edges: Array, mst_edges: Array) -> Array:
	potential_pathways.clear()

	for edge in edges:
		if mst_edge_set.has(edge):
			continue  # Skip MST edges

		var point1 = edge[0]
		var point2 = edge[1]
		var pathway_length = point1.distance_to(point2)

		if pathway_length > max_pathway_length:
			continue

		# Find a path between the two points
		var path = Pathfinder.find_path_a_star(
			point1.snapped(Vector3(1, 1, 1)),
			point2.snapped(Vector3(1, 1, 1)),
			[]
		)

		if path.size() > 0 and not is_redundant_pathway(path):
			potential_pathways.append(path)

	return potential_pathways

# Check if a pathway already exists in potential pathways
func is_redundant_pathway(path: Array) -> bool:
	for pathway in potential_pathways:
		if pathway == path:
			return true
	return false

# Debugging output for potential pathways
func debug_output():
	print("Potential pathways:")
	for pathway in potential_pathways:
		if pathway.size() > 1:
			var length = pathway[0].distance_to(pathway[pathway.size() - 1])
			print("Pathway from ", pathway[0], " to ", pathway[pathway.size() - 1], " with length: ", length)
