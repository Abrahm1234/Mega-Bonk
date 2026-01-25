extends Node3D
class_name BlockyTerrain

@export var size_x: int = 256
@export var size_z: int = 256
@export var cell_size: float = 2.0

# Voxel look
@export var height_step: float = 2.0
@export var min_height: float = -10.0

# Box / world bounds
@export var outer_floor_height: float = -40.0   # bottom of the world
@export var box_height: float = 80.0            # top of the box walls (world ceiling height)
@export var build_ceiling: bool = false

# Arena generation
@export var arena_seed: int = 1234
@export var arena_count: int = 12               # number of stamped arenas
@export var arena_min_size_m: float = 30.0
@export var arena_max_size_m: float = 90.0
@export var arena_margin_m: float = 8.0         # keep away from walls
@export var arena_height_range: float = 30.0    # +/- around 0, quantized
@export var ramp_height_m: float = 18.0         # typical ramp rise
@export var ramp_run_m: float = 40.0            # typical ramp run (controls steepness)
@export var blend_edge_m: float = 10.0          # soft blend between arenas

# Low-res arena noise (macro shapes)
@export var arena_lr_cells: int = 32            # low-res grid size (e.g. 16, 24, 32, 48)
@export var arena_noise_seed: int = 1234
@export var arena_noise_frequency: float = 0.08 # frequency in LOW-RES space (0.03..0.15)
@export var arena_noise_octaves: int = 3
@export var arena_noise_lacunarity: float = 2.0
@export var arena_noise_gain: float = 0.5
@export var arena_height_scale: float = 26.0    # meters of vertical variation (macro)

# Arena shaping / readability
@export var center_flat_radius_m: float = 55.0  # central flat-ish area
@export var center_flat_strength: float = 0.75  # 0..1, stronger = flatter center
@export var outer_ramp_strength: float = 0.35   # 0..1, pushes height up toward walls (creates run-up ramps)
@export var max_step_per_cell: float = 4.0      # clamp adjacent height deltas (voxel slope control)
@export var step_clamp_passes: int = 2

# Make hills chunkier (horizontal block size)
@export var macro_block_size_m: float = 8.0   # bigger = larger blocks/plateaus (try 8, 12, 16)
@export var use_nearest_upsample: bool = true # true = chunky, false = smoother bilinear

# Walkability + auto-ramps
@export var walk_max_step: float = 2.0              # max vertical delta per move (meters)
@export var auto_ramp_count: int = 6                # how many ramps to stamp
@export var auto_ramp_width_cells: int = 4          # ramp half-width in cells (4 => ~8m with cell_size=2)
@export var auto_ramp_grade_per_cell: float = 1.0   # rise per grid cell along ramp (meters)
@export var auto_ramp_min_peak_height: float = 12.0 # only build ramps for hills above this
@export var auto_ramp_debug: bool = false           # optional: prints some info

@onready var mesh_instance: MeshInstance3D = $TerrainBody/TerrainMesh
@onready var collision_shape: CollisionShape3D = $TerrainBody/TerrainCollision

var heights: PackedFloat32Array
var ramp_dir: PackedInt32Array
var _ox: float
var _oz: float

enum ArenaType { PLAIN, RAMP_X, RAMP_Z, PYRAMID, BOWL }

const RAMP_NONE := 0
const RAMP_PX := 1
const RAMP_NX := 2
const RAMP_PZ := 3
const RAMP_NZ := 4

class ArenaStamp:
	var x0: int
	var z0: int
	var x1: int
	var z1: int
	var base_h: float
	var type: int
	var ramp_dir: int # +1 or -1 for ramps

func _ready() -> void:
	generate()

func generate() -> void:
	_ox = -float(size_x) * cell_size * 0.5
	_oz = -float(size_z) * cell_size * 0.5
	_generate_heights_arenas()
	_build_blocky_mesh_and_collision()

