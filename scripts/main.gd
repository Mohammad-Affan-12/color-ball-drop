extends Node2D

const LEVEL_SCENES := {
	1: "res://scenes/levels/level_1.tscn",
	2: "res://scenes/levels/level_2.tscn",
	3: "res://scenes/levels/level_3.tscn",
	4: "res://scenes/levels/level_4.tscn",
	5: "res://scenes/levels/level_5.tscn"
}

const BASE_WIDTH: float = 720.0
const BASE_HEIGHT: float = 1280.0
const APP_VERSION: String = "1.0.0 (Commercial Build)"

var current_level_index: int = 1
var current_level: LevelController = null
var slice_controller: SliceController = null
var sfx: SfxManager = null
var save_manager: SaveManager = null
var analytics: AnalyticsService = null
var ad_service: AdService = null
var billing_service: BillingService = null
var is_daily_challenge_mode: bool = false
var _shake_strength: float = 0.0
var _bg_time: float = 0.0
var _hints_active: bool = false
var _is_paused: bool = false
var _camera: Camera2D = null
var _base_camera_offset: Vector2 = Vector2.ZERO
var _bonus_claimed_this_win: bool = false
var save_path: String = SaveManager.DEFAULT_SAVE_PATH
var _menu_was_open: bool = false
var _puzzle_bounds := Rect2(0, 140, 720, 1040)
var _framing_queued: bool = false
var _ui_layer: CanvasLayer
var _hud: GameplayHud
var _results_modal: ResultsModal
var _pause_modal: PauseModal
var _home_modal: HomeModal
var _level_select_modal: LevelSelectModal
var _cosmetics_modal: CosmeticsModal
var _settings_modal: SettingsModal
var _modal_backdrop: ColorRect
var _modal_header: Label
var _modal_body: Label
var _pause_backdrop: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	_camera.enabled = true
	add_child(_camera)

	save_manager = SaveManager.new(save_path)
	analytics = AnalyticsService.new()
	analytics.consent_granted = save_manager.privacy_consent_granted
	analytics.log_event("session_start", {"version": APP_VERSION})

	ad_service = AdService.new()
	ad_service.initialize(save_manager.privacy_consent_granted, save_manager.remove_ads_owned)
	billing_service = BillingService.new(save_manager)

	sfx = SfxManager.new()
	sfx.name = "SfxManager"
	sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx)
	sfx.muted = save_manager.sfx_muted
	sfx.volume_percent = save_manager.sfx_volume_percent
	sfx.music_muted = save_manager.music_muted
	sfx.music_volume_percent = save_manager.music_volume_percent

	slice_controller = SliceController.new()
	slice_controller.name = "SliceController"
	slice_controller.process_mode = Node.PROCESS_MODE_PAUSABLE
	slice_controller.vibration_enabled = save_manager.vibration_enabled
	slice_controller.current_trail_id = save_manager.equipped_cosmetic
	slice_controller.object_sliced.connect(_on_object_sliced)
	slice_controller.valid_move_performed.connect(_on_valid_move_performed)
	slice_controller.invalid_swipe_performed.connect(_on_invalid_swipe_performed)
	slice_controller.uncuttable_rejected.connect(_on_uncuttable_rejected)
	add_child(slice_controller)

	_build_ui()
	get_viewport().size_changed.connect(_update_viewport_layout)
	_update_viewport_layout()

	current_level_index = clampi(save_manager.highest_unlocked_level, 1, LevelData.TOTAL_LEVELS)
	load_level(current_level_index)
	_play_startup_splash()

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui_layer)

	_hud = GameplayHud.new()
	_hud.layout_changed.connect(_queue_puzzle_framing)
	_hud.build(_ui_layer, open_home_screen, _on_hint_pressed, _on_restart_pressed, toggle_pause, open_level_select, func(lvl_idx: int) -> void:
		sfx.play("ui_click"); is_daily_challenge_mode = false; load_level(lvl_idx)
	)

	_results_modal = ResultsModal.new()
	_results_modal.build(_ui_layer, _on_restart_pressed, _on_next_level_pressed, _on_bonus_coins_ad_pressed, open_level_select)
	_modal_backdrop = _results_modal.backdrop; _modal_header = _results_modal.header_label; _modal_body = _results_modal.body_label

	_pause_modal = PauseModal.new()
	_pause_modal.build(_ui_layer, toggle_pause, _on_toggle_sfx_pressed, _on_toggle_music_pressed, _on_toggle_haptics_pressed,
		func() -> void: _set_paused_state(false); _on_restart_pressed(),
		func() -> void: _set_paused_state(false); open_home_screen(),
		func() -> void: _set_paused_state(false); open_level_select()
	)
	_pause_backdrop = _pause_modal.backdrop

	_home_modal = HomeModal.new()
	_home_modal.build(_ui_layer,
		func() -> void: sfx.play("ui_click"); is_daily_challenge_mode = false; load_level(save_manager.highest_unlocked_level),
		open_level_select, start_daily_challenge, open_cosmetics_modal, open_settings_modal,
		_on_purchase_remove_ads_pressed, func() -> void: sfx.play("ui_click")
	)

	_level_select_modal = LevelSelectModal.new()
	_level_select_modal.build(_ui_layer, func(target_lvl: int) -> void: is_daily_challenge_mode = false; load_level(target_lvl, false),
		func() -> void: sfx.play("ui_click")
	)

	_cosmetics_modal = CosmeticsModal.new()
	_cosmetics_modal.build(_ui_layer, func() -> void: sfx.play("ui_click"), _on_cosmetic_action)

	_settings_modal = SettingsModal.new()
	_settings_modal.build(_ui_layer, APP_VERSION, _on_toggle_sfx_pressed, _on_toggle_music_pressed, _on_toggle_haptics_pressed,
		_on_toggle_colorblind_pressed, _on_toggle_particles_pressed, _on_toggle_consent_pressed,
		_on_restore_purchases_pressed, _on_reset_progress_pressed, func() -> void: sfx.play("ui_click")
	)

