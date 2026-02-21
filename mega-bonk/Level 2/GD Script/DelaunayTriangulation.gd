extends Node

func delaunay_triangulation(input_points: Array) -> Array:
	print("Starting Delaunay triangulation with " + str(input_points.size()) + " points.")

	if input_points.size() < 4:
		push_error("Error: At least 4 points are required for Delaunay triangulation. Received " + str(input_points.size()))
		return []

	# Ensure input points are snapped to the grid
	for i in range(input_points.size()):
		input_points[i] = input_points[i].snapped(Vector3(1, 1, 1))

	print("Normalized and snapped points: " + str(input_points))

	var bounding_box_min = Vector3(1e8, 1e8, 1e8)
	var bounding_box_max = Vector3(-1e8, -1e8, -1e8)

	for point in input_points:
		bounding_box_min.x = min(bounding_box_min.x, point.x)
		bounding_box_min.y = min(bounding_box_min.y, point.y)
		bounding_box_min.z = min(bounding_box_min.z, point.z)
		bounding_box_max.x = max(bounding_box_max.x, point.x)
		bounding_box_max.y = max(bounding_box_max.y, point.y)
		bounding_box_max.z = max(bounding_box_max.z, point.z)

	var super_tetrahedron_offset = Vector3(10.0, 10.0, 10.0)
	var super_tetrahedron = [
		bounding_box_min - super_tetrahedron_offset,
		Vector3(bounding_box_max.x + super_tetrahedron_offset.x, bounding_box_min.y, bounding_box_min.z),
		Vector3(bounding_box_min.x, bounding_box_max.y + super_tetrahedron_offset.y, bounding_box_min.z),
		bounding_box_min + Vector3(0.0, 0.0, super_tetrahedron_offset.z)
	]

	var triangulation = [super_tetrahedron]

	for point in input_points:
		var bad_tetrahedrons = []
		for tetrahedron in triangulation:
			if point_inside_circumsphere(point, tetrahedron):
				bad_tetrahedrons.append(tetrahedron)

		if bad_tetrahedrons.size() == 0:
			continue

		var polygon = []
		for tetrahedron in bad_tetrahedrons:
			for face in get_faces(tetrahedron):
				if not is_shared_face(face, bad_tetrahedrons):
					polygon.append(face)

		for tetrahedron in bad_tetrahedrons:
			triangulation.erase(tetrahedron)

		for face in polygon:
			var new_tetrahedron = [face[0], face[1], face[2], point]
			if is_degenerate(new_tetrahedron):
				continue
			triangulation.append(new_tetrahedron)

	triangulation = filter_super_tetrahedron(triangulation, super_tetrahedron)

	var unique_edges = {}
	for tetrahedron in triangulation:
		for edge in get_edges_from_tetrahedron(tetrahedron):
			edge.sort()
			var edge_key = str(edge[0]) + "|" + str(edge[1])
			unique_edges[edge_key] = edge

	var edges = unique_edges.values()
	print("Triangulation complete. Generated " + str(edges.size()) + " edges.")
	return edges

func point_inside_circumsphere(point: Vector3, tetrahedron: Array) -> bool:
	var matrix = []
	for vertex in tetrahedron:
		matrix.append([
			vertex.x - point.x,
			vertex.y - point.y,
			vertex.z - point.z,
			(vertex - point).length_squared()
		])
	return determinant(matrix) > 0

func get_faces(tetrahedron: Array) -> Array:
	return [
		[tetrahedron[0], tetrahedron[1], tetrahedron[2]],
		[tetrahedron[0], tetrahedron[1], tetrahedron[3]],
		[tetrahedron[0], tetrahedron[2], tetrahedron[3]],
		[tetrahedron[1], tetrahedron[2], tetrahedron[3]]
	]

func is_shared_face(face: Array, tetrahedrons: Array) -> bool:
	var count = 0
	for tetrahedron in tetrahedrons:
		if face in get_faces(tetrahedron):
			count += 1
			if count > 1:
				return true
	return false

func is_degenerate(tetrahedron: Array) -> bool:
	var matrix = []
	for vertex in tetrahedron:
		matrix.append([vertex.x, vertex.y, vertex.z, 1.0])
	return abs(determinant(matrix)) < 1e-10

func filter_super_tetrahedron(triangulation: Array, super_tetrahedron: Array) -> Array:
	var filtered = []
	for tetrahedron in triangulation:
		var has_super_vertex = false
		for vertex in tetrahedron:
			if vertex in super_tetrahedron:
				has_super_vertex = true
				break
		if not has_super_vertex:
			filtered.append(tetrahedron)
	return filtered

func get_edges_from_tetrahedron(tetrahedron: Array) -> Array:
	return [
		[tetrahedron[0], tetrahedron[1]],
		[tetrahedron[0], tetrahedron[2]],
		[tetrahedron[0], tetrahedron[3]],
		[tetrahedron[1], tetrahedron[2]],
		[tetrahedron[1], tetrahedron[3]],
		[tetrahedron[2], tetrahedron[3]]
	]

func determinant(matrix: Array) -> float:
	return (
		matrix[0][0] * matrix[1][1] * matrix[2][2] * matrix[3][3] +
		matrix[0][0] * matrix[1][2] * matrix[2][3] * matrix[3][1] +
		matrix[0][0] * matrix[1][3] * matrix[2][1] * matrix[3][2] -
		matrix[0][0] * matrix[1][3] * matrix[2][2] * matrix[3][1] -
		matrix[0][0] * matrix[1][2] * matrix[2][1] * matrix[3][3] -
		matrix[0][0] * matrix[1][1] * matrix[2][3] * matrix[3][2] +
		matrix[0][1] * matrix[1][0] * matrix[2][3] * matrix[3][2] +
		matrix[0][1] * matrix[1][2] * matrix[2][0] * matrix[3][3] +
		matrix[0][1] * matrix[1][3] * matrix[2][2] * matrix[3][0] -
		matrix[0][1] * matrix[1][3] * matrix[2][0] * matrix[3][2] -
		matrix[0][1] * matrix[1][2] * matrix[2][3] * matrix[3][0] -
		matrix[0][1] * matrix[1][0] * matrix[2][2] * matrix[3][3] +
		matrix[0][2] * matrix[1][0] * matrix[2][1] * matrix[3][3] +
		matrix[0][2] * matrix[1][1] * matrix[2][3] * matrix[3][0] +
		matrix[0][2] * matrix[1][3] * matrix[2][0] * matrix[3][1] -
		matrix[0][2] * matrix[1][3] * matrix[2][1] * matrix[3][0] -
		matrix[0][2] * matrix[1][1] * matrix[2][0] * matrix[3][3] -
		matrix[0][2] * matrix[1][0] * matrix[2][3] * matrix[3][1] +
		matrix[0][3] * matrix[1][0] * matrix[2][2] * matrix[3][1] +
		matrix[0][3] * matrix[1][1] * matrix[2][0] * matrix[3][2] +
		matrix[0][3] * matrix[1][2] * matrix[2][1] * matrix[3][0] -
		matrix[0][3] * matrix[1][1] * matrix[2][2] * matrix[3][0] -
		matrix[0][3] * matrix[1][0] * matrix[2][1] * matrix[3][2]
	)
