class_name Chapter3Levels
extends RefCounted

## Chapter 3 (Levels 41 - 60): Physics Workshop
## Introduces Seesaw Bridges (Levels 41-50) and Uncuttable Steel Chains (Levels 51-60).

static func build(lc: LevelController, lvl: int, p: Array) -> void:
	var c0: GameColors.ColorType = p[0]
	var c1: GameColors.ColorType = p[1]
	var c2: GameColors.ColorType = p[2]
	var c3: GameColors.ColorType = p[3]

	if lvl == 41:
		lc.tutorial_tip = "NEW: Seesaw Bridges tilt dynamically under falling balls!"
	elif lvl == 51:
		lc.tutorial_tip = "NEW: Steel Chains cannot be cut! Use Chain Triggers (⚡) to retract them!"

	var use_chains := (lvl >= 51)
	var variant := lvl % 2

	if variant == 1:
		lc.level_subtitle = "Retract the armored Steel Chains with the Striker and balance the Seesaw!" if use_chains else "Drop balls onto the Seesaw Bridges to guide them into matching containers!"
		lc.par_moves = 3
		var col0 := GameColors.get_main_color(c0)
		var col1 := GameColors.get_main_color(c1)

		lc.add_container(Vector2(185, 1060), c0, 3, 144.0)
		lc.add_container(Vector2(535, 1060), c1, 3, 144.0)

		lc.add_ramp(Vector2(150, 360), 190.0, 18.0, col0, 48.0, 0.0)
		var left_gate := lc.add_cuttable_beam(Vector2(246, 370), 82.0, 108.0, 0, "⚡")
		lc.add_ball(Vector2(115, 322), c0)
		lc.add_ball(Vector2(160, 336), c0)

		var left_pivoting_ramp := lc.add_ramp(Vector2(250, 555), 220.0, 12.0, col0, 0.0, 118.0)
		lc.add_ramp(Vector2(74, 770), 240.0, 62.0, col0, 0.0, 0.0)

		lc.add_ramp(Vector2(570, 360), 190.0, -18.0, col1, 0.0, 48.0)
		var right_gate := lc.add_cuttable_beam(Vector2(474, 370), 82.0, 72.0, 0, "⚡")
		lc.add_ball(Vector2(605, 322), c1)
		lc.add_ball(Vector2(560, 336), c1)

		var right_pivoting_ramp := lc.add_ramp(Vector2(470, 555), 220.0, -12.0, col1, 118.0, 0.0)
		lc.add_ramp(Vector2(646, 770), 240.0, -62.0, col1, 0.0, 0.0)
		lc.add_seesaw_bridge(Vector2(360, 820), 150.0, -14.0, 16.0, true)

		var striker := lc.add_ball(Vector2(360, 290), GameColors.ColorType.STEEL, 22.0)
		lc.add_cuttable_rope(Vector2(360, 200), striker, Vector2(0, 90.0), Vector2.ZERO, 1, "1")

		var trig := lc.add_chain_trigger(Vector2(360, 430), 28.0, true)
		trig.link_beam_to_break(left_gate)
		trig.link_beam_to_break(right_gate)
		trig.link_ramp_to_rotate(left_pivoting_ramp, -20.0)
		trig.link_ramp_to_rotate(right_pivoting_ramp, 20.0)

		if use_chains:
			var ch_l := lc.add_steel_chain(Vector2(185, 920), 120.0, 0.0)
			var ch_r := lc.add_steel_chain(Vector2(535, 920), 120.0, 0.0)
			trig.link_chain_to_retract(ch_l)
			trig.link_chain_to_retract(ch_r)

		var r0 := lc.add_ball(Vector2(205, 810), c0)
		lc.add_cuttable_rope(Vector2(205, 720), r0, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		var r1 := lc.add_ball(Vector2(515, 810), c1)
		lc.add_cuttable_rope(Vector2(515, 720), r1, Vector2(0, 90.0), Vector2.ZERO, 3, "3")

		lc.solution_steps = [
			{"delay": 0.25, "from": Vector2(310, 245), "to": Vector2(410, 245)},
			{"delay": 0.35, "from": Vector2(155, 765), "to": Vector2(255, 765)},
			{"delay": 0.20, "from": Vector2(465, 765), "to": Vector2(565, 765)}
		]
	else:
		lc.level_subtitle = "Trigger both Chain Switches to retract the Steel Chains and collect 4 colors!"
		lc.par_moves = 3
		var col0 := GameColors.get_main_color(c0)
		var col3 := GameColors.get_main_color(c3)

		lc.add_container(Vector2(105, 1060), c0, 2, 118.0)
		lc.add_container(Vector2(275, 1060), c1, 2, 118.0)
		lc.add_container(Vector2(445, 1060), c2, 2, 118.0)
		lc.add_container(Vector2(615, 1060), c3, 2, 118.0)

		lc.add_ramp(Vector2(195, 350), 170.0, -22.0, col0, 0.0, 48.0)
		var g0 := lc.add_cuttable_beam(Vector2(114, 364), 78.0, 68.0, 0, "⚡")
		lc.add_ball(Vector2(230, 310), c0)
		lc.add_ball(Vector2(188, 326), c0)
		var f0 := lc.add_ramp(Vector2(46, 620), 210.0, 45.0, col0, 0.0, 0.0)
		lc.add_ramp(Vector2(178, 730), 210.0, -79.0, col0, 0.0, 0.0)

		var st_l := lc.add_ball(Vector2(310, 260), GameColors.ColorType.STEEL, 20.0)
		lc.add_cuttable_rope(Vector2(310, 180), st_l, Vector2(0, 80.0), Vector2.ZERO, 1, "1")
		var tr_l := lc.add_chain_trigger(Vector2(310, 390), 26.0, true)
		tr_l.link_beam_to_break(g0)
		tr_l.link_ramp_to_rotate(f0, 73.0)

		var b1_1 := lc.add_ball(Vector2(262, 580), c1)
		lc.add_cuttable_rope(Vector2(262, 490), b1_1, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		var b1_2 := lc.add_ball(Vector2(288, 790), c1)
		lc.add_cuttable_rope(Vector2(288, 700), b1_2, Vector2(0, 90.0), Vector2.ZERO, 3, "3")

		var b2_1 := lc.add_ball(Vector2(432, 580), c2)
		lc.add_cuttable_rope(Vector2(432, 490), b2_1, Vector2(0, 90.0), Vector2.ZERO, 2, "2")
		var b2_2 := lc.add_ball(Vector2(458, 790), c2)
		lc.add_cuttable_rope(Vector2(458, 700), b2_2, Vector2(0, 90.0), Vector2.ZERO, 3, "3")

		var st_r := lc.add_ball(Vector2(410, 260), GameColors.ColorType.STEEL, 20.0)
		lc.add_cuttable_rope(Vector2(410, 180), st_r, Vector2(0, 80.0), Vector2.ZERO, 1, "1")
		var tr_r := lc.add_chain_trigger(Vector2(410, 390), 26.0, true)

		lc.add_ramp(Vector2(525, 350), 170.0, 22.0, col3, 48.0, 0.0)
		var g3 := lc.add_cuttable_beam(Vector2(606, 364), 78.0, 112.0, 0, "⚡")
		lc.add_ball(Vector2(490, 310), c3)
		lc.add_ball(Vector2(532, 326), c3)
		var f3 := lc.add_ramp(Vector2(674, 620), 210.0, -45.0, col3, 0.0, 0.0)
		lc.add_ramp(Vector2(542, 730), 210.0, 79.0, col3, 0.0, 0.0)

		tr_r.link_beam_to_break(g3)
		tr_r.link_ramp_to_rotate(f3, -73.0)

		if use_chains:
			var ch_1 := lc.add_steel_chain(Vector2(275, 920), 108.0, 0.0)
			var ch_2 := lc.add_steel_chain(Vector2(445, 920), 108.0, 0.0)
			tr_l.link_chain_to_retract(ch_1)
			tr_r.link_chain_to_retract(ch_2)

		lc.solution_steps = [
			{"delay": 0.25, "from": Vector2(270, 220), "to": Vector2(450, 220)},
			{"delay": 0.25, "from": Vector2(220, 535), "to": Vector2(480, 535)},
			{"delay": 0.25, "from": Vector2(240, 745), "to": Vector2(500, 745)}
		]
