class_name ChainTrigger
extends Area2D

signal chain_activated(trigger: ChainTrigger)

@export var radius: float = 24.0
@export var trigger_color: Color = Color(0.25, 0.95, 0.85)
@export var consume_striker_ball: bool = false

var is_activated: bool = false
var linked_beams: Array[CuttableBeam] = []
var linked_ramps: Array[Ramp] = []
var linked_ramp_angles: Array[float] = []
var linked_chains: Array[SteelChain] = []

var _particles: CPUParticles2D
var _anim_pulse: float = 0.0

func _ready() -> void:
	monitoring = true
	monitorable = false

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	col.shape = circle
	add_child(col)

	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 22
	_particles.lifetime = 0.5
	_particles.explosiveness = 0.95
	_particles.spread = 180.0
	_particles.gravity = Vector2(0, 200.0)
	_particles.initial_velocity_min = 110.0
	_particles.initial_velocity_max = 240.0
	_particles.scale_amount_min = 3.5
	_particles.scale_amount_max = 7.0
	_particles.color = trigger_color
	add_child(_particles)

	body_entered.connect(_on_body_entered)

func link_beam_to_break(beam: CuttableBeam) -> void:
	if beam != null:
		linked_beams.append(beam)
		queue_redraw()

func link_ramp_to_rotate(ramp: Ramp, new_angle_deg: float) -> void:
	if ramp != null:
		linked_ramps.append(ramp)
		linked_ramp_angles.append(new_angle_deg)
		queue_redraw()

func link_chain_to_retract(chain: SteelChain) -> void:
	if chain != null:
		linked_chains.append(chain)
		queue_redraw()

func _on_body_entered(body: Node) -> void:
	if is_activated:
		return
	if not (body is PuzzleBall):
		return
	is_activated = true
	_particles.restart()
	_particles.emitting = true

	if consume_striker_ball and (body as PuzzleBall).color_type == GameColors.ColorType.STEEL:
		var ball := body as PuzzleBall
		ball.is_collected = true
		ball.collision_layer = 0
		ball.collision_mask = 0
		ball.set_deferred("freeze", true)
		var tw := create_tween()
		tw.tween_property(ball, "scale", Vector2(0.1, 0.1), 0.15)
		tw.tween_callback(ball.queue_free)

	for beam in linked_beams:
		if beam != null and is_instance_valid(beam) and not beam.is_cut:
			beam.perform_cut(beam.global_position)

	for i in range(linked_ramps.size()):
		var r := linked_ramps[i]
		if r != null and is_instance_valid(r):
			r.rotate_to_degrees(linked_ramp_angles[i], 0.20)

	for ch in linked_chains:
		if ch != null and is_instance_valid(ch) and not ch.is_retracted:
			ch.retract_chain()

	chain_activated.emit(self)
	queue_redraw()

func _process(delta: float) -> void:
	_anim_pulse += delta * 5.0
	queue_redraw()

func _draw() -> void:
	var wire_col := Color(trigger_color.r, trigger_color.g, trigger_color.b, 0.38 if not is_activated else 0.85)
	for beam in linked_beams:
		if beam != null and is_instance_valid(beam):
			draw_dashed_line(Vector2.ZERO, to_local(beam.global_position), wire_col, 2.5, 8.0)
	for r in linked_ramps:
		if r != null and is_instance_valid(r):
			draw_dashed_line(Vector2.ZERO, to_local(r.global_position), wire_col, 2.5, 8.0)
	for ch in linked_chains:
		if ch != null and is_instance_valid(ch):
			draw_dashed_line(Vector2.ZERO, to_local(ch.global_position), wire_col, 2.5, 8.0)

	var pulse_r := radius + sin(_anim_pulse) * 2.5
	var ring_col := trigger_color if not is_activated else Color(0.5, 1.0, 0.6, 0.55)
	draw_circle(Vector2.ZERO, pulse_r + 3.0, Color(ring_col.r, ring_col.g, ring_col.b, 0.22))
	draw_circle(Vector2.ZERO, radius, Color(0.14, 0.18, 0.26))
	draw_arc(Vector2.ZERO, radius - 2.0, 0.0, TAU, 28, ring_col, 3.5, true)

	# Inner lightning/gear icon
	var core_r := radius * 0.48
	if not is_activated:
		draw_circle(Vector2.ZERO, core_r, trigger_color)
	else:
		draw_circle(Vector2.ZERO, core_r * 0.6, Color(0.6, 1.0, 0.7))
