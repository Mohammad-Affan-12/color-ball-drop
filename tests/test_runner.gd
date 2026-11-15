extends SceneTree

var _main_node: Node2D = null

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("=== Starting Cut & Cascade Commercial Verification Suite ===")

	# 1. Verify all component scenes load cleanly
	if not _verify_component_scenes():
		quit(1)
		return

	# 2. Verify SaveManager persistence, checksums, .bak recovery, economy, and cosmetics
	if not _verify_save_manager_and_economy():
		quit(1)
		return

	# 3. Verify DailyChallenge, AnalyticsService, AdService frequency caps, and BillingService
	if not _verify_services_and_daily():
		quit(1)
		return

	# 4. Instantiate Main scene
	var main_packed: PackedScene = load("res://scenes/main.tscn")
	if main_packed == null:
		printerr("FAIL: Could not load res://scenes/main.tscn")
		quit(1)
		return

	_main_node = main_packed.instantiate()
	root.add_child(_main_node)
	await process_frame
	await physics_frame

	# 5. Verify invalid swipes (empty air, already-cut beam, uncuttable SteelChain) consume 0 moves
	if not await _verify_move_accounting_and_uncuttables():
		quit(1)
		return

	# 6. Verify Pause / Resume and UI modals
	if not await _verify_pause_and_modals():
		quit(1)
		return

	# 7. Verify all 100 playable levels (pre-cut stability + solution completion)
	var total_levels := LevelData.TOTAL_LEVELS
	for lvl in range(1, total_levels + 1):
		var use_real_touch := (lvl <= 5 or lvl % 20 == 0)
		var ok := await _verify_level_solvable(lvl, use_real_touch)
		if not ok:
			printerr("FAIL: Level %d verification failed!" % lvl)
			quit(1)
			return

	# 8. Verify Wrong-Color Fail Detection & Decoy Trap Fail Detection
	if not await _verify_fail_detection():
		printerr("FAIL: Fail detection test failed!")
		quit(1)
		return

	# 9. Verify Next Level & Restart button callbacks
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

	print("=== ALL TESTS PASSED SUCCESSFULLY (%d/100 levels + mechanics + economy + save + services) ===" % total_levels)
	quit(0)

func _verify_component_scenes() -> bool:
	print("--- Testing Component Scene Loading ---")
	var required_scenes := [
		"res://scenes/main.tscn",
		"res://scenes/components/ball.tscn",
		"res://scenes/components/container_bucket.tscn",
		"res://scenes/components/cuttable_beam.tscn",
		"res://scenes/components/cuttable_rope.tscn",
		"res://scenes/components/ramp.tscn",
		"res://scenes/components/chain_trigger.tscn",
		"res://scenes/components/bumper_pin.tscn",
		"res://scenes/components/color_filter_gate.tscn",
		"res://scenes/components/color_dye_ring.tscn",
		"res://scenes/components/seesaw_bridge.tscn",
		"res://scenes/components/steel_chain.tscn",
		"res://scenes/components/portal_pair.tscn",
		"res://scenes/components/moving_deflector.tscn",
		"res://scenes/components/tutorial_guide.tscn"
	]
	for path in required_scenes:
		var packed: PackedScene = load(path)
		if packed == null:
			printerr("FAIL: Could not load scene: %s" % path)
			return false
		var inst := packed.instantiate()
		if inst == null:
			printerr("FAIL: Could not instantiate scene: %s" % path)
			return false
		inst.free()
	print("  PASS: All %d component scenes loaded and instantiated cleanly." % required_scenes.size())
	return true

