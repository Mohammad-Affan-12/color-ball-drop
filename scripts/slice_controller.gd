class_name SliceController
extends Node2D

signal object_sliced(item: CuttableBase, cut_point: Vector2, cuts_in_swipe: int)
signal valid_move_performed(total_cuts_in_move: int)
signal invalid_swipe_performed()
signal uncuttable_rejected(chain: SteelChain, hit_point: Vector2)

var enabled: bool = true
var vibration_enabled: bool = true
var current_trail_id: String = "classic_slash":
	set(value):
		current_trail_id = value
		_trail_def = CosmeticsCatalog.get_trail_def(value)
		if _slash_particles != null:
			_slash_particles.color = _trail_def.get("spark_color", Color(1.0, 0.94, 0.48))
		queue_redraw()

var _trail_def: Dictionary = CosmeticsCatalog.get_trail_def("classic_slash")
var _is_dragging: bool = false
var _using_touch: bool = false
var _last_point: Vector2 = Vector2.ZERO
var _start_point: Vector2 = Vector2.ZERO
var _cuts_in_current_swipe: int = 0
var _active_touch_index: int = -1
var _rejected_in_current_swipe: Dictionary = {}

var _trail_points: Array[Dictionary] = []
var _cut_flashes: Array[Dictionary] = []
var _slash_particles: CPUParticles2D
var _rainbow_hue: float = 0.0

const TRAIL_LIFETIME := 0.24
const FLASH_LIFETIME := 0.28
const HUD_TOP_LIMIT_Y := 122.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 40
	_trail_def = CosmeticsCatalog.get_trail_def(current_trail_id)
	_slash_particles = CPUParticles2D.new()
	_slash_particles.emitting = false
	_slash_particles.one_shot = true
	_slash_particles.amount = 18
	_slash_particles.lifetime = 0.32
	_slash_particles.explosiveness = 0.92
	_slash_particles.spread = 180.0
	_slash_particles.gravity = Vector2(0, 180.0)
	_slash_particles.initial_velocity_min = 110.0
	_slash_particles.initial_velocity_max = 230.0
	_slash_particles.scale_amount_min = 3.0
	_slash_particles.scale_amount_max = 6.5
	_slash_particles.color = _trail_def.get("spark_color", Color(1.0, 0.94, 0.48))
	add_child(_slash_particles)

func screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos

func world_to_screen(world_pos: Vector2) -> Vector2:
	return get_canvas_transform() * world_pos

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or get_tree().paused:
		_is_dragging = false
		_using_touch = false
		_active_touch_index = -1
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var world_pos := screen_to_world(st.position)
		if st.pressed:
			if _active_touch_index == -1 and world_pos.y >= HUD_TOP_LIMIT_Y:
				_active_touch_index = st.index
				_using_touch = true
				_start_swipe(world_pos)
		else:
			if st.index == _active_touch_index:
				_active_touch_index = -1
				_end_swipe()
				_using_touch = false
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _active_touch_index == -1 or sd.index == _active_touch_index:
			var world_pos := screen_to_world(sd.position)
			if not _is_dragging:
				if world_pos.y >= HUD_TOP_LIMIT_Y:
					_active_touch_index = sd.index
					_using_touch = true
					_start_swipe(world_pos)
			else:
				_continue_swipe(world_pos)
	elif event is InputEventMouseButton:
		if _using_touch:
			return
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var world_pos := screen_to_world(mb.position)
			if mb.pressed:
				if world_pos.y >= HUD_TOP_LIMIT_Y:
					_start_swipe(world_pos)
			else:
				_end_swipe()
	elif event is InputEventMouseMotion and _is_dragging:
		if _using_touch:
			return
		var mm := event as InputEventMouseMotion
		_continue_swipe(screen_to_world(mm.position))

func _start_swipe(world_pos: Vector2) -> void:
	_is_dragging = true
	_start_point = world_pos
	_last_point = world_pos
	_cuts_in_current_swipe = 0
	_rejected_in_current_swipe.clear()
	_add_trail_point(world_pos, false)

func _continue_swipe(world_pos: Vector2) -> void:
	if not _is_dragging:
		return
	if _last_point.distance_to(world_pos) < 2.0:
		return
	var newly_cut := _check_cuts_along_segment(_last_point, world_pos)
	_last_point = world_pos
	_add_trail_point(world_pos, _cuts_in_current_swipe > 0 or newly_cut > 0)

func _end_swipe() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	if _cuts_in_current_swipe > 0:
		valid_move_performed.emit(_cuts_in_current_swipe)
	else:
		if _start_point.distance_to(_last_point) >= 8.0:
			invalid_swipe_performed.emit()
	_cuts_in_current_swipe = 0
	_rejected_in_current_swipe.clear()

func simulate_swipe(world_from: Vector2, world_to: Vector2) -> int:
	_start_swipe(world_from)
	var steps := 8
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		_continue_swipe(world_from.lerp(world_to, t))
	var total_sliced := _cuts_in_current_swipe
	_end_swipe()
	return total_sliced

func dispatch_real_touch_swipe(world_from: Vector2, world_to: Vector2, steps: int = 8) -> void:
	var screen_from := world_to_screen(world_from)
	var screen_to := world_to_screen(world_to)

	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.pressed = true
	touch_down.position = screen_from
	get_viewport().push_input(touch_down, true)

	var prev_screen := screen_from
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var cur_screen := screen_from.lerp(screen_to, t)
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = cur_screen
		drag.relative = cur_screen - prev_screen
		prev_screen = cur_screen
		get_viewport().push_input(drag, true)

	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.pressed = false
	touch_up.position = screen_to
	get_viewport().push_input(touch_up, true)

