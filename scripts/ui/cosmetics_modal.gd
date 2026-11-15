class_name CosmeticsModal
extends RefCounted

## Single-responsibility controller for Blade Trails & Star Chests progression modal.

var backdrop: ColorRect
var panel: PanelContainer
var list_vbox: VBoxContainer
var star_chest_label: Label

func build(ui_layer: CanvasLayer, on_click_sfx: Callable) -> void:
	backdrop = ColorRect.new()
	backdrop.color = Color(0.02, 0.04, 0.09, 0.90)
	backdrop.size = Vector2(UiThemeHelper.BASE_WIDTH, UiThemeHelper.BASE_HEIGHT)
	backdrop.visible = false
	ui_layer.add_child(backdrop)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(628, 940)
	panel.position = Vector2(46, 130)
	panel.add_theme_stylebox_override("panel", UiThemeHelper.create_modal_style(Color(0.82, 0.54, 1.0, 0.94)))
	backdrop.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var header := Label.new()
	header.text = "BLADE TRAILS & STAR CHESTS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 25)
	header.add_theme_color_override("font_color", Color(0.96, 0.90, 1.0))
	vbox.add_child(header)

	star_chest_label = Label.new()
	star_chest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_chest_label.add_theme_font_size_override("font_size", 15)
	star_chest_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(star_chest_label)

	list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	list_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(list_vbox)

	var close_btn := UiThemeHelper.create_styled_button("Close ✕", Color(0.22, 0.26, 0.38), Color(0.68, 0.80, 0.98))
	close_btn.custom_minimum_size = Vector2(240, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void:
		on_click_sfx.call()
		backdrop.visible = false
	)
	vbox.add_child(close_btn)

func refresh(
	save_manager: SaveManager,
	slice_controller: SliceController,
	sfx: SfxManager,
	analytics: AnalyticsService,
	on_hud_refresh: Callable
) -> void:
	if list_vbox == null or save_manager == null:
		return
	for child in list_vbox.get_children():
		child.queue_free()

	var total_stars: int = save_manager.get_total_stars()
	var coins: int = save_manager.coins
	star_chest_label.text = "Total Stars: ★ %d / 300  •  Coins: 💰 %d  (Star Chests auto-unlock trails at 10★–190★!)" % [total_stars, coins]

	for raw_item in CosmeticsCatalog.get_all_trails():
		var item: Dictionary = raw_item as Dictionary
		var tid: String = String(item.get("id", "classic_slash"))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		list_vbox.add_child(row)

		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(28, 38)
		swatch.color = item.get("spark_color", Color.WHITE)
		row.add_child(swatch)

		var info_lbl := Label.new()
		info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cost: int = int(item.get("coin_cost", 0))
		var ms: int = int(item.get("star_milestone", 0))
		var ms_note: String = " [Star Chest: %d★]" % ms if ms > 0 else ""
		info_lbl.text = "%s — %s%s" % [String(item.get("name", tid)), String(item.get("desc", "")), ms_note]
		info_lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(info_lbl)

		var is_unlocked: bool = save_manager.owned_cosmetics.has(tid)
		var is_equipped: bool = save_manager.equipped_cosmetic == tid
		var action_btn: Button
		if is_equipped:
			action_btn = UiThemeHelper.create_styled_button("Equipped ✓", Color(0.14, 0.44, 0.26), Color(0.45, 1.0, 0.65))
			action_btn.disabled = true
		elif is_unlocked:
			action_btn = UiThemeHelper.create_styled_button("Equip", Color(0.18, 0.30, 0.48), Color(0.55, 0.85, 1.0))
			var equip_id: String = tid
			action_btn.pressed.connect(func() -> void:
				sfx.play("ui_click")
				save_manager.equip_cosmetic(equip_id)
				slice_controller.current_trail_id = equip_id
				refresh(save_manager, slice_controller, sfx, analytics, on_hud_refresh)
			)
		else:
			action_btn = UiThemeHelper.create_styled_button("Unlock (%d 💰)" % cost, Color(0.32, 0.24, 0.10), Color(1.0, 0.84, 0.28))
			action_btn.disabled = coins < cost
			var buy_id: String = tid
			action_btn.pressed.connect(func() -> void:
				if save_manager.unlock_cosmetic_with_coins(buy_id):
					sfx.play("star")
					slice_controller.current_trail_id = buy_id
					if analytics != null:
						analytics.log_event("cosmetic_unlocked", {"trail_id": buy_id})
					on_hud_refresh.call()
					refresh(save_manager, slice_controller, sfx, analytics, on_hud_refresh)
			)
		action_btn.custom_minimum_size = Vector2(150, 38)
		row.add_child(action_btn)
