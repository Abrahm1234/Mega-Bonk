extends RefCounted
class_name PatternPieces

static func get_default_patterns() -> Array[Dictionary]:
	var base_patterns: Array[Dictionary] = [
		{
			"id": "piece_2x2_full",
			"size": Vector2i(2, 2),
			"required": [
				["full", "full"],
				["full", "full"],
			],
			"priority": 100,
		},
		{
			"id": "piece_3x1_edge",
			"size": Vector2i(3, 1),
			"required": [
				["edge", "edge", "edge"],
			],
			"priority": 90,
		},
		{
			"id": "piece_2x2_bay",
			"size": Vector2i(2, 2),
			"required": [
				["inverse_corner", "edge"],
				["edge", "full"],
			],
			"priority": 80,
		},
	]

	var expanded: Array[Dictionary] = []
	for pattern in base_patterns:
		var required: Array = pattern["required"]
		var size: Vector2i = pattern["size"]
		for rot_steps in range(4):
			expanded.append({
				"id": pattern["id"],
				"size": size,
				"required": required,
				"priority": pattern["priority"],
				"rot_steps": rot_steps,
			})
			required = _rotate_required_90(required)
			size = Vector2i(size.y, size.x)
	return expanded

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
