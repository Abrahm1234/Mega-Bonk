extends Node3D

@export var debug_mode: bool = false
@export var sphere_size: float = 0.5
@export var blue_cube_color: Color = Color(0, 0, 1)  # Blue for rooms
@export var red_cube_color: Color = Color(1, 0, 0)  # Red for corridors
@export var blue_wire_color: Color = Color(1, 1, 0)  # Yellow for room wireframes
@export var red_wire_color: Color = Color(0, 1, 1)  # Cyan for corridor wireframes
@export var edge_color: Color = Color(0, 1, 1)  # Cyan for edges
@export var mst_edge_color: Color = Color(0, 1, 0)  # Green for MST edges
@export var grid_width: int = 30
@export var grid_height: int = 30
@export var grid_depth: int = 30

var blue_cubes = []
var red_cubes = []
var input_points = []  # Random points
var edges = []  # Edges
var mst_edges = []  # Minimum Spanning Tree edges
var corridor_data = []  # Corridor positions and sizes
var room_data = []  # Room positions and sizes

var blue_cube_wireframes = []
var red_cube_wireframes = []
var point_mesh_instances = []
var edge_mesh_instances = []
var mst_edge_mesh_instances = []
var corridor_mesh_instances = []
var room_mesh_instances = []

var button_blue_cubes
var button_red_cubes
var button_grid
var button_points
var button_edges
var button_mst_edges
var button_corridors
var button_rooms

var blue_cubes_visible = true
var red_cubes_visible = true
var grid_visible = true
var points_visible = true
var edges_visible = true
var mst_edges_visible = true
var corridors_visible = true
var rooms_visible = true

func _ready():
	create_ui()
	visualize()

func create_ui():
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

	var control = Control.new()
	canvas_layer.add_child(control)

	button_blue_cubes = Button.new()
	button_blue_cubes.text = "Toggle Room Wires"
	button_blue_cubes.position = Vector2(10, 250)
	button_blue_cubes.connect("pressed", Callable(self, "_on_toggle_blue_cubes"))
	control.add_child(button_blue_cubes)

	button_red_cubes = Button.new()
	button_red_cubes.text = "Toggle Corridor Wires"
	button_red_cubes.position = Vector2(10, 290)
	button_red_cubes.connect("pressed", Callable(self, "_on_toggle_red_cubes"))
	control.add_child(button_red_cubes)

	button_grid = Button.new()
	button_grid.text = "Toggle Grid (1)"
	button_grid.position = Vector2(10, 10)
	button_grid.connect("pressed", Callable(self, "_on_toggle_grid"))
	control.add_child(button_grid)

	button_points = Button.new()
	button_points.text = "Toggle Points (4)"
	button_points.position = Vector2(10, 50)
	button_points.connect("pressed", Callable(self, "_on_toggle_points"))
	control.add_child(button_points)

	button_edges = Button.new()
	button_edges.text = "Toggle Edges (2)"
	button_edges.position = Vector2(10, 90)
	button_edges.connect("pressed", Callable(self, "_on_toggle_edges"))
	control.add_child(button_edges)

	button_mst_edges = Button.new()
	button_mst_edges.text = "Toggle MST Edges (3)"
	button_mst_edges.position = Vector2(10, 130)
	button_mst_edges.connect("pressed", Callable(self, "_on_toggle_mst_edges"))
	control.add_child(button_mst_edges)

	button_corridors = Button.new()
	button_corridors.text = "Toggle Corridors (5)"
	button_corridors.position = Vector2(10, 170)
	button_corridors.connect("pressed", Callable(self, "_on_toggle_corridors"))
	control.add_child(button_corridors)

	button_rooms = Button.new()
	button_rooms.text = "Toggle Rooms (6)"
	button_rooms.position = Vector2(10, 210)
	button_rooms.connect("pressed", Callable(self, "_on_toggle_rooms"))
	control.add_child(button_rooms)

