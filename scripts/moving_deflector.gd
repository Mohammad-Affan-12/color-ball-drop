class_name MovingDeflector
extends StaticBody2D

@export var length: float = 130.0:
	set(value):
		length = maxf(value, 24.0)
		_rebuild()
		queue_redraw()

@export var thickness: float = 16.0
@export var move_delta: Vector2 = Vector2(90.0, 0.0)
@export var cycle_speed: float = 1.6
@export var angular_speed_deg: float = 0.0
@export var accent_color: Color = Color(1.0, 0.55, 0.22)

var _start_pos: Vector2 = Vector2.ZERO
var _start_rot_deg: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var mat := PhysicsMaterial.new()
	mat.friction = 0.02
	mat.bounce = 0.18
	physics_material_override = mat

	_start_pos = position
	_start_rot_deg = rotation_degrees
	_rebuild()
	queue_redraw()

func reset_state() -> void:
	_time = 0.0
	position = _start_pos
	rotation_degrees = _start_rot_deg
	queue_redraw()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, thickness)
	col.shape = rect
	add_child(col)

func _physics_process(delta: float) -> void:
	_time += delta
	if move_delta.length_squared() > 0.5:
		position = _start_pos + move_delta * sin(_time * cycle_speed)
	if absf(angular_speed_deg) > 0.1:
		rotation_degrees = _start_rot_deg + _time * angular_speed_deg
	queue_redraw()

func _draw() -> void:
	var hl := length * 0.5
	var r := thickness * 0.5
	var dark := Color(0.18, 0.14, 0.24)
	var fill := Color(0.32, 0.24, 0.38)

	draw_rect(Rect2(-hl, -r, length, thickness), dark, true)
	draw_rect(Rect2(-hl + 2.0, -r + 2.0, length - 4.0, thickness - 4.0), fill, true)
	draw_line(Vector2(-hl, -r + 2.5), Vector2(hl, -r + 2.5), accent_color, 3.0, true)
	draw_circle(Vector2.ZERO, 4.5, accent_color)
