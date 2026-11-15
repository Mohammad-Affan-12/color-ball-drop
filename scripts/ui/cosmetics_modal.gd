class_name CosmeticsModal
extends RefCounted

## Read-only inventory presentation; equip/purchase callbacks belong to Main.
var backdrop: ColorRect
var panel: PanelContainer
var list_vbox: VBoxContainer
var star_chest_label: Label
var _on_action: Callable

func build(ui_layer: CanvasLayer, on_close: Callable, on_action: Callable) -> void:
	_on_action = on_action
	panel = UiThemeHelper.modal(ui_layer, Vector2(640, 1160))
	backdrop = panel.get_parent()
	var content := UiThemeHelper.modal_content(panel)
	content.add_child(UiThemeHelper.label("A cut above", 44))
	content.add_child(UiThemeHelper.label("BLADE TRAILS & STAR CHESTS", 26, UiThemeHelper.TEAL))
	star_chest_label = UiThemeHelper.label("", 28, UiThemeHelper.GOLD)
	content.add_child(star_chest_label)
	list_vbox = VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 24)
	content.add_child(list_vbox)
	UiThemeHelper.action(content, "Back to puzzle", func() -> void:
		backdrop.hide()
		on_close.call()
	)

func refresh(save: SaveManager) -> void:
	for child in list_vbox.get_children():
		list_vbox.remove_child(child)
		child.queue_free()
	star_chest_label.text = "%d coins · %d / 300 stars\nStar chests unlock from 10 to 190 stars" % [save.coins, save.get_total_stars()]
	for item in CosmeticsCatalog.get_all_trails():
		var id: String = item["id"]
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiThemeHelper.create_hud_bar_style())
		list_vbox.add_child(card)
		var details := VBoxContainer.new()
		card.add_child(details)
		details.add_child(UiThemeHelper.label(item["name"], 32, item.get("spark_color", Color.WHITE)))
		details.add_child(UiThemeHelper.label(item.get("desc", ""), 28, UiThemeHelper.MUTED))
		var owned := save.owned_cosmetics.has(id)
		var equipped := save.equipped_cosmetic == id
		var cost: int = item.get("coin_cost", 0)
		var caption := "Equipped" if equipped else ("Equip" if owned else "Unlock · %d coins" % cost)
		var button := UiThemeHelper.action(details, caption, _on_action.bind(id), owned)
		button.disabled = equipped or (not owned and save.coins < cost)
