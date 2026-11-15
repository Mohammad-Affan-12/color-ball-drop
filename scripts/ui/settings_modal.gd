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
var consent_btn: Button
var status_label: Label

func build(ui_layer: CanvasLayer, app_version: String, on_sfx: Callable, on_music: Callable, on_haptics: Callable, on_colorblind: Callable, on_particles: Callable, on_consent: Callable, on_restore: Callable, on_reset: Callable, on_close: Callable) -> void:
	panel = UiThemeHelper.modal(ui_layer, Vector2(640, 1160))
	backdrop = panel.get_parent()
	var content := UiThemeHelper.modal_content(panel)
	content.add_child(UiThemeHelper.label("Make it yours", 44))
	content.add_child(UiThemeHelper.label("SETTINGS & ACCESSIBILITY", 26, UiThemeHelper.TEAL))
	sfx_btn = UiThemeHelper.action(content, "", on_sfx)
	music_btn = UiThemeHelper.action(content, "", on_music)
	haptics_btn = UiThemeHelper.action(content, "", on_haptics)
	colorblind_btn = UiThemeHelper.action(content, "", on_colorblind)
	particles_btn = UiThemeHelper.action(content, "", on_particles)
	consent_btn = UiThemeHelper.action(content, "", on_consent)
	UiThemeHelper.action(content, "Restore purchases", on_restore)
	UiThemeHelper.action(content, "Reset local progress", on_reset)
	status_label = UiThemeHelper.label("Version %s · Play offline" % app_version, 26, UiThemeHelper.MUTED)
	content.add_child(status_label)
	UiThemeHelper.action(content, "Back to puzzle", func() -> void:
		backdrop.hide()
		on_close.call()
	)

func refresh(sfx: SfxManager, slice: SliceController, save: SaveManager) -> void:
	sfx_btn.text = "Sound effects · " + ("Off" if sfx.muted else "On")
	music_btn.text = "Music · " + ("Off" if sfx.music_muted else "On")
	haptics_btn.text = "Vibration · " + ("On" if slice.vibration_enabled else "Off")
	colorblind_btn.text = "Color symbols · " + ("On" if save.colorblind_assist else "Off")
	particles_btn.text = "Particles · " + ("Battery saver" if save.particle_quality_low else "Full")
	consent_btn.text = "Analytics & ads · " + ("Allowed" if save.privacy_consent_granted else "Declined")
