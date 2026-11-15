class_name SettingsModal
extends RefCounted

## Single-responsibility controller for Settings, Accessibility & Privacy modal and preference persistence.

var backdrop: ColorRect
var panel: PanelContainer
var sfx_btn: Button
var music_btn: Button
var haptics_btn: Button
var colorblind_btn: Button
var particles_btn: Button
var consent_btn: Button
var status_label: Label

func build(
	ui_layer: CanvasLayer,
	app_version: String,
	on_toggle_sfx: Callable,
	on_toggle_music: Callable,
	on_toggle_haptics: Callable,
	on_toggle_colorblind: Callable,
	on_toggle_particles: Callable,
	on_toggle_consent: Callable,
	on_restore_purchases: Callable,
	on_reset_progress: Callable,
	on_close: Callable
) -> void:
	backdrop = ColorRect.new()
	backdrop.color = Color(0.02, 0.04, 0.09, 0.90)
	backdrop.size = Vector2(UiThemeHelper.BASE_WIDTH, UiThemeHelper.BASE_HEIGHT)
	backdrop.visible = false
	ui_layer.add_child(backdrop)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(592, 860)
	panel.position = Vector2(64, 170)
	panel.add_theme_stylebox_override("panel", UiThemeHelper.create_modal_style(Color(0.54, 0.78, 1.0, 0.94)))
	backdrop.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var header := Label.new()
	header.text = "SETTINGS & PRIVACY"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 26)
	header.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	vbox.add_child(header)

	sfx_btn = _add_centered_btn(vbox, "Sound Effects: ON", Color(0.18, 0.26, 0.40), Color(0.58, 0.82, 1.0), on_toggle_sfx)
	music_btn = _add_centered_btn(vbox, "Background Music: ON", Color(0.18, 0.26, 0.40), Color(0.58, 0.82, 1.0), on_toggle_music)
	haptics_btn = _add_centered_btn(vbox, "Haptic Vibration: ON", Color(0.18, 0.26, 0.40), Color(0.58, 0.82, 1.0), on_toggle_haptics)
	colorblind_btn = _add_centered_btn(vbox, "Colorblind Symbols (● ◆ ★ ▲): ON", Color(0.18, 0.28, 0.36), Color(0.48, 0.90, 0.82), on_toggle_colorblind)
	particles_btn = _add_centered_btn(vbox, "Particle Quality: HIGH", Color(0.18, 0.26, 0.40), Color(0.58, 0.82, 1.0), on_toggle_particles)
	consent_btn = _add_centered_btn(vbox, "Analytics & Ad Consent: GRANTED", Color(0.20, 0.24, 0.36), Color(0.68, 0.78, 0.96), on_toggle_consent)

	_add_centered_btn(vbox, "Restore Purchases", Color(0.16, 0.32, 0.36), Color(0.48, 0.88, 0.94), on_restore_purchases)
	_add_centered_btn(vbox, "Reset Local Progress", Color(0.38, 0.14, 0.18), Color(1.0, 0.45, 0.50), on_reset_progress)

	status_label = Label.new()
	status_label.text = "Version %s • Offline-First Ready" % app_version
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.72, 0.80, 0.92))
	vbox.add_child(status_label)

	var close_btn := UiThemeHelper.create_styled_button("Close ✕", Color(0.22, 0.26, 0.38), Color(0.68, 0.80, 0.98))
	close_btn.custom_minimum_size = Vector2(240, 44)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func() -> void:
		backdrop.visible = false
		on_close.call()
	)
	vbox.add_child(close_btn)

func _add_centered_btn(parent: VBoxContainer, label: String, bg: Color, border: Color, callback: Callable) -> Button:
	var btn := UiThemeHelper.create_styled_button(label, bg, border)
	btn.custom_minimum_size = Vector2(420, 42)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func refresh(sfx: SfxManager, slice_controller: SliceController, save_manager: SaveManager) -> void:
	if sfx != null:
		sfx_btn.text = "Sound Effects: %s" % ("OFF" if sfx.muted else "ON")
		music_btn.text = "Background Music: %s" % ("OFF" if sfx.music_muted else "ON")
	if slice_controller != null:
		haptics_btn.text = "Haptic Vibration: %s" % ("ON" if slice_controller.vibration_enabled else "OFF")
	if save_manager != null:
		colorblind_btn.text = "Colorblind Symbols (● ◆ ★ ▲): %s" % ("ON" if save_manager.colorblind_assist else "OFF")
		particles_btn.text = "Particle Quality: %s" % ("LOW (Battery Saver)" if save_manager.particle_quality_low else "HIGH")
		consent_btn.text = "Analytics & Ad Consent: %s" % ("GRANTED" if save_manager.privacy_consent_granted else "DECLINED")

func toggle_sfx(sfx: SfxManager, save_manager: SaveManager, pause_modal: PauseModal, slice_controller: SliceController) -> void:
	sfx.muted = not sfx.muted
	if save_manager != null:
		save_manager.sfx_muted = sfx.muted
		save_manager.save_data()
	if not sfx.muted:
		sfx.play("ui_click")
	pause_modal.refresh(sfx, slice_controller)
	refresh(sfx, slice_controller, save_manager)

func toggle_music(sfx: SfxManager, save_manager: SaveManager, pause_modal: PauseModal, slice_controller: SliceController) -> void:
	sfx.music_muted = not sfx.music_muted
	if save_manager != null:
		save_manager.music_muted = sfx.music_muted
		save_manager.save_data()
	sfx.play("ui_click")
	pause_modal.refresh(sfx, slice_controller)
	refresh(sfx, slice_controller, save_manager)

func toggle_haptics(sfx: SfxManager, save_manager: SaveManager, pause_modal: PauseModal, slice_controller: SliceController) -> void:
	slice_controller.vibration_enabled = not slice_controller.vibration_enabled
	if save_manager != null:
		save_manager.vibration_enabled = slice_controller.vibration_enabled
		save_manager.save_data()
	sfx.play("ui_click")
	pause_modal.refresh(sfx, slice_controller)
	refresh(sfx, slice_controller, save_manager)
