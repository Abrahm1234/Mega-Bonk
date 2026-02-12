extends MeshInstance3D
class_name DebugRays3D

@export var enabled: bool = false : set = set_enabled
@export var max_rays: int = 3000
@export var show_hit_markers: bool = true
@export var depth_test: bool = true

var _im: ImmediateMesh = ImmediateMesh.new()
var _mat: StandardMaterial3D = StandardMaterial3D.new()
var _rays: Array[Dictionary] = []

func _ready() -> void:
	mesh = _im
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.no_depth_test = not depth_test
	_rebuild()

func set_enabled(v: bool) -> void:
	enabled = v
	visible = v
	if not v:
		clear()
	else:
		_rebuild()

func clear() -> void:
	_rays.clear()
	_rebuild()

func add_ray(a: Vector3, b: Vector3, color: Color, hit_pos: Variant = null) -> void:
	if not enabled:
		return

	var has_hit: bool = hit_pos != null
	_rays.append({
		"a": a,
		"b": b,
		"c": color,
		"has_hit": has_hit,
		"hit": hit_pos if has_hit else Vector3.ZERO
	})

	if _rays.size() > max_rays:
		_rays.pop_front()

	_rebuild()

func _rebuild() -> void:
	_mat.no_depth_test = not depth_test
	if not enabled:
		_im.clear_surfaces()
		return

	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_LINES, _mat)

	for r in _rays:
		_im.surface_set_color(r["c"])
		_im.surface_add_vertex(r["a"])
		_im.surface_add_vertex(r["b"])

		if show_hit_markers and bool(r["has_hit"]):
			var p: Vector3 = r["hit"]
			var s: float = 0.15
			_im.surface_add_vertex(p + Vector3(s, 0, 0))
			_im.surface_add_vertex(p - Vector3(s, 0, 0))
			_im.surface_add_vertex(p + Vector3(0, s, 0))
			_im.surface_add_vertex(p - Vector3(0, s, 0))
			_im.surface_add_vertex(p + Vector3(0, 0, s))
			_im.surface_add_vertex(p - Vector3(0, 0, s))

	_im.surface_end()
