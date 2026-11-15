class_name ColorContainer
extends Node2D

signal ball_collected(container: ColorContainer, ball: PuzzleBall)
signal wrong_ball_entered(container: ColorContainer, ball: PuzzleBall)

@export var color_type: GameColors.ColorType = GameColors.ColorType.RED:
	set(value):
		color_type = value
		queue_redraw()

@export var required_count: int = 2:
	set(value):
		required_count = max(value, 1)
		queue_redraw()

@export var bucket_width: float = 124.0
@export var bucket_height: float = 92.0

var collected_count: int = 0
var _display_fill: float = 0.0
var _pulse: float = 0.0
var _error_flash: float = 0.0
var _wave_time: float = 0.0

var _static_body: StaticBody2D
var _area: Area2D
var _particles: CPUParticles2D

func _ready() -> void:
	_build_physics()
	_build_particles()
	queue_redraw()

func is_satisfied() -> bool:
	return collected_count >= required_count

func _build_physics() -> void:
	if _static_body != null:
		_static_body.queue_free()
	if _area != null:
		_area.queue_free()

	_static_body = StaticBody2D.new()
	_static_body.name = "Walls"
	add_child(_static_body)

	var hw := bucket_width * 0.5
	var hh := bucket_height * 0.5
	var wall_thick := 10.0

	var poly_left := CollisionPolygon2D.new()
	poly_left.polygon = PackedVector2Array([
		Vector2(-hw - 14.0, -hh - 14.0),
		Vector2(-hw + 2.0, -hh),
		Vector2(-hw + 2.0, hh),
		Vector2(-hw - wall_thick, hh),
		Vector2(-hw - wall_thick, -hh)
	])
	_static_body.add_child(poly_left)

	var poly_right := CollisionPolygon2D.new()
	poly_right.polygon = PackedVector2Array([
		Vector2(hw + 14.0, -hh - 14.0),
		Vector2(hw + wall_thick, -hh),
		Vector2(hw + wall_thick, hh),
		Vector2(hw - 2.0, hh),
		Vector2(hw - 2.0, -hh)
	])
	_static_body.add_child(poly_right)

	var floor_col := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(bucket_width + wall_thick * 2.0, wall_thick)
	floor_col.shape = floor_rect
	floor_col.position = Vector2(0.0, hh + wall_thick * 0.5 - 2.0)
	_static_body.add_child(floor_col)

	_area = Area2D.new()
	_area.name = "CollectorZone"
	_area.monitoring = true
	_area.monitorable = false
	add_child(_area)

	var sensor_col := CollisionShape2D.new()
	var sensor_rect := RectangleShape2D.new()
	sensor_rect.size = Vector2(bucket_width - 12.0, bucket_height - 16.0)
	sensor_col.shape = sensor_rect
	sensor_col.position = Vector2(0.0, 6.0)
	_area.add_child(sensor_col)

	_area.body_entered.connect(_on_body_entered)

func _build_particles() -> void:
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 24
	_particles.lifetime = 0.65
	_particles.explosiveness = 0.92
	_particles.direction = Vector2(0, -1)
	_particles.spread = 65.0
	_particles.gravity = Vector2(0, 420.0)
	_particles.initial_velocity_min = 120.0
	_particles.initial_velocity_max = 260.0
	_particles.scale_amount_min = 4.0
	_particles.scale_amount_max = 8.0
	_particles.position = Vector2(0, -bucket_height * 0.25)
	add_child(_particles)

func _on_body_entered(body: Node) -> void:
	if not (body is PuzzleBall):
		return
	var ball: PuzzleBall = body as PuzzleBall
	if ball.is_collected or ball.color_type == GameColors.ColorType.STEEL:
		return

	ball.is_collected = true
	if ball.color_type == color_type:
		collected_count += 1
		_pulse = 1.0
		_particles.color = GameColors.get_light_color(color_type)
		_particles.restart()
		_particles.emitting = true
		_absorb_ball(ball)
		ball_collected.emit(self, ball)
	else:
		_error_flash = 1.0
		_particles.color = Color(1.0, 0.2, 0.2)
		_particles.restart()
		_particles.emitting = true
		_absorb_ball(ball)
		wrong_ball_entered.emit(self, ball)

func _absorb_ball(ball: PuzzleBall) -> void:
	ball.set_deferred("freeze", true)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ball, "global_position", global_position + Vector2(0, 12.0), 0.18)
	tw.tween_property(ball, "scale", Vector2(0.1, 0.1), 0.18)
	tw.tween_property(ball, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(ball.queue_free)

func _process(delta: float) -> void:
	_wave_time += delta * 4.5
	var target_ratio := clampf(float(collected_count) / float(max(required_count, 1)), 0.0, 1.0)
	_display_fill = lerpf(_display_fill, target_ratio, clampf(delta * 8.0, 0.0, 1.0))
	if _pulse > 0.0:
		_pulse = maxf(_pulse - delta * 3.5, 0.0)
		var sc := 1.0 + sin(_pulse * PI) * 0.08
		scale = Vector2(sc, 2.0 - sc)
	else:
		scale = Vector2.ONE
	if _error_flash > 0.0:
		_error_flash = maxf(_error_flash - delta * 2.5, 0.0)
	queue_redraw()

func _draw() -> void:
	var main := GameColors.get_main_color(color_type).lerp(Color.WHITE, 0.12)
	var light := GameColors.get_light_color(color_type)
	main = main.lerp(Color("ff677f"), _error_flash)
	var hw := bucket_width * 0.5
	var hh := bucket_height * 0.5
	var shell := StyleBoxFlat.new()
	shell.bg_color = Color("172b40")
	shell.set_corner_radius_all(14)
	shell.shadow_color = Color(0, 0, 0, 0.25)
	shell.shadow_size = 5
	draw_style_box(shell, Rect2(-hw - 6, -hh, bucket_width + 12, bucket_height + 10))
	if _display_fill > 0.01:
		var height := (bucket_height - 8) * _display_fill
		draw_rect(Rect2(-hw + 7, hh - height, bucket_width - 14, height), Color(main, 0.23))
		draw_line(Vector2(-hw + 7, hh - height), Vector2(hw - 7, hh - height), Color(light, 0.75), 2, true)
	var rim := PackedVector2Array([
		Vector2(-hw - 12, -hh - 12), Vector2(-hw, -hh),
		Vector2(-hw, hh), Vector2(hw, hh), Vector2(hw, -hh), Vector2(hw + 12, -hh - 12)])
	draw_polyline(rim, Color("2e4358"), 12, true)
	draw_polyline(rim, main, 6, true)
	draw_line(Vector2(-hw + 9, -hh + 10), Vector2(-hw + 9, hh - 10), Color(1, 1, 1, 0.12), 3, true)
	var arrow := Vector2(0, -hh - 14)
	draw_polyline(PackedVector2Array([arrow + Vector2(-7, -5), arrow, arrow + Vector2(7, -5)]), light, 2, true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-hw, 8), "%d / %d" % [collected_count, required_count], HORIZONTAL_ALIGNMENT_CENTER, bucket_width, 30, UiThemeHelper.TEXT)
	GameColors.draw_color_emblem(self, Vector2(0, -23), 19, color_type, light)
	draw_string(font, Vector2(-hw, hh + 39), GameColors.get_color_name(color_type), HORIZONTAL_ALIGNMENT_CENTER, bucket_width, 24, light)
	if is_satisfied():
		draw_polyline(PackedVector2Array([Vector2(-8, -20), Vector2(-2, -14), Vector2(10, -28)]), UiThemeHelper.TEAL, 3, true)
