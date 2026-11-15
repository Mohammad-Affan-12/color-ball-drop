class_name CuttableBeam
extends CuttableBase

@export var length: float = 92.0:
	set(value):
		length = maxf(value, 20.0)
		_rebuild_collision()
		queue_redraw()

@export var thickness: float = 14.0:
	set(value):
		thickness = maxf(value, 6.0)
		_rebuild_collision()
		queue_redraw()

var _body: StaticBody2D
var _col_shape: CollisionShape2D
var _particles: CPUParticles2D

var _cut_anim_time: float = 0.0
var _left_offset: Vector2 = Vector2.ZERO
var _right_offset: Vector2 = Vector2.ZERO
var _left_rot: float = 0.0
var _right_rot: float = 0.0

func _ready() -> void:
	_rebuild_collision()
	_build_particles()
	queue_redraw()

func _rebuild_collision() -> void:
	if _body == null:
		_body = StaticBody2D.new()
		_body.name = "BeamBody"
		add_child(_body)
	if _col_shape == null:
		_col_shape = CollisionShape2D.new()
		_col_shape.name = "CollisionShape2D"
		_body.add_child(_col_shape)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, thickness)
	_col_shape.shape = rect

func _build_particles() -> void:
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 18
	_particles.lifetime = 0.48
	_particles.explosiveness = 0.95
	_particles.spread = 180.0
	_particles.gravity = Vector2(0, 500.0)
	_particles.initial_velocity_min = 90.0
	_particles.initial_velocity_max = 220.0
	_particles.scale_amount_min = 3.5
	_particles.scale_amount_max = 7.0
	_particles.color = Color(1.0, 0.72, 0.24)
	add_child(_particles)

func get_endpoints_global() -> Array[Vector2]:
	var half := Vector2(length * 0.5, 0.0)
	return [to_global(-half), to_global(half)]

func check_segment_cut(world_a: Vector2, world_b: Vector2) -> Vector2:
	if is_cut:
		return Vector2.INF
	var pts := get_endpoints_global()
	var beam_a := pts[0]
	var beam_b := pts[1]
	var hit: Variant = Geometry2D.segment_intersects_segment(world_a, world_b, beam_a, beam_b)
	if hit != null:
		return hit as Vector2
	# Also allow grazing across the thickness of the beam for comfortable mobile touch
	var closest := Geometry2D.get_closest_points_between_segments(world_a, world_b, beam_a, beam_b)
	if closest.size() == 2 and closest[0].distance_to(closest[1]) <= maxf(thickness * 0.95, 13.0):
		return closest[1]
	return Vector2.INF

func perform_cut(world_point: Vector2, _swipe_dir: Vector2 = Vector2.RIGHT) -> void:
	if is_cut:
		return
	if _body != null:
		_body.collision_layer = 0
		_body.collision_mask = 0
	if _col_shape != null:
		_col_shape.set_deferred("disabled", true)
	if _particles != null:
		_particles.global_position = world_point
		_particles.restart()
		_particles.emitting = true
	super.perform_cut(world_point, _swipe_dir)

func _process(delta: float) -> void:
	super._process(delta)
	if is_cut and _cut_anim_time < 1.0:
		_cut_anim_time = minf(_cut_anim_time + delta * 2.4, 1.0)
		_left_offset += Vector2(-45.0, 180.0 * _cut_anim_time) * delta
		_right_offset += Vector2(45.0, 180.0 * _cut_anim_time) * delta
		_left_rot -= 2.8 * delta
		_right_rot += 2.8 * delta
		queue_redraw()

func _draw() -> void:
	var hl := length * 0.5
	var ht := thickness * 0.5
	var wood_dark := Color(0.55, 0.28, 0.08)
	var wood_main := Color(0.96, 0.62, 0.18)
	var wood_light := Color(1.0, 0.84, 0.42)

	if not is_cut:
		# Outer frame
		draw_rect(Rect2(-hl, -ht, length, thickness), wood_dark, true)
		draw_rect(Rect2(-hl + 2.0, -ht + 2.0, length - 4.0, thickness - 4.0), wood_main, true)

		# Diagonal hazard/cut stripes
		var stripe_step := 16.0
		var x := -hl + 8.0
		while x < hl - 8.0:
			draw_line(
				Vector2(x - 3.0, ht - 2.0),
				Vector2(x + 3.0, -ht + 2.0),
				Color(0.75, 0.38, 0.08, 0.75),
				3.0,
				true
			)
			x += stripe_step

		# Center dotted cut guide line
		var pulse_alpha := 0.65 + 0.3 * sin(_hint_pulse)
		draw_line(
			Vector2(0, -ht - 6.0),
			Vector2(0, ht + 6.0),
			Color(1.0, 0.95, 0.6, pulse_alpha),
			2.2,
			true
		)

		# End bolts
		draw_circle(Vector2(-hl + 6.0, 0), 4.0, wood_light)
		draw_circle(Vector2(hl - 6.0, 0), 4.0, wood_light)

		draw_hint_badge(Vector2(0, -ht - 18.0))
	else:
		var alpha := 1.0 - _cut_anim_time
		if alpha <= 0.02:
			return
		var col := Color(wood_main.r, wood_main.g, wood_main.b, alpha)
		# Left piece
		draw_set_transform(_left_offset, _left_rot, Vector2.ONE)
		draw_rect(Rect2(-hl, -ht, hl - 3.0, thickness), col, true)
		# Right piece
		draw_set_transform(_right_offset, _right_rot, Vector2.ONE)
		draw_rect(Rect2(3.0, -ht, hl - 3.0, thickness), col, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
