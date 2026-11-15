class_name CuttableRope
extends CuttableBase

@export var rope_offset: Vector2 = Vector2(0, 88.0):
	set(value):
		rope_offset = value
		queue_redraw()

@export var release_impulse: Vector2 = Vector2.ZERO

var attached_body: RigidBody2D = null
var _particles: CPUParticles2D
var _cut_local_point: Vector2 = Vector2.ZERO
var _recoil_t: float = 0.0

func _ready() -> void:
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 16
	_particles.lifetime = 0.42
	_particles.explosiveness = 0.92
	_particles.spread = 180.0
	_particles.gravity = Vector2(0, 360.0)
	_particles.initial_velocity_min = 80.0
	_particles.initial_velocity_max = 190.0
	_particles.scale_amount_min = 3.0
	_particles.scale_amount_max = 6.0
	_particles.color = Color(0.95, 0.82, 0.52)
	add_child(_particles)

	if attached_body != null and is_instance_valid(attached_body):
		attached_body.global_position = global_position + rope_offset
		attached_body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		attached_body.freeze = true

func attach_rigid_body(body: RigidBody2D, offset: Vector2 = Vector2(0, 88.0), impulse_on_cut: Vector2 = Vector2.ZERO) -> void:
	attached_body = body
	rope_offset = offset
	release_impulse = impulse_on_cut
	if attached_body != null and is_instance_valid(attached_body):
		attached_body.global_position = global_position + rope_offset
		attached_body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		attached_body.freeze = true
	queue_redraw()

func get_end_global() -> Vector2:
	if not is_cut and attached_body != null and is_instance_valid(attached_body):
		return attached_body.global_position
	return to_global(rope_offset)

func get_cut_center_global() -> Vector2:
	return global_position.lerp(get_end_global(), 0.5)

func check_segment_cut(world_a: Vector2, world_b: Vector2) -> Vector2:
	if is_cut:
		return Vector2.INF
	var p1 := global_position
	var p2 := get_end_global()
	var hit: Variant = Geometry2D.segment_intersects_segment(world_a, world_b, p1, p2)
	if hit != null:
		return hit as Vector2
	var closest := Geometry2D.get_closest_points_between_segments(world_a, world_b, p1, p2)
	if closest.size() == 2 and closest[0].distance_to(closest[1]) <= 14.0:
		return closest[1]
	return Vector2.INF

func perform_cut(world_point: Vector2, _swipe_dir: Vector2 = Vector2.RIGHT) -> void:
	if is_cut:
		return
	_cut_local_point = to_local(world_point)
	if _particles != null:
		_particles.global_position = world_point
		_particles.restart()
		_particles.emitting = true
	if attached_body != null and is_instance_valid(attached_body):
		attached_body.freeze = false
		attached_body.sleeping = false
		if release_impulse.length_squared() > 0.01:
			attached_body.apply_central_impulse(release_impulse)
	super.perform_cut(world_point, _swipe_dir)

func _process(delta: float) -> void:
	super._process(delta)
	if not is_cut:
		if attached_body != null and is_instance_valid(attached_body):
			attached_body.global_position = global_position + rope_offset
		queue_redraw()
	elif _recoil_t < 1.0:
		_recoil_t = minf(_recoil_t + delta * 2.8, 1.0)
		queue_redraw()

func _draw() -> void:
	var rope_dark := Color(0.48, 0.30, 0.14)
	var rope_main := Color(0.92, 0.72, 0.38)
	var rope_highlight := Color(1.0, 0.90, 0.62)

	# Top ceiling mount ring
	draw_circle(Vector2.ZERO, 9.0, Color(0.22, 0.26, 0.36))
	draw_circle(Vector2.ZERO, 5.5, Color(0.75, 0.82, 0.94))

	if not is_cut:
		var end_local := to_local(get_end_global())
		draw_line(Vector2.ZERO, end_local, rope_dark, 8.0, true)
		draw_line(Vector2.ZERO, end_local, rope_main, 4.5, true)

		# Braided fiber ticks along rope
		var dist := end_local.length()
		var dir := end_local.normalized()
		var perp := Vector2(-dir.y, dir.x)
		var d := 12.0
		while d < dist - 10.0:
			var pt := dir * d
			draw_line(pt - perp * 3.0 + dir * 2.0, pt + perp * 3.0 - dir * 2.0, rope_highlight, 1.8, true)
			d += 11.0

		# Bottom attachment clamp
		draw_circle(end_local, 6.5, Color(0.28, 0.32, 0.42))
		draw_hint_badge(end_local * 0.5 + Vector2(22.0, 0.0))
	else:
		var alpha := 1.0 - _recoil_t
		if alpha > 0.02:
			var top_stub := _cut_local_point * (1.0 - _recoil_t * 0.7)
			draw_line(Vector2.ZERO, top_stub, Color(rope_main.r, rope_main.g, rope_main.b, alpha), 4.5, true)
