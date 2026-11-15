extends SceneTree

var _main_node: Node2D = null

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("=== Starting Cut & Cascade Headless Verification ===")
	var main_packed: PackedScene = load("res://scenes/main.tscn")
	if main_packed == null:
		printerr("FAIL: Could not load res://scenes/main.tscn")
		quit(1)
		return

	_main_node = main_packed.instantiate()
	root.add_child(_main_node)
	await process_frame
	await physics_frame

	var max_level_to_test := 5

	for lvl in range(1, max_level_to_test + 1):
		var ok := await _verify_level_solvable(lvl)
		if not ok:
			printerr("FAIL: Level %d verification failed!" % lvl)
			quit(1)
			return

	var fail_ok := await _verify_fail_detection()
	if not fail_ok:
		printerr("FAIL: Wrong-color fail detection test failed!")
		quit(1)
		return

	# Test Next Level & Restart button callbacks
	_main_node.load_level(1)
	await process_frame
	_main_node._on_next_level_pressed()
	await process_frame
	if _main_node.current_level_index != 2:
		printerr("FAIL: Next level navigation did not advance to level 2!")
		quit(1)
		return
	_main_node._on_restart_pressed()
	await process_frame
	if _main_node.current_level_index != 2 or _main_node.current_level.is_finished:
		printerr("FAIL: Restart level did not reset cleanly!")
		quit(1)
		return

	print("=== ALL TESTS PASSED SUCCESSFULLY (%d levels + fail detection) ===" % max_level_to_test)
	quit(0)

func _verify_level_solvable(lvl: int) -> bool:
	print("--- Testing Level %d ---" % lvl)
	_main_node.load_level(lvl)
	await process_frame
	await physics_frame

	var lc: LevelController = _main_node.current_level
	if lc == null:
		printerr("LevelController is null for level %d" % lvl)
		return false

	# Wait 0.4s before cutting to verify balls are stably held prior to player action
	var pre_frames := 24
	for i in range(pre_frames):
		await physics_frame
		if lc.is_finished:
			printerr("Level %d finished prematurely before any cuts!" % lvl)
			return false

	# Execute solution swipe steps
	for step_idx in range(lc.solution_steps.size()):
		var step: Dictionary = lc.solution_steps[step_idx]
		var delay_sec: float = step.get("delay", 0.2)
		var wait_frames := int(delay_sec * 60.0)
		for f in range(wait_frames):
			await physics_frame
		var from_pt: Vector2 = step["from"]
		var to_pt: Vector2 = step["to"]
		var sliced: int = _main_node.slice_controller.simulate_swipe(from_pt, to_pt)
		print("  Level %d Step %d swipe %s -> %s sliced %d object(s)" % [lvl, step_idx + 1, str(from_pt), str(to_pt), sliced])
		if sliced <= 0:
			printerr("  WARNING: Step %d did not slice any object!" % (step_idx + 1))

	# Simulate up to 6.5 seconds (390 physics frames) for cascade to complete
	var won := false
	for frame in range(390):
		await physics_frame
		if lc.is_finished:
			var all_full := true
			for c in lc.containers:
				if not c.is_satisfied():
					all_full = false
			if all_full:
				won = true
				print("  PASS: Level %d WON at frame %d!" % [lvl, frame])
			else:
				printerr("  FAIL: Level %d ended in FAIL state at frame %d! Modal text: %s" % [lvl, frame, _main_node._modal_body.text])
				_dump_ball_positions(lc)
			break

	if not lc.is_finished:
		printerr("  FAIL: Level %d timed out without finishing!" % lvl)
		_dump_ball_positions(lc)
		return false

	return won

func _verify_fail_detection() -> bool:
	print("--- Testing Wrong-Color Fail Detection ---")
	_main_node.load_level(1)
	await process_frame
	await physics_frame
	var lc: LevelController = _main_node.current_level
	# Drop a BLUE ball directly into the RED container at (210, 1020)
	lc.add_ball(Vector2(210, 1020), GameColors.ColorType.BLUE)
	for f in range(60):
		await physics_frame
		if lc.is_finished:
			if _main_node._modal_header.text == "LEVEL FAILED":
				print("  PASS: Wrong-color fail detection triggered cleanly (%s)" % _main_node._modal_body.text)
				return true
	return false

func _dump_ball_positions(lc: LevelController) -> void:
	for i in range(lc.balls.size()):
		var b := lc.balls[i]
		if is_instance_valid(b):
			print("    Ball %d (%s): pos=%s collected=%s vel=%s" % [
				i,
				GameColors.get_color_name(b.color_type),
				str(b.global_position),
				str(b.is_collected),
				str(b.linear_velocity)
			])
	for i in range(lc.containers.size()):
		var c := lc.containers[i]
		print("    Container %d (%s): %d / %d at %s" % [
			i,
			GameColors.get_color_name(c.color_type),
			c.collected_count,
			c.required_count,
			str(c.global_position)
		])