func _play_startup_splash() -> void:
	var sb := _results_modal.splash_backdrop
	if sb == null:
		return
	sb.visible = true
	sb.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.18)
	tw.tween_property(sb, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void:
		if is_instance_valid(sb):
			sb.visible = false
	)

func _update_viewport_layout() -> void:
	var vp_size := get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return
	var insets := MobileLayout.safe_insets(get_viewport())
	if _hud != null:
		_hud.layout(insets)
	_update_puzzle_framing()

	for modal_panel in [_results_modal.panel, _pause_modal.panel, _home_modal.panel, _level_select_modal.panel, _cosmetics_modal.panel, _settings_modal.panel]:
		if modal_panel != null:
			MobileLayout.fit_modal(modal_panel, vp_size, insets)

func _queue_puzzle_framing() -> void:
	if not _framing_queued:
		_framing_queued = true
		_update_puzzle_framing.call_deferred()

func _update_puzzle_framing() -> void:
	_framing_queued = false
	var framing := MobileLayout.puzzle_transform(_puzzle_bounds, _hud.puzzle_area())
	_camera.zoom = Vector2.ONE * framing.x.x
	_base_camera_offset = -framing.origin / framing.x.x
	_camera.offset = _base_camera_offset
	_camera.force_update_scroll()

func load_level(level_idx: int, force_unlocked: bool = true) -> void:
	var target_idx := clampi(level_idx, 1, LevelData.TOTAL_LEVELS)
	if not force_unlocked and save_manager != null and not save_manager.is_level_unlocked(target_idx):
		sfx.play("reject")
		return

	current_level_index = target_idx
	_bonus_claimed_this_win = false
	_set_paused_state(false)
	for modal in [_results_modal, _home_modal, _level_select_modal, _cosmetics_modal, _settings_modal]:
		modal.backdrop.hide()
	_menu_was_open = false
	slice_controller.enabled = true

	if current_level != null and is_instance_valid(current_level):
		remove_child(current_level)
		current_level.queue_free()
		current_level = null

	var scene_path: String = LEVEL_SCENES.get(current_level_index, "")
	if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
		current_level = (load(scene_path) as PackedScene).instantiate() as LevelController
	else:
		current_level = LevelController.new()
		current_level.level_number = current_level_index

	current_level.level_won.connect(_on_level_won)
	current_level.level_failed.connect(_on_level_failed)
	current_level.progress_updated.connect(_on_progress_updated)
	current_level.moves_updated.connect(_on_moves_updated)
	current_level.chain_reaction_triggered.connect(_on_chain_reaction)
	current_level.mechanic_sfx_requested.connect(_on_mechanic_sfx_requested)
	add_child(current_level)
	if save_manager != null:
		current_level.set_low_particle_quality(save_manager.particle_quality_low)
		save_manager.stats["levels_played"] = int(save_manager.stats.get("levels_played", 0)) + 1
	current_level.set_hints_visible(_hints_active)

	if analytics != null:
		analytics.log_event("level_start", {"level": current_level_index, "daily_challenge": is_daily_challenge_mode})

	_hud.show_level(current_level_index, current_level.level_title, is_daily_challenge_mode)
	if not current_level.tutorial_tip.is_empty():
		_hud.subtitle_label.text = current_level.tutorial_tip
	_hud.update_moves_display(current_level.moves_used, current_level.par_moves)
	_hud.set_hint_active(_hints_active)
	_puzzle_bounds = MobileLayout.measure_level(current_level)
	_queue_puzzle_framing()
	queue_redraw()

