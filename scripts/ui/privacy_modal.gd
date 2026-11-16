class_name PrivacyModal
extends RefCounted

## Renders choices only. AdService exclusively owns Google consent.
var backdrop: ColorRect
var panel: PanelContainer
var analytics_btn: Button
var language_btn: Button

func build(layer: CanvasLayer, on_analytics: Callable, on_ads: Callable, on_language: Callable, on_close: Callable, show_ad_choices: bool = false) -> void:
	panel = UiThemeHelper.modal(layer, Vector2(640, 1160))
	backdrop = panel.get_parent()
	var content := UiThemeHelper.modal_content(panel)
	content.add_child(UiThemeHelper.label("Privacy & data choices", 40))
	content.add_child(UiThemeHelper.label("Your puzzles and progress work offline. No account needed.", 28, UiThemeHelper.MUTED))
	content.add_child(UiThemeHelper.label("Optional analytics sends puzzle events, a random app ID, language and app version to PostHog. Your IP can estimate your country. No GPS, email or advertising ID. Turn off to stop sending and clear the local analytics ID. Previously sent data stays subject to the published privacy policy.", 26, UiThemeHelper.MUTED))
	analytics_btn = UiThemeHelper.action(content, "", on_analytics)
	if show_ad_choices:
		content.add_child(UiThemeHelper.label("Google manages ad privacy separately. Ads need internet. Hints, retries and all puzzles stay free. Advertising may process IP address, device identifiers, interactions and diagnostics.", 26, UiThemeHelper.MUTED))
		UiThemeHelper.action(content, "Google ad privacy options", on_ads)
	var policy_btn := UiThemeHelper.action(content, "Privacy policy", func() -> void:
		var url := str(ProjectSettings.get_setting("release/privacy_policy_url", ""))
		if url.begins_with("https://"):
			OS.shell_open(url)
	)
	policy_btn.disabled = not str(ProjectSettings.get_setting("release/privacy_policy_url", "")).begins_with("https://")
	language_btn = UiThemeHelper.action(content, "", on_language)
	UiThemeHelper.action(content, "Back to puzzle", func() -> void:
		backdrop.hide()
		on_close.call()
	)

func refresh(save: SaveManager) -> void:
	analytics_btn.text = tr("Optional analytics: On") if save.analytics_opt_in else tr("Optional analytics: Off")
	language_btn.text = tr("Language: %s") % TranslationServer.get_locale_name(TranslationServer.get_locale())
