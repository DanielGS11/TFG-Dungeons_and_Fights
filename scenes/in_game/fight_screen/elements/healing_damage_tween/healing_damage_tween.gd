extends Label

## Ejecuta la animación
func start(value: int, pos: Vector2, color: Color):
	# Configura los valores base que tiene
	text = str(value)
	add_theme_color_override("font_color", color)
	position = pos
	
	# Crea el tween (animación por código) y le dice qué animación hacer y la ejecuta
	var tween = create_tween()
	tween.tween_property(self, "position", pos + Vector2(50, -50), 1).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0, 1).set_ease(Tween.EASE_IN)
	
	# Al terminar, se destruye
	tween.chain().tween_callback(queue_free)