# -----------------------------
# HEIGHTS: arena stamping
# -----------------------------
func _generate_heights_arenas() -> void:
	heights = PackedFloat32Array()
	heights.resize(size_x * size_z)
	var floor_y: float = minf(outer_floor_height, min_height)
	for i in range(size_x * size_z):
		heights[i] = floor_y
	ramp_dir = PackedInt32Array()
	ramp_dir.resize(size_x * size_z)
	for i in range(size_x * size_z):
		ramp_dir[i] = RAMP_NONE
	var lr: int = max(2, arena_lr_cells)
	var lr_grid: PackedFloat32Array = PackedFloat32Array()
	lr_grid.resize(lr * lr)

	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = arena_noise_seed
	noise.frequency = arena_noise_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = arena_noise_octaves
	noise.fractal_lacunarity = arena_noise_lacunarity
	noise.fractal_gain = arena_noise_gain

	for gz in range(lr):
		for gx in range(lr):
			var n: float = noise.get_noise_2d(float(gx), float(gz))
			n = signf(n) * pow(absf(n), 1.35)
			lr_grid[gz * lr + gx] = n

	var cx_cells: float = (float(size_x) - 1.0) * 0.5
	var cz_cells: float = (float(size_z) - 1.0) * 0.5
	var flat_r_cells: float = maxf(0.0, center_flat_radius_m / cell_size)
	var block_cells: int = max(1, int(round(macro_block_size_m / cell_size)))

	for z in range(size_z):
		for x in range(size_x):
			var sx: int = int(floor(float(x) / float(block_cells))) * block_cells
			var sz: int = int(floor(float(z) / float(block_cells))) * block_cells

			var u: float = float(sx) / maxf(1.0, float(size_x - 1)) * float(lr - 1)
			var v: float = float(sz) / maxf(1.0, float(size_z - 1)) * float(lr - 1)

			var nxy: float
			if use_nearest_upsample:
				var gx: int = clampi(int(round(u)), 0, lr - 1)
				var gz: int = clampi(int(round(v)), 0, lr - 1)
				nxy = lr_grid[gz * lr + gx]
			else:
				var x0: int = int(floor(u))
				var z0: int = int(floor(v))
				var x1: int = min(x0 + 1, lr - 1)
				var z1: int = min(z0 + 1, lr - 1)

				var fu: float = u - float(x0)
				var fv: float = v - float(z0)

				var n00: float = lr_grid[z0 * lr + x0]
				var n10: float = lr_grid[z0 * lr + x1]
				var n01: float = lr_grid[z1 * lr + x0]
				var n11: float = lr_grid[z1 * lr + x1]

				var nx0: float = lerpf(n00, n10, fu)
				var nx1: float = lerpf(n01, n11, fu)
				nxy = lerpf(nx0, nx1, fv)

			var h: float = floor_y + (nxy * arena_height_scale)

			var dx: float = float(x) - cx_cells
			var dz: float = float(z) - cz_cells
			var d: float = sqrt(dx * dx + dz * dz)

			if flat_r_cells > 0.0:
				var t: float = clampf(d / flat_r_cells, 0.0, 1.0)
				var flatten: float = lerpf(center_flat_strength, 0.0, t)
				h = lerpf(h, 0.0, flatten)

			var nxw: float = absf(dx) / maxf(1.0, cx_cells)
			var nzw: float = absf(dz) / maxf(1.0, cz_cells)
			var edge_t: float = clampf(maxf(nxw, nzw), 0.0, 1.0)
			h += edge_t * edge_t * arena_height_scale * outer_ramp_strength

			h = maxf(h, min_height)
			h = _quantize(h, height_step)
			heights[z * size_x + x] = h

	for _p in range(step_clamp_passes):
		_apply_step_limit(max_step_per_cell)

	_stamp_auto_ramps()

func _apply_step_limit(max_step: float) -> void:
	if max_step <= 0.0:
		return

	for z in range(size_z):
		for x in range(size_x):
			var idx: int = z * size_x + x
			var h0: float = heights[idx]

			if x + 1 < size_x:
				var j: int = z * size_x + (x + 1)
				var h1: float = heights[j]
				var d: float = h0 - h1
				if d > max_step:
					h0 = h1 + max_step
				elif d < -max_step:
					h0 = h1 - max_step

			if z + 1 < size_z:
				var j2: int = (z + 1) * size_x + x
				var h2: float = heights[j2]
				var d2: float = h0 - h2
				if d2 > max_step:
					h0 = h2 + max_step
				elif d2 < -max_step:
					h0 = h2 - max_step

			heights[idx] = _quantize(h0, height_step)

