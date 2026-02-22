extends Node3D

@export var grid_size: int = 15
@export var min_cube_size: float = 0.5
@export var max_cube_size: float = 4.0
@export var cube_spacing: float = 6.0
@export var connection_probability: float = 0.5
@export var max_connections: int = 4
@export var compute_shader_path: String = "res://Orbital webwork/Scripts/Compute Shader/compute_shader.glsl"

const CHUNK_SIZE: int = 10000

const COLORS = [
	Color(1, 0, 0),
	Color(0.67, 0.326, 0.0, 1.0),
	Color(1, 1, 0),
	Color(0, 1, 0),
	Color(0, 0, 1),
	Color(0.72, 0.001, 0.813, 1.0)
]

var cubes = {}
var cube_nodes = []

func _ready():
	if FileAccess.file_exists(compute_shader_path):
		var shader_file = FileAccess.open(compute_shader_path, FileAccess.READ)
		var shader_code = shader_file.get_as_text()
		shader_file.close()

		var shader = Shader.new()
		shader.code = shader_code

		var material = ShaderMaterial.new()
		material.shader = shader

		var num_cubes = grid_size * grid_size * grid_size

		material.set("shader_param/grid_size", grid_size)
		material.set("shader_param/min_size", min_cube_size)
		material.set("shader_param/max_size", max_cube_size)
		material.set("shader_param/spacing", cube_spacing)

		for chunk_start in range(0, num_cubes, CHUNK_SIZE):
			process_chunk(chunk_start, min(CHUNK_SIZE, num_cubes - chunk_start), material)

		create_bridges()
	else:
		push_error("Shader file not found: " + compute_shader_path)
		return

func process_chunk(start_index: int, count: int, _material: ShaderMaterial):
	var buffer_data = PackedFloat32Array()
	buffer_data.resize(count * 4)

	var center = Vector3(grid_size * 0.5 * cube_spacing, grid_size * 0.5 * cube_spacing, grid_size * 0.5 * cube_spacing)

	for i in range(count):
		buffer_data[i * 4] = randf() * (max_cube_size - min_cube_size) + min_cube_size
		var x = float((start_index + i) % int(grid_size)) * cube_spacing
		var y = float((int(start_index + i) / int(grid_size)) % int(grid_size)) * cube_spacing
		var z = float(int((start_index + i) / (grid_size * grid_size))) * cube_spacing
		buffer_data[i * 4 + 1] = x
		buffer_data[i * 4 + 2] = y
		buffer_data[i * 4 + 3] = z

	for i in range(count):
		var cube = MeshInstance3D.new()
		var size = buffer_data[i * 4]
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(size, size, size)
		cube.mesh = box_mesh

		var position = Vector3(buffer_data[i * 4 + 1], buffer_data[i * 4 + 2], buffer_data[i * 4 + 3])

		var cube_material = StandardMaterial3D.new()
		cube_material.albedo_color = Color.WHITE  # Initialize all cubes as white
		cube.material_override = cube_material

		cube.transform.origin = position
		add_child(cube)

		cubes[position] = {"mesh": cube, "connected": false, "connections": 0}
		cube_nodes.append(cube)

func create_bridges():
	for pos in cubes.keys():
		var cube_data = cubes[pos]
		var neighbors = get_neighbors(pos)
		for neighbor_pos in neighbors:
			if randf() < connection_probability and cube_data["connections"] < max_connections:
				create_bridge(pos, neighbor_pos)
				cube_data["connected"] = true
				cube_data["connections"] += 1
				cubes[neighbor_pos]["connected"] = true
				cubes[neighbor_pos]["connections"] += 1

				# Change color if connected for both cubes
				update_cube_color(pos)
				update_cube_color(neighbor_pos)

func get_neighbors(position: Vector3) -> Array[Vector3]:
	var neighbors: Array[Vector3] = []
	var offsets = [
		Vector3(cube_spacing, 0, 0),
		Vector3(-cube_spacing, 0, 0),
		Vector3(0, cube_spacing, 0),
		Vector3(0, -cube_spacing, 0),
		Vector3(0, 0, cube_spacing),
		Vector3(0, 0, -cube_spacing)
	]

	for offset in offsets:
		var neighbor_pos = position + offset
		if neighbor_pos in cubes:
			neighbors.append(neighbor_pos)

	return neighbors

func update_cube_color(position: Vector3):
	var cube_data = cubes[position]
	var distance_from_center = position.distance_to(Vector3(grid_size * 0.5 * cube_spacing, grid_size * 0.5 * cube_spacing, grid_size * 0.5 * cube_spacing))
	var max_distance = Vector3(grid_size * 0.5 * cube_spacing, grid_size * 0.5 * cube_spacing, grid_size * 0.5 * cube_spacing).length()
	var layer_count = COLORS.size()
	var color_index = int((distance_from_center / max_distance) * (layer_count - 1))
	var color = COLORS[color_index]

	var cube_material = StandardMaterial3D.new()
	cube_material.albedo_color = color
	cube_data["mesh"].material_override = cube_material

func create_bridge(start: Vector3, end: Vector3):
	var distance = start.distance_to(end)
	var cylinder = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = distance
	cylinder_mesh.top_radius = 0.1
	cylinder_mesh.bottom_radius = 0.1
	cylinder.mesh = cylinder_mesh

	var midpoint = (start + end) / 2
	cylinder.transform.origin = midpoint

	var direction = (end - start).normalized()
	var up = Vector3.UP
	var axis = up.cross(direction)
	if axis.length() < 0.0001:
		axis = Vector3.RIGHT
	axis = axis.normalized()
	var angle = acos(up.dot(direction))
	var rotation = Quaternion(axis, angle)
	cylinder.transform.basis = Basis(rotation)

	add_child(cylinder)
