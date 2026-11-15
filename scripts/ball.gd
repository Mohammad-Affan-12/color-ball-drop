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
var show_color_symbol := true
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
	if freeze and _trail_points.is_empty() and _dye_flash <= 0.0:
		return # Static held balls do not need to rebuild their draw commands.
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
	var main := GameColors.get_main_color(color_type)
	var dark := GameColors.get_dark_color(color_type)
	var light := GameColors.get_light_color(color_type)
	main = main.lerp(Color.WHITE, _dye_flash * 0.65)
	# Visual rim only; radius and collision shape retain their original values.
	draw_circle(Vector2.ZERO, radius + 3.0, Color(light, 0.18))
	for i in range(_trail_points.size()):
		var fade := 1.0 - float(i) / float(_trail_points.size())
		draw_circle(to_local(_trail_points[i]), radius * fade * 0.7, Color(main, fade * 0.18))
	draw_circle(Vector2(1, 4).rotated(-rotation), radius + 1, Color(0, 0, 0, 0.32))
	draw_circle(Vector2.ZERO, radius, light.lerp(dark, 0.55))
	# Small layered discs create a soft enamel gradient without textures.
	for step in range(10):
		var t := float(step) / 9.0
		draw_circle(Vector2(-1, -2).rotated(-rotation) * t, (radius - 1.4) * (1.0 - t * 0.42), main.lerp(light, t * 0.55))
	draw_arc(Vector2.ZERO, radius - 2, PI * 1.08 - rotation, PI * 1.8 - rotation, 20, Color(light, 0.8), 1.5, true)
	if show_color_symbol:
		GameColors.draw_color_emblem(self, Vector2(0, 1), radius * 0.9, color_type, Color(dark.darkened(0.25), 0.9))
	draw_circle(Vector2(-radius * 0.3, -radius * 0.4).rotated(-rotation), radius * 0.18, Color(1, 1, 1, 0.88))
