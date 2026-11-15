class_name TutorialGuide
extends Node2D

var level_controller: LevelController = null
var active: bool = true
var contextual_tip: String = ""
var contextual_pos: Vector2 = Vector2(360, 260)

var _anim_t: float = 0.0
var _display_center: Vector2 = Vector2.ZERO
var _has_target: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 35

func setup(lc: LevelController, tip_text: String = "", tip_pos: Vector2 = Vector2(360, 240)) -> void:
	level_controller = lc
	contextual_tip = tip_text
	contextual_pos = tip_pos
	_update_target(1.0)

func skip_tutorial() -> void:
	active = false
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	_anim_t += delta * 1.4
	_update_target(delta * 10.0)
	queue_redraw()

func _update_target(lerp_weight: float) -> void:
	if level_controller == null or not is_instance_valid(level_controller):
		_has_target = false
		return

	var best_item: CuttableBase = null
	var best_order := 9999
	for c in level_controller.cuttables:
		if is_instance_valid(c) and not c.is_cut and c.hint_order > 0:
			if c.hint_order < best_order:
				best_order = c.hint_order
				best_item = c

	if best_item != null:
		var target_pt := best_item.get_cut_center_global()
		if not _has_target:
			_display_center = target_pt
			_has_target = true
		else:
			_display_center = _display_center.lerp(target_pt, clampf(lerp_weight, 0.0, 1.0))
	else:
		_has_target = false

func _draw() -> void:
	if not active:
		return
	var font := ThemeDB.fallback_font

	if level_controller != null and level_controller.level_number == 1 and _has_target:
		var local_c := to_local(_display_center)
		var phase := fmod(_anim_t, 1.0)
		var p_start := local_c + Vector2(-52.0, 0.0)
		var p_end := local_c + Vector2(52.0, 0.0)
		var finger_pos := p_start.lerp(p_end, smoothstep(0.08, 0.88, phase))
		var alpha := sin(phase * PI)

		# Target pulsing ring
		var pulse_r := 28.0 + sin(_anim_t * 4.0) * 4.0
		draw_arc(local_c, pulse_r, 0.0, TAU, 28, Color(1.0, 0.92, 0.28, 0.65), 3.0, true)

		# Dashed swipe guide path
		draw_dashed_line(p_start, p_end, Color(0.4, 0.95, 1.0, 0.65), 3.0, 8.0)

		# Animated swipe trail behind pointer
		draw_line(p_start, finger_pos, Color(0.35, 0.95, 1.0, alpha * 0.78), 6.0, true)

		# Glowing pointer circle
		draw_circle(finger_pos, 14.0, Color(0.15, 0.88, 1.0, alpha * 0.45))
		draw_circle(finger_pos, 8.5, Color(1.0, 1.0, 1.0, alpha * 0.95))

		if font != null:
			var pill_rect := Rect2(local_c.x - 84.0, local_c.y - 56.0, 168.0, 26.0)
			draw_rect(pill_rect, Color(0.08, 0.12, 0.22, 0.88), true)
			draw_rect(pill_rect, Color(0.38, 0.88, 1.0, 0.8), false, 1.5)
			draw_string(
				font,
				Vector2(local_c.x - 84.0, local_c.y - 38.0),
				"SWIPE ACROSS TO CUT",
				HORIZONTAL_ALIGNMENT_CENTER,
				168.0,
				13,
				Color(1.0, 0.96, 0.55)
			)
	elif not contextual_tip.is_empty() and _anim_t < 6.0:
		if font != null:
			var fade := clampf(6.0 - _anim_t, 0.0, 1.0)
			var lp := to_local(contextual_pos)
			var rect := Rect2(lp.x - 160.0, lp.y - 18.0, 320.0, 30.0)
			draw_rect(rect, Color(0.08, 0.12, 0.22, 0.86 * fade), true)
			draw_rect(rect, Color(1.0, 0.86, 0.32, 0.75 * fade), false, 1.5)
			draw_string(
				font,
				Vector2(lp.x - 156.0, lp.y + 2.0),
				contextual_tip,
				HORIZONTAL_ALIGNMENT_CENTER,
				312.0,
				14,
				Color(1.0, 0.96, 0.65, fade)
			)