func _add_trail_point(pos: Vector2, hit_hot: bool) -> void:
	_trail_points.append({
		"pos": pos,
		"age": 0.0,
		"hot": hit_hot
	})
	if _trail_points.size() > 32:
		_trail_points.pop_front()
	queue_redraw()

func _add_cut_flash(world_pt: Vector2, dir: Vector2, col: Color = Color(1.0, 0.92, 0.38)) -> void:
	_cut_flashes.append({
		"pos": world_pt,
		"dir": dir if dir.length_squared() > 0.01 else Vector2.RIGHT,
		"color": col,
		"age": 0.0
	})
	queue_redraw()

func _check_cuts_along_segment(world_a: Vector2, world_b: Vector2) -> int:
	var cut_count := 0
	var dir := (world_b - world_a).normalized()

	# Check uncuttable obstacles first for deflection feedback (consumes 0 moves)
	var uncuttables := get_tree().get_nodes_in_group("uncuttables")
	for u_node in uncuttables:
		if u_node is SteelChain:
			var chain := u_node as SteelChain
			var cid := chain.get_instance_id()
			if not _rejected_in_current_swipe.has(cid):
				var r_pt := chain.check_segment_hit(world_a, world_b)
				if r_pt != Vector2.INF:
					_rejected_in_current_swipe[cid] = true
					chain.trigger_reject_feedback(r_pt)
					_add_cut_flash(r_pt, dir, Color(1.0, 0.32, 0.32))
					uncuttable_rejected.emit(chain, r_pt)

	# Check eligible cuttable supports
	var nodes := get_tree().get_nodes_in_group("cuttables")
	for node in nodes:
		if node is CuttableBase:
			var cuttable := node as CuttableBase
			if not cuttable.is_cut:
				var hit_pt := cuttable.check_segment_cut(world_a, world_b)
				if hit_pt != Vector2.INF:
					cuttable.perform_cut(hit_pt, dir)
					_cuts_in_current_swipe += 1
					cut_count += 1
					_slash_particles.global_position = hit_pt
					_slash_particles.restart()
					_slash_particles.emitting = true
					_add_cut_flash(hit_pt, dir, _trail_def.get("spark_color", Color(1.0, 0.92, 0.38)))
					if vibration_enabled and DisplayServer.get_name() != "headless":
						Input.vibrate_handheld(22)
					object_sliced.emit(cuttable, hit_pt, _cuts_in_current_swipe)
	return cut_count

func _process(delta: float) -> void:
	_rainbow_hue = fmod(_rainbow_hue + delta * 1.4, 1.0)
	var needs_redraw := false
	if not _trail_points.is_empty():
		var i := _trail_points.size() - 1
		while i >= 0:
			_trail_points[i]["age"] += delta
			if _trail_points[i]["age"] >= TRAIL_LIFETIME:
				_trail_points.remove_at(i)
			i -= 1
		needs_redraw = true

	if not _cut_flashes.is_empty():
		var j := _cut_flashes.size() - 1
		while j >= 0:
			_cut_flashes[j]["age"] += delta
			if _cut_flashes[j]["age"] >= FLASH_LIFETIME:
				_cut_flashes.remove_at(j)
			j -= 1
		needs_redraw = true

	if needs_redraw:
		queue_redraw()

func _draw() -> void:
	var is_rainbow := bool(_trail_def.get("is_rainbow", false))
	var base_outer: Color = _trail_def.get("outer_color", Color(0.22, 0.86, 1.0, 0.45))
	var base_core: Color = _trail_def.get("core_color", Color(0.88, 0.98, 1.0, 0.92))
	var hot_outer: Color = _trail_def.get("hot_outer", Color(1.0, 0.78, 0.22, 0.55))
	var hot_core: Color = _trail_def.get("hot_core", Color(1.0, 0.98, 0.82, 0.98))

	if _trail_points.size() >= 2:
		for i in range(_trail_points.size() - 1):
			var p1: Vector2 = to_local(_trail_points[i]["pos"])
			var p2: Vector2 = to_local(_trail_points[i + 1]["pos"])
			var age: float = _trail_points[i + 1]["age"]
			var is_hot: bool = _trail_points[i + 1]["hot"]
			var life_ratio := clampf(1.0 - age / TRAIL_LIFETIME, 0.0, 1.0)
			var width := maxf(life_ratio * 12.0, 1.5)
			var outer_col := hot_outer if is_hot else base_outer
			var core_col := hot_core if is_hot else base_core
			if is_rainbow:
				var h := fmod(_rainbow_hue + float(i) * 0.04, 1.0)
				outer_col = Color.from_hsv(h, 0.85, 1.0, 0.62)
			outer_col.a *= life_ratio
			core_col.a *= life_ratio
			draw_line(p1, p2, outer_col, width + 6.0, true)
			draw_line(p1, p2, core_col, width, true)

	for flash in _cut_flashes:
		var pt: Vector2 = to_local(flash["pos"])
		var dir: Vector2 = flash["dir"]
		var col: Color = flash.get("color", Color(1.0, 0.92, 0.38))
		var age: float = flash["age"]
		var t := clampf(age / FLASH_LIFETIME, 0.0, 1.0)
		var alpha := 1.0 - t
		var radius := lerpf(8.0, 38.0, t)
		draw_arc(pt, radius, 0.0, TAU, 24, Color(col.r, col.g, col.b, alpha * 0.85), maxf(3.5 * alpha, 1.0), true)
		var slash_len := lerpf(16.0, 44.0, t)
		draw_line(pt - dir * slash_len, pt + dir * slash_len, Color(1.0, 1.0, 0.9, alpha), 3.0, true)
