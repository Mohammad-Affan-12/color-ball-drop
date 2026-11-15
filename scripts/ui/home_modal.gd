class_name HomeModal
extends RefCounted

var backdrop: ColorRect
var panel: PanelContainer
var stats_label: Label
var currency_label: Label
var play_btn: Button
var daily_btn: Button
var remove_ads_btn: Button

func build(ui_layer: CanvasLayer, on_play: Callable, on_levels: Callable, on_daily: Callable, on_cosmetics: Callable, on_settings: Callable, on_purchase: Callable, on_close: Callable) -> void:
	panel = UiThemeHelper.modal(ui_layer, Vector2(640, 1160))
	backdrop = panel.get_parent()
	var content := UiThemeHelper.modal_content(panel)
	content.add_child(UiThemeHelper.label("CUT &\nCASCADE", 64, UiThemeHelper.TEAL))
	content.add_child(UiThemeHelper.label("A little cut. A colorful cascade.", 28, UiThemeHelper.MUTED))
	var wallet := PanelContainer.new()
	wallet.add_theme_stylebox_override("panel", UiThemeHelper.create_hud_bar_style())
	content.add_child(wallet)
	var wallet_box := VBoxContainer.new()
	wallet.add_child(wallet_box)
	currency_label = UiThemeHelper.label("", 30, UiThemeHelper.GOLD)
	wallet_box.add_child(currency_label)
	stats_label = UiThemeHelper.label("", 26, UiThemeHelper.MUTED)
	wallet_box.add_child(stats_label)
	play_btn = UiThemeHelper.action(content, "Continue", _navigate.bind(on_play), true)
	UiThemeHelper.action(content, "Choose a level", _navigate.bind(on_levels))
	daily_btn = UiThemeHelper.action(content, "Daily challenge", _navigate.bind(on_daily))
	UiThemeHelper.action(content, "Blade trails", _navigate.bind(on_cosmetics))
	UiThemeHelper.action(content, "Settings", _navigate.bind(on_settings))
	remove_ads_btn = UiThemeHelper.action(content, "Remove Ads", on_purchase)
	remove_ads_btn.hide() # No purchase offer until real verified billing exists.
	UiThemeHelper.action(content, "Back to puzzle", _navigate.bind(on_close))

func _navigate(callback: Callable) -> void:
	backdrop.hide()
	callback.call()

func refresh(save: SaveManager) -> void:
	currency_label.text = tr("%d coins   ·   %d / 300 stars") % [save.coins, save.get_total_stars()]
	stats_label.text = tr("Level %d of 100 unlocked · %d day streak") % [save.highest_unlocked_level, save.daily_streak]
	play_btn.text = tr("Continue · Level %d") % save.highest_unlocked_level
	daily_btn.text = "Daily challenge · " + ("Completed" if save.is_daily_completed(DailyChallenge.get_today_date_string()) else "+75 coins")
	remove_ads_btn.hide()
