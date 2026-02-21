extends Node3D

@export var width: int = 30
@export var height: int = 30
@export var depth: int = 30
@export var num_points: int = 12
@export var additional_pathway_chance: float = 0.1
@export var max_additional_pathways: int = 5
@export var debug_mode: bool = false

var _random: RandomNumberGenerator = RandomNumberGenerator.new()

var random_points: Array = []
var edges: Array = []
var mst_edges: Array = []
var corridor_data: Array = []  # Collect corridor visualization data
var room_data: Array = []  # Collect room visualization data
var placed_positions: Dictionary = {}

var point_mesh_instances: Array = []
var edge_mesh_instances: Array = []
var mst_edge_mesh_instances: Array = []
var corridor_mesh_instances: Array = []
var room_mesh_instances: Array = []


func _ready():
	print("Grid setup with step size:", Grid.STEP_SIZE)
	if not check_dependencies():
		push_error("Required singleton(s) not found.")
		return

	initialize_grid()
	generate_dungeon()
	collect_visualization_data()
	visualize()

func check_dependencies() -> bool:
	return Grid != null and DelaunayTriangulation != null and KruskalMST != null and CorridorCreator != null and Pathfinder != null and Visualize != null

func initialize_grid():
	Grid.initialize(width, height, depth)
	if debug_mode:
		print("Grid initialized with dimensions: width =", width, ", height =", height, ", depth =", depth)

func generate_dungeon():
	generate_random_points()
	perform_delaunay_triangulation()
	generate_mst()
	integrate_additional_pathways()
	connect_corridors()

func generate_random_points():
	random_points.clear()
	var min_distance = Grid.STEP_SIZE.x * 8
	var margin = Grid.STEP_SIZE.x * 6

	while random_points.size() < num_points:
		var new_point = Vector3(
			_random.randi_range(margin, width * Grid.STEP_SIZE.x - margin - 1),
			_random.randi_range(margin, height * Grid.STEP_SIZE.y - margin - 1),
			_random.randi_range(margin, depth * Grid.STEP_SIZE.z - margin - 1)
		)
		if Grid.is_within_bounds(new_point) and random_points.all(func(p): return p.distance_to(new_point) > min_distance):
			random_points.append(new_point)

	if debug_mode:
		print("Generated random points:", random_points)

func perform_delaunay_triangulation():
	edges = DelaunayTriangulation.delaunay_triangulation(random_points)
	if debug_mode:
		print("Delaunay edges:", edges)

func generate_mst():
	var edges_with_weights = edges.map(func(edge):
		if edge.size() == 2 and edge[0] is Vector3 and edge[1] is Vector3:
			return [edge[0], edge[1], edge[0].distance_to(edge[1])]
		return null
	).filter(func(x): return x != null)
	mst_edges = KruskalMST.kruskal_mst(edges_with_weights)
	if debug_mode:
		print("MST edges:", mst_edges)

func integrate_additional_pathways():
	var additional_pathways_added = 0
	for edge in edges:
		if not mst_edges.has(edge) and additional_pathways_added < max_additional_pathways:
			if _random.randf() < additional_pathway_chance:
				mst_edges.append(edge)
				additional_pathways_added += 1
				if debug_mode:
					print("Added additional pathway:", edge)

func connect_corridors():
	for edge in mst_edges:
		var start = edge[0].snapped(Grid.STEP_SIZE)
		var end = edge[1].snapped(Grid.STEP_SIZE)

		if not Grid.is_within_bounds(start) or not Grid.is_within_bounds(end):
			if debug_mode:
				print("Out-of-bounds edge detected:", start, "to", end)
			continue

		# Use CorridorCreator singleton for corridor creation
		CorridorCreator.create_corridors(start, [end], placed_positions)

		
func collect_visualization_data():
	# Sync corridor and room data for visualization
	corridor_data = CorridorCreator.get_corridor_data()
	room_data = CorridorCreator.get_room_data()
	if debug_mode:
		print("Collected corridor data:", corridor_data)
		print("Collected room data:", room_data)

func visualize():
	# Assign necessary properties to the Visualize singleton
	Visualize.grid_width = width
	Visualize.grid_height = height
	Visualize.grid_depth = depth

	Visualize.input_points = random_points
	Visualize.edges = edges
	Visualize.mst_edges = mst_edges
	Visualize.corridor_data = corridor_data  # Corridors as red cubes
	Visualize.room_data = room_data  # Rooms as blue cubes

	print("Visualizing with room_data:", room_data, "and corridor_data:", corridor_data)

	# Trigger the visualization
	Visualize.visualize()
