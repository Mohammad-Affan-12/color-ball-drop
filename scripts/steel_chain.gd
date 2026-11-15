class_name SteelChain
extends Node2D

signal uncuttable_hit(chain: SteelChain, world_point: Vector2)

@export var length: float = 92.0:
	set(value):
		length = maxf(value, 24.0)
		_rebuild()
		queue_redraw()

@export var thickness: float = 16.0

var is_retracted: bool = false
var _body: StaticBody2D
var _col_shape: CollisionShape2D
var _reject_flash: float = 0.0
var _particles: CPUParticles2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("uncuttables")
	_rebuild()
	queue_redraw()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	_body = StaticBody2D.new()
	add_child(_body)

	_col_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, thickness)
	_col_shape.shape = rect
	_body.add_child(_col_shape)

	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 12
	_particles.lifetime = 0.28
	_particles.explosiveness = 0.95
	_particles.spread = 180.0
	_particles.gravity = Vector2(0, 300.0)
	_particles.initial_velocity_min = 90.0
	_particles.initial_velocity_max = 180.0
	_particles.scale_amount_min = 2.5
	_particles.scale_amount_max = 5.0
	_particles.color = Color(0.85, 0.92, 1.0)
	add_child(_particles)

func check_segment_hit(world_a: Vector2, world_b: Vector2) -> Vector2:
	if is_retracted:
		return Vector2.INF
	var half := Vector2(length * 0.5, 0.0)
	var p1 := to_global(-half)
	var p2 := to_global(half)
	var hit: Variant = Geometry2D.segment_intersects_segment(world_a, world_b, p1, p2)
	if hit != null:
		return hit as Vector2
	var closest := Geometry2D.get_closest_points_between_segments(world_a, world_b, p1, p2)
	if closest.size() == 2 and closest[0].distance_to(closest[1]) <= thickness * 0.85:
		return closest[1]
	return Vector2.INF

func trigger_reject_feedback(world_pt: Vector2) -> void:
	if is_retracted:
		return
	_reject_flash = 1.0
	if _particles != null:
		_particles.global_position = world_pt
		_particles.restart()
		_particles.emitting = true
	uncuttable_hit.emit(self, world_pt)
	queue_redraw()

func retract_chain() -> void:
	if is_retracted:
		return
	is_retracted = true
	if _body != null:
		_body.collision_layer = 0
		_body.collision_mask = 0
	if _col_shape != null:
		_col_shape.set_deferred("disabled", true)
	queue_redraw()

func _process(delta: float) -> void:
	if _reject_flash > 0.0:
		_reject_flash = maxf(_reject_flash - delta * 4.0, 0.0)
		queue_redraw()

func _draw() -> void:
	if is_retracted:
		return
	var hl := length * 0.5
	var ht := thickness * 0.5
	var steel_dark := Color(0.20, 0.24, 0.32)
	var steel_mid := Color(0.48, 0.54, 0.66).lerp(Color(1.0, 0.35, 0.35), _reject_flash * 0.7)
	var steel_light := Color(0.78, 0.84, 0.94)

	draw_rect(Rect2(-hl, -ht, length, thickness), steel_dark, true)
	draw_rect(Rect2(-hl + 2.0, -ht + 2.0, length - 4.0, thickness - 4.0), steel_mid, true)

	# Draw armored chain links along length
	var step := 18.0
	var x := -hl + 12.0
	while x <= hl - 12.0:
		draw_arc(Vector2(x, 0), 5.5, 0.0, TAU, 12, steel_dark, 2.5, true)
		draw_circle(Vector2(x, 0), 2.5, steel_light)
		x += step

	# Central padlock shield badge indicating UNCUTTABLE
	draw_circle(Vector2.ZERO, 11.0, steel_dark)
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 18, steel_light, 2.0, true)
	draw_rect(Rect2(-5.0, -2.0, 10.0, 8.0), steel_light, true)
	draw_arc(Vector2(0, -2.0), 3.5, PI, TAU, 10, steel_light, 2.0, true)