func _stamp_auto_ramps() -> void:
	if auto_ramp_count <= 0:
		return

	var peaks: Array[Vector2i] = _find_peak_candidates(auto_ramp_count * 6)
	if peaks.is_empty():
		return

	var starts: Array[Vector2i] = _collect_border_starts()
	if starts.is_empty():
		return

	var built: int = 0
	for p: Vector2i in peaks:
		if built >= auto_ramp_count:
			break

		var peak_h: float = _h(p.x, p.y)
		if peak_h < auto_ramp_min_peak_height:
			continue

		var start: Vector2i = _best_start_for_peak(starts, p)
		var path: Array[Vector2i] = _astar_walkable_path(start, p, walk_max_step)

		if path.size() < 2:
			continue

		_stamp_ramp_along_path(path)
		built += 1

		if auto_ramp_debug:
			print("Ramp ", built, " path len=", path.size(), " peak_h=", peak_h)

func _find_peak_candidates(max_count: int) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var stride: int = max(2, int(round(6.0 / cell_size)))
	for z in range(stride, size_z - stride, stride):
		for x in range(stride, size_x - stride, stride):
			var h0: float = _h(x, z)
			if h0 < auto_ramp_min_peak_height:
				continue

			var higher: bool = true
			for dz in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if dx == 0 and dz == 0:
						continue
					var hx: float = _h(x + dx * stride, z + dz * stride)
					if hx > h0:
						higher = false
						break
				if not higher:
					break
			if higher:
				candidates.append(Vector2i(x, z))

	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _h(a.x, a.y) > _h(b.x, b.y)
	)

	var picked: Array[Vector2i] = []
	var min_sep_cells: int = max(6, int(round(30.0 / cell_size)))
	for c: Vector2i in candidates:
		var ok: bool = true
		for p: Vector2i in picked:
			if abs(c.x - p.x) + abs(c.y - p.y) < min_sep_cells:
				ok = false
				break
		if ok:
			picked.append(c)
			if picked.size() >= max_count:
				break

	return picked

func _collect_border_starts() -> Array[Vector2i]:
	var starts: Array[Vector2i] = []
	var ring: int = max(2, int(round(10.0 / cell_size)))
	for x in range(ring, size_x - ring):
		starts.append(Vector2i(x, ring))
		starts.append(Vector2i(x, size_z - 1 - ring))
	for z in range(ring, size_z - ring):
		starts.append(Vector2i(ring, z))
		starts.append(Vector2i(size_x - 1 - ring, z))

	starts.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _h(a.x, a.y) < _h(b.x, b.y)
	)
	var keep: int = max(16, starts.size() / 2)
	starts.resize(keep)
	return starts

func _best_start_for_peak(starts: Array[Vector2i], peak: Vector2i) -> Vector2i:
	var best: Vector2i = starts[0]
	var best_d: int = 1 << 30
	for s: Vector2i in starts:
		var d: int = abs(s.x - peak.x) + abs(s.y - peak.y)
		if d < best_d:
			best_d = d
			best = s
	return best

func _astar_walkable_path(start: Vector2i, goal: Vector2i, max_step: float) -> Array[Vector2i]:
	var open: Array[Vector2i] = []
	open.append(start)

	var came_from: Dictionary = {}
	var g: Dictionary = {}
	var f: Dictionary = {}

	var start_key: int = start.y * size_x + start.x
	g[start_key] = 0.0
	f[start_key] = float(_manhattan(start, goal))

	var in_open: Dictionary = {}
	in_open[start_key] = true

	while not open.is_empty():
		var best_i: int = 0
		var best_f: float = 1e30
		for i in range(open.size()):
			var v: Vector2i = open[i]
			var k: int = v.y * size_x + v.x
			var fv: float = f.get(k, 1e30)
			if fv < best_f:
				best_f = fv
				best_i = i

		var current: Vector2i = open[best_i]
		open.remove_at(best_i)
		var ck: int = current.y * size_x + current.x
		in_open.erase(ck)

		if current == goal:
			return _reconstruct_path(came_from, current)

		var ch: float = _h(current.x, current.y)

		for n in _neighbors4(current):
			if n.x < 0 or n.x >= size_x or n.y < 0 or n.y >= size_z:
				continue

			var nh: float = _h(n.x, n.y)
			if absf(nh - ch) > max_step:
				continue

			var nk: int = n.y * size_x + n.x

			var slope_pen: float = absf(nh - ch) * 2.0
			var tentative: float = float(g.get(ck, 1e30)) + 1.0 + slope_pen

			if tentative < float(g.get(nk, 1e30)):
				came_from[nk] = current
				g[nk] = tentative
				f[nk] = tentative + float(_manhattan(n, goal))

				if not in_open.has(nk):
					open.append(n)
					in_open[nk] = true

	return []

