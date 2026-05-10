extends Label

func start(value: int, pos: Vector2, color: Color):
	text = str(value)
	add_theme_color_override("font_color", color)
	position = pos
	
	var tween = create_tween()
	
	tween.tween_property(self, "position", pos + Vector2(50, -50), 1).set_ease(Tween.EASE_IN)