func _input(event):
	# Check if the event is a key press
	if event is InputEventKey:
		# Handle key press events
		if event.pressed:
			if event.keycode == Key.KEY_1:
				_on_toggle_grid()
			elif event.keycode == Key.KEY_2:
				_on_toggle_edges()
			elif event.keycode == Key.KEY_3:
				_on_toggle_mst_edges()
			elif event.keycode == Key.KEY_4:
				_on_toggle_points()
			elif event.keycode == Key.KEY_5:
				_on_toggle_corridors()
			elif event.keycode == Key.KEY_6:
				_on_toggle_rooms()

func _on_toggle_blue_cubes():
	blue_cubes_visible = not blue_cubes_visible
	visualize()

func _on_toggle_red_cubes():
	red_cubes_visible = not red_cubes_visible
	visualize()

func _on_toggle_grid():
	grid_visible = not grid_visible
	visualize()

func _on_toggle_points():
	points_visible = not points_visible
	visualize()

func _on_toggle_edges():
	edges_visible = not edges_visible
	visualize()

func _on_toggle_mst_edges():
	mst_edges_visible = not mst_edges_visible
	visualize()

func _on_toggle_corridors():
	corridors_visible = not corridors_visible
	visualize()

func _on_toggle_rooms():
	rooms_visible = not rooms_visible
	visualize()

func visualize():
	clear_visualizations()

	# Visualize grid
	if grid_visible:
		create_wire_mesh()

	# Visualize points
	if points_visible:
		visualize_data_points()

	# Visualize edges
	if edges_visible:
		visualize_edges(edges, edge_color)

	# Visualize MST edges
	if mst_edges_visible:
		visualize_edges(mst_edges, mst_edge_color)

	# Visualize corridors
	if corridors_visible:
		visualize_corridors()

	# Visualize rooms
	if rooms_visible:
		visualize_rooms()

	# Visualize room bounding boxes (blue wireframes)
	if blue_cubes_visible:
		visualize_cubes(room_data, blue_wire_color, blue_cube_wireframes)

	# Visualize corridor bounding boxes (red wireframes)
	if red_cubes_visible:
		visualize_cubes(corridor_data, red_wire_color, red_cube_wireframes)

func visualize_cubes(cubes, color, instances):
	for cube in cubes:
		if not cube.has("position") or not cube.has("size"):
			print("Cube data missing required fields: ", cube)
			#print("Rendering bounding box for:", cube["position"], "with size:", cube["size"])
			continue

		var position = cube["position"]
		var size = cube["size"]
		#print("Visualizing bounding box at position: ", position, ", size: ", size)

		var wire_material = StandardMaterial3D.new()
		wire_material.flags_transparent = true
		wire_material.flags_unshaded = true
		wire_material.albedo_color = color

		var array_mesh = ArrayMesh.new()
		var vertices = PackedVector3Array([
			position + Vector3(-size.x / 2, -size.y / 2, -size.z / 2),
			position + Vector3(size.x / 2, -size.y / 2, -size.z / 2),
			position + Vector3(size.x / 2, size.y / 2, -size.z / 2),
			position + Vector3(-size.x / 2, size.y / 2, -size.z / 2),
			position + Vector3(-size.x / 2, -size.y / 2, size.z / 2),
			position + Vector3(size.x / 2, -size.y / 2, size.z / 2),
			position + Vector3(size.x / 2, size.y / 2, size.z / 2),
			position + Vector3(-size.x / 2, size.y / 2, size.z / 2),
		])

		var indices = PackedInt32Array([
			0, 1, 1, 2, 2, 3, 3, 0,
			4, 5, 5, 6, 6, 7, 7, 4,
			0, 4, 1, 5, 2, 6, 3, 7
		])

		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_INDEX] = indices

		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

		var wire_instance = MeshInstance3D.new()
		wire_instance.mesh = array_mesh
		wire_instance.material_override = wire_material

		add_child(wire_instance)
		instances.append(wire_instance)

func visualize_data_points():
	for point in input_points:
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = sphere_size

		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 1, 0)  # Yellow for points

		var point_instance = MeshInstance3D.new()
		point_instance.name = "PointMesh"
		point_instance.mesh = sphere_mesh
		point_instance.transform.origin = point
		point_instance.material_override = material

		add_child(point_instance)
		point_mesh_instances.append(point_instance)

