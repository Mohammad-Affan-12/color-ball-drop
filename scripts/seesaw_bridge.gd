class_name SeesawBridge
extends StaticBody2D

signal seesaw_tipped(bridge: SeesawBridge, new_angle_deg: float)

@export var length: float = 210.0:
	set(value):
		length = maxf(value, 40.0)
		_rebuild()
		queue_redraw()

@export var thickness: float = 16.0
@export var max_tilt_deg: float = 22.0
@export var initial_tilt_deg: float = -18.0
@export var alternate_on_pass: bool = true

var _sensor_left: Area2D
var _sensor_right: Area2D
var _target_deg: float = 0.0
var _cooldown: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var mat := PhysicsMaterial.new()
	mat.friction = 0.02
	mat.bounce = 0.06
	physics_material_override = mat

	rotation_degrees = initial_tilt_deg
	_target_deg = initial_tilt_deg
	_rebuild()
	queue_redraw()

func reset_state() -> void:
	rotation_degrees = initial_tilt_deg
	_target_deg = initial_tilt_deg
	_cooldown = 0.0
	queue_redraw()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var hl := length * 0.5
	var r := thickness * 0.5

	var main_col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, thickness)
	main_col.shape = rect
	add_child(main_col)

	var left_cap := CollisionShape2D.new()
	var c1 := CircleShape2D.new()
	c1.radius = r
	left_cap.shape = c1
	left_cap.position = Vector2(-hl, 0)
	add_child(left_cap)

	var right_cap := CollisionShape2D.new()
	var c2 := CircleShape2D.new()
	c2.radius = r
	right_cap.shape = c2
	right_cap.position = Vector2(hl, 0)
	add_child(right_cap)

	_sensor_left = Area2D.new()
	_sensor_left.monitoring = true
	_sensor_left.monitorable = false
	var sl_col := CollisionShape2D.new()
	var sl_rect := RectangleShape2D.new()
	sl_rect.size = Vector2(hl - 12.0, 26.0)
	sl_col.shape = sl_rect
	sl_col.position = Vector2(-hl * 0.5, -16.0)
	_sensor_left.add_child(sl_col)
	_sensor_left.body_entered.connect(_on_left_entered)
	add_child(_sensor_left)

	_sensor_right = Area2D.new()
	_sensor_right.monitoring = true
	_sensor_right.monitorable = false
	var sr_col := CollisionShape2D.new()
	var sr_rect := RectangleShape2D.new()
	sr_rect.size = Vector2(hl - 12.0, 26.0)
	sr_col.shape = sr_rect
	sr_col.position = Vector2(hl * 0.5, -16.0)
	_sensor_right.add_child(sr_col)
	_sensor_right.body_entered.connect(_on_right_entered)
	add_child(_sensor_right)

func _on_left_entered(body: Node) -> void:
	if _cooldown > 0.0 or not (body is PuzzleBall):
		return
	var next_deg := -absf(max_tilt_deg)
	if alternate_on_pass and absf(_target_deg - next_deg) < 1.0:
		next_deg = absf(max_tilt_deg)
	_tip_to(next_deg)

func _on_right_entered(body: Node) -> void:
	if _cooldown > 0.0 or not (body is PuzzleBall):
		return
	var next_deg := absf(max_tilt_deg)
	if alternate_on_pass and absf(_target_deg - next_deg) < 1.0:
		next_deg = -absf(max_tilt_deg)
	_tip_to(next_deg)

func _tip_to(deg: float) -> void:
	if absf(_target_deg - deg) < 0.5:
		return
	_target_deg = deg
	_cooldown = 0.28
	seesaw_tipped.emit(self, _target_deg)

func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)
	if absf(rotation_degrees - _target_deg) > 0.1:
		rotation_degrees = lerpf(rotation_degrees, _target_deg, clampf(delta * 10.0, 0.0, 1.0))
		queue_redraw()

func _draw() -> void:
	var hl := length * 0.5
	var r := thickness * 0.5
	var dark := Color(0.18, 0.16, 0.28)
	var fill := Color(0.32, 0.28, 0.48)
	var accent := Color(1.0, 0.68, 0.24)

	draw_circle(Vector2(-hl, 0), r, dark)
	draw_circle(Vector2(hl, 0), r, dark)
	draw_rect(Rect2(-hl, -r, length, thickness), dark, true)

	draw_circle(Vector2(-hl, 0), r - 2.0, fill)
	draw_circle(Vector2(hl, 0), r - 2.0, fill)
	draw_rect(Rect2(-hl, -r + 2.0, length, thickness - 4.0), fill, true)
	draw_line(Vector2(-hl, -r + 2.5), Vector2(hl, -r + 2.5), accent, 3.0, true)

	# Center fulcrum triangle & axle
	draw_circle(Vector2.ZERO, 12.0, dark)
	draw_circle(Vector2.ZERO, 8.5, accent)
	draw_circle(Vector2.ZERO, 3.5, dark)
