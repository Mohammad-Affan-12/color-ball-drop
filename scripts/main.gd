extends Node2D

const LEVEL_SCENES := {
	1: "res://scenes/levels/level_1.tscn",
	2: "res://scenes/levels/level_2.tscn",
	3: "res://scenes/levels/level_3.tscn",
	4: "res://scenes/levels/level_4.tscn",
	5: "res://scenes/levels/level_5.tscn"
}

var current_level_index: int = 1
var current_level: LevelController = null
var slice_controller: SliceController = null
var sfx: SfxManager = null

var _shake_strength: float = 0.0
var _bg_time: float = 0.0
var _hints_active: bool = false
var _camera: Camera2D = null

# UI nodes built in code for clean self-contained styling
var _ui_layer: CanvasLayer
var _title_label: Label
var _subtitle_label: Label
var _progress_label: Label
var _hint_btn: Button
var _restart_btn: Button
var _level_buttons: Array[Button] = []

var _modal_backdrop: ColorRect
var _modal_panel: PanelContainer
var _modal_header: Label
var _modal_body: Label
var _modal_next_btn: Button
var _modal_retry_btn: Button

func _ready() -> void:
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	_camera.enabled = true
	add_child(_camera)

	sfx = SfxManager.new()
	sfx.name = "SfxManager"
	add_child(sfx)

	slice_controller = SliceController.new()
	slice_controller.name = "SliceController"
	slice_controller.object_sliced.connect(_on_object_sliced)
	add_child(slice_controller)

	_build_ui()
	load_level(current_level_index)

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	add_child(_ui_layer)

	# Top HUD bar
	var top_bar := PanelContainer.new()
	top_bar.position = Vector2(14, 12)
	top_bar.custom_minimum_size = Vector2(692, 106)
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.09, 0.12, 0.20, 0.92)
	top_style.border_color = Color(0.26, 0.42, 0.68, 0.65)
	top_style.set_border_width_all(2)
	top_style.set_corner_radius_all(14)
	top_style.content_margin_left = 14
	top_style.content_margin_right = 14
	top_style.content_margin_top = 8
	top_style.content_margin_bottom = 8
	top_bar.add_theme_stylebox_override("panel", top_style)
	_ui_layer.add_child(top_bar)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	top_bar.add_child(vbox)

	# Row 1: Title + Progress + Hint + Restart
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)

	_title_label = Label.new()
	_title_label.text = "Level 1"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	row1.add_child(_title_label)

	_progress_label = Label.new()
	_progress_label.text = "0 / 0"
	_progress_label.add_theme_font_size_override("font_size", 17)
	_progress_label.add_theme_color_override("font_color", Color(0.45, 0.92, 1.0))
	row1.add_child(_progress_label)

	_hint_btn = _create_styled_button("Hint", Color(0.28, 0.24, 0.10), Color(1.0, 0.85, 0.28))
	_hint_btn.custom_minimum_size = Vector2(72, 34)
	_hint_btn.pressed.connect(_on_hint_pressed)
	row1.add_child(_hint_btn)

	_restart_btn = _create_styled_button("Restart", Color(0.18, 0.26, 0.42), Color(0.55, 0.82, 1.0))
	_restart_btn.custom_minimum_size = Vector2(86, 34)
	_restart_btn.pressed.connect(_on_restart_pressed)
	row1.add_child(_restart_btn)

	# Row 2: Subtitle + Level selector buttons (1..5)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	vbox.add_child(row2)

	_subtitle_label = Label.new()
	_subtitle_label.text = "Swipe to cut supports!"
	_subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_subtitle_label.add_theme_font_size_override("font_size", 13)
	_subtitle_label.add_theme_color_override("font_color", Color(0.72, 0.80, 0.94))
	_subtitle_label.clip_text = true
	row2.add_child(_subtitle_label)

	for i in range(1, LevelData.TOTAL_LEVELS + 1):
		var lbtn := _create_styled_button(str(i), Color(0.14, 0.18, 0.28), Color(0.45, 0.60, 0.85))
		lbtn.custom_minimum_size = Vector2(34, 28)
		var lvl_idx := i
		lbtn.pressed.connect(func() -> void: load_level(lvl_idx))
		row2.add_child(lbtn)
		_level_buttons.append(lbtn)

	# Modal Backdrop & Win/Fail Overlay
	_modal_backdrop = ColorRect.new()
	_modal_backdrop.color = Color(0.02, 0.04, 0.08, 0.72)
	_modal_backdrop.size = Vector2(720, 1280)
	_modal_backdrop.visible = false
	_ui_layer.add_child(_modal_backdrop)

	_modal_panel = PanelContainer.new()
	_modal_panel.custom_minimum_size = Vector2(520, 290)
	_modal_panel.position = Vector2(100, 480)
	_modal_panel.pivot_offset = Vector2(260, 145)
	var modal_style := StyleBoxFlat.new()
	modal_style.bg_color = Color(0.10, 0.14, 0.24, 0.98)
	modal_style.border_color = Color(0.38, 0.78, 1.0, 0.9)
	modal_style.set_border_width_all(3)
	modal_style.set_corner_radius_all(20)
	modal_style.content_margin_left = 28
	modal_style.content_margin_right = 28
	modal_style.content_margin_top = 24
	modal_style.content_margin_bottom = 24
	_modal_panel.add_theme_stylebox_override("panel", modal_style)
	_modal_backdrop.add_child(_modal_panel)

	var modal_vbox := VBoxContainer.new()
	modal_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_vbox.add_theme_constant_override("separation", 18)
	_modal_panel.add_child(modal_vbox)

	_modal_header = Label.new()
	_modal_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_header.add_theme_font_size_override("font_size", 32)
	modal_vbox.add_child(_modal_header)

	_modal_body = Label.new()
	_modal_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_modal_body.add_theme_font_size_override("font_size", 18)
	_modal_body.add_theme_color_override("font_color", Color(0.84, 0.90, 0.98))
	modal_vbox.add_child(_modal_body)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 18)
	modal_vbox.add_child(btn_row)

	_modal_retry_btn = _create_styled_button("Retry Level", Color(0.22, 0.28, 0.42), Color(0.7, 0.85, 1.0))
	_modal_retry_btn.custom_minimum_size = Vector2(170, 50)
	_modal_retry_btn.pressed.connect(_on_restart_pressed)
	btn_row.add_child(_modal_retry_btn)

	_modal_next_btn = _create_styled_button("Next Level ▶", Color(0.12, 0.46, 0.26), Color(0.4, 1.0, 0.62))
	_modal_next_btn.custom_minimum_size = Vector2(190, 50)
	_modal_next_btn.pressed.connect(_on_next_level_pressed)
	btn_row.add_child(_modal_next_btn)

