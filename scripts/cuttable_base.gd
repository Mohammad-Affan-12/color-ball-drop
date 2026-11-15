class_name CuttableBase
extends Node2D

signal cut_performed(item: CuttableBase, world_cut_point: Vector2)

@export var hint_order: int = 0
@export var hint_label: String = ""

var is_cut: bool = false
var show_hint: bool = false
var _hint_pulse: float = 0.0

func _process(delta: float) -> void:
	_hint_pulse += delta * 4.0
	if show_hint and not is_cut:
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

func draw_hint_badge(local_pos: Vector2) -> void:
	if not show_hint or is_cut:
		return
	var r := 16.0 + sin(_hint_pulse) * 2.5
	draw_circle(local_pos, r + 3.0, Color(1.0, 0.92, 0.2, 0.32))
	draw_circle(local_pos, r, Color(0.12, 0.14, 0.22, 0.92))
	draw_arc(local_pos, r, 0.0, TAU, 24, Color(1.0, 0.88, 0.25), 2.5, true)
	var font := ThemeDB.fallback_font
	if font != null:
		var text := hint_label if not hint_label.is_empty() else (str(hint_order) if hint_order > 0 else "✂")
		draw_string(
			font,
			local_pos + Vector2(-r, 6.0),
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			r * 2.0,
			15,
			Color(1.0, 0.95, 0.4)
		)
