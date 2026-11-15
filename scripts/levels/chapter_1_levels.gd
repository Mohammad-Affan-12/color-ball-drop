class_name Chapter1Levels
extends RefCounted

## Chapter 1 (Levels 1 - 20): The First Cut
## Covers Onboarding (Levels 1-5), Order of Operations, Decoy Supports (✖), and Bumper Pins.

static func build(lc: LevelController, lvl: int, p: Array) -> void:
	match lvl:
		1:
			_build_level_1(lc)
		2:
			_build_level_2(lc)
		3:
			_build_level_3(lc)
		4:
			_build_level_4(lc)
		5:
			_build_level_5(lc)
		_:
			_build_progression_level(lc, lvl, p)

static func _build_level_1(lc: LevelController) -> void:
	lc.level_subtitle = "Swipe across the beams and rope to cascade Red & Blue balls!"
	lc.par_moves = 3

	var red_col := GameColors.get_main_color(GameColors.ColorType.RED)
	var blue_col := GameColors.get_main_color(GameColors.ColorType.BLUE)

	lc.add_container(Vector2(185, 1060), GameColors.ColorType.RED, 3, 144.0)
	lc.add_container(Vector2(535, 1060), GameColors.ColorType.BLUE, 2, 144.0)

	lc.add_ramp(Vector2(150, 360), 190.0, 18.0, red_col, 48.0, 0.0)
	lc.add_cuttable_beam(Vector2(246, 370), 82.0, 108.0, 1, "1")
	lc.add_ball(Vector2(115, 322), GameColors.ColorType.RED)
	lc.add_ball(Vector2(160, 336), GameColors.ColorType.RED)

	lc.add_ramp(Vector2(250, 555), 220.0, -20.0, red_col, 0.0, 118.0)
	lc.add_ramp(Vector2(74, 770), 240.0, 62.0, red_col, 0.0, 0.0)

	var rope_ball := lc.add_ball(Vector2(205, 800), GameColors.ColorType.RED)
	lc.add_cuttable_rope(Vector2(205, 710), rope_ball, Vector2(0, 90.0), Vector2.ZERO, 2, "2")

	lc.add_ramp(Vector2(570, 360), 190.0, -18.0, blue_col, 0.0, 48.0)
	lc.add_cuttable_beam(Vector2(474, 370), 82.0, 72.0, 3, "3")
	lc.add_ball(Vector2(605, 322), GameColors.ColorType.BLUE)
	lc.add_ball(Vector2(560, 336), GameColors.ColorType.BLUE)

	lc.add_ramp(Vector2(470, 555), 220.0, 20.0, blue_col, 118.0, 0.0)
	lc.add_ramp(Vector2(646, 770), 240.0, -62.0, blue_col, 0.0, 0.0)

	lc.solution_steps = [
		{"delay": 0.25, "from": Vector2(200, 370), "to": Vector2(290, 370)},
		{"delay": 0.20, "from": Vector2(155, 755), "to": Vector2(255, 755)},
		{"delay": 0.20, "from": Vector2(430, 370), "to": Vector2(520, 370)}
	]