func visualize_edges(edge_list: Array, color: Color):
	for edge in edge_list:
		if edge.size() < 2:
			continue
		var start = edge[0]
		var end = edge[1]

		var array_mesh = ArrayMesh.new()
		var vertices = PackedVector3Array([start, end])
		var indices = PackedInt32Array([0, 1])

		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_INDEX] = indices

		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

		var line_instance = MeshInstance3D.new()
		line_instance.name = "EdgeMesh"
		line_instance.mesh = array_mesh

		var material = StandardMaterial3D.new()
		material.albedo_color = color
		line_instance.material_override = material

		add_child(line_instance)

		if color == mst_edge_color:
			mst_edge_mesh_instances.append(line_instance)
		else:
			edge_mesh_instances.append(line_instance)

func visualize_corridors():
	for corridor in corridor_data:
		if not corridor.has("position") or not corridor.has("size"):
			print("Corridor data missing required fields: ", corridor)
			continue

		var position = corridor["position"]
		var size = corridor["size"]
		#print("Visualizing corridor at position: ", position, ", size: ", size)

		var cube_mesh = BoxMesh.new()
		cube_mesh.size = size

		var material = StandardMaterial3D.new()
		material.albedo_color = red_cube_color

		var corridor_instance = MeshInstance3D.new()
		corridor_instance.name = "CorridorMesh"
		corridor_instance.mesh = cube_mesh
		corridor_instance.transform.origin = position
		corridor_instance.material_override = material

		add_child(corridor_instance)
		corridor_mesh_instances.append(corridor_instance)

func visualize_rooms():
	for room in room_data:
		if not room.has("position") or not room.has("size"):
			print("Room data missing required fields: ", room)
			continue

		var position = room["position"]
		var size = room["size"]
		#print("Visualizing room at position: ", position, ", size: ", size)

		var cube_mesh = BoxMesh.new()
		cube_mesh.size = size

		var material = StandardMaterial3D.new()
		material.albedo_color = blue_cube_color

		var room_instance = MeshInstance3D.new()
		room_instance.name = "RoomMesh"
		room_instance.mesh = cube_mesh
		room_instance.transform.origin = position
		room_instance.material_override = material

		add_child(room_instance)
		room_mesh_instances.append(room_instance)

func create_wire_mesh():
	if grid_width <= 0 or grid_height <= 0 or grid_depth <= 0:
		print("Invalid grid dimensions: width=", grid_width, ", height=", grid_height, ", depth=", grid_depth)
		return

	var wire_material = StandardMaterial3D.new()
	wire_material.flags_transparent = true
	wire_material.flags_unshaded = true
	wire_material.albedo_color = Color(1, 1, 1)  # White

	var array_mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var index = 0

	# Add vertical lines
	for x in range(grid_width + 1):
		for z in range(grid_depth + 1):
			vertices.append(Vector3(x, 0, z))
			vertices.append(Vector3(x, grid_height, z))
			indices.append(index)
			indices.append(index + 1)
			index += 2

	# Add horizontal lines
	for y in range(grid_height + 1):
		for z in range(grid_depth + 1):
			vertices.append(Vector3(0, y, z))
			vertices.append(Vector3(grid_width, y, z))
			indices.append(index)
			indices.append(index + 1)
			index += 2

	# Add depth lines
	for x in range(grid_width + 1):
		for y in range(grid_height + 1):
			vertices.append(Vector3(x, y, 0))
			vertices.append(Vector3(x, y, grid_depth))
			indices.append(index)
			indices.append(index + 1)
			index += 2

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	var wire_mesh_instance = MeshInstance3D.new()
	wire_mesh_instance.mesh = array_mesh
	wire_mesh_instance.material_override = wire_material
	wire_mesh_instance.name = "WireMesh"

	add_child(wire_mesh_instance)

func clear_visualizations():
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()

	point_mesh_instances.clear()
	edge_mesh_instances.clear()
	mst_edge_mesh_instances.clear()
	corridor_mesh_instances.clear()
	room_mesh_instances.clear()
	blue_cube_wireframes.clear()
	red_cube_wireframes.clear()