func _on_object_sliced(item: CuttableBase, _pt: Vector2, _cuts_in_swipe: int = 1) -> void:
	sfx.play("slice_rope" if item is CuttableRope else "slice_beam", randf_range(0.95, 1.08))

func _on_valid_move_performed(cuts_count: int) -> void:
	if current_level != null and is_instance_valid(current_level):
		current_level.record_valid_move(cuts_count)
	if save_manager != null:
		save_manager.stats["total_valid_cuts"] = int(save_manager.stats.get("total_valid_cuts", 0)) + cuts_count

func _on_invalid_swipe_performed() -> void:
	if analytics != null:
		analytics.log_event("invalid_cut", {"level": current_level_index})

func _on_uncuttable_rejected(_chain: SteelChain, _pt: Vector2) -> void:
	sfx.play("reject", 1.0)
	_shake_strength = 4.0

func _on_mechanic_sfx_requested(sound_name: String) -> void:
	sfx.play(sound_name, 1.0)

func _on_moves_updated(moves_used: int, par_moves: int) -> void:
	_hud.update_moves_display(moves_used, par_moves)

func _on_chain_reaction() -> void:
	sfx.play("chain", 1.0)
	_shake_strength = 8.0

func _on_progress_updated(collected: int, total_req: int) -> void:
	_hud.update_progress_display(collected, total_req)
	if collected > 0:
		sfx.play("collect", 0.95 + float(collected) * 0.05)

func _on_level_won(lvl_idx: int) -> void:
	slice_controller.enabled = false
	sfx.play("win")
	var earned_stars: int = current_level.compute_earned_stars() if (current_level != null and is_instance_valid(current_level)) else 3
	var moves_taken: int = current_level.moves_used if (current_level != null and is_instance_valid(current_level)) else 1
	var coins_awarded: int = 0
	if save_manager != null:
		coins_awarded = save_manager.record_level_win(lvl_idx, earned_stars, moves_taken)
		if is_daily_challenge_mode:
			coins_awarded += save_manager.record_daily_challenge_win(DailyChallenge.get_today_date_string())
	if analytics != null:
		analytics.log_event("level_complete", {"level": lvl_idx, "stars": earned_stars, "moves": moves_taken, "coins_awarded": coins_awarded})
	_results_modal.show_win(self, lvl_idx, earned_stars, coins_awarded, moves_taken, save_manager)

func _on_level_failed(lvl_idx: int, reason: String) -> void:
	slice_controller.enabled = false
	sfx.play("fail")
	_shake_strength = 12.0
	if save_manager != null:
		save_manager.stats["levels_failed"] = int(save_manager.stats.get("levels_failed", 0)) + 1
	if analytics != null:
		analytics.log_event("level_fail", {"level": lvl_idx, "reason": reason})
	_results_modal.show_fail(self, reason)

func _on_bonus_coins_ad_pressed() -> void:
	if _bonus_claimed_this_win or ad_service == null or save_manager == null:
		return
	sfx.play("ui_click")
	ad_service.show_rewarded_ad("win_bonus_coins", func() -> void:
		_bonus_claimed_this_win = true
		save_manager.coins += 25
		save_manager.save_data()
		sfx.play("star")
		if analytics != null:
			analytics.log_event("rewarded_ad_completed", {"placement": "win_bonus_coins"})
		_results_modal.bonus_btn.text = "Bonus Claimed (+25 coins)"
		_results_modal.bonus_btn.disabled = true
	)

