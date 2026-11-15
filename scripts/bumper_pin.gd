class_name BumperPin
extends Node2D

signal bumper_hit(bumper: BumperPin, ball: PuzzleBall)

@export var radius: float = 22.0:
	set(value):
		radius = maxf(value, 10.0)
		_rebuild()
		queue_redraw()

@export var bounce_impulse: float = 240.0
@export var pin_color: Color = Color(1.0, 0.36, 0.78)

var _body: StaticBody2D
var _sensor: Area2D
var _particles: CPUParticles2D
var _hit_flash: float = 0.0
var _pulse_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rebuild()
	queue_redraw()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	_body = StaticBody2D.new()
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.85
	mat.friction = 0.01
	_body.physics_material_override = mat
	add_child(_body)

	var col := CollisionShape2D.new()
	var c_shape := CircleShape2D.new()
	c_shape.radius = radius
	col.shape = c_shape
	_body.add_child(col)

	_sensor = Area2D.new()
	_sensor.monitoring = true
	_sensor.monitorable = false
	add_child(_sensor)

	var s_col := CollisionShape2D.new()
	var s_shape := CircleShape2D.new()
	s_shape.radius = radius + 5.0
	s_col.shape = s_shape
	_sensor.add_child(s_col)
	_sensor.body_entered.connect(_on_body_entered)

	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 14
	_particles.lifetime = 0.35
	_particles.explosiveness = 0.95
	_particles.spread = 180.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = 90.0
	_particles.initial_velocity_max = 180.0
	_particles.scale_amount_min = 3.0
	_particles.scale_amount_max = 6.0
	_particles.color = pin_color.lightened(0.3)
	add_child(_particles)

func _on_body_entered(body: Node) -> void:
	if not (body is PuzzleBall):
		return
	var ball := body as PuzzleBall
	if ball.is_collected:
		return
	_hit_flash = 1.0
	var dir := (ball.global_position - global_position).normalized()
	if dir.length_squared() < 0.01:
		dir = Vector2.UP
	if bounce_impulse > 0.0:
		ball.apply_central_impulse(dir * bounce_impulse)
	_particles.restart()
	_particles.emitting = true
	bumper_hit.emit(self, ball)
	queue_redraw()

func _process(delta: float) -> void:
	_pulse_time += delta * 4.0
	if _hit_flash > 0.0:
		_hit_flash = maxf(_hit_flash - delta * 4.5, 0.0)
		var sc := 1.0 + sin(_hit_flash * PI) * 0.18
		scale = Vector2(sc, sc)
	else:
		scale = Vector2.ONE
	queue_redraw()

func _draw() -> void:
	var c := pin_color.lerp(Color.WHITE, _hit_flash * 0.65)
	var dark := pin_color.darkened(0.55)
	draw_circle(Vector2.ZERO, radius + 3.0 + sin(_pulse_time) * 1.5, Color(c.r, c.g, c.b, 0.25))
	draw_circle(Vector2.ZERO, radius, dark)
	draw_circle(Vector2.ZERO, radius - 3.0, c)
	draw_arc(Vector2.ZERO, radius * 0.58, 0.0, TAU, 20, Color.WHITE, 2.2, true)
	draw_circle(Vector2.ZERO, radius * 0.25, Color.WHITE)
