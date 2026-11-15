extends SceneTree

## Real Godot renderer captures and layout assertions; never writes the player's save.
## --headless validates geometry only. Use -- --capture with a renderer for PNGs.
var failures: Array[String] = []
var checks: int = 0
var captures: Array[String] = []
var game: Node2D
var viewport: SubViewport
var capture_enabled := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	capture_enabled = OS.get_cmdline_user_args().has("--capture")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.test-user"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
	if OS.get_cmdline_user_args().has("--platform-capture"):
		await _platform_capture()
		return
	for physical in [Vector2i(540, 960), Vector2i(720, 1280), Vector2i(1080, 1920), Vector2i(540, 1170), Vector2i(1080, 2400), Vector2i(768, 1024)]:
		paused = false
		viewport = SubViewport.new()
		viewport.size = physical
		var factor := minf(float(physical.x) / 720.0, float(physical.y) / 1280.0)
		viewport.size_2d_override = Vector2i(Vector2(physical) / factor)
		viewport.size_2d_override_stretch = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		root.add_child(viewport)
		game = load("res://scenes/main.tscn").instantiate()
		game.save_path = "res://.test-user/ui_preview.cfg"
		viewport.add_child(game)
		game.sfx.muted = true
		game.sfx.music_muted = true
		game.load_level(1)
		await _settle()
		game._results_modal.splash_backdrop.hide()
		await _check_screen("gameplay", physical)
		if not capture_enabled:
			# Measure every real puzzle, including the longest instructions and titles.
			for index in range(1, 101):
				game.load_level(index)
				await _settle()
				_check_tree(game._hud.root)
				_check_puzzle_frame(index, physical)
				var previous := viewport.canvas_transform
				await _settle()
				_require(previous.is_equal_approx(viewport.canvas_transform), "Camera drift before cut: level %d" % index)
		game.load_level(1)
		await _settle()
		game._on_hint_pressed()
		await _check_screen("hints", physical)
		game._on_hint_pressed()
		game.open_home_screen()
		await _check_screen("home", physical)
		_require(paused and not game.slice_controller.enabled, "Home must suspend gameplay")
		game._home_modal.backdrop.hide()
		await _settle()
		_require(not paused and game.slice_controller.enabled, "Closing home must restore gameplay")
		game.open_level_select()
		await _check_screen("levels", physical)
		for chapter in range(1, 6):
			game._level_select_modal._select_chapter(chapter)
			await _settle()
			_check_tree(game._level_select_modal.panel)
			_require(game._level_select_modal.grid_container.get_child_count() == 20, "Chapter must contain 20 levels")
		game._level_select_modal.backdrop.hide()
		await _settle()
		game.toggle_pause()
		await _check_screen("pause", physical)
		game.toggle_pause()
		game.open_settings_modal()
		await _check_screen("settings", physical)
		game._settings_modal.backdrop.hide()
		await _settle()
		game.open_cosmetics_modal()
		await _check_screen("trails", physical)
		game._cosmetics_modal.backdrop.hide()
		await _settle()
		game._results_modal.show_win(game, 1, 3, 25, 3)
		await _check_screen("win", physical)
		game._results_modal.show_win(game, 100, 3, 25, 4)
		await _check_screen("complete_100", physical)
		game._results_modal.show_fail(game, "A blue ball entered the red container. Match each ball to its color.")
		await _check_screen("retry", physical)
		game._results_modal.backdrop.hide()
		game.load_level(99)
		await _check_screen("mastery", physical)
		# Simulate notch/home-indicator insets in logical canvas units.
		var safe := Vector4(0, 72, 0, 48)
		game._hud.layout(safe)
		for modal in [game._home_modal, game._level_select_modal, game._pause_modal, game._results_modal, game._settings_modal, game._cosmetics_modal]:
			MobileLayout.fit_modal(modal.panel, viewport.get_visible_rect().size, safe)
			_require(modal.panel.get_global_rect().position.y >= 72, "Modal violates simulated safe top")
		await _settle()
		_check_tree(game._hud.root)
		var framing := MobileLayout.puzzle_transform(game._puzzle_bounds, game._hud.puzzle_area())
		_require((framing * game._puzzle_bounds.position).y >= game._hud.top_bar.get_global_rect().end.y + 11, "Puzzle violates simulated safe header")
		game.load_level(51)
		await _settle()
		var rope: CuttableBase = game.current_level.cuttables[0]
		var center: Vector2 = rope.get_cut_center_global()
		var before: int = game.current_level.moves_used
		game.slice_controller.dispatch_real_touch_swipe(center - Vector2(44, 0), center + Vector2(44, 0))
		_require(game.current_level.moves_used > before, "Touch mapping failed at %s" % physical)
		paused = false
		viewport.queue_free()
		await process_frame
	print("UI VERIFICATION: %d checks, %d failures, %d screenshots" % [checks, failures.size(), captures.size()])
	var report := {"engine": Engine.get_version_info().string, "checks": checks, "failures": failures, "captures": captures,
		"testing": "Desktop Godot renderer / automated viewport previews. No physical device or mobile emulator testing."}
	FileAccess.open("res://docs/screenshots/corrected-verification.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	for failure in failures:
		printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)

func _settle() -> void:
	for frame in range(3):
		await process_frame

