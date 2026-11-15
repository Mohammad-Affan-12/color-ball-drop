class_name Ramp
extends StaticBody2D

@export var length: float = 220.0:
	set(value):
		length = maxf(value, 20.0)
		_rebuild_shapes()
		queue_redraw()

@export var thickness: float = 16.0:
	set(value):
		thickness = maxf(value, 6.0)
		_rebuild_shapes()
		queue_redraw()

@export var accent_color: Color = Color(0.32, 0.78, 0.98):
	set(value):
		accent_color = value
		queue_redraw()

@export var bounce_amount: float = 0.08
@export var left_lip_height: float = 0.0:
	set(value):
		left_lip_height = value
		_rebuild_shapes()
		queue_redraw()

@export var right_lip_height: float = 0.0:
	set(value):
		right_lip_height = value
		_rebuild_shapes()
		queue_redraw()

var _main_col: CollisionShape2D
var _left_cap: CollisionShape2D
var _right_cap: CollisionShape2D
var _left_lip_col: CollisionShape2D
var _right_lip_col: CollisionShape2D

func _ready() -> void:
	var mat := PhysicsMaterial.new()
	mat.friction = 0.02
	mat.bounce = bounce_amount
	physics_material_override = mat
	_rebuild_shapes()
	queue_redraw()

func rotate_to_degrees(target_deg: float, duration: float = 0.22) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation_degrees", target_deg, duration)

func move_to_position(target_pos: Vector2, duration: float = 0.22) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", target_pos, duration)

func _rebuild_shapes() -> void:
	for child in get_children():
		child.queue_free()

	var hl := length * 0.5
	var r := thickness * 0.5

	_main_col = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, thickness)
	_main_col.shape = rect
	add_child(_main_col)

	_left_cap = CollisionShape2D.new()
	var c1 := CircleShape2D.new()
	c1.radius = r
	_left_cap.shape = c1
	_left_cap.position = Vector2(-hl, 0.0)
	add_child(_left_cap)

	_right_cap = CollisionShape2D.new()
	var c2 := CircleShape2D.new()
	c2.radius = r
	_right_cap.shape = c2
	_right_cap.position = Vector2(hl, 0.0)
	add_child(_right_cap)

	if left_lip_height > 1.0:
		_left_lip_col = CollisionShape2D.new()
		var l_rect := RectangleShape2D.new()
		l_rect.size = Vector2(thickness, left_lip_height)
		_left_lip_col.shape = l_rect
		_left_lip_col.position = Vector2(-hl + r * 0.5, -left_lip_height * 0.5)
		add_child(_left_lip_col)

	if right_lip_height > 1.0:
		_right_lip_col = CollisionShape2D.new()
		var r_rect := RectangleShape2D.new()
		r_rect.size = Vector2(thickness, right_lip_height)
		_right_lip_col.shape = r_rect
		_right_lip_col.position = Vector2(hl - r * 0.5, -right_lip_height * 0.5)
		add_child(_right_lip_col)

func _draw() -> void:
	var half := length * 0.5
	var r := thickness * 0.5
	var body := Color("34465b")
	var edge := Color("6e8499").lerp(accent_color, 0.2)
	draw_line(Vector2(-half, 4), Vector2(half, 4), Color(0, 0, 0, 0.28), thickness + 3, true)
	draw_circle(Vector2(-half, 0), r, body)
	draw_circle(Vector2(half, 0), r, body)
	draw_line(Vector2(-half, 0), Vector2(half, 0), body, thickness, true)
	draw_line(Vector2(-half, -r + 2), Vector2(half, -r + 2), edge, 2.5, true)
	for side: float in [-1.0, 1.0]:
		var height: float = left_lip_height if side < 0.0 else right_lip_height
		var x: float = side * (half - r * 0.5)
		if height > 1:
			draw_line(Vector2(x, 0), Vector2(x, -height + r), body, thickness, true)
			draw_circle(Vector2(x, -height + r), r, body)
			draw_line(Vector2(x - side * 3, -r), Vector2(x - side * 3, -height + r), edge, 2.5, true)
		draw_circle(Vector2(side * half, 0), 3.0, Color("a7bacb"))
		draw_line(Vector2(side * half - 1.5, 0), Vector2(side * half + 1.5, 0), Color("22334a"), 1.5, true)