func _create_styled_button(text_str: String, bg_col: Color, border_col: Color) -> Button:
	var btn := Button.new()
	btn.text = text_str
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_col
	normal.border_color = border_col
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg_col.lightened(0.16)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg_col.darkened(0.18)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn

func load_level(level_idx: int) -> void:
	current_level_index = clampi(level_idx, 1, LevelData.TOTAL_LEVELS)
	_modal_backdrop.visible = false
	slice_controller.enabled = true

	if current_level != null and is_instance_valid(current_level):
		current_level.queue_free()
		current_level = null

	var scene_path: String = LEVEL_SCENES.get(current_level_index, "")
	if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
		var packed: PackedScene = load(scene_path)
		current_level = packed.instantiate() as LevelController
	else:
		current_level = LevelController.new()
		current_level.level_number = current_level_index

	current_level.level_won.connect(_on_level_won)
	current_level.level_failed.connect(_on_level_failed)
	current_level.progress_updated.connect(_on_progress_updated)
	current_level.chain_reaction_triggered.connect(_on_chain_reaction)
	add_child(current_level)
	current_level.set_hints_visible(_hints_active)

	_title_label.text = current_level.level_title
	_subtitle_label.text = current_level.level_subtitle
	_update_level_buttons()

func _update_level_buttons() -> void:
	for i in range(_level_buttons.size()):
		var btn := _level_buttons[i]
		var active := (i + 1) == current_level_index
		btn.modulate = Color(1.0, 0.95, 0.45) if active else Color(0.78, 0.84, 0.95)

