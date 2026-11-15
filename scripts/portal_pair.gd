class_name PortalPair
extends Node2D

signal ball_teleported(portal: PortalPair, ball: PuzzleBall)

@export var exit_offset: Vector2 = Vector2(260.0, -160.0):
	set(value):
		exit_offset = value
		_rebuild()
		queue_redraw()

@export var portal_radius: float = 32.0
@export var portal_color: Color = Color(0.68, 0.35, 1.0)
@export var exit_velocity_override: Vector2 = Vector2.ZERO

const COOLDOWN_SEC := 0.50

var _entry_area: Area2D
var _exit_area: Area2D
var _entry_particles: CPUParticles2D
var _exit_particles: CPUParticles2D
var _cooldowns: Dictionary = {}
var _spin_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rebuild()
	queue_redraw()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	_entry_area = Area2D.new()
	_entry_area.monitoring = true
	_entry_area.monitorable = false
	var c1 := CollisionShape2D.new()
	var s1 := CircleShape2D.new()
	s1.radius = portal_radius
	c1.shape = s1
	_entry_area.add_child(c1)
	_entry_area.body_entered.connect(func(b: Node) -> void: _try_teleport(b, true))
	add_child(_entry_area)

	_exit_area = Area2D.new()
	_exit_area.position = exit_offset
	_exit_area.monitoring = true
	_exit_area.monitorable = false
	var c2 := CollisionShape2D.new()
	var s2 := CircleShape2D.new()
	s2.radius = portal_radius
	c2.shape = s2
	_exit_area.add_child(c2)
	_exit_area.body_entered.connect(func(b: Node) -> void: _try_teleport(b, false))
	add_child(_exit_area)

	_entry_particles = _make_burst(Vector2.ZERO)
	add_child(_entry_particles)
	_exit_particles = _make_burst(exit_offset)
	add_child(_exit_particles)

func _make_burst(pos: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = false
	p.one_shot = true
	p.amount = 16
	p.lifetime = 0.36
	p.explosiveness = 0.92
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 70.0
	p.initial_velocity_max = 160.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = portal_color.lightened(0.35)
	return p

func _try_teleport(body: Node, from_entry_to_exit: bool) -> void:
	if not (body is PuzzleBall):
		return
	var ball := body as PuzzleBall
	if ball.is_collected:
		return
	var id := ball.get_instance_id()
	if _cooldowns.has(id):
		return
	_cooldowns[id] = COOLDOWN_SEC

	var target_world := to_global(exit_offset) if from_entry_to_exit else global_position
	var vel := ball.linear_velocity
	if exit_velocity_override.length_squared() > 1.0:
		vel = exit_velocity_override
	_entry_particles.restart()
	_entry_particles.emitting = true
	_exit_particles.restart()
	_exit_particles.emitting = true

	PhysicsServer2D.body_set_state(
		ball.get_rid(),
		PhysicsServer2D.BODY_STATE_TRANSFORM,
		Transform2D(ball.global_rotation, target_world)
	)
	ball.global_position = target_world
	ball.linear_velocity = vel
	ball_teleported.emit(self, ball)

func _process(delta: float) -> void:
	_spin_time += delta * 4.5
	var expired: Array = []
	for id in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			expired.append(id)
	for id in expired:
		_cooldowns.erase(id)
	queue_redraw()

func _draw() -> void:
	var link_col := Color(portal_color.r, portal_color.g, portal_color.b, 0.28)
	draw_dashed_line(Vector2.ZERO, exit_offset, link_col, 2.0, 9.0)
	_draw_portal_ring(Vector2.ZERO, "IN")
	_draw_portal_ring(exit_offset, "OUT")

func _draw_portal_ring(center: Vector2, _tag: String) -> void:
	var light := portal_color.lightened(0.4)
	var dark := portal_color.darkened(0.55)
	draw_circle(center, portal_radius, Color(dark.r, dark.g, dark.b, 0.82))
	draw_arc(center, portal_radius, 0.0, TAU, 28, portal_color, 5.5, true)
	draw_arc(center, portal_radius - 5.0, _spin_time, _spin_time + PI, 16, light, 3.0, true)
	draw_arc(center, portal_radius - 10.0, -_spin_time, -_spin_time + PI, 14, Color.WHITE, 2.0, true)
	draw_circle(center, 5.0, light)
