extends RefCounted
class_name CityPrototypeLibrary

static func make_ground_prototypes() -> Array[Dictionary]:
	var base: Array[Dictionary] = [
		{
			"id": "road_straight",
			"base_id": "road_straight",
			"weight": 4.0,
			"rotations": 2,
			"tags": ["road"],
			"sockets": {"N": "road", "E": "curb", "S": "road", "W": "curb"},
		},
		{
			"id": "road_corner",
			"base_id": "road_corner",
			"weight": 2.4,
			"rotations": 4,
			"tags": ["road"],
			"sockets": {"N": "road", "E": "road", "S": "curb", "W": "curb"},
		},
		{
			"id": "road_t",
			"base_id": "road_t",
			"weight": 1.2,
			"rotations": 4,
			"tags": ["road"],
			"sockets": {"N": "road", "E": "road", "S": "road", "W": "curb"},
		},
		{
			"id": "crossroad",
			"base_id": "crossroad",
			"weight": 0.5,
			"rotations": 1,
			"tags": ["road"],
			"sockets": {"N": "road", "E": "road", "S": "road", "W": "road"},
		},
		{
			"id": "sidewalk",
			"base_id": "sidewalk",
			"weight": 3.0,
			"rotations": 1,
			"tags": ["edge"],
			"sockets": {"N": "lot|curb", "E": "lot|curb", "S": "lot|curb", "W": "lot|curb"},
		},
		{
			"id": "lot_fill",
			"base_id": "lot_fill",
			"weight": 6.0,
			"rotations": 1,
			"tags": ["buildable"],
			"sockets": {"N": "lot", "E": "lot", "S": "lot", "W": "lot"},
		},
		{
			"id": "park",
			"base_id": "park",
			"weight": 0.8,
			"rotations": 1,
			"tags": ["open"],
			"sockets": {"N": "green", "E": "green", "S": "green", "W": "green"},
		},
	]

	return _expand_rotations(base)

static func _expand_rotations(base: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for proto in base:
		var rot_count: int = int(proto.get("rotations", 1))
		for rot in range(rot_count):
			var p: Dictionary = proto.duplicate(true)
			p["rot"] = rot
			p["id"] = "%s_r%d" % [str(proto["base_id"]), rot]
			p["sockets"] = _rotate_sockets(proto["sockets"] as Dictionary, rot)
			out.append(p)
	return out

static func _rotate_sockets(sockets: Dictionary, steps: int) -> Dictionary:
	var out: Dictionary = sockets.duplicate(true)
	for _i in range(steps & 3):
		out = {
			"N": out["W"],
			"E": out["N"],
			"S": out["E"],
			"W": out["S"],
		}
	return out

static func find_indices_with_tag(prototypes: Array[Dictionary], tag: String) -> Array:
	var out: Array = []
	for i in range(prototypes.size()):
		var tags: Array = prototypes[i].get("tags", [])
		if tag in tags:
			out.append(i)
	return out

static func find_indices_by_base_ids(prototypes: Array[Dictionary], ids: Array[String]) -> Array:
	var out: Array = []
	for i in range(prototypes.size()):
		var base_id: String = str(prototypes[i].get("base_id", ""))
		if base_id in ids:
			out.append(i)
	return out
