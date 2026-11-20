class_name CuttableBase
extends Node2D

signal cut_performed(item: CuttableBase, world_cut_point: Vector2)

@export var hint_order: int = 0
@export var hint_label: String = ""

var is_cut: bool = false
var show_hint: bool = false
var _hint_pulse: float = 0.0
var _redraw_accum: float = 0.0

func _process(delta: float) -> void:
	_hint_pulse += delta * 4.0
	if not is_cut:
		_redraw_accum += delta
		if _redraw_accum >= 0.066:
			_redraw_accum = 0.0
			queue_redraw()

## Returns the intersection point in global coordinates if segment (world_a, world_b) cuts this object,
## or Vector2.INF if no intersection.
func check_segment_cut(_world_a: Vector2, _world_b: Vector2) -> Vector2:
	return Vector2.INF

## Executes the cut at world_point
func perform_cut(world_point: Vector2, _swipe_dir: Vector2 = Vector2.RIGHT) -> void:
	if is_cut:
		return
	is_cut = true
	cut_performed.emit(self, world_point)
	queue_redraw()

func get_cut_center_global() -> Vector2:
	return global_position

## Draws an unmistakable interactive slice cue across the cuttable midpoint.
func draw_cut_cue(center_pos: Vector2, normal_dir: Vector2, half_span: float) -> void:
	if is_cut:
		return
	var is_trap := show_hint and (hint_label == "✖")
	var pulse := 0.55 + 0.35 * sin(_hint_pulse)
	var cue_col := Color(1.0, 0.35, 0.35, pulse) if is_trap else Color(1.0, 0.94, 0.48, pulse)
	var glow_col := Color(1.0, 0.25, 0.25, pulse * 0.28) if is_trap else Color(0.38, 0.95, 1.0, pulse * 0.30)

	var p1 := center_pos - normal_dir * half_span
	var p2 := center_pos + normal_dir * half_span
	draw_line(p1, p2, glow_col, 6.0, true)

	var segments := 5
	for i in range(segments):
		if i % 2 == 0:
			var t0 := float(i) / float(segments)
			var t1 := float(i + 1) / float(segments)
			draw_line(p1.lerp(p2, t0), p1.lerp(p2, t1), cue_col, 2.2, true)

	draw_circle(center_pos, 4.5, Color(0.08, 0.12, 0.20, 0.9))
	draw_arc(center_pos, 4.5, 0.0, TAU, 16, cue_col, 1.8, true)

func draw_hint_badge(local_pos: Vector2) -> void:
	if not show_hint or is_cut:
		return
	# Keep order numbers upright even when the supporting beam is rotated.
	draw_set_transform(local_pos, -global_rotation, Vector2.ONE)
	local_pos = Vector2.ZERO
	var is_trap := (hint_label == "✖")
	var r := 23.0 + sin(_hint_pulse) * 1.5
	var ring_col := Color(1.0, 0.36, 0.36) if is_trap else Color(1.0, 0.88, 0.25)
	draw_circle(local_pos, r + 3.5, Color(ring_col.r, ring_col.g, ring_col.b, 0.32))
	draw_circle(local_pos, r, Color(0.09, 0.13, 0.22, 0.95))
	draw_arc(local_pos, r, 0.0, TAU, 24, ring_col, 2.5, true)
	var font := ThemeDB.fallback_font
	if font != null:
		var text := hint_label if not hint_label.is_empty() else (str(hint_order) if hint_order > 0 else "✂")
		draw_string(font, local_pos + Vector2(-r, 9.0), text, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 26, ring_col.lightened(0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
