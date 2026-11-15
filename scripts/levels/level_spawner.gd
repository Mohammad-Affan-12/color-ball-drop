class_name LevelSpawner
extends RefCounted

## Single-responsibility factory for instantiating and wiring level gameplay nodes
## onto a target LevelController.

static func add_ramp(lc: LevelController, pos: Vector2, length: float, angle_deg: float, accent: Color, left_lip: float, right_lip: float) -> Ramp:
	var r := Ramp.new()
	r.position = pos
	r.length = length
	r.rotation_degrees = angle_deg
	r.accent_color = accent
	r.left_lip_height = left_lip
	r.right_lip_height = right_lip
	lc.add_child(r)
	lc.ramps.append(r)
	return r

static func add_container(lc: LevelController, pos: Vector2, c_type: GameColors.ColorType, req_count: int, width: float) -> ColorContainer:
	var bucket := ColorContainer.new()
	bucket.position = pos
	bucket.color_type = c_type
	bucket.required_count = req_count
	bucket.bucket_width = width
	bucket.ball_collected.connect(lc._on_ball_collected)
	bucket.wrong_ball_entered.connect(lc._on_wrong_ball_entered)
	lc.add_child(bucket)
	lc.containers.append(bucket)
	return bucket

static func add_ball(lc: LevelController, pos: Vector2, c_type: GameColors.ColorType, radius: float) -> PuzzleBall:
	var b := PuzzleBall.new()
	b.position = pos
	b.color_type = c_type
	b.radius = radius
	if c_type == GameColors.ColorType.STEEL:
		b.is_heavy_striker = true
	lc.add_child(b)
	lc.balls.append(b)
	return b

static func add_cuttable_beam(lc: LevelController, pos: Vector2, length: float, angle_deg: float, order_hint: int, label_hint: String) -> CuttableBeam:
	var beam := CuttableBeam.new()
	beam.position = pos
	beam.length = length
	beam.rotation_degrees = angle_deg
	beam.hint_order = order_hint
	beam.hint_label = label_hint
	beam.add_to_group("cuttables")
	beam.cut_performed.connect(lc._on_cut_performed)
	lc.add_child(beam)
	lc.cuttables.append(beam)
	return beam

static func add_cuttable_rope(lc: LevelController, anchor_pos: Vector2, body: RigidBody2D, rope_offset: Vector2, impulse: Vector2, order_hint: int, label_hint: String) -> CuttableRope:
	var rope := CuttableRope.new()
	rope.position = anchor_pos
	rope.hint_order = order_hint
	rope.hint_label = label_hint
	rope.add_to_group("cuttables")
	rope.cut_performed.connect(lc._on_cut_performed)
	lc.add_child(rope)
	rope.attach_rigid_body(body, rope_offset, impulse)
	lc.cuttables.append(rope)
	return rope

static func add_chain_trigger(lc: LevelController, pos: Vector2, radius: float, consume_steel: bool) -> ChainTrigger:
	var trig := ChainTrigger.new()
	trig.position = pos
	trig.radius = radius
	trig.consume_striker_ball = consume_steel
	trig.chain_activated.connect(lc._on_chain_activated)
	lc.add_child(trig)
	lc.triggers.append(trig)
	return trig

static func add_bumper_pin(lc: LevelController, pos: Vector2, radius: float, impulse: float, col: Color) -> BumperPin:
	var pin := BumperPin.new()
	pin.position = pos
	pin.radius = radius
	pin.bounce_impulse = impulse
	pin.pin_color = col
	pin.bumper_hit.connect(func(_p: BumperPin, _b: PuzzleBall) -> void:
		lc._settled_timer = 0.0
		lc.mechanic_sfx_requested.emit("bounce")
	)
	lc.add_child(pin)
	lc.bumpers.append(pin)
	return pin

static func add_color_filter_gate(lc: LevelController, pos: Vector2, allowed_color: GameColors.ColorType, length: float, angle_deg: float) -> ColorFilterGate:
	var gate := ColorFilterGate.new()
	gate.position = pos
	gate.allowed_color = allowed_color
	gate.length = length
	gate.rotation_degrees = angle_deg
	gate.gate_passed.connect(func(_g: ColorFilterGate, _b: PuzzleBall) -> void:
		lc.mechanic_sfx_requested.emit("gate")
	)
	lc.add_child(gate)
	lc.filter_gates.append(gate)
	return gate

static func add_color_dye_ring(lc: LevelController, pos: Vector2, target_color: GameColors.ColorType, radius: float) -> ColorDyeRing:
	var ring := ColorDyeRing.new()
	ring.position = pos
	ring.dye_color = target_color
	ring.radius = radius
	ring.ball_dyed.connect(func(r: ColorDyeRing, _b: PuzzleBall, new_c: int) -> void:
		lc.spawn_floating_text(r.global_position + Vector2(0, -24), "DYED %s!" % GameColors.get_color_name(new_c), GameColors.get_light_color(new_c))
		lc.mechanic_sfx_requested.emit("gate")
	)
	lc.add_child(ring)
	lc.dye_rings.append(ring)
	return ring

static func add_seesaw_bridge(lc: LevelController, pos: Vector2, length: float, initial_deg: float, max_tilt: float, alternate: bool) -> SeesawBridge:
	var sb := SeesawBridge.new()
	sb.position = pos
	sb.length = length
	sb.initial_tilt_deg = initial_deg
	sb.max_tilt_deg = max_tilt
	sb.alternate_on_pass = alternate
	sb.seesaw_tipped.connect(func(_s: SeesawBridge, _deg: float) -> void:
		lc._settled_timer = 0.0
		lc.mechanic_sfx_requested.emit("bounce")
	)
	lc.add_child(sb)
	lc.seesaws.append(sb)
	return sb

static func add_steel_chain(lc: LevelController, pos: Vector2, length: float, angle_deg: float) -> SteelChain:
	var sc := SteelChain.new()
	sc.position = pos
	sc.length = length
	sc.rotation_degrees = angle_deg
	sc.uncuttable_hit.connect(func(_c: SteelChain, pt: Vector2) -> void:
		lc.spawn_floating_text(pt + Vector2(0, -18), "UNCUTTABLE!", Color(1.0, 0.45, 0.45))
		lc.mechanic_sfx_requested.emit("reject")
	)
	lc.add_child(sc)
	lc.steel_chains.append(sc)
	return sc

static func add_portal_pair(lc: LevelController, entry_pos: Vector2, exit_offset: Vector2, col: Color, exit_vel: Vector2) -> PortalPair:
	var pp := PortalPair.new()
	pp.position = entry_pos
	pp.exit_offset = exit_offset
	pp.portal_color = col
	pp.exit_velocity_override = exit_vel
	pp.ball_teleported.connect(func(_p: PortalPair, _b: PuzzleBall) -> void:
		lc._settled_timer = 0.0
		lc.spawn_floating_text(entry_pos + exit_offset + Vector2(0, -24), "WARP!", col.lightened(0.35))
		lc.mechanic_sfx_requested.emit("portal")
	)
	lc.add_child(pp)
	lc.portals.append(pp)
	return pp

static func add_moving_deflector(lc: LevelController, pos: Vector2, length: float, angle_deg: float, move_delta: Vector2, speed: float, ang_speed: float) -> MovingDeflector:
	var md := MovingDeflector.new()
	md.position = pos
	md.length = length
	md.rotation_degrees = angle_deg
	md.move_delta = move_delta
	md.cycle_speed = speed
	md.angular_speed_deg = ang_speed
	lc.add_child(md)
	lc.moving_deflectors.append(md)
	return md
