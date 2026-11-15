class_name PauseModal
extends RefCounted

## Single-responsibility controller for the in-game Pause overlay modal.

var backdrop: ColorRect
var panel: PanelContainer
var sfx_btn: Button
var music_btn: Button
var haptics_btn: Button

func build(
	ui_layer: CanvasLayer,
	on_resume: Callable,
	on_toggle_sfx: Callable,
	on_toggle_music: Callable,
	on_toggle_haptics: Callable,
	on_restart: Callable,
	on_home: Callable
) -> void:
	backdrop = ColorRect.new()
	backdrop.color = Color(0.02, 0.04, 0.08, 0.78)
	backdrop.size = Vector2(UiThemeHelper.BASE_WIDTH, UiThemeHelper.BASE_HEIGHT)
	backdrop.visible = false
	ui_layer.add_child(backdrop)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 460)
	panel.position = Vector2(110, 360)
	panel.add_theme_stylebox_override("panel", UiThemeHelper.create_modal_style(Color(0.45, 0.72, 1.0, 0.9)))
	backdrop.add_child(panel)

	var pvbox := VBoxContainer.new()
	pvbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pvbox.add_theme_constant_override("separation", 12)
	panel.add_child(pvbox)

	var ptitle := Label.new()
	ptitle.text = "GAME PAUSED"
	ptitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ptitle.add_theme_font_size_override("font_size", 28)
	ptitle.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	pvbox.add_child(ptitle)

	var resume_btn := UiThemeHelper.create_styled_button("Resume Game ▶", Color(0.14, 0.44, 0.26), Color(0.42, 0.98, 0.64))
	resume_btn.custom_minimum_size = Vector2(300, 44)
	resume_btn.pressed.connect(on_resume)
	pvbox.add_child(resume_btn)

	sfx_btn = UiThemeHelper.create_styled_button("Sound Effects: ON", Color(0.18, 0.26, 0.40), Color(0.58, 0.82, 1.0))
	sfx_btn.custom_minimum_size = Vector2(300, 42)
	sfx_btn.pressed.connect(on_toggle_sfx)
	pvbox.add_child(sfx_btn)

	music_btn = UiThemeHelper.create_styled_button("Music: ON", Color(0.18, 0.26, 0.40), Color(0.58, 0.82, 1.0))
	music_btn.custom_minimum_size = Vector2(300, 42)
	music_btn.pressed.connect(on_toggle_music)
	pvbox.add_child(music_btn)

	haptics_btn = UiThemeHelper.create_styled_button("Vibration / Haptics: ON", Color(0.18, 0.26, 0.40), Color(0.58, 0.82, 1.0))
	haptics_btn.custom_minimum_size = Vector2(300, 42)
	haptics_btn.pressed.connect(on_toggle_haptics)
	pvbox.add_child(haptics_btn)

	var restart_pbtn := UiThemeHelper.create_styled_button("Restart Level ↻", Color(0.24, 0.28, 0.42), Color(0.72, 0.84, 1.0))
	restart_pbtn.custom_minimum_size = Vector2(300, 42)
	restart_pbtn.pressed.connect(on_restart)
	pvbox.add_child(restart_pbtn)

	var home_pbtn := UiThemeHelper.create_styled_button("Home Menu ⌂", Color(0.22, 0.18, 0.34), Color(0.75, 0.62, 1.0))
	home_pbtn.custom_minimum_size = Vector2(300, 42)
	home_pbtn.pressed.connect(on_home)
	pvbox.add_child(home_pbtn)

func refresh(sfx: SfxManager, slice_controller: SliceController) -> void:
	if sfx_btn != null and sfx != null:
		sfx_btn.text = "Sound Effects: %s" % ("OFF" if sfx.muted else "ON")
	if music_btn != null and sfx != null:
		music_btn.text = "Music: %s" % ("OFF" if sfx.music_muted else "ON")
	if haptics_btn != null and slice_controller != null:
		haptics_btn.text = "Vibration / Haptics: %s" % ("ON" if slice_controller.vibration_enabled else "OFF")
