extends Node3D
class_name BlockyTerrain

@export var size_x: int = 256
@export var size_z: int = 256
@export var cell_size: float = 2.0

# Height controls
@export var height_scale: float = 80.0          # overall mountain height
@export var height_step: float = 2.0            # TERRACE size (blockiness)
@export var min_height: float = -10.0           # optional bowl / valleys

# Noise controls
@export var noise_seed: int = 1234
@export var noise_frequency: float = 0.005
@export var noise_octaves: int = 5
@export var noise_lacunarity: float = 2.0
@export var noise_gain: float = 0.5

# Arena shaping (optional)
@export var center_flat_radius: float = 60.0    # flat-ish play area in center (meters)
@export var center_flat_strength: float = 0.75  # 0..1
@export var bowl_strength: float = 1.0          # pushes edges down

@onready var mesh_instance: MeshInstance3D = $TerrainBody/TerrainMesh
@onready var collision_shape: CollisionShape3D = $TerrainBody/TerrainCollision

var heights: PackedFloat32Array

func _ready() -> void:
	generate()

func generate() -> void:
	_generate_heights_blocky()
	_build_blocky_mesh_and_collision()

func _generate_heights_blocky() -> void:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = noise_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = noise_octaves
	noise.fractal_lacunarity = noise_lacunarity
	noise.fractal_gain = noise_gain

	heights = PackedFloat32Array()
	heights.resize(size_x * size_z)

	var cx: float = (float(size_x) - 1.0) * 0.5
	var cz: float = (float(size_z) - 1.0) * 0.5
	var flat_r_cells: float = maxf(0.0, center_flat_radius / cell_size)

	for z in range(size_z):
		for x in range(size_x):
			var nx: float = float(x)
			var nz: float = float(z)

			# Base height from noise
			var h: float = noise.get_noise_2d(nx, nz) # ~[-1..1]
			h = _shape_height(h) * height_scale

			# Optional: flatten center a bit (combat readability)
			if flat_r_cells > 0.0:
				var dx: float = nx - cx
				var dz: float = nz - cz
				var d: float = sqrt(dx * dx + dz * dz)
				var t: float = clampf(d / flat_r_cells, 0.0, 1.0)
				var blend: float = 1.0 - (1.0 - t) * center_flat_strength
				h *= blend

				# Optional bowl: push edges down so you stay “in the world”
				if bowl_strength > 0.0 and d > flat_r_cells:
					var out: float = (d - flat_r_cells) / maxf(1.0, flat_r_cells)
					h -= (out * out) * height_scale * 0.6 * bowl_strength

			# Clamp and TERRACE (blocky)
			h = maxf(h, min_height)
			h = _quantize(h, height_step)

			heights[z * size_x + x] = h

func _shape_height(v: float) -> float:
	# makes more “mountainy” distribution than raw noise
	var s: float = clampf(v, -1.0, 1.0)
	return signf(s) * pow(absf(s), 1.25)

func _quantize(h: float, step: float) -> float:
	if step <= 0.0:
		return h
	return roundf(h / step) * step

func _h(x: int, z: int) -> float:
	return heights[z * size_x + x]

func _pos(x: int, z: int, y: float) -> Vector3:
	# Center terrain around (0,0,0) like an “open world chunk”
	var ox: float = -float(size_x) * cell_size * 0.5
	var oz: float = -float(size_z) * cell_size * 0.5
	return Vector3(ox + float(x) * cell_size, y, oz + float(z) * cell_size)

func _build_blocky_mesh_and_collision() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# UV tiling (optional)
	var uv_scale: float = 0.08

	for z in range(size_z - 1):
		for x in range(size_x - 1):
			var h0: float = _h(x, z)

			# --- Top face (always) ---
			_add_quad(
				st,
				_pos(x,     z,     h0),
				_pos(x + 1, z,     h0),
				_pos(x + 1, z + 1, h0),
				_pos(x,     z + 1, h0),
				Vector2(float(x), float(z)) * uv_scale,
				Vector2(float(x + 1), float(z)) * uv_scale,
				Vector2(float(x + 1), float(z + 1)) * uv_scale,
				Vector2(float(x), float(z + 1)) * uv_scale
			)

			# --- Side faces where neighbor is lower (vertical walls) ---
			var hn: float = _h(x, z - 1) if z > 0 else h0
			var hs: float = _h(x, z + 1)
			var hw: float = _h(x - 1, z) if x > 0 else h0
			var he: float = _h(x + 1, z)

			# North (toward -Z)
			if z > 0 and hn < h0:
				_add_wall_z(st, x, z, hn, h0, true, uv_scale)
			# West (toward -X)
			if x > 0 and hw < h0:
				_add_wall_x(st, x, z, hw, h0, true, uv_scale)
			# South (toward +Z) uses neighbor of the cell below, so check current cell vs next row
			if hs < h0:
				_add_wall_z(st, x, z + 1, hs, h0, false, uv_scale)
			# East (toward +X)
			if he < h0:
				_add_wall_x(st, x + 1, z, he, h0, false, uv_scale)

	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	mesh_instance.mesh = mesh

	# Collision: matches the blocky mesh
	collision_shape.shape = mesh.create_trimesh_shape()

func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	# triangle 1: a b c
	st.set_uv(ua); st.add_vertex(a)
	st.set_uv(ub); st.add_vertex(b)
	st.set_uv(uc); st.add_vertex(c)
	# triangle 2: a c d
	st.set_uv(ua); st.add_vertex(a)
	st.set_uv(uc); st.add_vertex(c)
	st.set_uv(ud); st.add_vertex(d)

func _add_wall_z(st: SurfaceTool, x: int, z_edge: int, h_low: float, h_high: float, north: bool, uv_scale: float) -> void:
	# wall along a Z edge at z_edge, spanning one cell in X
	var x0 := x
	var x1 := x + 1
	var z := z_edge

	var a := _pos(x0, z, h_low)
	var b := _pos(x1, z, h_low)
	var c := _pos(x1, z, h_high)
	var d := _pos(x0, z, h_high)

	# Flip winding depending on which side we want outward normals
	if north:
		_add_quad(st, a, b, c, d,
			Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale)
	else:
		_add_quad(st, b, a, d, c,
			Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale)

func _add_wall_x(st: SurfaceTool, x_edge: int, z: int, h_low: float, h_high: float, west: bool, uv_scale: float) -> void:
	# wall along an X edge at x_edge, spanning one cell in Z
	var x := x_edge
	var z0 := z
	var z1 := z + 1

	var a := _pos(x, z0, h_low)
	var b := _pos(x, z1, h_low)
	var c := _pos(x, z1, h_high)
	var d := _pos(x, z0, h_high)

	if west:
		_add_quad(st, b, a, d, c,
			Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale)
	else:
		_add_quad(st, a, b, c, d,
			Vector2(0, 0) * uv_scale, Vector2(1, 0) * uv_scale, Vector2(1, 1) * uv_scale, Vector2(0, 1) * uv_scale)
