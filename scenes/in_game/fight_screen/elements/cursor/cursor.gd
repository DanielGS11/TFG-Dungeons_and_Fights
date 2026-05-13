extends Label

var tween= create_tween()

func move_to(pos: Vector2):
	tween.pause()
	
	global_position = pos
	
	start()

func start():
	var actual_pos = global_position
	
	tween.set_loops()
	tween.tween_property(self, "global_position:y", global_position.y * 0.05, 0)
	tween.tween_interval(1)
	tween.tween_property(self, "global_position:y", actual_pos, 0)
	tween.tween_interval(1)
	
	tween.play()

func terminate():
	tween.kill()
	queue_free()