func _verify_save_manager_and_economy() -> bool:
	print("--- Testing SaveManager, Checksum, Backup Recovery & Cosmetics ---")
	var test_path := "user://test_commercial_save.cfg"
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	if FileAccess.file_exists(test_path + ".bak"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + ".bak"))

	var sm := SaveManager.new(test_path)
	sm.reset_to_defaults(true)
	if sm.highest_unlocked_level != 1 or sm.coins != 0:
		printerr("FAIL: SaveManager default state invalid")
		return false

	var earned := sm.record_level_win(1, 3, 1)
	if earned <= 0 or sm.highest_unlocked_level != 2 or sm.get_level_stars(1) != 3:
		printerr("FAIL: SaveManager record_level_win failed")
		return false

	# Save again so .bak is populated with valid state
	sm.coins = 500
	sm.save_data()

	# Verify reload
	var sm2 := SaveManager.new(test_path)
	if sm2.highest_unlocked_level != 2 or sm2.coins != 500 or sm2.get_level_stars(1) != 3:
		printerr("FAIL: SaveManager reload mismatch")
		return false

	# Unlock & equip cosmetic
	if not sm2.unlock_cosmetic_with_coins("neon_blue"):
		printerr("FAIL: Could not unlock neon_blue with 500 coins")
		return false
	if sm2.equipped_cosmetic != "neon_blue" or sm2.coins != 380:
		printerr("FAIL: Cosmetic unlock coin deduction or equip state mismatch")
		return false

	# Corrupt primary file and verify automatic recovery from .bak
	var bad_file := FileAccess.open(test_path, FileAccess.WRITE)
	bad_file.store_string("[progress]\nhighest_unlocked_level=99\ncoins=999999\n[meta]\nchecksum=\"corrupted_hash\"\n")
	bad_file.close()

	var sm3 := SaveManager.new(test_path)
	if sm3.highest_unlocked_level == 99 or sm3.coins == 999999:
		printerr("FAIL: SaveManager accepted tampered checksum!")
		return false
	if sm3.highest_unlocked_level != 2:
		printerr("FAIL: SaveManager did not recover from .bak backup!")
		return false

	# Clean up test save files
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	if FileAccess.file_exists(test_path + ".bak"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + ".bak"))

	print("  PASS: SaveManager persistence, SHA-256 checksum, .bak recovery, and cosmetics verified.")
	return true

func _verify_services_and_daily() -> bool:
	print("--- Testing DailyChallenge, AnalyticsService, AdService & BillingService ---")
	var d1 := DailyChallenge.get_level_index_for_date("2026-11-15")
	var d2 := DailyChallenge.get_level_index_for_date("2026-11-15")
	if d1 != d2 or d1 < 1 or d1 > LevelData.TOTAL_LEVELS:
		printerr("FAIL: DailyChallenge deterministic level index invalid: %d" % d1)
		return false

	var an := AnalyticsService.new()
	an.log_event("level_start", {"level": 1})
	if not an.has_logged_event("level_start"):
		printerr("FAIL: AnalyticsService did not record level_start")
		return false
	an.consent_granted = false
	an.log_event("custom_event", {})
	if an.has_logged_event("custom_event"):
		printerr("FAIL: AnalyticsService logged non-essential event when consent_granted=false")
		return false

	var ads := AdService.new()
	ads.initialize(true, false)
	# Level 5 (< 11) must never show interstitial
	if ads.can_show_interstitial(5, 500.0):
		printerr("FAIL: AdService allowed interstitial before Level 11")
		return false
	# Simulate 3 completed levels and check level 12 at t=500s
	ads.on_level_completed_break(11, 100.0, Callable())
	ads.on_level_completed_break(12, 200.0, Callable())
	if not ads.on_level_completed_break(13, 400.0, Callable()):
		printerr("FAIL: AdService did not trigger eligible interstitial on 3rd level break >= Level 11")
		return false
	# Immediately after interstitial, cooldown must block next one
	if ads.can_show_interstitial(14, 410.0):
		printerr("FAIL: AdService did not enforce cooldown after interstitial")
		return false

	# Test BillingService SKU validation and production security gate
	var temp_path := "user://test_billing_save.cfg"
	var temp_sm := SaveManager.new(temp_path)
	temp_sm.reset_to_defaults(true)
	var billing := BillingService.new(temp_sm)
	if billing.purchase_product("invalid_sku_hack"):
		printerr("FAIL: BillingService accepted invalid SKU")
		return false
	billing.allow_sandbox_mock_purchases = false
	if billing.purchase_remove_ads():
		printerr("FAIL: BillingService granted unverified purchase when allow_sandbox_mock_purchases=false")
		return false
	billing.allow_sandbox_mock_purchases = true
	if not billing.purchase_remove_ads() or not billing.has_remove_ads():
		printerr("FAIL: BillingService failed valid sandbox purchase")
		return false
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	if FileAccess.file_exists(temp_path + ".bak"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path + ".bak"))

	print("  PASS: DailyChallenge, AnalyticsService, AdService frequency caps, and BillingService verified.")
	return true

