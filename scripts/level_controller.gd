class_name LevelController
extends Node2D

signal level_won(level_idx: int)
signal level_failed(level_idx: int, reason: String)
signal progress_updated(collected: int, total_required: int)
signal moves_updated(moves_used: int, par_moves: int)
signal cut_made(item: CuttableBase, point: Vector2)
signal chain_reaction_triggered()
signal mechanic_sfx_requested(sound_name: String)

@export var level_number: int = 1

var level_title: String = "Level 1"
var level_subtitle: String = "Swipe across supports to drop balls into matching containers!"
var chapter_number: int = 1
var par_moves: int = 3
var tutorial_tip: String = ""
var tutorial_tip_pos: Vector2 = Vector2(360, 240)
var solution_steps: Array[Dictionary] = []

var containers: Array[ColorContainer] = []
var balls: Array[PuzzleBall] = []
var cuttables: Array[CuttableBase] = []
var ramps: Array[Ramp] = []
var triggers: Array[ChainTrigger] = []
var bumpers: Array[BumperPin] = []
var filter_gates: Array[ColorFilterGate] = []
var dye_rings: Array[ColorDyeRing] = []
var seesaws: Array[SeesawBridge] = []
var steel_chains: Array[SteelChain] = []
var portals: Array[PortalPair] = []
var moving_deflectors: Array[MovingDeflector] = []

var tutorial_guide: TutorialGuide = null
var is_finished: bool = false
var hints_enabled: bool = false
var moves_used: int = 0
var _cuts_made_count: int = 0
var _settled_timer: float = 0.0
var _floating_texts: Array[Dictionary] = []
var _confetti: CPUParticles2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_side_walls()
	_build_confetti()
	LevelData.populate_level(self, level_number)
	_build_tutorial_guide()
	_emit_initial_progress()
	moves_updated.emit(moves_used, par_moves)

func _build_side_walls() -> void:
	var walls := StaticBody2D.new()
	walls.name = "ArenaWalls"
	add_child(walls)
	for x_pos in [6.0, 714.0]:
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(24.0, 1400.0)
		col.shape = rect
		col.position = Vector2(x_pos, 640.0)
		walls.add_child(col)

func _build_confetti() -> void:
	_confetti = CPUParticles2D.new()
	_confetti.position = Vector2(360.0, 260.0)
	_confetti.emitting = false
	_confetti.one_shot = true
	_confetti.amount = 56
	_confetti.lifetime = 1.5
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

func _build_tutorial_guide() -> void:
	if level_number == 1 or not tutorial_tip.is_empty():
		tutorial_guide = TutorialGuide.new()
		tutorial_guide.name = "TutorialGuide"
		add_child(tutorial_guide)
		tutorial_guide.setup(self, tutorial_tip, tutorial_tip_pos)

func set_low_particle_quality(low: bool) -> void:
	if _confetti != null:
		_confetti.amount = 24 if low else 56

func record_valid_move(cuts_in_move: int = 1) -> void:
	if is_finished:
		return
	moves_used += 1
	if cuts_in_move >= 2:
		spawn_floating_text(Vector2(360, 240), "MULTI-CUT x%d!" % cuts_in_move, Color(1.0, 0.95, 0.35))
	moves_updated.emit(moves_used, par_moves)

func compute_earned_stars() -> int:
	var effective_moves := maxi(moves_used, 1)
	if effective_moves <= par_moves:
		return 3
	elif effective_moves == par_moves + 1:
		return 2
	return 1

func set_hints_visible(show: bool) -> void:
	hints_enabled = show
	for c in cuttables:
		if is_instance_valid(c):
			c.show_hint = show
			c.queue_redraw()
	queue_redraw()

# --- Delegated Spawner API ---

func add_ramp(pos: Vector2, length: float, angle_deg: float, accent: Color = Color(0.32, 0.78, 0.98), left_lip: float = 0.0, right_lip: float = 0.0) -> Ramp:
	return LevelSpawner.add_ramp(self, pos, length, angle_deg, accent, left_lip, right_lip)

func add_container(pos: Vector2, c_type: GameColors.ColorType, req_count: int, width: float = 124.0) -> ColorContainer:
	return LevelSpawner.add_container(self, pos, c_type, req_count, width)

func add_ball(pos: Vector2, c_type: GameColors.ColorType, radius: float = 18.0) -> PuzzleBall:
	return LevelSpawner.add_ball(self, pos, c_type, radius)

func add_cuttable_beam(pos: Vector2, length: float, angle_deg: float, order_hint: int = 1, label_hint: String = "") -> CuttableBeam:
	return LevelSpawner.add_cuttable_beam(self, pos, length, angle_deg, order_hint, label_hint)

func add_cuttable_rope(anchor_pos: Vector2, body: RigidBody2D, rope_offset: Vector2 = Vector2(0, 84.0), impulse: Vector2 = Vector2.ZERO, order_hint: int = 1, label_hint: String = "") -> CuttableRope:
	return LevelSpawner.add_cuttable_rope(self, anchor_pos, body, rope_offset, impulse, order_hint, label_hint)

func add_chain_trigger(pos: Vector2, radius: float = 24.0, consume_steel: bool = true) -> ChainTrigger:
	return LevelSpawner.add_chain_trigger(self, pos, radius, consume_steel)

