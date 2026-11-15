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
	if level_controller == null or level_controller.level_number != 1 or not _has_target:
		return
	var center := to_local(_display_center)
	var phase := fmod(_anim_t, 1.0)
	var start := center + Vector2(-52, 0)
	var end := center + Vector2(52, 0)
	var finger := start.lerp(end, smoothstep(0.08, 0.88, phase))
	var alpha := sin(phase * PI)
	draw_dashed_line(start, end, Color(0.45, 0.91, 0.80, 0.5), 2, 8)
	draw_circle(finger, 12, Color(0.45, 0.91, 0.80, alpha * 0.25))
	draw_circle(finger, 6, Color(1, 1, 1, alpha * 0.9))