func _verify_move_accounting_and_uncuttables() -> bool:
	print("--- Testing Move Accounting & Uncuttable SteelChain Rejection ---")
	# Load Level 51 (which has uncuttable SteelChain barriers at (185, 920) and (535, 920))
	_main_node.load_level(51)
	await process_frame
	await physics_frame
	var lc: LevelController = _main_node.current_level

	# 1. Swipe across empty space -> 0 moves consumed
	_main_node.slice_controller.simulate_swipe(Vector2(60, 200), Vector2(180, 200))
	if lc.moves_used != 0:
		printerr("FAIL: Empty air swipe consumed a move! moves_used=%d" % lc.moves_used)
		return false

	# 2. Swipe across uncuttable SteelChain at (185, 920) -> 0 moves consumed
	_main_node.slice_controller.simulate_swipe(Vector2(185, 880), Vector2(185, 960))
	if lc.moves_used != 0:
		printerr("FAIL: Swiping uncuttable SteelChain consumed a move! moves_used=%d" % lc.moves_used)
		return false

	# 3. Swipe valid striker rope at (360, 245) -> 1 move consumed
	var cut_cnt: int = _main_node.slice_controller.simulate_swipe(Vector2(310, 245), Vector2(410, 245))
	if cut_cnt != 1 or lc.moves_used != 1:
		printerr("FAIL: Valid cut did not record moves_used=1 (cut_cnt=%d, moves_used=%d)" % [cut_cnt, lc.moves_used])
		return false

	# 4. Swipe the same already-cut rope again -> still 1 move
	_main_node.slice_controller.simulate_swipe(Vector2(310, 245), Vector2(410, 245))
	if lc.moves_used != 1:
		printerr("FAIL: Re-swiping already cut rope incremented moves_used to %d" % lc.moves_used)
		return false

	print("  PASS: Invalid swipes and uncuttable SteelChains consume 0 moves; valid cuts increment moves_used.")
	return true

func _verify_pause_and_modals() -> bool:
	print("--- Testing Pause/Resume & Modal Controls ---")
	_main_node.load_level(1)
	await process_frame
	_main_node.toggle_pause()
	if not paused or not _main_node._pause_backdrop.visible or _main_node.slice_controller.enabled:
		printerr("FAIL: toggle_pause() did not pause SceneTree or disable SliceController")
		return false
	_main_node.toggle_pause()
	if paused or _main_node._pause_backdrop.visible or not _main_node.slice_controller.enabled:
		printerr("FAIL: second toggle_pause() did not resume cleanly")
		return false
	print("  PASS: Pause/Resume and modal states verified.")
	return true

func _verify_level_solvable(lvl: int, use_real_touch: bool = false) -> bool:
	_main_node.load_level(lvl)
	await process_frame
	await physics_frame

	var lc: LevelController = _main_node.current_level
	if lc == null:
		printerr("LevelController is null for level %d" % lvl)
		return false

	# Wait 24 physics frames (0.4s) before cutting to verify balls are stably held prior to player action
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
		if use_real_touch:
			_main_node.slice_controller.dispatch_real_touch_swipe(from_pt, to_pt)
		else:
			var sliced: int = _main_node.slice_controller.simulate_swipe(from_pt, to_pt)
			if sliced <= 0:
				printerr("  WARNING: Level %d Step %d (%s -> %s) did not slice any object!" % [lvl, step_idx + 1, str(from_pt), str(to_pt)])

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
				print("  PASS: Level %3d (%s) WON at frame %d (moves=%d/%d, touch=%s)" % [
					lvl, lc.level_title, frame, lc.moves_used, lc.par_moves, str(use_real_touch)
				])
			else:
				printerr("  FAIL: Level %d ended in FAIL state at frame %d! Reason: %s" % [lvl, frame, _main_node._modal_body.text])
				_dump_ball_positions(lc)
			break

	if not lc.is_finished:
		printerr("  FAIL: Level %d timed out without finishing!" % lvl)
		_dump_ball_positions(lc)
		return false

	return won

func _verify_fail_detection() -> bool:
	print("--- Testing Wrong-Color & Decoy Trap Fail Detection ---")
	_main_node.load_level(1)
	await process_frame
	await physics_frame
	var lc: LevelController = _main_node.current_level
	# Drop a BLUE ball directly into the RED container at (210, 1020)
	lc.add_ball(Vector2(210, 1020), GameColors.ColorType.BLUE)
	var wrong_color_ok := false
	for f in range(60):
		await physics_frame
		if lc.is_finished and _main_node._modal_header.text == "LEVEL FAILED":
			wrong_color_ok = true
			break
	if not wrong_color_ok:
		printerr("FAIL: Wrong-color fail detection did not trigger on Level 1")
		return false

	# Test Level 7 decoy rope cut (✖ at (360, 305)) -> wrong-color ball falls into center container
	_main_node.load_level(7)
	await process_frame
	await physics_frame
	lc = _main_node.current_level
	# Cut the decoy rope at (360, 305)
	_main_node.slice_controller.simulate_swipe(Vector2(310, 305), Vector2(410, 305))
	var decoy_fail_ok := false
	for f in range(180):
		await physics_frame
		if lc.is_finished and _main_node._modal_header.text == "LEVEL FAILED":
			decoy_fail_ok = true
			break
	if not decoy_fail_ok:
		printerr("FAIL: Cutting decoy rope on Level 7 did not trigger LEVEL FAILED")
		return false

	print("  PASS: Wrong-color and decoy-trap fail detection verified.")
	return true

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
