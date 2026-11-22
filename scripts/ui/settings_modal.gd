class_name SettingsModal
extends RefCounted

## Preferences are changed and persisted by Main; this class only renders them.
var backdrop: ColorRect
var panel: PanelContainer
var sfx_btn: Button
var music_btn: Button
var haptics_btn: Button
var colorblind_btn: Button
var particles_btn: Button
var language_btn: Button
var consent_btn: Button
var reset_btn: Button
var status_label: Label
var _reset_armed: bool = false
var _on_reset_confirmed: Callable

func build(ui_layer: CanvasLayer, app_version: String, on_sfx: Callable, on_music: Callable, on_haptics: Callable, on_colorblind: Callable, on_particles: Callable, on_consent: Callable, on_restore: Callable, on_reset: Callable, on_close: Callable, on_language: Callable = Callable()) -> void:
	_on_reset_confirmed = on_reset
	panel = UiThemeHelper.modal(ui_layer, Vector2(640, 1160))
	backdrop = panel.get_parent()
	var content := UiThemeHelper.modal_content(panel)
	content.add_child(UiThemeHelper.label("Settings", 42, UiThemeHelper.TEXT))
	content.add_child(UiThemeHelper.label("AUDIO · ACCESSIBILITY · DATA", 24, UiThemeHelper.TEAL))

	sfx_btn = UiThemeHelper.action(content, "", on_sfx)
	music_btn = UiThemeHelper.action(content, "", on_music)
	haptics_btn = UiThemeHelper.action(content, "", on_haptics)
	colorblind_btn = UiThemeHelper.action(content, "", on_colorblind)
	particles_btn = UiThemeHelper.action(content, "", on_particles)
	if on_language.is_valid():
		language_btn = UiThemeHelper.action(content, "", on_language)
	consent_btn = UiThemeHelper.action(content, "", on_consent)

	var restore := UiThemeHelper.action(content, "Restore purchases", on_restore)
	restore.hide()

	reset_btn = UiThemeHelper.danger_action(content, "Reset local progress", _on_reset_pressed)

	status_label = UiThemeHelper.label(tr("Version %s · Offline Ready") % app_version, 24, UiThemeHelper.MUTED)
	content.add_child(status_label)

	UiThemeHelper.action(content, "Back to puzzle", func() -> void:
		_disarm_reset()
		backdrop.hide()
		on_close.call()
	)

func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		reset_btn.text = tr("Tap again to confirm reset")
		status_label.text = tr("Warning: resets levels, stars & coins")
		return
	_disarm_reset()
	if _on_reset_confirmed.is_valid():
		_on_reset_confirmed.call()

func _disarm_reset() -> void:
	_reset_armed = false
	if reset_btn != null:
		reset_btn.text = tr("Reset local progress")

const LOCALE_LABELS := {
	"en": "English",
	"es": "Español",
	"pt_BR": "Português (BR)",
	"fr": "Français",
	"de": "Deutsch",
	"id": "Indonesia"
}

func _short_locale_name(loc: String) -> String:
	if LOCALE_LABELS.has(loc):
		return LOCALE_LABELS[loc]
	var base := loc.split("_")[0].split("-")[0]
	return LOCALE_LABELS.get(base, "English")

func refresh(sfx: SfxManager, slice: SliceController, save: SaveManager) -> void:
	_disarm_reset()
	sfx_btn.text = tr("Sound effects · ") + (tr("Off") if sfx.muted else tr("On"))
	music_btn.text = tr("Music · ") + (tr("Off") if sfx.music_muted else tr("On"))
	haptics_btn.text = tr("Vibration · ") + (tr("On") if slice.vibration_enabled else tr("Off"))
	colorblind_btn.text = tr("Color symbols · ") + (tr("On") if save.colorblind_assist else tr("Off"))
	particles_btn.text = tr("Particles · ") + (tr("Battery saver") if save.particle_quality_low else tr("Full"))
	if language_btn != null:
		language_btn.text = tr("Language · %s") % _short_locale_name(TranslationServer.get_locale())
	consent_btn.text = tr("Privacy & data choices")
