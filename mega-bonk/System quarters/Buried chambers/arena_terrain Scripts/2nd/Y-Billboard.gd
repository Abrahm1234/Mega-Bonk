extends Node3D
@export var y_billboard := true

func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var pos := global_transform.origin
	var target := cam.global_transform.origin
	if y_billboard:
		target.y = pos.y
	look_at(target, Vector3.UP)
