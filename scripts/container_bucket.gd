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

	# Left flared wall + vertical wall + bottom floor + right vertical wall + right flared wall
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
	if ball.is_collected:
		return
	if ball.color_type == GameColors.ColorType.STEEL:
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
	var main_col := GameColors.get_main_color(color_type)
	var dark_col := GameColors.get_dark_color(color_type)
	var light_col := GameColors.get_light_color(color_type)

	if _error_flash > 0.0:
		main_col = main_col.lerp(Color(1.0, 0.1, 0.1), _error_flash)

	var hw := bucket_width * 0.5
	var hh := bucket_height * 0.5

	# Background dark glass interior
	var bg_rect := Rect2(-hw + 3.0, -hh + 2.0, bucket_width - 6.0, bucket_height - 4.0)
	draw_rect(bg_rect, Color(dark_col.r * 0.35, dark_col.g * 0.35, dark_col.b * 0.35, 0.78), true)

	# Liquid fill level
	if _display_fill > 0.01:
		var fill_h := (bucket_height - 10.0) * _display_fill
		var fill_top := hh - 4.0 - fill_h
		var fill_rect := Rect2(-hw + 5.0, fill_top, bucket_width - 10.0, fill_h)
		var fill_col := Color(main_col.r, main_col.g, main_col.b, 0.55)
		draw_rect(fill_rect, fill_col, true)
		# Bright surface line
		draw_line(
			Vector2(-hw + 5.0, fill_top),
			Vector2(hw - 5.0, fill_top),
			light_col,
			3.0,
			true
		)

	# Outer glow if full
	if is_satisfied():
		var glow_alpha := 0.25 + 0.12 * sin(_wave_time)
		draw_rect(
			Rect2(-hw - 6.0, -hh - 4.0, bucket_width + 12.0, bucket_height + 10.0),
			Color(light_col.r, light_col.g, light_col.b, glow_alpha),
			false,
			4.0
		)

	# Container U-frame walls with flared funnel lips
	var rim_pts := PackedVector2Array([
		Vector2(-hw - 12.0, -hh - 12.0),
		Vector2(-hw, -hh),
		Vector2(-hw, hh),
		Vector2(hw, hh),
		Vector2(hw, -hh),
		Vector2(hw + 12.0, -hh - 12.0)
	])
	draw_polyline(rim_pts, dark_col, 11.0, true)
	draw_polyline(rim_pts, main_col, 6.5, true)

	# Top inner funnel chevrons
	var arrow_y := -hh - 8.0 + sin(_wave_time) * 2.5
	draw_line(Vector2(-10, arrow_y - 4), Vector2(0, arrow_y + 4), light_col, 2.5, true)
	draw_line(Vector2(10, arrow_y - 4), Vector2(0, arrow_y + 4), light_col, 2.5, true)

	# Draw counter badge and color name
	var font := ThemeDB.fallback_font
	if font != null:
		var count_str := "%d / %d" % [collected_count, required_count]
		if is_satisfied():
			count_str += " ✓"
		draw_string(
			font,
			Vector2(-hw, 6.0),
			count_str,
			HORIZONTAL_ALIGNMENT_CENTER,
			bucket_width,
			20,
			Color.WHITE
		)
		var cname := "%s %s" % [GameColors.get_color_symbol(color_type), GameColors.get_color_name(color_type)]
		draw_string(
			font,
			Vector2(-hw, 28.0),
			cname,
			HORIZONTAL_ALIGNMENT_CENTER,
			bucket_width,
			13,
			light_col
		)