func _neighbors4(p: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(p.x + 1, p.y),
		Vector2i(p.x - 1, p.y),
		Vector2i(p.x, p.y + 1),
		Vector2i(p.x, p.y - 1),
	]

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	path.append(current)
	var ck: int = current.y * size_x + current.x
	while came_from.has(ck):
		current = came_from[ck]
		path.append(current)
		ck = current.y * size_x + current.x
	path.reverse()
	return path

func _stamp_ramp_along_path(path: Array[Vector2i]) -> void:
	var width: int = max(1, auto_ramp_width_cells)
	var grade: float = maxf(0.1, auto_ramp_grade_per_cell)

	var start: Vector2i = path[0]
	var target_h: float = _h(start.x, start.y)

	for i in range(1, path.size()):
		var a: Vector2i = path[i - 1]
		var b: Vector2i = path[i]

		target_h += grade

		var dx: int = b.x - a.x
		var dz: int = b.y - a.y

		var dir_a: int = RAMP_NONE
		var dir_b: int = RAMP_NONE
		if dx == 1 and dz == 0:
			dir_a = RAMP_PX; dir_b = RAMP_NX
		elif dx == -1 and dz == 0:
			dir_a = RAMP_NX; dir_b = RAMP_PX
		elif dz == 1 and dx == 0:
			dir_a = RAMP_PZ; dir_b = RAMP_NZ
		elif dz == -1 and dx == 0:
			dir_a = RAMP_NZ; dir_b = RAMP_PZ
		else:
			continue

		var ha: float = _h(a.x, a.y)
		var hb: float = _h(b.x, b.y)

		var desired_b: float = minf(hb, target_h)
		desired_b = _quantize(desired_b, height_step)

		if desired_b < ha:
			ha = desired_b
			heights[a.y * size_x + a.x] = ha

		heights[b.y * size_x + b.x] = desired_b

		_set_rd(a.x, a.y, dir_a)
		_set_rd(b.x, b.y, dir_b)

		for oz in range(-width, width + 1):
			for ox in range(-width, width + 1):
				var ax: int = a.x + ox
				var az: int = a.y + oz
				var bx: int = b.x + ox
				var bz: int = b.y + oz
				if ax < 0 or ax >= size_x or az < 0 or az >= size_z:
					continue
				if bx < 0 or bx >= size_x or bz < 0 or bz >= size_z:
					continue

				_set_rd(ax, az, dir_a)
				_set_rd(bx, bz, dir_b)

				var wgt: float = clampf(1.0 - (float(abs(ox) + abs(oz)) / float(width + 1)), 0.0, 1.0)
				if wgt <= 0.0:
					continue

				var ia: int = az * size_x + ax
				var ib: int = bz * size_x + bx
				heights[ia] = _quantize(lerpf(heights[ia], ha, wgt), height_step)
				heights[ib] = _quantize(lerpf(heights[ib], desired_b, wgt), height_step)

func _create_arena_stamps(rng: RandomNumberGenerator) -> Array[ArenaStamp]:
	var stamps: Array[ArenaStamp] = []

	var margin_cells: int = int(ceil(arena_margin_m / cell_size))
	var min_cells: int = int(ceil(arena_min_size_m / cell_size))
	var max_cells: int = int(ceil(arena_max_size_m / cell_size))
	var pad: int = int(ceil(blend_edge_m / cell_size))

	# Place up to arena_count non-overlapping rectangles (simple rejection sampling)
	var tries: int = arena_count * 40
	while stamps.size() < arena_count and tries > 0:
		tries -= 1

		var w: int = rng.randi_range(min_cells, max_cells)
		var h: int = rng.randi_range(min_cells, max_cells)

		var max_x0: int = max(margin_cells, size_x - margin_cells - w - 1)
		var max_z0: int = max(margin_cells, size_z - margin_cells - h - 1)

		var x0: int = rng.randi_range(margin_cells, max_x0)
		var z0: int = rng.randi_range(margin_cells, max_z0)
		var x1: int = x0 + w
		var z1: int = z0 + h

		# Overlap test with a small buffer
		var ok: bool = true
		for s: ArenaStamp in stamps:
			if _rects_overlap(x0, z0, x1, z1, s.x0, s.z0, s.x1, s.z1, pad):
				ok = false
				break
		if not ok:
			continue

		var stamp: ArenaStamp = ArenaStamp.new()
		stamp.x0 = x0
		stamp.z0 = z0
		stamp.x1 = x1
		stamp.z1 = z1

		var raw_base: float = rng.randf_range(-arena_height_range, arena_height_range)
		stamp.base_h = _quantize(raw_base, height_step)

		stamp.type = rng.randi_range(0, 4)
		stamp.ramp_dir = rng.randi_range(0, 1) * 2 - 1 # -1 or +1

		stamps.append(stamp)

	return stamps

