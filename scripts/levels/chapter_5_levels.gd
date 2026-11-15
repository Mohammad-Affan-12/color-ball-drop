class_name Chapter5Levels
extends RefCounted

## Chapter 5 (Levels 81 - 100): Cascade Master
## Master Contraptions combining Chain Triggers, Steel Chains, Dye Rings, Filter Gates, Portals, and Deflectors.

static func build(lc: LevelController, lvl: int, p: Array) -> void:
	var c0: GameColors.ColorType = p[0]
	var c1: GameColors.ColorType = p[1]
	var c2: GameColors.ColorType = p[2]
	var c3: GameColors.ColorType = p[3]

	if lvl == 81:
		lc.tutorial_tip = "CHAPTER 5: Master puzzles combine Triggers, Chains, Dye Rings & Portals!"

	var variant := lvl % 2
	if variant == 1:
		lc.level_subtitle = "Trigger dual chain reactions, retract steel chains, and dye all 4 colors!"
		lc.par_moves = 3
		var col0 := GameColors.get_main_color(c0)
		var col3 := GameColors.get_main_color(c3)

		lc.add_container(Vector2(105, 1060), c0, 2, 118.0)
		lc.add_container(Vector2(275, 1060), c1, 2, 118.0)
		lc.add_container(Vector2(445, 1060), c2, 2, 118.0)
		lc.add_container(Vector2(615, 1060), c3, 2, 118.0)

		lc.add_color_filter_gate(Vector2(105, 955), c0, 112.0, 0.0)
		lc.add_color_filter_gate(Vector2(275, 955), c1, 112.0, 0.0)
		lc.add_color_filter_gate(Vector2(445, 955), c2, 112.0, 0.0)
		lc.add_color_filter_gate(Vector2(615, 955), c3, 112.0, 0.0)

		lc.add_ramp(Vector2(195, 350), 170.0, -22.0, col0, 0.0, 48.0)
		var g0 := lc.add_cuttable_beam(Vector2(114, 364), 78.0, 68.0, 0, "⚡")
		lc.add_ball(Vector2(230, 310), c3)
		lc.add_ball(Vector2(188, 326), c3)
		var f0 := lc.add_ramp(Vector2(46, 620), 210.0, 45.0, col0, 0.0, 0.0)
		lc.add_ramp(Vector2(178, 730), 210.0, -79.0, col0, 0.0, 0.0)
		lc.add_color_dye_ring(Vector2(108, 865), c0, 34.0)

		var st_l := lc.add_ball(Vector2(310, 260), GameColors.ColorType.STEEL, 20.0)
		lc.add_cuttable_rope(Vector2(310, 180), st_l, Vector2(0, 80.0), Vector2.ZERO, 1, "1")
		var tr_l := lc.add_chain_trigger(Vector2(310, 390), 26.0, true)
		tr_l.link_beam_to_break(g0)
		tr_l.link_ramp_to_rotate(f0, 73.0)

		var b1_1 := lc.add_ball(Vector2(275, 550), c2)
		lc.add_cuttable_rope(Vector2(275, 460), b1_1, Vector2(0, 90.0), Vector2.ZERO, 3, "3")
		var b1_2 := lc.add_ball(Vector2(275, 720), c2)
		lc.add_cuttable_rope(Vector2(275, 630), b1_2, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		lc.add_color_dye_ring(Vector2(275, 865), c1, 34.0)

		var b2_1 := lc.add_ball(Vector2(445, 550), c1)
		lc.add_cuttable_rope(Vector2(445, 460), b2_1, Vector2(0, 90.0), Vector2.ZERO, 3, "3")
		var b2_2 := lc.add_ball(Vector2(445, 720), c1)
		lc.add_cuttable_rope(Vector2(445, 630), b2_2, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		lc.add_color_dye_ring(Vector2(445, 865), c2, 34.0)

		var st_r := lc.add_ball(Vector2(410, 260), GameColors.ColorType.STEEL, 20.0)
		lc.add_cuttable_rope(Vector2(410, 180), st_r, Vector2(0, 80.0), Vector2.ZERO, 1, "1")
		var tr_r := lc.add_chain_trigger(Vector2(410, 390), 26.0, true)

		lc.add_ramp(Vector2(525, 350), 170.0, 22.0, col3, 48.0, 0.0)
		var g3 := lc.add_cuttable_beam(Vector2(606, 364), 78.0, 112.0, 0, "⚡")
		lc.add_ball(Vector2(490, 310), c0)
		lc.add_ball(Vector2(532, 326), c0)
		var f3 := lc.add_ramp(Vector2(674, 620), 210.0, -45.0, col3, 0.0, 0.0)
		lc.add_ramp(Vector2(542, 730), 210.0, 79.0, col3, 0.0, 0.0)
		lc.add_color_dye_ring(Vector2(612, 865), c3, 34.0)

		var ch_1 := lc.add_steel_chain(Vector2(275, 910), 108.0, 0.0)
		var ch_2 := lc.add_steel_chain(Vector2(445, 910), 108.0, 0.0)
		tr_l.link_chain_to_retract(ch_1)
		tr_r.link_chain_to_retract(ch_2)
		tr_r.link_beam_to_break(g3)
		tr_r.link_ramp_to_rotate(f3, -73.0)

		lc.solution_steps = [
			{"delay": 0.25, "from": Vector2(270, 220), "to": Vector2(450, 220)},
			{"delay": 0.25, "from": Vector2(230, 675), "to": Vector2(490, 675)},
			{"delay": 0.28, "from": Vector2(230, 505), "to": Vector2(490, 505)}
		]
	else:
		lc.level_subtitle = "Warp through Portals, dye into matching colors, and avoid the decoy trap (✖)!"
		lc.par_moves = 4
		var col0 := GameColors.get_main_color(c0)
		var col1 := GameColors.get_main_color(c1)
		var col2 := GameColors.get_main_color(c2)
		var col3 := GameColors.get_main_color(c3)

		lc.add_container(Vector2(105, 1060), c0, 2, 118.0)
		lc.add_container(Vector2(275, 1060), c1, 2, 118.0)
		lc.add_container(Vector2(445, 1060), c2, 2, 118.0)
		lc.add_container(Vector2(615, 1060), c3, 2, 118.0)

		lc.add_color_filter_gate(Vector2(105, 955), c0, 112.0, 0.0)
		lc.add_color_filter_gate(Vector2(275, 955), c1, 112.0, 0.0)
		lc.add_color_filter_gate(Vector2(445, 955), c2, 112.0, 0.0)
		lc.add_color_filter_gate(Vector2(615, 955), c3, 112.0, 0.0)

		lc.add_ramp(Vector2(195, 330), 170.0, -22.0, col0, 0.0, 48.0)
		lc.add_cuttable_beam(Vector2(114, 344), 78.0, 68.0, 1, "1")
		lc.add_ball(Vector2(230, 290), c1)
		lc.add_ball(Vector2(188, 306), c1)
		lc.add_ramp(Vector2(46, 610), 210.0, 73.0, col0, 0.0, 0.0)
		lc.add_ramp(Vector2(178, 720), 210.0, -79.0, col0, 0.0, 0.0)
		lc.add_color_dye_ring(Vector2(108, 865), c0, 34.0)

		var b_in_1 := lc.add_ball(Vector2(275, 440), c0)
		lc.add_cuttable_rope(Vector2(275, 350), b_in_1, Vector2(0, 90.0), Vector2.ZERO, 3, "3")
		var b_in_2 := lc.add_ball(Vector2(275, 580), c0)
		lc.add_cuttable_rope(Vector2(275, 490), b_in_2, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		lc.add_portal_pair(Vector2(275, 690), Vector2(170, 110), col2, Vector2(0, 220))
		lc.add_color_dye_ring(Vector2(445, 875), c2, 34.0)

		var y_in_1 := lc.add_ball(Vector2(445, 440), c3)
		lc.add_cuttable_rope(Vector2(445, 350), y_in_1, Vector2(0, 90.0), Vector2.ZERO, 3, "3")
		var y_in_2 := lc.add_ball(Vector2(445, 580), c3)
		lc.add_cuttable_rope(Vector2(445, 490), y_in_2, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		lc.add_portal_pair(Vector2(445, 690), Vector2(-170, 110), col1, Vector2(0, 220))
		lc.add_color_dye_ring(Vector2(275, 875), c1, 34.0)

		lc.add_ramp(Vector2(525, 330), 170.0, 22.0, col3, 48.0, 0.0)
		lc.add_cuttable_beam(Vector2(606, 344), 78.0, 112.0, 4, "4")
		lc.add_ball(Vector2(490, 290), c2)
		lc.add_ball(Vector2(532, 306), c2)
		lc.add_ramp(Vector2(674, 610), 210.0, -73.0, col3, 0.0, 0.0)
		lc.add_ramp(Vector2(542, 720), 210.0, 79.0, col3, 0.0, 0.0)
		lc.add_color_dye_ring(Vector2(612, 865), c3, 34.0)

		lc.add_moving_deflector(Vector2(360, 920), 90.0, 90.0, Vector2(0, 25), 2.2, 0.0)

		lc.solution_steps = [
			{"delay": 0.20, "from": Vector2(70, 344), "to": Vector2(160, 344)},
			{"delay": 0.15, "from": Vector2(230, 535), "to": Vector2(490, 535)},
			{"delay": 0.28, "from": Vector2(230, 395), "to": Vector2(490, 395)},
			{"delay": 0.15, "from": Vector2(560, 344), "to": Vector2(650, 344)}
		]
