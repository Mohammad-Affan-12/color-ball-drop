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

static func puzzle_transform(bounds: Rect2, area: Rect2) -> Transform2D:
	var factor := minf(area.size.x / bounds.size.x, area.size.y / bounds.size.y)
	var origin := area.get_center() - bounds.get_center() * factor
	return Transform2D(Vector2(factor, 0), Vector2(0, factor), origin)

## Measure once at spawn, never track falling balls or change physics transforms.
## Include collision geometry, labels, hints and the full travel of moving parts.
static func measure_level(level: LevelController) -> Rect2:
	var bounds := _geometry_bounds(level, level.global_transform.affine_inverse())
	for cup in level.containers:
		bounds = bounds.merge(Rect2(cup.position - Vector2(cup.bucket_width * 0.5 + 20, cup.bucket_height * 0.5 + 24),
			Vector2(cup.bucket_width + 40, cup.bucket_height + 72)))
	for support in level.cuttables:
		bounds = bounds.merge(Rect2(level.to_local(support.get_cut_center_global()) - Vector2(40, 40), Vector2(80, 80)))
	for paddle in level.moving_deflectors:
		var extent := paddle.move_delta.abs() + Vector2.ONE * (paddle.length * 0.5 + paddle.thickness)
		bounds = bounds.merge(Rect2(paddle.position - extent, extent * 2))
	for seesaw in level.seesaws:
		var extent := Vector2.ONE * (seesaw.length * 0.5 + seesaw.thickness)
		bounds = bounds.merge(Rect2(seesaw.position - extent, extent * 2))
	# Retain the entire arena width, including the side-wall travel corridor.
	bounds = bounds.expand(Vector2(0, bounds.get_center().y)).expand(Vector2(720, bounds.get_center().y))
	return bounds.grow(12)

static func _geometry_bounds(node: Node, inverse: Transform2D) -> Rect2:
	var bounds := Rect2()
	if node.name == "ArenaWalls" or node.is_queued_for_deletion():
		return bounds
	if node is CollisionShape2D and node.shape != null:
		bounds = (inverse * node.global_transform) * node.shape.get_rect()
	elif node is CollisionPolygon2D:
		for point in node.polygon:
			var world_point: Vector2 = inverse * node.to_global(point)
			bounds = Rect2(world_point, Vector2(0.01, 0.01)) if not bounds.has_area() else bounds.expand(world_point)
	for child in node.get_children():
		var child_bounds := _geometry_bounds(child, inverse)
		if child_bounds.has_area():
			bounds = child_bounds if not bounds.has_area() else bounds.merge(child_bounds)
	return bounds
