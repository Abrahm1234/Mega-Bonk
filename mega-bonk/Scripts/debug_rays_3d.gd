extends Node3D
class_name DebugRays3D

@export var enabled: bool = false
@export var max_rays: int = 5000
@export var depth_test: bool = false
@export var show_hit_markers: bool = true
@export var hit_size: float = 0.05

var _rays: Array = [] # each: [from:Vector3, to:Vector3, color:Color, hit_pos:Variant]

var _mesh := ImmediateMesh.new()
var _mi := MeshInstance3D.new()
var _mat := StandardMaterial3D.new()

var _hit_mmi := MultiMeshInstance3D.new()
var _hit_mm := MultiMesh.new()
var _hit_mesh := SphereMesh.new()
var _hit_mat := StandardMaterial3D.new()

func _ready() -> void:
	top_level = true

	_mi.mesh = _mesh
	add_child(_mi)

	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mi.material_override = _mat

	_hit_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_hit_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	_hit_mm.mesh = _hit_mesh
	_hit_mmi.multimesh = _hit_mm
	_hit_mmi.material_override = _hit_mat
	add_child(_hit_mmi)

	_apply_material_settings()
	_apply_visibility()

func set_enabled(v: bool) -> void:
	enabled = v
	_apply_visibility()
	if not enabled:
		clear()

func clear() -> void:
	_rays.clear()
	_mesh.clear_surfaces()
	_hit_mm.instance_count = 0

func add_ray(a: Vector3, b: Vector3, c: Color, hit_pos: Variant) -> void:
	if not enabled:
		return

	if _rays.size() >= max_rays:
		_rays.pop_front()

	_rays.append([a, b, c, hit_pos])
	_rebuild()

func _rebuild() -> void:
	_apply_material_settings()
	_apply_visibility()

	_mesh.clear_surfaces()

	if _rays.is_empty():
		_hit_mm.instance_count = 0
		return

	_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _mat)
	for r in _rays:
		var a: Vector3 = r[0]
		var b: Vector3 = r[1]
		var col: Color = r[2]

		var la := to_local(a)
		var lb := to_local(b)

		_mesh.surface_set_color(col)
		_mesh.surface_add_vertex(la)
		_mesh.surface_add_vertex(lb)
	_mesh.surface_end()

	if show_hit_markers:
		_build_hits()
	else:
		_hit_mm.instance_count = 0

func _build_hits() -> void:
	var hits: Array[Vector3] = []
	for r in _rays:
		var hp: Variant = r[3]
		if hp != null:
			hits.append(hp as Vector3)

	_hit_mm.instance_count = hits.size()
	for i in hits.size():
		var p := hits[i]
		var t := Transform3D(Basis(), to_local(p))
		_hit_mm.set_instance_transform(i, t)
		_hit_mm.set_instance_color(i, Color(1, 0.2, 0.2, 1))

func _apply_material_settings() -> void:
	_mat.no_depth_test = not depth_test
	_hit_mat.no_depth_test = not depth_test
	_hit_mesh.radius = hit_size
	_hit_mesh.height = hit_size * 2.0

func _apply_visibility() -> void:
	visible = enabled
	_mi.visible = enabled
	_hit_mmi.visible = enabled and show_hit_markers

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if enabled:
			_rebuild()
