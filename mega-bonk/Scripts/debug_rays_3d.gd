extends Node3D

# Drop-in debug ray visualizer (Godot 4.x)
# - Draws ray segments as line primitives (ImmediateMesh)
# - Optionally draws hit markers via MultiMesh (requires TRANSFORM_3D + use_colors)

@export var enabled: bool = true
@export_range(1, 20000, 1) var max_rays: int = 5000
@export var rebuild_on_add: bool = true

@export var show_hit_markers: bool = true
@export_range(0.005, 0.25, 0.005) var hit_radius: float = 0.04
@export var no_depth_test: bool = false

var _segments: Array[Dictionary] = []

var _line_mi: MeshInstance3D
var _line_mesh: ImmediateMesh
var _line_mat: StandardMaterial3D

var _hit_mmi: MultiMeshInstance3D
var _hit_mm: MultiMesh
var _hit_mat: StandardMaterial3D

func _ready() -> void:
	_setup()
	_rebuild()

func set_enabled(v: bool) -> void:
	enabled = v
	visible = v

func clear() -> void:
	_segments.clear()
	_rebuild()

func rebuild() -> void:
	_rebuild()

func add_ray(from: Vector3, to: Vector3, color: Color = Color(0, 1, 0, 0.85), hit_pos: Variant = null) -> void:
	if not enabled:
		return

	var draw_to: Vector3 = to
	if hit_pos is Vector3:
		draw_to = hit_pos

	_segments.append({
		"a": from,
		"b": draw_to,
		"c": color,
		"hit": hit_pos,
	})

	if _segments.size() > max_rays:
		_segments.pop_front()

	if rebuild_on_add:
		_rebuild()

func _setup() -> void:
	# Lines
	_line_mi = get_node_or_null(^"Lines") as MeshInstance3D
	if _line_mi == null:
		_line_mi = MeshInstance3D.new()
		_line_mi.name = "Lines"
		add_child(_line_mi)

	_line_mesh = ImmediateMesh.new()
	_line_mi.mesh = _line_mesh

	_line_mat = StandardMaterial3D.new()
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_mat.vertex_color_use_as_albedo = true
	_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_line_mat.no_depth_test = no_depth_test
	_line_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	_line_mi.material_override = _line_mat
	_line_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_line_mat.render_priority = 0

	# Hit markers
	if show_hit_markers:
		_hit_mmi = get_node_or_null(^"Hits") as MultiMeshInstance3D
		if _hit_mmi == null:
			_hit_mmi = MultiMeshInstance3D.new()
			_hit_mmi.name = "Hits"
			add_child(_hit_mmi)

		_hit_mm = MultiMesh.new()
		_hit_mm.transform_format = MultiMesh.TRANSFORM_3D
		_hit_mm.use_colors = true

		var sm := SphereMesh.new()
		sm.radius = hit_radius
		sm.height = hit_radius * 2.0
		_hit_mm.mesh = sm
		_hit_mmi.multimesh = _hit_mm

		_hit_mat = StandardMaterial3D.new()
		_hit_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_hit_mat.vertex_color_use_as_albedo = true
		_hit_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		_hit_mat.no_depth_test = no_depth_test
		_hit_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
		_hit_mmi.material_override = _hit_mat
		_hit_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_hit_mat.render_priority = 0
	else:
		_hit_mmi = get_node_or_null(^"Hits") as MultiMeshInstance3D
		if _hit_mmi != null:
			_hit_mmi.queue_free()
		_hit_mmi = null
		_hit_mm = null
		_hit_mat = null

func _rebuild() -> void:
	if _line_mesh == null:
		_setup()

	# Rebuild line mesh
	_line_mesh.clear_surfaces()
	if _segments.is_empty():
		# Avoid ImmediateMesh.surface_end() error when there are no vertices.
		if _hit_mm != null:
			_hit_mm.instance_count = 0
		return

	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _line_mat)
	for s in _segments:
		var col: Color = s.get("c", Color(0, 1, 0, 0.85))
		_line_mesh.surface_set_color(col)
		_line_mesh.surface_add_vertex(to_local(s.get("a", Vector3.ZERO)))
		_line_mesh.surface_add_vertex(to_local(s.get("b", Vector3.ZERO)))
	_line_mesh.surface_end()

	# Rebuild hit markers
	if _hit_mm == null:
		return

	var hits: Array[Dictionary] = []
	for s2 in _segments:
		var hp: Variant = s2.get("hit", null)
		if hp is Vector3:
			hits.append(s2)

	_hit_mm.instance_count = hits.size()
	for i in range(hits.size()):
		var h: Dictionary = hits[i]
		var hp3: Vector3 = h["hit"]
		_hit_mm.set_instance_transform(i, Transform3D(Basis(), to_local(hp3)))
		_hit_mm.set_instance_color(i, h.get("c", Color(1, 0, 0, 0.85)))
