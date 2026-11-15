class_name PuzzleBall
extends RigidBody2D

@export var color_type: GameColors.ColorType = GameColors.ColorType.RED:
	set(value):
		color_type = value
		_update_collision_filter()
		queue_redraw()

@export var radius: float = 18.0:
	set(value):
		radius = value
		_update_collision_shape()
		queue_redraw()

var is_collected: bool = false
var is_heavy_striker: bool = false
var _trail_points: Array[Vector2] = []
var _dye_flash: float = 0.0
const MAX_TRAIL_POINTS := 9

var _collision_shape: CollisionShape2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
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
	_update_collision_filter()

func _update_collision_filter() -> void:
	var c_bit := GameColors.get_collision_bit(color_type)
	# Layer: Bit 1 (1) so standard Area2D sensors (mask=1) detect balls + Bit 7 (64) for ball-to-ball + color bit
	collision_layer = 1 | 64 | c_bit
	# Mask: Bit 1 (1) WorldStatic + Bit 7 (64) other balls + own color gate bit
	collision_mask = 1 | 64 | c_bit

func transform_to_color(new_color: GameColors.ColorType) -> void:
	if color_type == GameColors.ColorType.STEEL or is_heavy_striker:
		return
	if color_type == new_color:
		return
	color_type = new_color
	_dye_flash = 1.0
	queue_redraw()

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

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	if _dye_flash > 0.0:
		_dye_flash = maxf(_dye_flash - delta * 3.5, 0.0)
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

	if _dye_flash > 0.0:
		main_col = main_col.lerp(Color.WHITE, _dye_flash * 0.65)

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

	# Accessible colorblind geometric emblem inside ball
	var emblem_col := Color(dark_col.r, dark_col.g, dark_col.b, 0.58)
	GameColors.draw_color_emblem(self, Vector2.ZERO, radius, color_type, emblem_col)

	# Specular highlight (kept near top-left in world space for 3D glossy look)
	var shine_pos := Vector2(-radius * 0.32, -radius * 0.34).rotated(-rotation)
	draw_circle(shine_pos, radius * 0.28, Color(1.0, 1.0, 1.0, 0.78))
	var shine_pos2 := Vector2(-radius * 0.12, -radius * 0.52).rotated(-rotation)
	draw_circle(shine_pos2, radius * 0.12, Color(1.0, 1.0, 1.0, 0.55))
