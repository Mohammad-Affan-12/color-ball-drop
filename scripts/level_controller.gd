class_name LevelController
extends Node2D

signal level_won(level_idx: int)
signal level_failed(level_idx: int, reason: String)
signal progress_updated(collected: int, total_required: int)
signal cut_made(item: CuttableBase, point: Vector2)
signal chain_reaction_triggered()

@export var level_number: int = 1

var level_title: String = "Level 1"
var level_subtitle: String = "Swipe across supports to drop balls into matching containers!"
var solution_steps: Array[Dictionary] = []

var containers: Array[ColorContainer] = []
var balls: Array[PuzzleBall] = []
var cuttables: Array[CuttableBase] = []
var ramps: Array[Ramp] = []
var triggers: Array[ChainTrigger] = []

var is_finished: bool = false
var hints_enabled: bool = false
var _cuts_made_count: int = 0
var _settled_timer: float = 0.0
var _floating_texts: Array[Dictionary] = []
var _confetti: CPUParticles2D

func _ready() -> void:
	_build_side_walls()
	_build_confetti()
	LevelData.populate_level(self, level_number)
	_emit_initial_progress()

func _build_side_walls() -> void:
	var walls := StaticBody2D.new()
	walls.name = "ArenaWalls"
	add_child(walls)

	var left_col := CollisionShape2D.new()
	var left_rect := RectangleShape2D.new()
	left_rect.size = Vector2(24.0, 1400.0)
	left_col.shape = left_rect
	left_col.position = Vector2(6.0, 640.0)
	walls.add_child(left_col)

	var right_col := CollisionShape2D.new()
	var right_rect := RectangleShape2D.new()
	right_rect.size = Vector2(24.0, 1400.0)
	right_col.shape = right_rect
	right_col.position = Vector2(714.0, 640.0)
	walls.add_child(right_col)

func _build_confetti() -> void:
	_confetti = CPUParticles2D.new()
	_confetti.position = Vector2(360.0, 260.0)
	_confetti.emitting = false
	_confetti.one_shot = true
	_confetti.amount = 64
	_confetti.lifetime = 1.6
	_confetti.explosiveness = 0.88
	_confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_confetti.emission_rect_extents = Vector2(260.0, 40.0)
	_confetti.direction = Vector2(0, -1)
	_confetti.spread = 110.0
	_confetti.gravity = Vector2(0, 380.0)
	_confetti.initial_velocity_min = 180.0
	_confetti.initial_velocity_max = 420.0
	_confetti.scale_amount_min = 6.0
	_confetti.scale_amount_max = 12.0
	_confetti.color = Color(1.0, 0.88, 0.28)
	add_child(_confetti)

func set_hints_visible(show: bool) -> void:
	hints_enabled = show
	for c in cuttables:
		if is_instance_valid(c):
			c.show_hint = show
			c.queue_redraw()
	queue_redraw()

func add_ramp(pos: Vector2, length: float, angle_deg: float, accent: Color = Color(0.32, 0.78, 0.98), left_lip: float = 0.0, right_lip: float = 0.0) -> Ramp:
	var r := Ramp.new()
	r.position = pos
	r.length = length
	r.rotation_degrees = angle_deg
	r.accent_color = accent
	r.left_lip_height = left_lip
	r.right_lip_height = right_lip
	add_child(r)
	ramps.append(r)
	return r

func add_container(pos: Vector2, c_type: GameColors.ColorType, req_count: int, width: float = 124.0) -> ColorContainer:
	var bucket := ColorContainer.new()
	bucket.position = pos
	bucket.color_type = c_type
	bucket.required_count = req_count
	bucket.bucket_width = width
	bucket.ball_collected.connect(_on_ball_collected)
	bucket.wrong_ball_entered.connect(_on_wrong_ball_entered)
	add_child(bucket)
	containers.append(bucket)
	return bucket

func add_ball(pos: Vector2, c_type: GameColors.ColorType, radius: float = 18.0) -> PuzzleBall:
	var b := PuzzleBall.new()
	b.position = pos
	b.color_type = c_type
	b.radius = radius
	if c_type == GameColors.ColorType.STEEL:
		b.is_heavy_striker = true
	add_child(b)
	balls.append(b)
	return b

func add_cuttable_beam(pos: Vector2, length: float, angle_deg: float, order_hint: int = 1, label_hint: String = "") -> CuttableBeam:
	var beam := CuttableBeam.new()
	beam.position = pos
	beam.length = length
	beam.rotation_degrees = angle_deg
	beam.hint_order = order_hint
	beam.hint_label = label_hint
	beam.add_to_group("cuttables")
	beam.cut_performed.connect(_on_cut_performed)
	add_child(beam)
	cuttables.append(beam)
	return beam

func add_cuttable_rope(anchor_pos: Vector2, body: RigidBody2D, rope_offset: Vector2 = Vector2(0, 84.0), impulse: Vector2 = Vector2.ZERO, order_hint: int = 1, label_hint: String = "") -> CuttableRope:
	var rope := CuttableRope.new()
	rope.position = anchor_pos
	rope.hint_order = order_hint
	rope.hint_label = label_hint
	rope.add_to_group("cuttables")
	rope.cut_performed.connect(_on_cut_performed)
	add_child(rope)
	rope.attach_rigid_body(body, rope_offset, impulse)
	cuttables.append(rope)
	return rope