static func _build_level_2(lc: LevelController) -> void:
	lc.level_subtitle = "Route Green, Yellow, and Red balls into their three matching containers!"
	lc.par_moves = 4

	var green_col := GameColors.get_main_color(GameColors.ColorType.GREEN)
	var red_col := GameColors.get_main_color(GameColors.ColorType.RED)

	lc.add_container(Vector2(150, 1060), GameColors.ColorType.GREEN, 2, 134.0)
	lc.add_container(Vector2(360, 1060), GameColors.ColorType.YELLOW, 2, 134.0)
	lc.add_container(Vector2(570, 1060), GameColors.ColorType.RED, 2, 134.0)

	lc.add_ramp(Vector2(215, 360), 185.0, -22.0, green_col, 0.0, 50.0)
	lc.add_cuttable_beam(Vector2(128, 375), 82.0, 68.0, 1, "1")
	lc.add_ball(Vector2(250, 318), GameColors.ColorType.GREEN)
	lc.add_ball(Vector2(205, 336), GameColors.ColorType.GREEN)
	lc.add_ramp(Vector2(58, 630), 220.0, 70.0, green_col, 0.0, 0.0)
	lc.add_ramp(Vector2(236, 750), 210.0, -78.0, green_col, 0.0, 0.0)

	var y_ball_1 := lc.add_ball(Vector2(342, 600), GameColors.ColorType.YELLOW)
	lc.add_cuttable_rope(Vector2(342, 500), y_ball_1, Vector2(0, 100.0), Vector2.ZERO, 2, "2")

	var y_ball_2 := lc.add_ball(Vector2(378, 760), GameColors.ColorType.YELLOW)
	lc.add_cuttable_rope(Vector2(378, 660), y_ball_2, Vector2(0, 100.0), Vector2.ZERO, 3, "3")

	lc.add_ramp(Vector2(505, 360), 185.0, 22.0, red_col, 50.0, 0.0)
	lc.add_cuttable_beam(Vector2(592, 375), 82.0, 112.0, 4, "4")
	lc.add_ball(Vector2(470, 318), GameColors.ColorType.RED)
	lc.add_ball(Vector2(515, 336), GameColors.ColorType.RED)
	lc.add_ramp(Vector2(662, 630), 220.0, -70.0, red_col, 0.0, 0.0)
	lc.add_ramp(Vector2(484, 750), 210.0, 78.0, red_col, 0.0, 0.0)

	lc.solution_steps = [
		{"delay": 0.20, "from": Vector2(85, 375), "to": Vector2(175, 375)},
		{"delay": 0.20, "from": Vector2(290, 550), "to": Vector2(390, 550)},
		{"delay": 0.20, "from": Vector2(330, 710), "to": Vector2(430, 710)},
		{"delay": 0.20, "from": Vector2(545, 375), "to": Vector2(635, 375)}
	]

static func _build_level_3(lc: LevelController) -> void:
	lc.level_subtitle = "Cut the top rope to drop the Steel Striker onto the Chain Trigger!"
	lc.tutorial_tip = "NEW: Steel Strikers activate Chain Triggers (⚡)!"
	lc.tutorial_tip_pos = Vector2(360, 160)
	lc.par_moves = 3

	var blue_col := GameColors.get_main_color(GameColors.ColorType.BLUE)
	var yellow_col := GameColors.get_main_color(GameColors.ColorType.YELLOW)

	lc.add_container(Vector2(185, 1060), GameColors.ColorType.BLUE, 3, 144.0)
	lc.add_container(Vector2(535, 1060), GameColors.ColorType.YELLOW, 3, 144.0)

	lc.add_ramp(Vector2(150, 360), 190.0, 18.0, blue_col, 48.0, 0.0)
	var left_gate := lc.add_cuttable_beam(Vector2(246, 370), 82.0, 108.0, 0, "⚡")
	lc.add_ball(Vector2(115, 322), GameColors.ColorType.BLUE)
	lc.add_ball(Vector2(160, 336), GameColors.ColorType.BLUE)

	var left_pivoting_ramp := lc.add_ramp(Vector2(250, 555), 220.0, 12.0, blue_col, 0.0, 118.0)
	lc.add_ramp(Vector2(74, 770), 240.0, 62.0, blue_col, 0.0, 0.0)

	lc.add_ramp(Vector2(570, 360), 190.0, -18.0, yellow_col, 0.0, 48.0)
	var right_gate := lc.add_cuttable_beam(Vector2(474, 370), 82.0, 72.0, 0, "⚡")
	lc.add_ball(Vector2(605, 322), GameColors.ColorType.YELLOW)
	lc.add_ball(Vector2(560, 336), GameColors.ColorType.YELLOW)

	var right_pivoting_ramp := lc.add_ramp(Vector2(470, 555), 220.0, -12.0, yellow_col, 118.0, 0.0)
	lc.add_ramp(Vector2(646, 770), 240.0, -62.0, yellow_col, 0.0, 0.0)

	var striker := lc.add_ball(Vector2(360, 290), GameColors.ColorType.STEEL, 22.0)
	lc.add_cuttable_rope(Vector2(360, 200), striker, Vector2(0, 90.0), Vector2.ZERO, 1, "1")

	var trig := lc.add_chain_trigger(Vector2(360, 430), 28.0, true)
	trig.link_beam_to_break(left_gate)
	trig.link_beam_to_break(right_gate)
	trig.link_ramp_to_rotate(left_pivoting_ramp, -20.0)
	trig.link_ramp_to_rotate(right_pivoting_ramp, 20.0)

	var blue_rope_ball := lc.add_ball(Vector2(205, 810), GameColors.ColorType.BLUE)
	lc.add_cuttable_rope(Vector2(205, 720), blue_rope_ball, Vector2(0, 90.0), Vector2.ZERO, 2, "2")

	var yellow_rope_ball := lc.add_ball(Vector2(515, 810), GameColors.ColorType.YELLOW)
	lc.add_cuttable_rope(Vector2(515, 720), yellow_rope_ball, Vector2(0, 90.0), Vector2.ZERO, 3, "3")

	lc.solution_steps = [
		{"delay": 0.25, "from": Vector2(310, 245), "to": Vector2(410, 245)},
		{"delay": 0.35, "from": Vector2(155, 765), "to": Vector2(255, 765)},
		{"delay": 0.20, "from": Vector2(465, 765), "to": Vector2(565, 765)}
	]

