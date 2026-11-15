extends SceneTree

## Genuine deterministic replay in the running game. No fabricated animation.
## CLI: --write-movie marketing/videos/level-3.avi --fixed-fps 60
##      --script tools/record_gameplay.gd -- --level=3
var game: Node2D
var level := 3
var captures_only := false

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			level = clampi(int(arg.get_slice("=", 1)), 1, 100)
		if arg == "--screenshots":
			captures_only = true
	call_deferred("_record")

func frames(count: int) -> void:
	for _i in range(count):
		await physics_frame

func screenshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://marketing/store/" + name + ".png")
	if error != OK:
		printerr("Screenshot failed: ", error)
		quit(1)

func _record() -> void:
	TranslationServer.set_locale("en")
	root.size = Vector2i(1080, 1920) if captures_only else Vector2i(720, 1280)
	root.content_scale_size = Vector2i(720, 1280)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.test-user"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://marketing/store"))
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "res://.test-user/marketing_capture.cfg"
	root.add_child(game)
	game.analytics.set_opt_in(false)
	game.ad_service.ads_enabled = false
	game._results_modal.splash_backdrop.hide()
	game.sfx.music_muted = true
	game.sfx.muted = true
	if captures_only:
		for index in [1, 3, 21, 41, 61, 81]:
			game.load_level(index)
			await frames(20)
			await screenshot("gameplay-level-%02d" % index)
		game.open_level_select()
		await frames(10)
		await screenshot("level-select")
		game._level_select_modal.backdrop.hide()
		paused = false
		game.load_level(1)
		game.open_home_screen()
		await process_frame
		await screenshot("home")
		quit()
		return
	game.load_level(level)
	await frames(100)
	var controller: LevelController = game.current_level
	for step in controller.solution_steps:
		await frames(int(float(step.get("delay", 0.2)) * 60))
		game.slice_controller.dispatch_real_touch_swipe(step["from"], step["to"])
	await frames(420)
	var solved := controller.is_finished
	for bucket in controller.containers:
		solved = solved and bucket.is_satisfied()
	print("Genuine gameplay capture: level %d, solved=%s, cuts=%d" % [level, solved, controller.moves_used])
	quit(0 if solved else 1)
