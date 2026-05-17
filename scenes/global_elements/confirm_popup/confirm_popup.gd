extends Panel

# Señal que emite la respuesta
signal confirm(value: bool)

@onready var label: Label = %Text

# Cargar texto del label
func load_text(text: String):
	label.text = text

# Botones que emiten el valor de la señal
func _on_yes_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	confirm.emit(true)
	queue_free()

func _on_no_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	confirm.emit(false)
	queue_free()
