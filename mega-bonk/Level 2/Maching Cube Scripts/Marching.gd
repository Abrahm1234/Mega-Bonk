# res://Level 2/Maching Cube Scripts/Marching.gd
extends MeshInstance3D

const Tables = preload("res://Level 2/Maching Cube Scripts/MCTables.gd")

# ── Parameters ────────────────────────────────────────────────────────────────
@export var grid_size: Vector3i = Vector3i(48, 32, 48) : set = _set_grid_size
@export var voxel_scale: float = 1.0                   : set = _set_voxel_scale
@export var iso_level: float = 0.0                     : set = _set_iso

# renamed from `seed` → `noise_seed` to avoid shadowing the global `seed()` fn
@export var noise_seed: int = 1337                     : set = _set_noise_seed
@export var noise_freq: float = 0.04                   : set = _set_noise_freq
@export var noise_gain: float = 0.5                    : set = _set_noise_gain
@export var noise_octaves: int = 4                     : set = _set_noise_octaves

@export var do_simple_erosion: bool = false            : set = _set_do_erosion
@export var erosion_passes: int = 3                    : set = _set_erosion_passes

# One-shot button to rebuild (resets itself)
@export var Regenerate: bool = false                   : set = _set_regenerate

# If true we set per-vertex normals; if false we let SurfaceTool generate them.
@export var use_explicit_normals: bool = true

var _noise: FastNoiseLite

func _ready() -> void:
	_setup_noise()
	_generate()

# ── Property setters ─────────────────────────────────────────────────────────
func _set_grid_size(v: Vector3i) -> void:
	grid_size = Vector3i(max(1, v.x), max(1, v.y), max(1, v.z))
	_queue_regenerate()

func _set_voxel_scale(v: float) -> void:
	voxel_scale = max(0.001, v)
	_queue_regenerate()

func _set_iso(v: float) -> void:
	iso_level = v
	_queue_regenerate()

func _set_noise_seed(v: int) -> void:
	noise_seed = v
	if _noise: _noise.seed = noise_seed
	_queue_regenerate()

func _set_noise_freq(v: float) -> void:
	noise_freq = max(0.0001, v)
	if _noise: _noise.frequency = noise_freq
	_queue_regenerate()

func _set_noise_gain(v: float) -> void:
	noise_gain = v
	if _noise: _noise.fractal_gain = noise_gain
	_queue_regenerate()

func _set_noise_octaves(v: int) -> void:
	noise_octaves = clampi(v, 1, 12)
	if _noise: _noise.fractal_octaves = noise_octaves
	_queue_regenerate()

func _set_do_erosion(v: bool) -> void:
	do_simple_erosion = v
	_queue_regenerate()

func _set_erosion_passes(v: int) -> void:
	erosion_passes = maxi(0, v)
	_queue_regenerate()

func _set_regenerate(v: bool) -> void:
	if v:
		Regenerate = false
		_setup_noise()
		_generate()

func _queue_regenerate() -> void:
	if Engine.is_editor_hint():
		call_deferred("_generate")

# ── Noise ────────────────────────────────────────────────────────────────────
func _setup_noise() -> void:
	if _noise == null:
		_noise = FastNoiseLite.new()
	_noise.seed = noise_seed
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = noise_freq
	_noise.fractal_octaves = noise_octaves
	_noise.fractal_gain = noise_gain

# ── Generate mesh ────────────────────────────────────────────────────────────
func _generate() -> void:
	if Tables == null:
		push_error("MCTables.gd failed to load. Check path: res://Level 2/Maching Cube Scripts/MCTables.gd")
		return

	var nx: int = grid_size.x + 1
	var ny: int = grid_size.y + 1
	var nz: int = grid_size.z + 1
	var field: Array = _alloc_field(nx, ny, nz)

	for z in range(nz):
		for y in range(ny):
			for x in range(nx):
				var p := Vector3(x, y, z) * voxel_scale
				_field_set(field, x, y, z, _sample_density(p))

	if do_simple_erosion and erosion_passes > 0:
		_box_blur(field, erosion_passes)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var verts: Array[Vector3] = []
	var norms: Array[Vector3] = []

	for z in range(grid_size.z):
		for y in range(grid_size.y):
			for x in range(grid_size.x):
				_polygonize_cell(Vector3i(x, y, z), field, iso_level, verts, norms)

	if verts.is_empty():
		push_warning("Marching: no triangles generated (check iso_level/noise).")
		return

	if use_explicit_normals:
		for i in range(verts.size()):
			st.set_normal(norms[i])   # Godot 4.5: set_normal instead of add_normal
			st.add_vertex(verts[i])
	else:
		for v in verts:
			st.add_vertex(v)
		st.generate_normals()

	mesh = st.commit()

# ── Field helpers ────────────────────────────────────────────────────────────
func _alloc_field(nx: int, ny: int, nz: int) -> Array:
	var a: Array = []
	a.resize(nx)
	for x in range(nx):
		var b: Array = []
		b.resize(ny)
		for y in range(ny):
			var row := PackedFloat32Array()
			row.resize(nz)
			b[y] = row
		a[x] = b
	return a

