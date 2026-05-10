extends Label

var tween= create_tween()

func move_to(pos: Vector2):
	tween.pause()
	
	global_position = pos
	
	start()

func start():
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 5, 0)
	tween.tween_interval(1)
	tween.tween_property(self, "position:y", position.y + 5, 0)
	tween.tween_interval(1)
	
	tween.play()

func terminate():
	tween.kill()
	queue_free()