func _check_screen(screen: String, physical: Vector2i) -> void:
	await _settle()
	_check_tree(game._ui_layer)
	var bounds := viewport.get_visible_rect()
	for modal in [game._home_modal, game._level_select_modal, game._pause_modal, game._results_modal, game._settings_modal, game._cosmetics_modal]:
		if modal.backdrop.visible:
			_require(bounds.encloses(modal.panel.get_global_rect()), "%s panel outside viewport at %s" % [screen, physical])
			# Intentional scrolling must make the last action reachable.
			var scroll: ScrollContainer = modal.panel.get_child(0)
			scroll.scroll_vertical = 100000
			await _settle()
			var content: Control = scroll.get_child(0)
			var last: Control = content.get_child(content.get_child_count() - 1)
			_require(last.get_global_rect().end.y <= scroll.get_global_rect().end.y + 2, "%s final action unreachable" % screen)
			scroll.scroll_vertical = 0
	await _settle()
	if capture_enabled and (physical == Vector2i(720, 1280) or screen in ["gameplay", "mastery"]):
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		RenderingServer.force_draw(false)
		var filename := "corrected_%s_%dx%d.png" % [screen, physical.x, physical.y]
		var err := viewport.get_texture().get_image().save_png("res://docs/screenshots/" + filename)
		_require(err == OK, "Cannot save " + filename)
		captures.append(filename)
		print("CAPTURE: " + filename)

func _require(condition: bool, message: String) -> void:
	checks += 1
	if not condition and not failures.has(message):
		failures.append(message)

func _check_label(label: Label) -> void:
	_require(label.size.y + 1 >= label.get_minimum_size().y, "Label height clips: " + label.text)
	_require(label.get_visible_line_count() >= label.get_line_count(), "Label lines clip: " + label.text)

func _check_tree(node: Node) -> void:
	if node is Control and not node.is_visible_in_tree():
		return
	if node is Label:
		_check_label(node)
	if node is Button:
		var button := node as Button
		_require(button.size.y >= 96, "Touch target below 96 logical pixels: " + button.text)
		var style := button.get_theme_stylebox("normal")
		var available := button.size.x - style.get_content_margin(SIDE_LEFT) - style.get_content_margin(SIDE_RIGHT)
		if button.icon != null:
			available -= 46
		for line in button.text.split("\n"):
			var text_size := button.get_theme_font("font").get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size"))
			_require(text_size.x <= available + 1, "Button text clips: " + button.text)
	if node is BoxContainer or node is GridContainer:
		var siblings: Array[Control] = []
		for child in node.get_children():
			if child is Control and child.visible:
				for sibling in siblings:
					_require(not child.get_global_rect().grow(-0.5).intersects(sibling.get_global_rect()), "Overlapping controls in " + node.name)
				siblings.append(child)
	for child in node.get_children():
		_check_tree(child)

func _check_puzzle_frame(index: int, physical: Vector2i) -> void:
	var hud: GameplayHud = game._hud
	_require(not hud.subtitle_label.get_global_rect().intersects(hud.bottom_bar.get_global_rect()), "Instruction overlaps buttons: level %d at %s" % [index, physical])
	_require(hud.bottom_bar.get_global_rect().end.y <= viewport.get_visible_rect().end.y - 19, "Actions clip viewport")
	var displayed: Rect2 = viewport.canvas_transform * game._puzzle_bounds
	_require(hud.puzzle_area().grow(1).encloses(displayed), "Puzzle clips HUD: level %d at %s" % [index, physical])
	for cup in game.current_level.containers:
		_require(cup._static_body.collision_layer == 1, "Presentation changed container physics")
	for ball in game.current_level.balls:
		_require(is_equal_approx(ball._collision_shape.shape.radius, ball.radius), "Visual enhancement changed ball collision")
	var camera_before := viewport.canvas_transform
	var world_point := Vector2(360, 600)
	_require(game.slice_controller.screen_to_world(game.slice_controller.world_to_screen(world_point)).distance_to(world_point) < 0.01, "Swipe mapping round-trip error")
	_require(camera_before.is_equal_approx(viewport.canvas_transform), "Mapping changed camera")

func _platform_capture() -> void:
	capture_enabled = true
	viewport = SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "res://.test-user/platform-preview.cfg"
	viewport.add_child(game)
	game.sfx.muted = true
	game.sfx.music_muted = true
	var evidence: Array[Dictionary] = []
	for index in [1, 3]:
		game.load_level(index)
		await _settle()
		game._results_modal.splash_backdrop.hide()
		var lc: LevelController = game.current_level
		await _check_screen("platform_level%d_before" % index, viewport.size)
		for step in lc.solution_steps:
			for frame in range(int(float(step.get("delay", 0.2)) * 60)):
				await physics_frame
			game.slice_controller.dispatch_real_touch_swipe(step["from"], step["to"])
		var after_saved := false
		for frame in range(390):
			await physics_frame
			if not after_saved and (index == 1 or (lc.triggers[0].is_activated and is_equal_approx(lc.triggers[0].linked_ramps[0].rotation_degrees, -20))):
				await _check_screen("platform_level%d_after" % index, viewport.size)
				var angles: Array[float] = []
				for ramp in lc.ramps:
					if is_equal_approx(ramp.position.y, 555):
						angles.append(ramp.rotation_degrees)
				evidence.append({"level": index, "central_angles_after": angles, "moves": lc.moves_used})
				after_saved = true
			if lc.is_finished:
				break
		_require(lc.is_finished and lc.compute_earned_stars() == 3, "Platform capture solution must finish at par")
		for cup in lc.containers:
			_require(cup.is_satisfied(), "Platform capture must collect every required ball")
		evidence[-1]["solved"] = lc.is_finished
		evidence[-1]["cuts"] = lc.moves_used
	var report := {"checks": checks, "failures": failures, "levels": evidence, "captures": captures, "testing": "Godot 4.7.2 desktop OpenGL preview with injected touch events; no physical device."}
	FileAccess.open("res://docs/screenshots/platform-verification.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("PLATFORM CAPTURE: " + JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