func add_chain_trigger(pos: Vector2, radius: float = 24.0, consume_steel: bool = true) -> ChainTrigger:
	var trig := ChainTrigger.new()
	trig.position = pos
	trig.radius = radius
	trig.consume_striker_ball = consume_steel
	trig.chain_activated.connect(_on_chain_activated)
	add_child(trig)
	triggers.append(trig)
	return trig

func spawn_floating_text(world_pos: Vector2, text: String, col: Color) -> void:
	_floating_texts.append({
		"pos": world_pos,
		"text": text,
		"color": col,
		"age": 0.0
	})

func _on_cut_performed(item: CuttableBase, world_pt: Vector2) -> void:
	_cuts_made_count += 1
	_settled_timer = 0.0
	# Wake all balls so resting contacts re-evaluate immediately
	for b in balls:
		if is_instance_valid(b) and not b.is_collected and not b.freeze:
			b.sleeping = false
			b.apply_central_impulse(Vector2(0, 2.0))
	spawn_floating_text(world_pt + Vector2(0, -14.0), "SNIP!", Color(1.0, 0.92, 0.4))
	cut_made.emit(item, world_pt)

func _on_chain_activated(trig: ChainTrigger) -> void:
	_settled_timer = 0.0
	for b in balls:
		if is_instance_valid(b) and not b.is_collected and not b.freeze:
			b.sleeping = false
			b.apply_central_impulse(Vector2(0, 2.0))
	spawn_floating_text(trig.global_position + Vector2(0, -24.0), "CHAIN REACTION!", Color(0.3, 1.0, 0.9))
	chain_reaction_triggered.emit()

func _on_ball_collected(container: ColorContainer, _ball: PuzzleBall) -> void:
	if is_finished:
		return
	_settled_timer = 0.0
	var cname := GameColors.get_color_name(container.color_type)
	spawn_floating_text(
		container.global_position + Vector2(0, -56.0),
		"+1 %s!" % cname,
		GameColors.get_light_color(container.color_type)
	)
	_emit_initial_progress()
	_check_win_condition()

func _on_wrong_ball_entered(container: ColorContainer, ball: PuzzleBall) -> void:
	if is_finished:
		return
	var ball_name := GameColors.get_color_name(ball.color_type)
	var bucket_name := GameColors.get_color_name(container.color_type)
	spawn_floating_text(
		container.global_position + Vector2(0, -60.0),
		"WRONG COLOR!",
		Color(1.0, 0.25, 0.25)
	)
	_trigger_fail("%s ball landed in %s container!" % [ball_name, bucket_name])

func _emit_initial_progress() -> void:
	var total_req := 0
	var total_col := 0
	for c in containers:
		total_req += c.required_count
		total_col += mini(c.collected_count, c.required_count)
	progress_updated.emit(total_col, total_req)

func _check_win_condition() -> void:
	if is_finished:
		return
	for c in containers:
		if not c.is_satisfied():
			return
	is_finished = true
	_confetti.restart()
	_confetti.emitting = true
	level_won.emit(level_number)

func _trigger_fail(reason: String) -> void:
	if is_finished:
		return
	is_finished = true
	level_failed.emit(level_number, reason)

func _physics_process(delta: float) -> void:
	if is_finished:
		return

	# Check if any uncollected colored ball fell out of the bottom of the screen
	var any_moving := false
	for b in balls:
		if not is_instance_valid(b) or b.is_collected:
			continue
		if b.global_position.y > 1255.0:
			if b.color_type == GameColors.ColorType.STEEL:
				b.is_collected = true
				b.queue_free()
				continue
			else:
				var cname := GameColors.get_color_name(b.color_type)
				b.is_collected = true
				_trigger_fail("%s ball fell out of bounds!" % cname)
				return
		if not b.freeze and b.linear_velocity.length() > 14.0:
			any_moving = true

	# Check if all cuttables have been cut and all remaining balls are stuck/stopped
	var all_cut := true
	for c in cuttables:
		if is_instance_valid(c) and not c.is_cut:
			all_cut = false
			break

	if all_cut and not any_moving:
		_settled_timer += delta
		if _settled_timer >= 3.2:
			_trigger_fail("Balls stopped before filling all containers!")
	else:
		_settled_timer = 0.0

func _process(delta: float) -> void:
	if _floating_texts.is_empty():
		return
	var i := _floating_texts.size() - 1
	while i >= 0:
		_floating_texts[i]["age"] += delta
		_floating_texts[i]["pos"] += Vector2(0, -48.0 * delta)
		if _floating_texts[i]["age"] >= 0.95:
			_floating_texts.remove_at(i)
		i -= 1
	queue_redraw()

func _draw() -> void:
	# Subtle decorative playfield frame
	draw_rect(Rect2(18.0, 126.0, 684.0, 1094.0), Color(0.24, 0.30, 0.44, 0.35), false, 2.0)

	var font := ThemeDB.fallback_font
	if font != null:
		for item in _floating_texts:
			var age: float = item["age"]
			var alpha := clampf(1.0 - age / 0.95, 0.0, 1.0)
			var col: Color = item["color"]
			col.a = alpha
			var p: Vector2 = item["pos"]
			draw_string(
				font,
				p + Vector2(-100.0, 0.0),
				item["text"],
				HORIZONTAL_ALIGNMENT_CENTER,
				200.0,
				18,
				col
			)
