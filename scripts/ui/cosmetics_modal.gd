class_name CosmeticsModal
extends RefCounted

class TrailPreviewBar extends Control:
	var trail_def: Dictionary = {}

	func _ready() -> void:
		custom_minimum_size = Vector2(0, 44)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 10.0 or h <= 10.0:
			return
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("0b1629")
		bg.border_color = Color("26406b")
		bg.set_border_width_all(1)
		bg.set_corner_radius_all(14)
		draw_style_box(bg, Rect2(Vector2.ZERO, size))

		var is_rainbow := bool(trail_def.get("is_rainbow", false))
		var outer: Color = trail_def.get("outer_color", UiThemeHelper.TEAL)
		var core: Color = trail_def.get("core_color", Color.WHITE)
		var spark: Color = trail_def.get("spark_color", UiThemeHelper.GOLD)

		var segs := 14
		var x0 := 22.0
		var x1 := w - 22.0
		var mid := h * 0.5
		for i in range(segs):
			var t0 := float(i) / float(segs)
			var t1 := float(i + 1) / float(segs)
			var p0 := Vector2(lerpf(x0, x1, t0), mid + sin(t0 * PI * 2.0) * 8.0)
			var p1 := Vector2(lerpf(x0, x1, t1), mid + sin(t1 * PI * 2.0) * 8.0)
			var width := lerpf(4.0, 12.0, sin(t0 * PI))
			var col := Color.from_hsv(t0, 0.85, 1.0, 0.78) if is_rainbow else outer
			draw_line(p0, p1, col, width + 5.0, true)
			draw_line(p0, p1, core, maxf(width * 0.45, 2.0), true)

		# Spark accents along the blade curve
		for s in [0.28, 0.54, 0.78]:
			var sx := lerpf(x0, x1, s)
			var sy := mid + sin(s * PI * 2.0) * 8.0
			draw_circle(Vector2(sx, sy), 4.5, Color(spark.r, spark.g, spark.b, 0.9))

## Read-only inventory presentation; equip/purchase callbacks belong to Main.
var backdrop: ColorRect
var panel: PanelContainer
var list_vbox: VBoxContainer
var star_chest_label: Label
var _on_action: Callable

func build(ui_layer: CanvasLayer, on_close: Callable, on_action: Callable) -> void:
	_on_action = on_action
	panel = UiThemeHelper.modal(ui_layer, Vector2(650, 1160))
	backdrop = panel.get_parent()
	var content := UiThemeHelper.modal_content(panel)
	content.add_child(UiThemeHelper.label("Blade Trails", 42, UiThemeHelper.TEXT))
	content.add_child(UiThemeHelper.label("CUSTOMIZE YOUR SLASH", 24, UiThemeHelper.TEAL))
	star_chest_label = UiThemeHelper.label("", 26, UiThemeHelper.GOLD)
	content.add_child(star_chest_label)
	list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 18)
	content.add_child(list_vbox)
	UiThemeHelper.action(content, "Back to puzzle", func() -> void:
		backdrop.hide()
		on_close.call()
	)

func refresh(save: SaveManager) -> void:
	for child in list_vbox.get_children():
		list_vbox.remove_child(child)
		child.queue_free()
	star_chest_label.text = "%d coins   ·   ★ %d / 300 stars\nUnlock with coins or free at star milestones" % [save.coins, save.get_total_stars()]
	for item in CosmeticsCatalog.get_all_trails():
		var id: String = item["id"]
		var owned := save.owned_cosmetics.has(id)
		var equipped := save.equipped_cosmetic == id
		var cost: int = item.get("coin_cost", 0)
		var star_req: int = item.get("star_milestone", 0)

		var card := PanelContainer.new()
		var border := UiThemeHelper.TEAL if equipped else (UiThemeHelper.GOLD if owned else UiThemeHelper.BORDER_SUBTLE)
		card.add_theme_stylebox_override("panel", UiThemeHelper.create_card_style(Color("142645"), border))
		list_vbox.add_child(card)

		var details := VBoxContainer.new()
		details.add_theme_constant_override("separation", 10)
		card.add_child(details)

		details.add_child(UiThemeHelper.label(item["name"], 30, item.get("spark_color", Color.WHITE)))

		var preview := TrailPreviewBar.new()
		preview.trail_def = item
		details.add_child(preview)

		var desc_text: String = item.get("desc", "")
		if not owned and star_req > 0:
			desc_text += "  ·  Free at %d ★" % star_req
		details.add_child(UiThemeHelper.label(desc_text, 24, UiThemeHelper.MUTED))

		var caption := "✓ Equipped" if equipped else ("Equip" if owned else "Unlock · %d coins" % cost)
		var button := UiThemeHelper.action(details, caption, _on_action.bind(id), owned and not equipped)
		button.disabled = equipped or (not owned and save.coins < cost)
