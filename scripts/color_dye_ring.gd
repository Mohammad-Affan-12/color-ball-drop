class_name ColorDyeRing
extends Area2D

signal ball_dyed(ring: ColorDyeRing, ball: PuzzleBall, new_color: int)

@export var dye_color: GameColors.ColorType = GameColors.ColorType.BLUE:
	set(value):
		dye_color = value
		queue_redraw()

@export var radius: float = 28.0:
	set(value):
		radius = maxf(value, 14.0)
		_rebuild()
		queue_redraw()

var _dyed_ball_ids: Dictionary = {}
var _particles: CPUParticles2D
var _pulse: float = 0.0
var _flash: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	monitoring = true
	monitorable = false
	_rebuild()
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var col := CollisionShape2D.new()
	var c_shape := CircleShape2D.new()
	c_shape.radius = radius * 0.85
	col.shape = c_shape
	add_child(col)

	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 18
	_particles.lifetime = 0.42
	_particles.explosiveness = 0.92
	_particles.spread = 180.0
	_particles.gravity = Vector2(0, 180.0)
	_particles.initial_velocity_min = 80.0
	_particles.initial_velocity_max = 170.0
	_particles.scale_amount_min = 3.5
	_particles.scale_amount_max = 7.0
	add_child(_particles)

func _on_body_entered(body: Node) -> void:
	if not (body is PuzzleBall):
		return
	var ball := body as PuzzleBall
	if ball.is_collected or ball.color_type == GameColors.ColorType.STEEL or ball.is_heavy_striker:
		return
	var id := ball.get_instance_id()
	if _dyed_ball_ids.has(id) and ball.color_type == dye_color:
		return
	_dyed_ball_ids[id] = true
	if ball.color_type != dye_color:
		ball.transform_to_color(dye_color)
		_flash = 1.0
		_particles.color = GameColors.get_light_color(dye_color)
		_particles.restart()
		_particles.emitting = true
		ball_dyed.emit(self, ball, dye_color)
		queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta * 4.0
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 3.8, 0.0)
	queue_redraw()

func _draw() -> void:
	var main_col := GameColors.get_main_color(dye_color)
	var light_col := GameColors.get_light_color(dye_color)
	var dark_col := GameColors.get_dark_color(dye_color)

	var r := radius + sin(_pulse) * 2.0
	draw_circle(Vector2.ZERO, r, Color(main_col.r, main_col.g, main_col.b, 0.22 + _flash * 0.35))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, dark_col, 8.0, true)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, main_col.lerp(Color.WHITE, _flash * 0.6), 4.5, true)
	draw_arc(Vector2.ZERO, r - 5.0, _pulse, _pulse + PI * 1.3, 18, light_col, 2.2, true)
	GameColors.draw_color_emblem(self, Vector2.ZERO, radius * 0.55, dye_color, light_col)
