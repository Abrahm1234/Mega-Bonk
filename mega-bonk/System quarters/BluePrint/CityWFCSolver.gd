extends RefCounted
class_name CityWFCSolver

const DIRS := {
	"N": Vector2i(0, -1),
	"E": Vector2i(1, 0),
	"S": Vector2i(0, 1),
	"W": Vector2i(-1, 0),
}

const OPP := {
	"N": "S",
	"E": "W",
	"S": "N",
	"W": "E",
}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func solve(width: int, height: int, prototypes: Array[Dictionary], fixed: Dictionary = {}, seed: int = 12345, max_restarts: int = 20) -> Dictionary:
	_rng.seed = seed
	_build_neighbor_cache(prototypes)

	for attempt in range(max_restarts):
		var wave: Array = _make_initial_wave(width, height, prototypes, fixed)
		if wave.is_empty():
			continue

		if not _propagate(width, height, wave, prototypes, _all_positions(width, height)):
			continue

		while true:
			var pos: Vector2i = _find_lowest_entropy(width, height, wave)
			if pos.x < 0:
				return _build_result(width, height, wave, prototypes, attempt)

			var idx: int = pos.y * width + pos.x
			var options: Array = wave[idx]
			var chosen: int = _pick_weighted(options, prototypes)
			wave[idx] = [chosen]

			if not _propagate(width, height, wave, prototypes, [pos]):
				break

	return {
		"success": false,
		"attempt": max_restarts,
	}

func _make_initial_wave(width: int, height: int, prototypes: Array[Dictionary], fixed: Dictionary) -> Array:
	var wave: Array = []
	wave.resize(width * height)

	for i in range(width * height):
		var all_options: Array = []
		for p in range(prototypes.size()):
			all_options.append(p)
		wave[i] = all_options

	for key in fixed.keys():
		var pos: Vector2i = key
		if pos.x < 0 or pos.y < 0 or pos.x >= width or pos.y >= height:
			continue
		var idx: int = pos.y * width + pos.x
		var allowed: Array = fixed[key]
		if allowed.is_empty():
			return []
		wave[idx] = allowed.duplicate()

	return wave

func _build_neighbor_cache(prototypes: Array[Dictionary]) -> void:
	for i in range(prototypes.size()):
		var proto: Dictionary = prototypes[i]
		var allowed: Dictionary = {
			"N": {},
			"E": {},
			"S": {},
			"W": {},
		}

		for j in range(prototypes.size()):
			var other: Dictionary = prototypes[j]
			for dir_name in DIRS.keys():
				var a_socket: String = str((proto["sockets"] as Dictionary).get(dir_name, "*"))
				var b_socket: String = str((other["sockets"] as Dictionary).get(OPP[dir_name], "*"))
				if _socket_matches(a_socket, b_socket):
					(allowed[dir_name] as Dictionary)[j] = true

		proto["allowed"] = allowed
		prototypes[i] = proto

func _socket_matches(a: String, b: String) -> bool:
	if a == "*" or b == "*":
		return true

	if a.contains("|"):
		for part in a.split("|"):
			if _socket_matches(part.strip_edges(), b):
				return true
		return false

	if b.contains("|"):
		for part in b.split("|"):
			if _socket_matches(a, part.strip_edges()):
				return true
		return false

	return a == b

func _propagate(width: int, height: int, wave: Array, prototypes: Array[Dictionary], start_positions: Array) -> bool:
	var queue: Array = start_positions.duplicate()
	var head: int = 0

	while head < queue.size():
		var pos: Vector2i = queue[head]
		head += 1

		var idx: int = pos.y * width + pos.x
		var current_options: Array = wave[idx]
		if current_options.is_empty():
			return false

		for dir_name in DIRS.keys():
			var npos: Vector2i = pos + DIRS[dir_name]
			if npos.x < 0 or npos.y < 0 or npos.x >= width or npos.y >= height:
				continue

			var nidx: int = npos.y * width + npos.x
			var neighbor_options: Array = wave[nidx]
			var filtered: Array = []

			for candidate in neighbor_options:
				if _candidate_has_support(int(candidate), current_options, dir_name, prototypes):
					filtered.append(candidate)

			if filtered.size() != neighbor_options.size():
				if filtered.is_empty():
					return false
				wave[nidx] = filtered
				queue.append(npos)

	return true

func _candidate_has_support(candidate: int, current_options: Array, dir_name: String, prototypes: Array[Dictionary]) -> bool:
	for cur in current_options:
		var allowed: Dictionary = ((prototypes[int(cur)].get("allowed", {}) as Dictionary).get(dir_name, {}) as Dictionary)
		if allowed.has(candidate):
			return true
	return false

func _find_lowest_entropy(width: int, height: int, wave: Array) -> Vector2i:
	var best: int = 999999
	var tied: Array[Vector2i] = []

	for y in range(height):
		for x in range(width):
			var count: int = (wave[y * width + x] as Array).size()
			if count <= 1:
				continue
			if count < best:
				best = count
				tied.clear()
				tied.append(Vector2i(x, y))
			elif count == best:
				tied.append(Vector2i(x, y))

	if tied.is_empty():
		return Vector2i(-1, -1)

	return tied[_rng.randi_range(0, tied.size() - 1)]

func _pick_weighted(options: Array, prototypes: Array[Dictionary]) -> int:
	var total: float = 0.0
	for idx in options:
		total += max(float(prototypes[int(idx)].get("weight", 1.0)), 0.0)

	if total <= 0.0001:
		return int(options[_rng.randi_range(0, options.size() - 1)])

	var roll: float = _rng.randf() * total
	for idx in options:
		roll -= max(float(prototypes[int(idx)].get("weight", 1.0)), 0.0)
		if roll <= 0.0:
			return int(idx)

	return int(options.back())

func _build_result(width: int, height: int, wave: Array, prototypes: Array[Dictionary], attempt: int) -> Dictionary:
	var ids: PackedStringArray = PackedStringArray()
	var base_ids: PackedStringArray = PackedStringArray()
	var rotations: PackedInt32Array = PackedInt32Array()

	ids.resize(width * height)
	base_ids.resize(width * height)
	rotations.resize(width * height)

	for i in range(wave.size()):
		var chosen: int = int((wave[i] as Array)[0])
		var proto: Dictionary = prototypes[chosen]
		ids[i] = str(proto.get("id", ""))
		base_ids[i] = str(proto.get("base_id", proto.get("id", "")))
		rotations[i] = int(proto.get("rot", 0))

	return {
		"success": true,
		"ids": ids,
		"base_ids": base_ids,
		"rotations": rotations,
		"attempt": attempt,
	}

func _all_positions(width: int, height: int) -> Array:
	var out: Array = []
	for y in range(height):
		for x in range(width):
			out.append(Vector2i(x, y))
	return out
