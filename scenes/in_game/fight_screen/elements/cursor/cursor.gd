extends Label

# Crea el tween (animación por código) fuera ya que puede quedarse durante mucho tiempo y cambiar de posición
var tween = create_tween()

## Mueve el cursor de sitio
func move_to(pos: Vector2):
	# Para la animación, cambia su posición y ejecuta el método que lo reanuda
	tween.pause()
	global_position = pos
	start()

## Inicia la animación
func start():
	# Guarda la posición del cursor
	var actual_pos = global_position
	
	# Crea una animación en bucle infinita que se mueve hacia arriba ligeramente y de vuelta a su posiciñon cada segundo
	tween.set_loops()
	tween.tween_property(self, "global_position:y", global_position.y * 0.05, 0)
	tween.tween_interval(1)
	tween.tween_property(self, "global_position:y", actual_pos, 0)
	tween.tween_interval(1)
	
	# Reanuda/Inicia la animación
	tween.play()

## Termina la animación y destruye el cursor
func terminate():
	tween.kill()
	queue_free()
