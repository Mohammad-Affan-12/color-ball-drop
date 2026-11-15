extends SceneTree

class FeatureArt extends Node2D:
	var game_texture: ImageTexture
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1024, 500), Color("0b1626"))
		draw_rect(Rect2(645, 28, 330, 444), Color("20374b"))
		draw_texture_rect(game_texture, Rect2(682, 32, 249, 442), false)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(58, 137), "CUT &", HORIZONTAL_ALIGNMENT_LEFT, -1, 76, Color("72e7cd"))
		draw_string(font, Vector2(58, 220), "CASCADE", HORIZONTAL_ALIGNMENT_LEFT, -1, 76, Color("eef6ff"))
		draw_line(Vector2(60, 262), Vector2(560, 262), Color("ffd482"), 5)
		draw_string(font, Vector2(60, 325), "A little cut. A colorful cascade.", HORIZONTAL_ALIGNMENT_LEFT, -1, 29, Color("adbed1"))
		draw_string(font, Vector2(60, 385), "100 physics puzzles", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("eef6ff"))

func _init() -> void:
	call_deferred("_build")

func _build() -> void:
	var icon := Image.new()
	var error := icon.load_svg_from_string(FileAccess.get_file_as_string("res://marketing/store/icon.svg"))
	if error != OK:
		quit(1)
		return
	icon.convert(Image.FORMAT_RGB8)
	icon.save_png("res://marketing/store/icon-512.png")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1024, 500)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var art := FeatureArt.new()
	art.game_texture = ImageTexture.create_from_image(Image.load_from_file("res://marketing/store/gameplay-level-03.png"))
	viewport.add_child(art)
	await process_frame
	await RenderingServer.frame_post_draw
	var graphic := viewport.get_texture().get_image()
	graphic.convert(Image.FORMAT_RGB8)
	graphic.save_png("res://marketing/store/feature-1024x500.png")
	print("Store icon and feature graphic exported from code-native art and genuine gameplay")
	quit()
