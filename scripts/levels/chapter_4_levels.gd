class_name Chapter4Levels
extends RefCounted

## Chapter 4 (Levels 61 - 80): Cascade Factory
## Introduces Portal Pairs (Levels 61-70) and Moving Deflectors (Levels 71-80).

static func build(lc: LevelController, lvl: int, p: Array) -> void:
	var c0: GameColors.ColorType = p[0]
	var c1: GameColors.ColorType = p[1]
	var c2: GameColors.ColorType = p[2]
	var c3: GameColors.ColorType = p[3]

	if lvl == 61:
		lc.tutorial_tip = "NEW: Portal Pairs teleport falling balls across the arena!"
	elif lvl == 71:
		lc.tutorial_tip = "NEW: Moving Deflectors oscillate and rotate along the chutes!"

	var use_deflectors := (lvl >= 71)
	var variant := lvl % 2

	if variant == 1:
		lc.level_subtitle = "Teleport balls across the screen through linked Portal Pairs!"
		lc.par_moves = 6
		var col0 := GameColors.get_main_color(c0)
		var col2 := GameColors.get_main_color(c2)

		lc.add_container(Vector2(150, 1060), c0, 2, 134.0)
		lc.add_container(Vector2(360, 1060), c1, 2, 134.0)
		lc.add_container(Vector2(570, 1060), c2, 2, 134.0)

		var p_left_1 := lc.add_ball(Vector2(150, 310), c2)
		lc.add_cuttable_rope(Vector2(150, 220), p_left_1, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		var p_left_2 := lc.add_ball(Vector2(150, 440), c2)
		lc.add_cuttable_rope(Vector2(150, 350), p_left_2, Vector2(0, 90.0), Vector2.ZERO, 1, "1")
		lc.add_portal_pair(Vector2(150, 560), Vector2(420, 300), col2, Vector2(0, 260))

		var p_right_1 := lc.add_ball(Vector2(570, 310), c0)
		lc.add_cuttable_rope(Vector2(570, 220), p_right_1, Vector2(0, 90.0), Vector2.ZERO, 4, "4")
		var p_right_2 := lc.add_ball(Vector2(570, 440), c0)
		lc.add_cuttable_rope(Vector2(570, 350), p_right_2, Vector2(0, 90.0), Vector2.ZERO, 3, "3")
		lc.add_portal_pair(Vector2(570, 560), Vector2(-420, 300), col0, Vector2(0, 260))

		var mid_1 := lc.add_ball(Vector2(360, 580), c1)
		lc.add_cuttable_rope(Vector2(360, 490), mid_1, Vector2(0, 90.0), Vector2.ZERO, 6, "6")
		var mid_2 := lc.add_ball(Vector2(360, 740), c1)
		lc.add_cuttable_rope(Vector2(360, 650), mid_2, Vector2(0, 90.0), Vector2.ZERO, 5, "5")

		if use_deflectors:
			lc.add_moving_deflector(Vector2(255, 920), 90.0, 90.0, Vector2(0, 25), 2.0, 0.0)
			lc.add_moving_deflector(Vector2(465, 920), 90.0, 90.0, Vector2(0, -25), 2.0, 0.0)

		lc.solution_steps = [
			{"delay": 0.20, "from": Vector2(100, 395), "to": Vector2(200, 395)},
			{"delay": 0.22, "from": Vector2(100, 265), "to": Vector2(200, 265)},
			{"delay": 0.20, "from": Vector2(520, 395), "to": Vector2(620, 395)},
			{"delay": 0.22, "from": Vector2(520, 265), "to": Vector2(620, 265)},
			{"delay": 0.20, "from": Vector2(310, 695), "to": Vector2(410, 695)},
			{"delay": 0.22, "from": Vector2(310, 535), "to": Vector2(410, 535)}
		]
	else:
		lc.level_subtitle = "Combine Portals, Filter Gates, and Factory Deflectors across 4 lanes!"
		lc.par_moves = 4
		var col0 := GameColors.get_main_color(c0)
		var col1 := GameColors.get_main_color(c1)
		var col2 := GameColors.get_main_color(c2)
		var col3 := GameColors.get_main_color(c3)

		lc.add_container(Vector2(105, 1060), c0, 2, 118.0)
		lc.add_container(Vector2(275, 1060), c1, 2, 118.0)
		lc.add_container(Vector2(445, 1060), c2, 2, 118.0)
		lc.add_container(Vector2(615, 1060), c3, 2, 118.0)

		lc.add_ramp(Vector2(195, 330), 170.0, -22.0, col0, 0.0, 48.0)
		lc.add_cuttable_beam(Vector2(114, 344), 78.0, 68.0, 1, "1")
		lc.add_ball(Vector2(230, 290), c0)
		lc.add_ball(Vector2(188, 306), c0)
		lc.add_ramp(Vector2(46, 610), 210.0, 73.0, col0, 0.0, 0.0)
		lc.add_ramp(Vector2(178, 720), 210.0, -79.0, col0, 0.0, 0.0)

		var b_in_1 := lc.add_ball(Vector2(275, 440), c2)
		lc.add_cuttable_rope(Vector2(275, 350), b_in_1, Vector2(0, 90.0), Vector2.ZERO, 3, "3")
		var b_in_2 := lc.add_ball(Vector2(275, 580), c2)
		lc.add_cuttable_rope(Vector2(275, 490), b_in_2, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		lc.add_portal_pair(Vector2(275, 700), Vector2(170, 170), col2, Vector2(0, 250))

		var y_in_1 := lc.add_ball(Vector2(445, 440), c1)
		lc.add_cuttable_rope(Vector2(445, 350), y_in_1, Vector2(0, 90.0), Vector2.ZERO, 3, "3")
		var y_in_2 := lc.add_ball(Vector2(445, 580), c1)
		lc.add_cuttable_rope(Vector2(445, 490), y_in_2, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		lc.add_portal_pair(Vector2(445, 700), Vector2(-170, 170), col1, Vector2(0, 250))

		lc.add_ramp(Vector2(525, 330), 170.0, 22.0, col3, 48.0, 0.0)
		lc.add_cuttable_beam(Vector2(606, 344), 78.0, 112.0, 4, "4")
		lc.add_ball(Vector2(490, 290), c3)
		lc.add_ball(Vector2(532, 306), c3)
		lc.add_ramp(Vector2(674, 610), 210.0, -73.0, col3, 0.0, 0.0)
		lc.add_ramp(Vector2(542, 720), 210.0, 79.0, col3, 0.0, 0.0)

		if use_deflectors:
			lc.add_moving_deflector(Vector2(360, 920), 100.0, 90.0, Vector2(0, 30), 2.2, 0.0)

		lc.solution_steps = [
			{"delay": 0.20, "from": Vector2(70, 344), "to": Vector2(160, 344)},
			{"delay": 0.15, "from": Vector2(230, 535), "to": Vector2(490, 535)},
			{"delay": 0.28, "from": Vector2(230, 395), "to": Vector2(490, 395)},
			{"delay": 0.15, "from": Vector2(560, 344), "to": Vector2(650, 344)}
		]
