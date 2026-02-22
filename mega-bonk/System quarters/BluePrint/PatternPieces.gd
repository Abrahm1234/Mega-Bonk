extends RefCounted
class_name PatternPieces

static func get_default_patterns() -> Array[Dictionary]:
	return [
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
