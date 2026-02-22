# res://VFX/muzzle_flash.gd
extends Node3D

@export var life := 0.08
var _particles: Array[GPUParticles3D] = []

func _ready() -> void:
	_particles = _find_particles(self)
	visible = false

func play() -> void:
	visible = true
	for p in _particles:
		p.emitting = false
		p.restart()
		p.emitting = true
	await get_tree().create_timer(life).timeout
	visible = false

func _find_particles(n: Node) -> Array[GPUParticles3D]:
	var out: Array[GPUParticles3D] = []
	if n is GPUParticles3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_particles(c))
	return out
