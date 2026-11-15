class_name MobileLayout
extends RefCounted

## Presentation geometry only; the original physics world stays unchanged.
static func safe_insets(viewport: Viewport) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var window_size := Vector2(DisplayServer.window_get_size())
	if safe.size.x <= 0.0 or window_size.x <= 0.0:
		return Vector4.ZERO
	var ratio := viewport.get_visible_rect().size / window_size
	return Vector4(safe.position.x * ratio.x, safe.position.y * ratio.y,
		maxf(0, window_size.x - safe.end.x) * ratio.x,
		maxf(0, window_size.y - safe.end.y) * ratio.y)

static func fit_modal(panel: PanelContainer, viewport_size: Vector2, insets: Vector4) -> void:
	var preferred: Vector2 = panel.get_meta("preferred_size", Vector2(640, 1100))
	var available := viewport_size - Vector2(insets.x + insets.z + 48, insets.y + insets.w + 48)
	var fitted := preferred.min(available)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = (insets.x - insets.z - fitted.x) * 0.5
	panel.offset_top = (insets.y - insets.w - fitted.y) * 0.5
	panel.offset_right = panel.offset_left + fitted.x
	panel.offset_bottom = panel.offset_top + fitted.y
	panel.pivot_offset = fitted * 0.5

static func puzzle_transform(viewport_size: Vector2, insets: Vector4) -> Transform2D:
	var top := insets.y + 232.0
	var bottom := viewport_size.y - insets.w - 224.0
	var width := viewport_size.x - insets.x - insets.z
	var factor := minf((width - 40.0) / 720.0, (bottom - top) / 1040.0)
	var origin := Vector2(insets.x + (width - 720.0 * factor) * 0.5,
		top + (bottom - top - 1040.0 * factor) * 0.5 - 140.0 * factor)
	return Transform2D(Vector2(factor, 0), Vector2(0, factor), origin)
