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

@onready var mesh_instance: MeshInstance3D = $TerrainBody/TerrainMesh
@onready var collision_shape: CollisionShape3D = $TerrainBody/TerrainCollision

var heights: PackedFloat32Array
var _ox: float
var _oz: float

enum ArenaType { PLAIN, RAMP_X, RAMP_Z, PYRAMID, BOWL }

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

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = arena_seed

	var stamps: Array[ArenaStamp] = _create_arena_stamps(rng)

	# For each cell: combine stamps with soft edge blending.
	for z in range(size_z):
		for x in range(size_x):
			var h: float = floor_y
			var wsum: float = 0.0

			for s: ArenaStamp in stamps:
				var w: float = _stamp_weight(s, x, z)
				if w <= 0.0:
					continue

				var sh: float = _stamp_height(s, x, z)
				h += sh * w
				wsum += w

			if wsum > 0.0:
				h /= wsum

			h = maxf(h, min_height)
			h = _quantize(h, height_step)
			heights[z * size_x + x] = h

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
			var h0: float = _h(x, z)

			_add_quad(
				st,
				_pos(x,     z,     h0),
				_pos(x + 1, z,     h0),
				_pos(x + 1, z + 1, h0),
				_pos(x,     z + 1, h0),
				Vector2(float(x), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z)) * uv_scale_top,
				Vector2(float(x + 1), float(z + 1)) * uv_scale_top,
				Vector2(float(x), float(z + 1)) * uv_scale_top
			)

			var hn: float = _h(x, z - 1) if z > 0 else h0
			var hs: float = _h(x, z + 1)
			var hw: float = _h(x - 1, z) if x > 0 else h0
			var he: float = _h(x + 1, z)

			if z > 0 and hn < h0:
				_add_wall_z(st, x, z, hn, h0, true, uv_scale_wall)
			if x > 0 and hw < h0:
				_add_wall_x(st, x, z, hw, h0, true, uv_scale_wall)
			if hs < h0:
				_add_wall_z(st, x, z + 1, hs, h0, false, uv_scale_wall)
			if he < h0:
				_add_wall_x(st, x + 1, z, he, h0, false, uv_scale_wall)

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
		_add_wall_z_one_sided(st, x, 0, floor_y, top_y, false, uv_scale_wall)

	# South wall: z = size_z-1, inward faces -Z
	for x in range(size_x - 1):
		_add_wall_z_one_sided(st, x, size_z - 1, floor_y, top_y, true, uv_scale_wall)

	# West wall: x = 0, inward faces +X
	for z in range(size_z - 1):
		_add_wall_x_one_sided(st, 0, z, floor_y, top_y, false, uv_scale_wall)

	# East wall: x = size_x-1, inward faces -X
	for z in range(size_z - 1):
		_add_wall_x_one_sided(st, size_x - 1, z, floor_y, top_y, true, uv_scale_wall)

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

func _add_wall_x_one_sided(st: SurfaceTool, x_edge: int, z: int, h_low: float, h_high: float, west: bool, uv_scale: float) -> void:
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
			_add_quad(st, p1, p0, p3, p2, uv0, uv1, uv2, uv3)
		else:
			_add_quad(st, p0, p1, p2, p3, uv0, uv1, uv2, uv3)

		y0 = y1