func _on_hint_pressed() -> void:
	sfx.play("ui_click")
	_hints_active = not _hints_active
	_hud.set_hint_active(_hints_active)
	if _hints_active and analytics != null:
		analytics.log_event("hint_used", {"level": current_level_index})
	if current_level != null and is_instance_valid(current_level):
		current_level.set_hints_visible(_hints_active)

func _on_restart_pressed() -> void:
	sfx.play("ui_click")
	if analytics != null:
		analytics.log_event("level_restart", {"level": current_level_index})
	load_level(current_level_index)

func _on_next_level_pressed() -> void:
	sfx.play("ui_click")
	is_daily_challenge_mode = false
	var go_next := func() -> void:
		load_level(current_level_index + 1 if current_level_index < LevelData.TOTAL_LEVELS else 1)
	if ad_service != null:
		ad_service.on_level_completed_break(current_level_index, _bg_time, go_next)
	else:
		go_next.call()

func toggle_pause() -> void:
	sfx.play("ui_click")
	_set_paused_state(not _is_paused)

func _set_paused_state(paused: bool) -> void:
	_is_paused = paused
	get_tree().paused = _is_paused
	if _pause_modal != null and _pause_modal.backdrop != null:
		_pause_modal.backdrop.visible = _is_paused
	if slice_controller != null and _results_modal != null:
		slice_controller.enabled = (not _is_paused) and (not _results_modal.backdrop.visible)
	if _pause_modal != null and sfx != null and slice_controller != null:
		_pause_modal.refresh(sfx, slice_controller)

func open_home_screen() -> void:
	sfx.play("ui_click")
	_set_paused_state(false)
	_home_modal.refresh(save_manager)
	_home_modal.backdrop.visible = true

func start_daily_challenge() -> void:
	sfx.play("ui_click")
	is_daily_challenge_mode = true
	load_level(DailyChallenge.get_level_index_for_date(DailyChallenge.get_today_date_string()), true)

func open_level_select() -> void:
	sfx.play("ui_click")
	_set_paused_state(false)
	_level_select_modal.selected_chapter = clampi(int(ceil(float(current_level_index) / 20.0)), 1, 5)
	_level_select_modal.refresh(save_manager, current_level_index)
	_level_select_modal.backdrop.visible = true

func open_cosmetics_modal() -> void:
	sfx.play("ui_click")
	_set_paused_state(false)
	_cosmetics_modal.refresh(save_manager)
	_cosmetics_modal.backdrop.visible = true

func _on_cosmetic_action(trail_id: String) -> void:
	if save_manager == null:
		return
	if save_manager.owned_cosmetics.has(trail_id):
		save_manager.equip_cosmetic(trail_id)
		slice_controller.current_trail_id = trail_id
		sfx.play("ui_click")
	elif save_manager.unlock_cosmetic_with_coins(trail_id):
		slice_controller.current_trail_id = trail_id
		sfx.play("star")
		if analytics != null:
			analytics.log_event("cosmetic_unlocked", {"id": trail_id})
	else:
		sfx.play("reject")
	_cosmetics_modal.refresh(save_manager)

func open_settings_modal() -> void:
	sfx.play("ui_click")
	_set_paused_state(false)
	_settings_modal.refresh(sfx, slice_controller, save_manager)
	_settings_modal.backdrop.visible = true

func _on_purchase_remove_ads_pressed() -> void:
	sfx.play("ui_click")
	if billing_service.purchase_remove_ads():
		ad_service.remove_ads_owned = true
		if analytics != null:
			analytics.log_event("remove_ads_purchased")
		_home_modal.refresh(save_manager)

func _on_restore_purchases_pressed() -> void:
	sfx.play("ui_click")
	var restored: Array[String] = billing_service.restore_purchases()
	ad_service.remove_ads_owned = save_manager.remove_ads_owned
	_settings_modal.status_label.text = "Purchases verified (%d active)." % restored.size()
	_settings_modal.refresh(sfx, slice_controller, save_manager)

func _on_reset_progress_pressed() -> void:
	sfx.play("reject")
	save_manager.reset_to_defaults(true)
	_settings_modal.status_label.text = "Progress reset to Level 1."
	load_level(1)
	_settings_modal.refresh(sfx, slice_controller, save_manager)

