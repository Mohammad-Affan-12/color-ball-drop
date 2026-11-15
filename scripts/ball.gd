class_name PuzzleBall
extends RigidBody2D

@export var color_type: GameColors.ColorType = GameColors.ColorType.RED:
	set(value):
		color_type = value
		queue_redraw()

@export var radius: float = 18.0:
	set(value):
		radius = value
		_update_collision_shape()
		queue_redraw()

var is_collected: bool = false
var is_heavy_striker: bool = false
var _trail_points: Array[Vector2] = []
const MAX_TRAIL_POINTS := 9

var _collision_shape: CollisionShape2D

func _ready() -> void:
	continuous_cd = RigidBody2D.CCD_MODE_DISABLED
	contact_monitor = true
	max_contacts_reported = 4
	can_sleep = false

	var phys := PhysicsMaterial.new()
	phys.friction = 0.04
	phys.bounce = 0.22
	physics_material_override = phys

	if is_heavy_striker or color_type == GameColors.ColorType.STEEL:
		mass = 4.5
		gravity_scale = 1.15
	else:
		mass = 1.0
		gravity_scale = 1.0

	_ensure_collision_node()
	_update_collision_shape()

func _ensure_collision_node() -> void:
	_collision_shape = get_node_or_null("CollisionShape2D")
	if _collision_shape == null:
		_collision_shape = CollisionShape2D.new()
		_collision_shape.name = "CollisionShape2D"
		add_child(_collision_shape)

func _update_collision_shape() -> void:
	if _collision_shape == null:
		_collision_shape = get_node_or_null("CollisionShape2D")
	if _collision_shape != null:
		var circle := CircleShape2D.new()
		circle.radius = radius
		_collision_shape.shape = circle

func _physics_process(_delta: float) -> void:
	if is_collected:
		return
	if linear_velocity.length() > 35.0:
		_trail_points.push_front(global_position)
		if _trail_points.size() > MAX_TRAIL_POINTS:
			_trail_points.pop_back()
	elif not _trail_points.is_empty():
		_trail_points.pop_back()
	queue_redraw()

func _draw() -> void:
	var main_col := GameColors.get_main_color(color_type)
	var dark_col := GameColors.get_dark_color(color_type)
	var light_col := GameColors.get_light_color(color_type)

	# Draw motion trail in local coordinates
	if _trail_points.size() > 1:
		for i in range(_trail_points.size()):
			var local_pt := to_local(_trail_points[i])
			var ratio := 1.0 - float(i) / float(_trail_points.size())
			var trail_col := Color(main_col.r, main_col.g, main_col.b, ratio * 0.28)
			draw_circle(local_pt, radius * ratio * 0.78, trail_col)

	# Drop shadow (in screen-down direction)
	var down_local := Vector2(0, 3.0).rotated(-rotation)
	draw_circle(down_local, radius + 1.5, Color(0.0, 0.0, 0.0, 0.28))

	# Outer dark border
	draw_circle(Vector2.ZERO, radius, dark_col)
	# Main vibrant fill
	draw_circle(Vector2.ZERO, radius - 2.5, main_col)
	# Inner subtle glow
	draw_circle(Vector2(-radius * 0.15, -radius * 0.15), radius * 0.62, main_col.lerp(light_col, 0.35))

	# Subtle rotating emblem inside ball so rolling is visually clear
	var emblem_col := Color(dark_col.r, dark_col.g, dark_col.b, 0.38)
	if color_type == GameColors.ColorType.STEEL:
		for a in range(4):
			var ang := float(a) * PI * 0.5
			var p := Vector2.from_angle(ang) * (radius * 0.55)
			draw_circle(p, 3.0, dark_col)
		draw_arc(Vector2.ZERO, radius * 0.45, 0.0, TAU, 20, light_col, 2.0, true)
	else:
		draw_arc(Vector2.ZERO, radius * 0.42, 0.3, PI - 0.3, 12, emblem_col, 2.2, true)
		draw_arc(Vector2.ZERO, radius * 0.42, PI + 0.3, TAU - 0.3, 12, emblem_col, 2.2, true)

	# Specular highlight (kept near top-left in world space for 3D glossy look)
	var shine_pos := Vector2(-radius * 0.32, -radius * 0.34).rotated(-rotation)
	draw_circle(shine_pos, radius * 0.28, Color(1.0, 1.0, 1.0, 0.78))
	var shine_pos2 := Vector2(-radius * 0.12, -radius * 0.52).rotated(-rotation)
	draw_circle(shine_pos2, radius * 0.12, Color(1.0, 1.0, 1.0, 0.55))