static func _build_level_4(lc: LevelController) -> void:
	lc.level_subtitle = "Guide Red, Blue, Yellow, and Green balls into all four containers!"
	lc.par_moves = 4

	var red_col := GameColors.get_main_color(GameColors.ColorType.RED)
	var green_col := GameColors.get_main_color(GameColors.ColorType.GREEN)

	lc.add_container(Vector2(105, 1060), GameColors.ColorType.RED, 2, 118.0)
	lc.add_container(Vector2(275, 1060), GameColors.ColorType.BLUE, 2, 118.0)
	lc.add_container(Vector2(445, 1060), GameColors.ColorType.YELLOW, 2, 118.0)
	lc.add_container(Vector2(615, 1060), GameColors.ColorType.GREEN, 2, 118.0)

	lc.add_ramp(Vector2(195, 330), 170.0, -22.0, red_col, 0.0, 48.0)
	lc.add_cuttable_beam(Vector2(114, 344), 78.0, 68.0, 1, "1")
	lc.add_ball(Vector2(230, 290), GameColors.ColorType.RED)
	lc.add_ball(Vector2(188, 306), GameColors.ColorType.RED)
	lc.add_ramp(Vector2(46, 610), 210.0, 73.0, red_col, 0.0, 0.0)
	lc.add_ramp(Vector2(178, 720), 210.0, -79.0, red_col, 0.0, 0.0)

	var b_ball_1 := lc.add_ball(Vector2(262, 540), GameColors.ColorType.BLUE)
	lc.add_cuttable_rope(Vector2(262, 450), b_ball_1, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
	var b_ball_2 := lc.add_ball(Vector2(288, 760), GameColors.ColorType.BLUE)
	lc.add_cuttable_rope(Vector2(288, 670), b_ball_2, Vector2(0, 90.0), Vector2.ZERO, 3, "3")

	var y_ball_1 := lc.add_ball(Vector2(432, 540), GameColors.ColorType.YELLOW)
	lc.add_cuttable_rope(Vector2(432, 450), y_ball_1, Vector2(0, 90.0), Vector2.ZERO, 4, "4")
	var y_ball_2 := lc.add_ball(Vector2(458, 760), GameColors.ColorType.YELLOW)
	lc.add_cuttable_rope(Vector2(458, 670), y_ball_2, Vector2(0, 90.0), Vector2.ZERO, 5, "5")

	lc.add_ramp(Vector2(525, 330), 170.0, 22.0, green_col, 48.0, 0.0)
	lc.add_cuttable_beam(Vector2(606, 344), 78.0, 112.0, 6, "6")
	lc.add_ball(Vector2(490, 290), GameColors.ColorType.GREEN)
	lc.add_ball(Vector2(532, 306), GameColors.ColorType.GREEN)
	lc.add_ramp(Vector2(674, 610), 210.0, -73.0, green_col, 0.0, 0.0)
	lc.add_ramp(Vector2(542, 720), 210.0, 79.0, green_col, 0.0, 0.0)

	lc.solution_steps = [
		{"delay": 0.20, "from": Vector2(70, 344), "to": Vector2(160, 344)},
		{"delay": 0.15, "from": Vector2(220, 495), "to": Vector2(480, 495)},
		{"delay": 0.25, "from": Vector2(240, 715), "to": Vector2(500, 715)},
		{"delay": 0.15, "from": Vector2(560, 344), "to": Vector2(650, 344)}
	]

static func _build_level_5(lc: LevelController) -> void:
	lc.level_subtitle = "Trigger dual chain reactions and cut the ropes to collect all 4 colors!"
	lc.par_moves = 3

	var red_col := GameColors.get_main_color(GameColors.ColorType.RED)
	var yellow_col := GameColors.get_main_color(GameColors.ColorType.YELLOW)

	lc.add_container(Vector2(105, 1060), GameColors.ColorType.RED, 2, 118.0)
	lc.add_container(Vector2(275, 1060), GameColors.ColorType.GREEN, 2, 118.0)
	lc.add_container(Vector2(445, 1060), GameColors.ColorType.BLUE, 2, 118.0)
	lc.add_container(Vector2(615, 1060), GameColors.ColorType.YELLOW, 2, 118.0)

	lc.add_ramp(Vector2(195, 350), 170.0, -22.0, red_col, 0.0, 48.0)
	var red_gate := lc.add_cuttable_beam(Vector2(114, 364), 78.0, 68.0, 0, "⚡")
	lc.add_ball(Vector2(230, 310), GameColors.ColorType.RED)
	lc.add_ball(Vector2(188, 326), GameColors.ColorType.RED)
	var left_funnel := lc.add_ramp(Vector2(46, 620), 210.0, 45.0, red_col, 0.0, 0.0)
	lc.add_ramp(Vector2(178, 730), 210.0, -79.0, red_col, 0.0, 0.0)

	var left_striker := lc.add_ball(Vector2(310, 260), GameColors.ColorType.STEEL, 20.0)
	lc.add_cuttable_rope(Vector2(310, 180), left_striker, Vector2(0, 80.0), Vector2.ZERO, 1, "1")
	var left_trig := lc.add_chain_trigger(Vector2(310, 390), 26.0, true)
	left_trig.link_beam_to_break(red_gate)
	left_trig.link_ramp_to_rotate(left_funnel, 73.0)

	var g_ball_1 := lc.add_ball(Vector2(262, 580), GameColors.ColorType.GREEN)
	lc.add_cuttable_rope(Vector2(262, 490), g_ball_1, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
	var g_ball_2 := lc.add_ball(Vector2(288, 790), GameColors.ColorType.GREEN)
	lc.add_cuttable_rope(Vector2(288, 700), g_ball_2, Vector2(0, 90.0), Vector2.ZERO, 3, "3")

	var b_ball_1 := lc.add_ball(Vector2(432, 580), GameColors.ColorType.BLUE)
	lc.add_cuttable_rope(Vector2(432, 490), b_ball_1, Vector2(0, 90.0), Vector2.ZERO, 4, "4")
	var b_ball_2 := lc.add_ball(Vector2(458, 790), GameColors.ColorType.BLUE)
	lc.add_cuttable_rope(Vector2(458, 700), b_ball_2, Vector2(0, 90.0), Vector2.ZERO, 5, "5")

	var right_striker := lc.add_ball(Vector2(410, 260), GameColors.ColorType.STEEL, 20.0)
	lc.add_cuttable_rope(Vector2(410, 180), right_striker, Vector2(0, 80.0), Vector2.ZERO, 1, "1")
	var right_trig := lc.add_chain_trigger(Vector2(410, 390), 26.0, true)

	lc.add_ramp(Vector2(525, 350), 170.0, 22.0, yellow_col, 48.0, 0.0)
	var yellow_gate := lc.add_cuttable_beam(Vector2(606, 364), 78.0, 112.0, 0, "⚡")
	lc.add_ball(Vector2(490, 310), GameColors.ColorType.YELLOW)
	lc.add_ball(Vector2(532, 326), GameColors.ColorType.YELLOW)
	var right_funnel := lc.add_ramp(Vector2(674, 620), 210.0, -45.0, yellow_col, 0.0, 0.0)
	lc.add_ramp(Vector2(542, 730), 210.0, 79.0, yellow_col, 0.0, 0.0)

	right_trig.link_beam_to_break(yellow_gate)
	right_trig.link_ramp_to_rotate(right_funnel, -73.0)

	lc.solution_steps = [
		{"delay": 0.25, "from": Vector2(270, 220), "to": Vector2(450, 220)},
		{"delay": 0.25, "from": Vector2(220, 535), "to": Vector2(480, 535)},
		{"delay": 0.25, "from": Vector2(240, 745), "to": Vector2(500, 745)}
	]

static func _build_progression_level(lc: LevelController, lvl: int, p: Array) -> void:
	var c0: GameColors.ColorType = p[0]
	var c1: GameColors.ColorType = p[1]
	var c2: GameColors.ColorType = p[2]
	var c3: GameColors.ColorType = p[3]

	if lvl == 6:
		lc.tutorial_tip = "ORDER MATTERS: Drop the Steel Striker BEFORE cutting the ramp beams!"
	elif lvl == 7:
		lc.tutorial_tip = "WATCH OUT: Do NOT cut decoy ropes (✖) holding wrong-color balls!"
	elif lvl == 11:
		lc.tutorial_tip = "NEW: Bumper Pins bounce falling balls with extra energy!"

	var variant := lvl % 3
	if variant == 0:
		lc.level_subtitle = "Flip the lower bridge with the Steel Striker BEFORE releasing the upper ramp balls!"
		lc.par_moves = 4
		var col0 := GameColors.get_main_color(c0)
		var col1 := GameColors.get_main_color(c1)

		lc.add_container(Vector2(185, 1060), c0, 3, 144.0)
		lc.add_container(Vector2(535, 1060), c1, 3, 144.0)

		lc.add_ramp(Vector2(150, 360), 190.0, 18.0, col0, 48.0, 0.0)
		lc.add_cuttable_beam(Vector2(246, 370), 82.0, 108.0, 2, "2")
		lc.add_ball(Vector2(115, 322), c0)
		lc.add_ball(Vector2(160, 336), c0)

		var left_bridge := lc.add_ramp(Vector2(250, 555), 220.0, 15.0, col0, 0.0, 118.0)
		lc.add_ramp(Vector2(74, 770), 240.0, 62.0, col0, 0.0, 0.0)

		lc.add_ramp(Vector2(570, 360), 190.0, -18.0, col1, 0.0, 48.0)
		lc.add_cuttable_beam(Vector2(474, 370), 82.0, 72.0, 3, "3")
		lc.add_ball(Vector2(605, 322), c1)
		lc.add_ball(Vector2(560, 336), c1)

		var right_bridge := lc.add_ramp(Vector2(470, 555), 220.0, -15.0, col1, 118.0, 0.0)
		lc.add_ramp(Vector2(646, 770), 240.0, -62.0, col1, 0.0, 0.0)

		var striker := lc.add_ball(Vector2(360, 285), GameColors.ColorType.STEEL, 22.0)
		lc.add_cuttable_rope(Vector2(360, 195), striker, Vector2(0, 90.0), Vector2.ZERO, 1, "1")
		var trig := lc.add_chain_trigger(Vector2(360, 425), 28.0, true)
		trig.link_ramp_to_rotate(left_bridge, -20.0)
		trig.link_ramp_to_rotate(right_bridge, 20.0)

		var r_ball_0 := lc.add_ball(Vector2(205, 810), c0)
		lc.add_cuttable_rope(Vector2(205, 720), r_ball_0, Vector2(0, 90.0), Vector2.ZERO, 4, "4")
		var r_ball_1 := lc.add_ball(Vector2(515, 810), c1)
		lc.add_cuttable_rope(Vector2(515, 720), r_ball_1, Vector2(0, 90.0), Vector2.ZERO, 4, "4")

		if lvl >= 11:
			lc.add_bumper_pin(Vector2(360, 860), 18.0, 90.0, col0)

		lc.solution_steps = [
			{"delay": 0.20, "from": Vector2(310, 240), "to": Vector2(410, 240)},
			{"delay": 0.40, "from": Vector2(200, 370), "to": Vector2(290, 370)},
			{"delay": 0.15, "from": Vector2(430, 370), "to": Vector2(520, 370)},
			{"delay": 0.20, "from": Vector2(150, 765), "to": Vector2(570, 765)}
		]
	elif variant == 1:
		lc.level_subtitle = "Avoid the decoy trap rope (✖) and slice only the matching supports!"
		lc.par_moves = 4
		var col0 := GameColors.get_main_color(c0)
		var col2 := GameColors.get_main_color(c2)

		lc.add_container(Vector2(150, 1060), c0, 2, 134.0)
		lc.add_container(Vector2(360, 1060), c1, 2, 134.0)
		lc.add_container(Vector2(570, 1060), c2, 2, 134.0)

		lc.add_ramp(Vector2(215, 360), 185.0, -22.0, col0, 0.0, 50.0)
		lc.add_cuttable_beam(Vector2(128, 375), 82.0, 68.0, 1, "1")
		lc.add_ball(Vector2(250, 318), c0)
		lc.add_ball(Vector2(205, 336), c0)
		lc.add_ramp(Vector2(58, 630), 220.0, 70.0, col0, 0.0, 0.0)
		lc.add_ramp(Vector2(236, 750), 210.0, -78.0, col0, 0.0, 0.0)

		var mid_1 := lc.add_ball(Vector2(342, 600), c1)
		lc.add_cuttable_rope(Vector2(342, 500), mid_1, Vector2(0, 100.0), Vector2.ZERO, 2, "2")
		var mid_2 := lc.add_ball(Vector2(378, 760), c1)
		lc.add_cuttable_rope(Vector2(378, 660), mid_2, Vector2(0, 100.0), Vector2.ZERO, 2, "2")

		var decoy_ball := lc.add_ball(Vector2(360, 350), c3)
		lc.add_cuttable_rope(Vector2(360, 260), decoy_ball, Vector2(0, 90.0), Vector2.ZERO, 0, "✖")

		lc.add_ramp(Vector2(505, 360), 185.0, 22.0, col2, 50.0, 0.0)
		lc.add_cuttable_beam(Vector2(592, 375), 82.0, 112.0, 3, "3")
		lc.add_ball(Vector2(470, 318), c2)
		lc.add_ball(Vector2(515, 336), c2)
		lc.add_ramp(Vector2(662, 630), 220.0, -70.0, col2, 0.0, 0.0)
		lc.add_ramp(Vector2(484, 750), 210.0, 78.0, col2, 0.0, 0.0)

		if lvl >= 11:
			lc.add_bumper_pin(Vector2(255, 940), 14.0, 80.0)
			lc.add_bumper_pin(Vector2(465, 940), 14.0, 80.0)

		lc.solution_steps = [
			{"delay": 0.20, "from": Vector2(85, 375), "to": Vector2(175, 375)},
			{"delay": 0.20, "from": Vector2(290, 550), "to": Vector2(390, 550)},
			{"delay": 0.20, "from": Vector2(330, 710), "to": Vector2(430, 710)},
			{"delay": 0.20, "from": Vector2(545, 375), "to": Vector2(635, 375)}
		]
	else:
		lc.level_subtitle = "Use chain triggers and bumper ricochets to sort all four colors!"
		lc.par_moves = 3
		var col0 := GameColors.get_main_color(c0)
		var col3 := GameColors.get_main_color(c3)

		lc.add_container(Vector2(105, 1060), c0, 2, 118.0)
		lc.add_container(Vector2(275, 1060), c1, 2, 118.0)
		lc.add_container(Vector2(445, 1060), c2, 2, 118.0)
		lc.add_container(Vector2(615, 1060), c3, 2, 118.0)

		lc.add_ramp(Vector2(195, 350), 170.0, -22.0, col0, 0.0, 48.0)
		var gate_0 := lc.add_cuttable_beam(Vector2(114, 364), 78.0, 68.0, 0, "⚡")
		lc.add_ball(Vector2(230, 310), c0)
		lc.add_ball(Vector2(188, 326), c0)
		var fun_0 := lc.add_ramp(Vector2(46, 620), 210.0, 45.0, col0, 0.0, 0.0)
		lc.add_ramp(Vector2(178, 730), 210.0, -79.0, col0, 0.0, 0.0)

		var st_l := lc.add_ball(Vector2(310, 260), GameColors.ColorType.STEEL, 20.0)
		lc.add_cuttable_rope(Vector2(310, 180), st_l, Vector2(0, 80.0), Vector2.ZERO, 1, "1")
		var tr_l := lc.add_chain_trigger(Vector2(310, 390), 26.0, true)
		tr_l.link_beam_to_break(gate_0)
		tr_l.link_ramp_to_rotate(fun_0, 73.0)

		var b1_a := lc.add_ball(Vector2(262, 580), c1)
		lc.add_cuttable_rope(Vector2(262, 490), b1_a, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		var b1_b := lc.add_ball(Vector2(288, 790), c1)
		lc.add_cuttable_rope(Vector2(288, 700), b1_b, Vector2(0, 90.0), Vector2.ZERO, 3, "3")

		var b2_a := lc.add_ball(Vector2(432, 580), c2)
		lc.add_cuttable_rope(Vector2(432, 490), b2_a, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		var b2_b := lc.add_ball(Vector2(458, 790), c2)
		lc.add_cuttable_rope(Vector2(458, 700), b2_b, Vector2(0, 90.0), Vector2.ZERO, 3, "3")

		var st_r := lc.add_ball(Vector2(410, 260), GameColors.ColorType.STEEL, 20.0)
		lc.add_cuttable_rope(Vector2(410, 180), st_r, Vector2(0, 80.0), Vector2.ZERO, 1, "1")
		var tr_r := lc.add_chain_trigger(Vector2(410, 390), 26.0, true)

		lc.add_ramp(Vector2(525, 350), 170.0, 22.0, col3, 48.0, 0.0)
		var gate_3 := lc.add_cuttable_beam(Vector2(606, 364), 78.0, 112.0, 0, "⚡")
		lc.add_ball(Vector2(490, 310), c3)
		lc.add_ball(Vector2(532, 326), c3)
		var fun_3 := lc.add_ramp(Vector2(674, 620), 210.0, -45.0, col3, 0.0, 0.0)
		lc.add_ramp(Vector2(542, 730), 210.0, 79.0, col3, 0.0, 0.0)

		tr_r.link_beam_to_break(gate_3)
		tr_r.link_ramp_to_rotate(fun_3, -73.0)

		if lvl >= 11:
			lc.add_bumper_pin(Vector2(190, 940), 14.0, 80.0, col0)
			lc.add_bumper_pin(Vector2(530, 940), 14.0, 80.0, col3)

		lc.solution_steps = [
			{"delay": 0.25, "from": Vector2(270, 220), "to": Vector2(450, 220)},
			{"delay": 0.25, "from": Vector2(220, 535), "to": Vector2(480, 535)},
			{"delay": 0.25, "from": Vector2(240, 745), "to": Vector2(500, 745)}
		]