func _rects_overlap(ax0:int, az0:int, ax1:int, az1:int, bx0:int, bz0:int, bx1:int, bz1:int, pad:int) -> bool:
	return not (ax1 + pad < bx0 or bx1 + pad < ax0 or az1 + pad < bz0 or bz1 + pad < az0)

func _stamp_weight(s: ArenaStamp, x: int, z: int) -> float:
	if x < s.x0 or x > s.x1 or z < s.z0 or z > s.z1:
		return 0.0

	var edge_cells: float = maxf(1.0, blend_edge_m / cell_size)
	var dx: float = minf(float(x - s.x0), float(s.x1 - x))
	var dz: float = minf(float(z - s.z0), float(s.z1 - z))
	var d: float = minf(dx, dz)

	var t: float = clampf(d / edge_cells, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _stamp_height(s: ArenaStamp, x: int, z: int) -> float:
	var floor_y: float = minf(outer_floor_height, min_height)

	var local_x: float = float(x - s.x0)
	var local_z: float = float(z - s.z0)
	var w: float = float(max(1, s.x1 - s.x0))
	var h: float = float(max(1, s.z1 - s.z0))

	var base: float = s.base_h

	match s.type:
		ArenaType.PLAIN:
			return base

		ArenaType.RAMP_X:
			var run_cells: float = maxf(1.0, ramp_run_m / cell_size)
			var rise: float = ramp_height_m
			var t: float = clampf(local_x / run_cells, 0.0, 1.0)
			if s.ramp_dir < 0:
				t = 1.0 - t
			return base + rise * t

		ArenaType.RAMP_Z:
			var run_cells: float = maxf(1.0, ramp_run_m / cell_size)
			var rise: float = ramp_height_m
			var t: float = clampf(local_z / run_cells, 0.0, 1.0)
			if s.ramp_dir < 0:
				t = 1.0 - t
			return base + rise * t

		ArenaType.PYRAMID:
			var cx: float = w * 0.5
			var cz: float = h * 0.5
			var dx: float = absf(local_x - cx) / maxf(1.0, cx)
			var dz: float = absf(local_z - cz) / maxf(1.0, cz)
			var d: float = maxf(dx, dz)
			var rise: float = ramp_height_m
			var tt: float = 1.0 - clampf(d, 0.0, 1.0)
			tt = clampf((tt - 0.25) / 0.75, 0.0, 1.0)
			return base + rise * tt

		ArenaType.BOWL:
			var cx: float = w * 0.5
			var cz: float = h * 0.5
			var dx: float = (local_x - cx) / maxf(1.0, cx)
			var dz: float = (local_z - cz) / maxf(1.0, cz)
			var r: float = clampf(sqrt(dx*dx + dz*dz), 0.0, 1.0)
			var depth: float = ramp_height_m * 0.75
			return base - depth * (1.0 - r)

	return floor_y

func _quantize(h: float, step: float) -> float:
	if step <= 0.0:
		return h
	return roundf(h / step) * step

func _h(x: int, z: int) -> float:
	return heights[z * size_x + x]

func _rd(x: int, z: int) -> int:
	return ramp_dir[z * size_x + x]

func _set_rd(x: int, z: int, d: int) -> void:
	ramp_dir[z * size_x + x] = d

func _edge_is_ramp_x(x: int, z: int, east: bool) -> bool:
	if east:
		if x + 1 >= size_x:
			return false
		return _rd(x, z) == RAMP_PX or _rd(x + 1, z) == RAMP_NX
	if x - 1 < 0:
		return false
	return _rd(x, z) == RAMP_NX or _rd(x - 1, z) == RAMP_PX

func _edge_is_ramp_z(x: int, z: int, south: bool) -> bool:
	if south:
		if z + 1 >= size_z:
			return false
		return _rd(x, z) == RAMP_PZ or _rd(x, z + 1) == RAMP_NZ
	if z - 1 < 0:
		return false
	return _rd(x, z) == RAMP_NZ or _rd(x, z - 1) == RAMP_PZ

func _pos(x: int, z: int, y: float) -> Vector3:
	return Vector3(_ox + float(x) * cell_size, y, _oz + float(z) * cell_size)

# -----------------------------
# MESH: top + interior walls + box walls
# -----------------------------
func _build_blocky_mesh_and_collision() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var uv_scale_top: float = 0.08
	var uv_scale_wall: float = 0.08

	# Terrain top + voxel cliffs between cells
	for z in range(size_z - 1):
		for x in range(size_x - 1):
			var rd: int = _rd(x, z)

			var h00: float = _h(x, z)
			var h10: float = _h(x + 1, z)
			var h01: float = _h(x, z + 1)

			var a_y: float = h00
			var b_y: float = h00
			var c_y: float = h00
			var d_y: float = h00

			if rd == RAMP_PX:
				a_y = h00; d_y = h00
				b_y = h10; c_y = h10
			elif rd == RAMP_NX:
				var hw0: float = _h(x - 1, z) if x > 0 else h00
				a_y = hw0; d_y = hw0
				b_y = h00; c_y = h00
			elif rd == RAMP_PZ:
				a_y = h00; b_y = h00
				c_y = h01; d_y = h01
			elif rd == RAMP_NZ:
				var hn0: float = _h(x, z - 1) if z > 0 else h00
				a_y = hn0; b_y = hn0
				c_y = h00; d_y = h00

			_add_quad(
				st,
				_pos(x,     z,     a_y),
				_pos(x + 1, z,     b_y),
				_pos(x + 1, z + 1, c_y),
				_pos(x,     z + 1, d_y),
				Vector2(float(x), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z + 1)) * uv_scale_top,
				Vector2(float(x), float(z + 1)) * uv_scale_top
			)

			var hn: float = _h(x, z - 1) if z > 0 else h00
			var hs: float = _h(x, z + 1)
			var hw: float = _h(x - 1, z) if x > 0 else h00
			var he: float = _h(x + 1, z)

			if z > 0 and hn < h00 and not _edge_is_ramp_z(x, z, false):
				_add_wall_z(st, x, z, hn, h00, true, uv_scale_wall)
			if x > 0 and hw < h00 and not _edge_is_ramp_x(x, z, false):
				_add_wall_x(st, x, z, hw, h00, true, uv_scale_wall)
			if hs < h00 and not _edge_is_ramp_z(x, z, true):
				_add_wall_z(st, x, z + 1, hs, h00, false, uv_scale_wall)
			if he < h00 and not _edge_is_ramp_x(x, z, true):
				_add_wall_x(st, x + 1, z, he, h00, false, uv_scale_wall)

	# Box walls (inward-facing)
	_add_box_walls(st, uv_scale_wall)

	# Optional ceiling
	if build_ceiling:
		_add_ceiling(st)

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	mesh_instance.mesh = mesh
	collision_shape.shape = mesh.create_trimesh_shape()

