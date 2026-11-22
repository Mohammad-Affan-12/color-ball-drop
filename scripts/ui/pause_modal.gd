class_name PauseModal
extends RefCounted

var backdrop: ColorRect
var panel: PanelContainer
var sfx_btn: Button
var music_btn: Button
var haptics_btn: Button

func build(ui_layer: CanvasLayer, on_resume: Callable, on_sfx: Callable, on_music: Callable, on_haptics: Callable, on_restart: Callable, on_home: Callable, on_levels: Callable = Callable()) -> void:
	panel = UiThemeHelper.modal(ui_layer, Vector2(600, 1040))
	backdrop = panel.get_parent()
	var content := UiThemeHelper.modal_content(panel)
	content.add_child(UiThemeHelper.label("Paused", 42, UiThemeHelper.TEXT))
	content.add_child(UiThemeHelper.label("Your progress is saved.", 26, UiThemeHelper.MUTED))
	UiThemeHelper.action(content, "Resume", on_resume, true)
	UiThemeHelper.action(content, "Restart level", on_restart)
	if on_levels.is_valid():
		UiThemeHelper.action(content, "Choose a level", on_levels)
	sfx_btn = UiThemeHelper.action(content, "Sound effects · On", on_sfx)
	music_btn = UiThemeHelper.action(content, "Music · On", on_music)
	haptics_btn = UiThemeHelper.action(content, "Vibration · On", on_haptics)
	UiThemeHelper.action(content, "Home", on_home)

func refresh(sfx: SfxManager, slice: SliceController) -> void:
	sfx_btn.text = "Sound effects · " + ("Off" if sfx.muted else "On")
	music_btn.text = "Music · " + ("Off" if sfx.music_muted else "On")
	haptics_btn.text = "Vibration · " + ("On" if slice.vibration_enabled else "Off")
