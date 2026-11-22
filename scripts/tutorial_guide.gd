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
	var start := center + Vector2(-62, 0)
	var end := center + Vector2(62, 0)
	var progress := smoothstep(0.08, 0.88, phase)
	var finger := start.lerp(end, progress)
	var alpha := sin(phase * PI)
	# Crisp glowing swipe guide path + arrowhead
	draw_dashed_line(start, end, Color(0.26, 0.93, 0.78, 0.65), 3.0, 9.0)
	draw_line(start, finger, Color(1.0, 0.88, 0.45, alpha * 0.85), 4.0, true)
	draw_polyline(PackedVector2Array([end + Vector2(-10, -8), end, end + Vector2(-10, 8)]), Color(0.26, 0.93, 0.78, 0.85), 2.8, true)
	draw_circle(finger, 16.0, Color(0.26, 0.93, 0.78, alpha * 0.28))
	draw_circle(finger, 8.0, Color(1.0, 1.0, 1.0, alpha * 0.95))
	# Floating pill caption above the target
	var pill_rect := Rect2(center + Vector2(-84, -54), Vector2(168, 32))
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(0.06, 0.12, 0.22, 0.90)
	pill.border_color = Color(0.26, 0.93, 0.78, 0.75)
	pill.set_border_width_all(1)
	pill.set_corner_radius_all(14)
	draw_style_box(pill, pill_rect)
	var font := ThemeDB.fallback_font
	if font != null:
		draw_string(font, pill_rect.position + Vector2(0, 22), tr("SWIPE TO CUT"), HORIZONTAL_ALIGNMENT_CENTER, pill_rect.size.x, 18, UiThemeHelper.TEAL)