func _add_box_walls(st: SurfaceTool, uv_scale_wall: float) -> void:
	var floor_y: float = minf(outer_floor_height, min_height)
	var top_y: float = box_height

	# North wall: z = 0, inward faces +Z
	for x in range(size_x - 1):
		_add_wall_z_one_sided(st, x, 0, floor_y, top_y, true, uv_scale_wall)

	# South wall: z = size_z-1, inward faces -Z
	for x in range(size_x - 1):
		_add_wall_z_one_sided(st, x, size_z - 1, floor_y, top_y, false, uv_scale_wall)

	# West wall: x = 0, inward faces +X
	for z in range(size_z - 1):
		_add_wall_x_one_sided(st, 0, z, floor_y, top_y, true, uv_scale_wall)

	# East wall: x = size_x-1, inward faces -X
	for z in range(size_z - 1):
		_add_wall_x_one_sided(st, size_x - 1, z, floor_y, top_y, false, uv_scale_wall)

func _add_ceiling(st: SurfaceTool) -> void:
	var y: float = box_height
	var a: Vector3 = _pos(0, 0, y)
	var b: Vector3 = _pos(size_x - 1, 0, y)
	var c: Vector3 = _pos(size_x - 1, size_z - 1, y)
	var d: Vector3 = _pos(0, size_z - 1, y)
	# inward ceiling normals face down
	_add_quad(st, a, d, c, b, Vector2(0,0), Vector2(0,1), Vector2(1,1), Vector2(1,0))