func _on_object_sliced(_item: CuttableBase, _pt: Vector2) -> void:
	sfx.play("slice", randf_range(0.92, 1.12))

func _on_chain_reaction() -> void:
	sfx.play("chain", 1.0)
	_shake_strength = 8.0

func _on_progress_updated(collected: int, total_req: int) -> void:
	_progress_label.text = "Balls: %d / %d" % [collected, total_req]
	if collected > 0:
		sfx.play("collect", 0.95 + float(collected) * 0.05)

func _on_level_won(lvl_idx: int) -> void:
	slice_controller.enabled = false
	sfx.play("win")
	_modal_backdrop.visible = true
	_modal_panel.scale = Vector2(0.75, 0.75)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_modal_panel, "scale", Vector2.ONE, 0.26)

	if lvl_idx < LevelData.TOTAL_LEVELS:
		_modal_header.text = "LEVEL COMPLETE!"
		_modal_header.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
		_modal_body.text = "All colored balls cascaded into their matching containers!"
		_modal_next_btn.text = "Next Level ▶"
		_modal_next_btn.visible = true
	else:
		_modal_header.text = "ALL LEVELS CLEARED!"
		_modal_header.add_theme_color_override("font_color", Color(1.0, 0.88, 0.28))
		_modal_body.text = "Congratulations! You solved all %d levels of Cut & Cascade!" % LevelData.TOTAL_LEVELS
		_modal_next_btn.text = "Play From Level 1"
		_modal_next_btn.visible = true

func _on_level_failed(_lvl_idx: int, reason: String) -> void:
	slice_controller.enabled = false
	sfx.play("fail")
	_shake_strength = 12.0
	_modal_backdrop.visible = true
	_modal_panel.scale = Vector2(0.75, 0.75)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_modal_panel, "scale", Vector2.ONE, 0.26)

	_modal_header.text = "LEVEL FAILED"
	_modal_header.add_theme_color_override("font_color", Color(1.0, 0.36, 0.38))
	_modal_body.text = reason
	_modal_next_btn.visible = false

func _on_hint_pressed() -> void:
	_hints_active = not _hints_active
	_hint_btn.text = "Hint: ON" if _hints_active else "Hint"
	if current_level != null and is_instance_valid(current_level):
		current_level.set_hints_visible(_hints_active)

func _on_restart_pressed() -> void:
	load_level(current_level_index)

func _on_next_level_pressed() -> void:
	if current_level_index < LevelData.TOTAL_LEVELS:
		load_level(current_level_index + 1)
	else:
		load_level(1)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_R:
			_on_restart_pressed()
		elif k.keycode == KEY_H:
			_on_hint_pressed()
		elif k.keycode == KEY_N and _modal_backdrop.visible and _modal_next_btn.visible:
			_on_next_level_pressed()

func _process(delta: float) -> void:
	_bg_time += delta
	if _shake_strength > 0.1:
		_shake_strength = lerpf(_shake_strength, 0.0, clampf(delta * 10.0, 0.0, 1.0))
		_camera.offset = Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))
	elif _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	# Deep rich dark-indigo background
	draw_rect(Rect2(-40, -40, 800, 1360), Color(0.06, 0.08, 0.14), true)

	# Subtle animated grid lines
	var grid_col := Color(0.14, 0.20, 0.32, 0.28)
	var step := 60.0
	var offset_y := fmod(_bg_time * 12.0, step)
	var x := 0.0
	while x <= 720.0:
		draw_line(Vector2(x, 0), Vector2(x, 1280), grid_col, 1.0)
		x += step
	var y := offset_y
	while y <= 1280.0:
		draw_line(Vector2(0, y), Vector2(720, y), grid_col, 1.0)
		y += step
