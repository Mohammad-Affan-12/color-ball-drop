class_name ColorFilterGate
extends Node2D

signal gate_passed(gate: ColorFilterGate, ball: PuzzleBall)

@export var allowed_color: GameColors.ColorType = GameColors.ColorType.RED:
	set(value):
		allowed_color = value
		_update_filter()
		queue_redraw()

@export var length: float = 120.0:
	set(value):
		length = maxf(value, 24.0)
		_rebuild()
		queue_redraw()

@export var thickness: float = 14.0:
	set(value):
		thickness = maxf(value, 6.0)
		_rebuild()
		queue_redraw()

var _body: StaticBody2D
var _sensor: Area2D
var _flash: float = 0.0
var _pulse: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rebuild()
	_update_filter()
	queue_redraw()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	_body = StaticBody2D.new()
	var mat := PhysicsMaterial.new()
	mat.friction = 0.02
	mat.bounce = 0.12
	_body.physics_material_override = mat
	add_child(_body)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, thickness)
	col.shape = rect
	_body.add_child(col)

	_sensor = Area2D.new()
	_sensor.monitoring = true
	_sensor.monitorable = false
	add_child(_sensor)

	var s_col := CollisionShape2D.new()
	var s_rect := RectangleShape2D.new()
	s_rect.size = Vector2(length, thickness + 10.0)
	s_col.shape = s_rect
	_sensor.add_child(s_col)
	_sensor.body_entered.connect(_on_body_entered)

func _update_filter() -> void:
	if _body == null:
		return
	var all_color_bits := 2 | 4 | 8 | 16 | 32
	var allowed_bit := GameColors.get_collision_bit(allowed_color)
	# Block all ball colors EXCEPT allowed_color
	_body.collision_layer = all_color_bits & (~allowed_bit)
	_body.collision_mask = 0

func _on_body_entered(body: Node) -> void:
	if body is PuzzleBall:
		var ball := body as PuzzleBall
		if ball.color_type == allowed_color:
			_flash = 1.0
			gate_passed.emit(self, ball)
			queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta * 4.5
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 4.0, 0.0)
	queue_redraw()

func _draw() -> void:
	var hl := length * 0.5
	var ht := thickness * 0.5
	var main_col := GameColors.get_main_color(allowed_color)
	var light_col := GameColors.get_light_color(allowed_color)
	var dark_col := GameColors.get_dark_color(allowed_color)

	var alpha := 0.42 + 0.12 * sin(_pulse) + _flash * 0.35
	var beam_col := Color(main_col.r, main_col.g, main_col.b, clampf(alpha, 0.2, 0.95))
	draw_rect(Rect2(-hl, -ht, length, thickness), beam_col, true)
	draw_line(Vector2(-hl, -ht), Vector2(hl, -ht), light_col, 2.2, true)
	draw_line(Vector2(-hl, ht), Vector2(hl, ht), light_col, 2.2, true)

	# End emitters
	draw_circle(Vector2(-hl, 0), ht + 2.0, dark_col)
	draw_circle(Vector2(hl, 0), ht + 2.0, dark_col)
	draw_circle(Vector2(-hl, 0), ht - 1.5, main_col)
	draw_circle(Vector2(hl, 0), ht - 1.5, main_col)

	# Center colorblind emblem badge
	draw_circle(Vector2.ZERO, 13.0, Color(0.10, 0.13, 0.22, 0.92))
	draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 20, light_col, 2.0, true)
	GameColors.draw_color_emblem(self, Vector2.ZERO, 12.0, allowed_color, light_col)