# -----------------------------
# Helpers: quads + walls
# -----------------------------
func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	st.set_uv(ua); st.add_vertex(a)
	st.set_uv(ub); st.add_vertex(b)
	st.set_uv(uc); st.add_vertex(c)
	st.set_uv(ua); st.add_vertex(a)
	st.set_uv(uc); st.add_vertex(c)
	st.set_uv(ud); st.add_vertex(d)

func _add_wall_z(st: SurfaceTool, x: int, z_edge: int, h_low: float, h_high: float, north: bool, uv_scale: float) -> void:
	_add_wall_z_one_sided(st, x, z_edge, h_low, h_high, north, uv_scale)
	_add_wall_z_one_sided(st, x, z_edge, h_low, h_high, not north, uv_scale)

func _add_wall_x(st: SurfaceTool, x_edge: int, z: int, h_low: float, h_high: float, west: bool, uv_scale: float) -> void:
	_add_wall_x_one_sided(st, x_edge, z, h_low, h_high, west, uv_scale)
	_add_wall_x_one_sided(st, x_edge, z, h_low, h_high, not west, uv_scale)

func _add_wall_z_one_sided(st: SurfaceTool, x: int, z_edge: int, h_low: float, h_high: float, north: bool, uv_scale: float) -> void:
	var step: float = maxf(0.001, height_step)
	var y0: float = h_low

	while y0 < h_high - 0.0001:
		var y1: float = minf(y0 + step, h_high)

		var x0: int = x
		var x1: int = x + 1
		var z: int = z_edge

		var p0: Vector3 = _pos(x0, z, y0)
		var p1: Vector3 = _pos(x1, z, y0)
		var p2: Vector3 = _pos(x1, z, y1)
		var p3: Vector3 = _pos(x0, z, y1)

		var u0: float = 0.0
		var u1: float = cell_size * uv_scale
		var v0: float = y0 * uv_scale
		var v1: float = y1 * uv_scale

		var uv0: Vector2 = Vector2(u0, v0)
		var uv1: Vector2 = Vector2(u1, v0)
		var uv2: Vector2 = Vector2(u1, v1)
		var uv3: Vector2 = Vector2(u0, v1)

		if north:
			_add_quad(st, p1, p0, p3, p2, uv0, uv1, uv2, uv3)
		else:
			_add_quad(st, p0, p1, p2, p3, uv0, uv1, uv2, uv3)

		y0 = y1

func _add_wall_x_one_sided(
	st: SurfaceTool,
	x_edge: int,
	z: int,
	h_low: float,
	h_high: float,
	west: bool,
	uv_scale: float
) -> void:
	var step: float = maxf(0.001, height_step)
	var y0: float = h_low

	while y0 < h_high - 0.0001:
		var y1: float = minf(y0 + step, h_high)

		var x: int = x_edge
		var z0: int = z
		var z1: int = z + 1

		var p0: Vector3 = _pos(x, z0, y0)
		var p1: Vector3 = _pos(x, z1, y0)
		var p2: Vector3 = _pos(x, z1, y1)
		var p3: Vector3 = _pos(x, z0, y1)

		var u0: float = 0.0
		var u1: float = cell_size * uv_scale
		var v0: float = y0 * uv_scale
		var v1: float = y1 * uv_scale

		var uv0: Vector2 = Vector2(u0, v0)
		var uv1: Vector2 = Vector2(u1, v0)
		var uv2: Vector2 = Vector2(u1, v1)
		var uv3: Vector2 = Vector2(u0, v1)

		if west:
			_add_quad(st, p0, p1, p2, p3, uv0, uv1, uv2, uv3)
		else:
			_add_quad(st, p1, p0, p3, p2, uv0, uv1, uv2, uv3)

		y0 = y1
