class_name Chapter2Levels
extends RefCounted

## Chapter 2 (Levels 21 - 40): Color Control
## Introduces Color Filter Gates (Levels 21-30) and Color Dye Rings (Levels 31-40).

static func build(lc: LevelController, lvl: int, p: Array) -> void:
	var c0: GameColors.ColorType = p[0]
	var c1: GameColors.ColorType = p[1]
	var c2: GameColors.ColorType = p[2]
	var c3: GameColors.ColorType = p[3]

	if lvl == 21:
		lc.tutorial_tip = "NEW: Color Filter Gates let ONLY matching colored balls pass!"
	elif lvl == 31:
		lc.tutorial_tip = "NEW: Color Dye Rings transform balls into a new color!"

	var use_dye := (lvl >= 31)
	var variant := lvl % 2

	if variant == 1:
		lc.level_subtitle = "Transform balls through Dye Rings and pass through matching Filter Gates!" if use_dye else "Guide balls through matching Color Filter Gates into their containers!"
		lc.par_moves = 4
		var col0 := GameColors.get_main_color(c0)
		var col2 := GameColors.get_main_color(c2)

		lc.add_container(Vector2(150, 1060), c0, 2, 134.0)
		lc.add_container(Vector2(360, 1060), c1, 2, 134.0)
		lc.add_container(Vector2(570, 1060), c2, 2, 134.0)

		lc.add_color_filter_gate(Vector2(150, 935), c0, 128.0, 0.0)
		lc.add_color_filter_gate(Vector2(360, 935), c1, 128.0, 0.0)
		lc.add_color_filter_gate(Vector2(570, 935), c2, 128.0, 0.0)

		var start_c0 := c3 if use_dye else c0
		var start_c1 := c0 if use_dye else c1
		var start_c2 := c1 if use_dye else c2

		lc.add_ramp(Vector2(215, 360), 185.0, -22.0, col0, 0.0, 50.0)
		lc.add_cuttable_beam(Vector2(128, 375), 82.0, 68.0, 1, "1")
		lc.add_ball(Vector2(250, 318), start_c0)
		lc.add_ball(Vector2(205, 336), start_c0)
		lc.add_ramp(Vector2(58, 630), 220.0, 70.0, col0, 0.0, 0.0)
		lc.add_ramp(Vector2(236, 750), 210.0, -78.0, col0, 0.0, 0.0)
		if use_dye:
			lc.add_color_dye_ring(Vector2(145, 845), c0, 34.0)

		var m1 := lc.add_ball(Vector2(342, 560), start_c1)
		lc.add_cuttable_rope(Vector2(342, 470), m1, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		var m2 := lc.add_ball(Vector2(378, 700), start_c1)
		lc.add_cuttable_rope(Vector2(378, 610), m2, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		if use_dye:
			lc.add_color_dye_ring(Vector2(360, 845), c1, 36.0)

		lc.add_ramp(Vector2(505, 360), 185.0, 22.0, col2, 50.0, 0.0)
		lc.add_cuttable_beam(Vector2(592, 375), 82.0, 112.0, 3, "3")
		lc.add_ball(Vector2(470, 318), start_c2)
		lc.add_ball(Vector2(515, 336), start_c2)
		lc.add_ramp(Vector2(662, 630), 220.0, -70.0, col2, 0.0, 0.0)
		lc.add_ramp(Vector2(484, 750), 210.0, 78.0, col2, 0.0, 0.0)
		if use_dye:
			lc.add_color_dye_ring(Vector2(575, 845), c2, 34.0)

		lc.solution_steps = [
			{"delay": 0.20, "from": Vector2(85, 375), "to": Vector2(175, 375)},
			{"delay": 0.20, "from": Vector2(290, 515), "to": Vector2(400, 515)},
			{"delay": 0.20, "from": Vector2(330, 655), "to": Vector2(430, 655)},
			{"delay": 0.20, "from": Vector2(545, 375), "to": Vector2(635, 375)}
		]
	else:
		lc.level_subtitle = "Dye falling balls and route them through four Color Filter Gates!" if use_dye else "Pass all four colors through their matching Color Filter Gates!"
		lc.par_moves = 4
		var col0 := GameColors.get_main_color(c0)
		var col3 := GameColors.get_main_color(c3)

		lc.add_container(Vector2(105, 1060), c0, 2, 118.0)
		lc.add_container(Vector2(275, 1060), c1, 2, 118.0)
		lc.add_container(Vector2(445, 1060), c2, 2, 118.0)
		lc.add_container(Vector2(615, 1060), c3, 2, 118.0)

		lc.add_color_filter_gate(Vector2(105, 940), c0, 112.0, 0.0)
		lc.add_color_filter_gate(Vector2(275, 940), c1, 112.0, 0.0)
		lc.add_color_filter_gate(Vector2(445, 940), c2, 112.0, 0.0)
		lc.add_color_filter_gate(Vector2(615, 940), c3, 112.0, 0.0)

		var s0 := c2 if use_dye else c0
		var s1 := c3 if use_dye else c1
		var s2 := c0 if use_dye else c2
		var s3 := c1 if use_dye else c3

		lc.add_ramp(Vector2(195, 330), 170.0, -22.0, col0, 0.0, 48.0)
		lc.add_cuttable_beam(Vector2(114, 344), 78.0, 68.0, 1, "1")
		lc.add_ball(Vector2(230, 290), s0)
		lc.add_ball(Vector2(188, 306), s0)
		lc.add_ramp(Vector2(46, 610), 210.0, 73.0, col0, 0.0, 0.0)
		lc.add_ramp(Vector2(178, 720), 210.0, -79.0, col0, 0.0, 0.0)
		if use_dye:
			lc.add_color_dye_ring(Vector2(108, 845), c0, 34.0)

		var b1_1 := lc.add_ball(Vector2(262, 540), s1)
		lc.add_cuttable_rope(Vector2(262, 450), b1_1, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		var b1_2 := lc.add_ball(Vector2(288, 720), s1)
		lc.add_cuttable_rope(Vector2(288, 630), b1_2, Vector2(0, 90.0), Vector2.ZERO, 3, "3")
		if use_dye:
			lc.add_color_dye_ring(Vector2(275, 845), c1, 34.0)

		var b2_1 := lc.add_ball(Vector2(432, 540), s2)
		lc.add_cuttable_rope(Vector2(432, 450), b2_1, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		var b2_2 := lc.add_ball(Vector2(458, 720), s2)
		lc.add_cuttable_rope(Vector2(458, 630), b2_2, Vector2(0, 90.0), Vector2.ZERO, 3, "3")
		if use_dye:
			lc.add_color_dye_ring(Vector2(445, 845), c2, 34.0)

		lc.add_ramp(Vector2(525, 330), 170.0, 22.0, col3, 48.0, 0.0)
		lc.add_cuttable_beam(Vector2(606, 344), 78.0, 112.0, 4, "4")
		lc.add_ball(Vector2(490, 290), s3)
		lc.add_ball(Vector2(532, 306), s3)
		lc.add_ramp(Vector2(674, 610), 210.0, -73.0, col3, 0.0, 0.0)
		lc.add_ramp(Vector2(542, 720), 210.0, 79.0, col3, 0.0, 0.0)
		if use_dye:
			lc.add_color_dye_ring(Vector2(612, 845), c3, 34.0)

		lc.solution_steps = [
			{"delay": 0.20, "from": Vector2(70, 344), "to": Vector2(160, 344)},
			{"delay": 0.15, "from": Vector2(220, 495), "to": Vector2(480, 495)},
			{"delay": 0.25, "from": Vector2(240, 675), "to": Vector2(500, 675)},
			{"delay": 0.15, "from": Vector2(560, 344), "to": Vector2(650, 344)}
		]
