extends Camera3D
class_name FreeCamera

@export var move_speed: float = 20.0
@export var boost_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.002

var yaw: float = 0.0
var pitch: float = 0.0
var mouse_captured: bool = true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clampf(pitch, -1.55, 1.55)
		rotation = Vector3(pitch, yaw, 0.0)

	# ESC toggles capture without needing an InputMap action
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		mouse_captured = !mouse_captured
		Input.set_mouse_mode(
			Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE
		)

func _physics_process(delta: float) -> void:
	# Uses built-in actions:
	# ui_up/ui_down/ui_left/ui_right exist by default (arrow keys)
	# We'll also support WASD directly.
	var dir: Vector3 = Vector3.ZERO

	# Forward/back (W/S or arrows)
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		dir += transform.basis.z

	# Strafe (A/D or arrows)
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		dir += transform.basis.x

	# Vertical (Q/E)
	if Input.is_key_pressed(KEY_E):
		dir += transform.basis.y
	if Input.is_key_pressed(KEY_Q):
		dir -= transform.basis.y

	if dir != Vector3.ZERO:
		dir = dir.normalized()

	var speed: float = move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= boost_multiplier

	position += dir * speed * delta
