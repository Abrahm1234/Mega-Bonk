extends RefCounted
class_name PatternPieces

static func get_default_patterns() -> Array[Dictionary]:
	var base_patterns: Array[Dictionary] = [
		{
			"id": "piece_3x3_full",
			"size": Vector2i(3, 3),
			"required": [
				["full", "full", "full"],
				["full", "full", "full"],
				["full", "full", "full"],
			],
			"priority": 140,
			"weight": 0.35,
			"cooldown_radius": 6.0,
			"cooldown_family": "full_large",
			"occupy": [["1","1","1"],["1","1","1"],["1","1","1"]],
		},
		{
			"id": "piece_2x3_full",
			"size": Vector2i(2, 3),
			"required": [
				["full", "full"],
				["full", "full"],
				["full", "full"],
			],
			"priority": 130,
			"weight": 0.45,
			"cooldown_radius": 5.0,
			"cooldown_family": "full_large",
			"occupy": [["1","1"],["1","1"],["1","1"]],
		},
		{
			"id": "piece_2x2_full",
			"size": Vector2i(2, 2),
			"required": [
				["full", "full"],
				["full", "full"],
			],
			"priority": 120,
			"weight": 0.9,
			"cooldown_radius": 2.5,
			"cooldown_family": "full_large",
			"occupy": [["1","1"],["1","1"]],
		},
		{
			"id": "piece_5x1_edge",
			"size": Vector2i(5, 1),
			"required": [
				["edge", "edge", "edge", "edge", "edge"],
			],
			"priority": 110,
			"weight": 0.7,
			"cooldown_radius": 4.0,
			"cooldown_family": "edge_strips",
			"occupy": [["1","1","1","1","1"]],
		},
		{
			"id": "piece_4x1_edge",
			"size": Vector2i(4, 1),
			"required": [
				["edge", "edge", "edge", "edge"],
			],
			"priority": 105,
			"weight": 0.85,
			"cooldown_radius": 3.0,
			"cooldown_family": "edge_strips",
			"occupy": [["1","1","1","1"]],
		},
		{
			"id": "piece_3x1_edge",
			"size": Vector2i(3, 1),
			"required": [
				["edge", "edge", "edge"],
			],
			"priority": 100,
			"weight": 1.0,
			"cooldown_radius": 0.0,
			"cooldown_family": "edge_strips",
			"occupy": [["1","1","1"]],
		},
		{
			"id": "piece_3x2_bay",
			"size": Vector2i(3, 2),
			"required": [
				["inverse_corner", "edge", "full"],
				["edge", "full", "full"],
			],
			"priority": 95,
			"weight": 0.6,
			"cooldown_radius": 3.5,
			"cooldown_family": "bay",
			"occupy": [["1","1","0"],["1","1","1"]],
		},
		{
			"id": "piece_2x2_bay",
			"size": Vector2i(2, 2),
			"required": [
				["inverse_corner", "edge"],
				["edge", "full"],
			],
			"priority": 90,
			"weight": 0.85,
			"cooldown_radius": 2.0,
			"cooldown_family": "bay",
			"occupy": [["1","1"],["1","0"]],
		},
		{
			"id": "piece_corner_cluster",
			"size": Vector2i(2, 2),
			"required": [
				["corner", "edge"],
				["edge", "full"],
			],
			"priority": 85,
			"weight": 1.0,
			"cooldown_radius": 0.0,
			"cooldown_family": "corner_cluster",
			"occupy": [["1","1"],["1","1"]],
		},
	]

	var expanded: Array[Dictionary] = []
	for pattern in base_patterns:
		var required: Array = pattern["required"]
		var occupy: Array = pattern.get("occupy", required)
		var size: Vector2i = pattern["size"]
		for mirrored in [false, true]:
			var work_required: Array = _deep_copy_required(required)
			var work_occupy: Array = _deep_copy_required(occupy)
			if mirrored:
				work_required = _mirror_required_x(work_required)
				work_occupy = _mirror_required_x(work_occupy)
			for rot_steps in range(4):
				expanded.append({
					"id": pattern["id"],
					"size": size,
					"required": work_required,
					"occupy": work_occupy,
					"priority": pattern["priority"],
					"weight": pattern.get("weight", 1.0),
					"cooldown_radius": pattern.get("cooldown_radius", 0.0),
					"cooldown_family": pattern.get("cooldown_family", pattern["id"]),
					"rot_steps": rot_steps,
					"mirrored": mirrored,
				})
				work_required = _rotate_required_90(work_required)
				work_occupy = _rotate_required_90(work_occupy)
				size = Vector2i(size.y, size.x)
	return expanded

static func _deep_copy_required(required: Array) -> Array:
	var out: Array = []
	for row_raw in required:
		var row: Array = row_raw as Array
		var new_row: Array = []
		for item in row:
			new_row.append(item)
		out.append(new_row)
	return out

static func _rotate_required_90(required: Array) -> Array:
	if required.is_empty():
		return []

	var h: int = required.size()
	var w: int = (required[0] as Array).size()
	var out: Array = []
	for x in range(w):
		var row: Array = []
		for y in range(h - 1, -1, -1):
			var source_row: Array = required[y] as Array
			row.append(source_row[x])
		out.append(row)
	return out

static func _mirror_required_x(required: Array) -> Array:
	var out: Array = []
	for row_raw in required:
		var row: Array = row_raw as Array
		var mirrored_row: Array = []
		for i in range(row.size() - 1, -1, -1):
			mirrored_row.append(row[i])
		out.append(mirrored_row)
	return out