func _field_set(field: Array, x: int, y: int, z: int, v: float) -> void:
	var row: PackedFloat32Array = field[x][y]
	row[z] = v
	field[x][y] = row

func _field_get(field: Array, x: int, y: int, z: int) -> float:
	return (field[x][y] as PackedFloat32Array)[z]

func _sample_density(p: Vector3) -> float:
	var d := _noise.get_noise_3d(p.x, p.y * 0.8, p.z)
	d += 0.5 * _noise.get_noise_3d(p.x * 2.1, p.y * 2.1, p.z * 2.1)
	return d - 0.1

# ── Simple smoother (placeholder) ────────────────────────────────────────────
func _box_blur(field: Array, radius: int) -> void:
	if radius <= 0: return
	var nx: int = field.size()
	var ny: int = (field[0] as Array).size()
	var nz: int = (field[0][0] as PackedFloat32Array).size()

	var tmp: Array = _alloc_field(nx, ny, nz)
	var win: int = radius * 2 + 1

	# X pass -> tmp
	for y in range(ny):
		for z in range(nz):
			var sum: float = 0.0
			for x0 in range(-radius, radius + 1):
				sum += _field_get(field, _clamp_i(x0, 0, nx - 1), y, z)
			for x in range(nx):
				_field_set(tmp, x, y, z, sum / float(win))
				var x_out: int = x - radius
				var x_in:  int = x + radius + 1
				sum -= _field_get(field, _clamp_i(x_out, 0, nx - 1), y, z)
				sum += _field_get(field, _clamp_i(x_in,  0, nx - 1), y, z)

	# Y pass -> field
	for x in range(nx):
		for z in range(nz):
			var sum: float = 0.0
			for y0 in range(-radius, radius + 1):
				sum += _field_get(tmp, x, _clamp_i(y0, 0, ny - 1), z)
			for y in range(ny):
				_field_set(field, x, y, z, sum / float(win))
				var y_out: int = y - radius
				var y_in:  int = y + radius + 1
				sum -= _field_get(tmp, x, _clamp_i(y_out, 0, ny - 1), z)
				sum += _field_get(tmp, x, _clamp_i(y_in,  0, ny - 1), z)

func _clamp_i(v: int, lo: int, hi: int) -> int:
	return min(hi, max(lo, v))

# ── Marching Cubes core ─────────────────────────────────────────────────────
const CORNERS: Array[Vector3] = [
	Vector3(0,0,0), Vector3(1,0,0), Vector3(1,1,0), Vector3(0,1,0),
	Vector3(0,0,1), Vector3(1,0,1), Vector3(1,1,1), Vector3(0,1,1),
]

const EDGE_CORNER: Array[Vector2i] = [
	Vector2i(0,1), Vector2i(1,2), Vector2i(2,3), Vector2i(3,0),
	Vector2i(4,5), Vector2i(5,6), Vector2i(6,7), Vector2i(7,4),
	Vector2i(0,4), Vector2i(1,5), Vector2i(2,6), Vector2i(3,7),
]

func _polygonize_cell(c: Vector3i, field: Array, iso: float, out_verts: Array, out_normals: Array) -> void:
	var val := PackedFloat32Array(); val.resize(8)
	var p: Array[Vector3] = []; p.resize(8)

	for i in range(8):
		var cp := c + Vector3i(CORNERS[i])
		p[i] = Vector3(cp) * voxel_scale
		val[i] = _field_get(field, cp.x, cp.y, cp.z)

	var cube_index: int = 0
	if val[0] < iso: cube_index |= 1
	if val[1] < iso: cube_index |= 2
	if val[2] < iso: cube_index |= 4
	if val[3] < iso: cube_index |= 8
	if val[4] < iso: cube_index |= 16
	if val[5] < iso: cube_index |= 32
	if val[6] < iso: cube_index |= 64
	if val[7] < iso: cube_index |= 128

	var edges: int = int(Tables.EDGE_TABLE[cube_index])
	if edges == 0: return

	var vert_list: Array[Vector3] = []; vert_list.resize(12)
	for e in range(12):
		if (edges & (1 << e)) != 0:
			var a: int = EDGE_CORNER[e].x
			var b: int = EDGE_CORNER[e].y
			vert_list[e] = _vertex_interp(iso, p[a], p[b], val[a], val[b])

	var row: Array = Tables.TRI_TABLE[cube_index]
	for t in range(0, 16, 3):
		var a_i: int = row[t]
		if a_i == -1: break
		var b_i: int = row[t + 1]
		var c_i: int = row[t + 2]

		var a_v: Vector3 = vert_list[a_i]
		var b_v: Vector3 = vert_list[b_i]
		var c_v: Vector3 = vert_list[c_i]
		var n: Vector3 = (b_v - a_v).cross(c_v - a_v).normalized()

		out_verts.append(a_v); out_normals.append(n)
		out_verts.append(b_v); out_normals.append(n)
		out_verts.append(c_v); out_normals.append(n)

func _vertex_interp(iso: float, p1: Vector3, p2: Vector3, v1: float, v2: float) -> Vector3:
	var diff: float = v2 - v1
	if absf(diff) < 0.00001: return p1
	var t: float = (iso - v1) / diff
	return p1.lerp(p2, clampf(t, 0.0, 1.0))