func add_bumper_pin(pos: Vector2, radius: float = 22.0, impulse: float = 220.0, col: Color = Color(1.0, 0.36, 0.78)) -> BumperPin:
	return LevelSpawner.add_bumper_pin(self, pos, radius, impulse, col)

func add_color_filter_gate(pos: Vector2, allowed_color: GameColors.ColorType, length: float = 120.0, angle_deg: float = 0.0) -> ColorFilterGate:
	return LevelSpawner.add_color_filter_gate(self, pos, allowed_color, length, angle_deg)

func add_color_dye_ring(pos: Vector2, target_color: GameColors.ColorType, radius: float = 28.0) -> ColorDyeRing:
	return LevelSpawner.add_color_dye_ring(self, pos, target_color, radius)

func add_seesaw_bridge(pos: Vector2, length: float = 200.0, initial_deg: float = -18.0, max_tilt: float = 20.0, alternate: bool = true) -> SeesawBridge:
	return LevelSpawner.add_seesaw_bridge(self, pos, length, initial_deg, max_tilt, alternate)

func add_steel_chain(pos: Vector2, length: float = 90.0, angle_deg: float = 0.0) -> SteelChain:
	return LevelSpawner.add_steel_chain(self, pos, length, angle_deg)

func add_portal_pair(entry_pos: Vector2, exit_offset: Vector2, col: Color = Color(0.68, 0.35, 1.0), exit_vel: Vector2 = Vector2.ZERO) -> PortalPair:
	return LevelSpawner.add_portal_pair(self, entry_pos, exit_offset, col, exit_vel)

func add_moving_deflector(pos: Vector2, length: float = 120.0, angle_deg: float = 0.0, move_delta: Vector2 = Vector2(80, 0), speed: float = 1.6, ang_speed: float = 0.0) -> MovingDeflector:
	return LevelSpawner.add_moving_deflector(self, pos, length, angle_deg, move_delta, speed, ang_speed)

func notify_dynamic_activity() -> void:
	_settled_timer = 0.0

func emit_mechanic_sfx(sound_name: String) -> void:
	mechanic_sfx_requested.emit(sound_name)

func spawn_floating_text(world_pos: Vector2, text: String, col: Color) -> void:
	_floating_texts.append({"pos": world_pos, "text": text, "color": col, "age": 0.0})

func _on_cut_performed(item: CuttableBase, world_pt: Vector2) -> void:
	_cuts_made_count += 1
	_settled_timer = 0.0
	_wake_resting_balls()
	spawn_floating_text(world_pt + Vector2(0, -14.0), "SNIP!", Color(1.0, 0.92, 0.4))
	cut_made.emit(item, world_pt)

func _on_chain_activated(trig: ChainTrigger) -> void:
	_settled_timer = 0.0
	_wake_resting_balls()
	spawn_floating_text(trig.global_position + Vector2(0, -24.0), "CHAIN REACTION!", Color(0.3, 1.0, 0.9))
	chain_reaction_triggered.emit()

func _wake_resting_balls() -> void:
	for b in balls:
		if is_instance_valid(b) and not b.is_collected and not b.freeze:
			b.sleeping = false
			if b.linear_velocity.length() < 10.0:
				b.apply_central_impulse(Vector2(0, 2.0))

func _on_ball_collected(container: ColorContainer, _ball: PuzzleBall) -> void:
	if is_finished:
		return
	_settled_timer = 0.0
	var cname := GameColors.get_color_name(container.color_type)
	spawn_floating_text(container.global_position + Vector2(0, -56.0), "+1 %s!" % cname, GameColors.get_light_color(container.color_type))
	_emit_initial_progress()
	_check_win_condition()

func _on_wrong_ball_entered(container: ColorContainer, ball: PuzzleBall) -> void:
	if is_finished:
		return
	var ball_name := GameColors.get_color_name(ball.color_type)
	var bucket_name := GameColors.get_color_name(container.color_type)
	spawn_floating_text(container.global_position + Vector2(0, -60.0), "WRONG COLOR!", Color(1.0, 0.25, 0.25))
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
	if tutorial_guide != null and is_instance_valid(tutorial_guide):
		tutorial_guide.skip_tutorial()
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
	var any_moving := false
	for b in balls:
		if not is_instance_valid(b) or b.is_collected:
			continue
		if b.global_position.y > 1255.0:
			if b.color_type == GameColors.ColorType.STEEL:
				b.is_collected = true
				b.queue_free()
				continue
			var cname := GameColors.get_color_name(b.color_type)
			b.is_collected = true
			_trigger_fail("%s ball fell out of bounds!" % cname)
			return
		if not b.freeze and b.linear_velocity.length() > 14.0:
			any_moving = true

	var all_player_cut := true
	for c in cuttables:
		if is_instance_valid(c) and not c.is_cut and c.hint_order > 0:
			all_player_cut = false
			break

	if all_player_cut and _cuts_made_count > 0 and not any_moving:
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
	draw_rect(Rect2(18.0, 126.0, 684.0, 1094.0), Color(0.24, 0.30, 0.44, 0.35), false, 2.0)
	var font := ThemeDB.fallback_font
	if font != null:
		for item in _floating_texts:
			var age: float = item["age"]
			var col: Color = item["color"]
			col.a = clampf(1.0 - age / 0.95, 0.0, 1.0)
			var p: Vector2 = item["pos"]
			draw_string(font, p + Vector2(-120.0, 0.0), item["text"], HORIZONTAL_ALIGNMENT_CENTER, 240.0, 18, col)