func _on_toggle_sfx_pressed() -> void:
	sfx.muted = not sfx.muted
	if save_manager != null: save_manager.sfx_muted = sfx.muted; save_manager.save_data()
	if not sfx.muted: sfx.play("ui_click")
	_pause_modal.refresh(sfx, slice_controller); _settings_modal.refresh(sfx, slice_controller, save_manager)

func _on_toggle_music_pressed() -> void:
	sfx.music_muted = not sfx.music_muted
	if save_manager != null: save_manager.music_muted = sfx.music_muted; save_manager.save_data()
	sfx.play("ui_click")
	_pause_modal.refresh(sfx, slice_controller); _settings_modal.refresh(sfx, slice_controller, save_manager)

func _on_toggle_haptics_pressed() -> void:
	slice_controller.vibration_enabled = not slice_controller.vibration_enabled
	if save_manager != null: save_manager.vibration_enabled = slice_controller.vibration_enabled; save_manager.save_data()
	sfx.play("ui_click")
	_pause_modal.refresh(sfx, slice_controller); _settings_modal.refresh(sfx, slice_controller, save_manager)

func _on_toggle_colorblind_pressed() -> void:
	if save_manager == null:
		return
	save_manager.colorblind_assist = not save_manager.colorblind_assist
	save_manager.save_data()
	sfx.play("ui_click")
	_settings_modal.refresh(sfx, slice_controller, save_manager)

func _on_toggle_particles_pressed() -> void:
	if save_manager == null:
		return
	save_manager.particle_quality_low = not save_manager.particle_quality_low
	save_manager.save_data()
	if current_level != null and is_instance_valid(current_level):
		current_level.set_low_particle_quality(save_manager.particle_quality_low)
	sfx.play("ui_click")
	_settings_modal.refresh(sfx, slice_controller, save_manager)

func _on_toggle_consent_pressed() -> void:
	if save_manager == null:
		return
	var new_val: bool = not save_manager.privacy_consent_granted
	save_manager.privacy_consent_granted = new_val
	save_manager.privacy_prompt_seen = true
	save_manager.save_data()
	if analytics != null:
		analytics.consent_granted = new_val
	if ad_service != null:
		ad_service.consent_granted = new_val
	sfx.play("ui_click")
	_settings_modal.refresh(sfx, slice_controller, save_manager)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_ESCAPE or k.keycode == KEY_P:
			toggle_pause()
		elif k.keycode == KEY_R and not _is_paused:
			_on_restart_pressed()
		elif k.keycode == KEY_H and not _is_paused:
			_on_hint_pressed()
		elif k.keycode == KEY_N and _results_modal.backdrop.visible and _results_modal.next_btn.visible:
			_on_next_level_pressed()

func _process(delta: float) -> void:
	_sync_menu_state()
	_bg_time += delta
	if _shake_strength > 0.1:
		_shake_strength = lerpf(_shake_strength, 0.0, clampf(delta * 10.0, 0.0, 1.0))
		_camera.offset = _base_camera_offset + Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))
	elif _camera != null and _camera.offset != _base_camera_offset:
		_camera.offset = _base_camera_offset

func _menu_open() -> bool:
	for modal in [_home_modal, _level_select_modal, _cosmetics_modal, _settings_modal]:
		if modal.backdrop.visible:
			return true
	return false

func _sync_menu_state() -> void:
	var menu_open := _menu_open()
	_hud.root.visible = not menu_open
	if menu_open != _menu_was_open:
		_menu_was_open = menu_open
		get_tree().paused = menu_open or _is_paused
		slice_controller.enabled = not menu_open and not _is_paused and not _results_modal.backdrop.visible

func _draw() -> void:
	# Static, quiet background keeps attention on the moving cascade.
	draw_rect(Rect2(-2000, -2000, 5000, 5000), Color("0b1626"))
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("101f32")
	plate.border_color = Color("22394f")
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(30)
	draw_style_box(plate, _puzzle_bounds)
	for x in range(60, 700, 40):
		for y in range(int(_puzzle_bounds.position.y) + 24, int(_puzzle_bounds.end.y) - 20, 40):
			draw_circle(Vector2(x, y), 1.2, Color(0.42, 0.58, 0.68, 0.1))
