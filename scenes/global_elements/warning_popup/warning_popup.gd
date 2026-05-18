extends Panel

## Texto de aviso
@onready var warning_text: Label = %Text

## Carga el aviso en su texto
func load_warn(text: String):
	warning_text.text = text

## se ejecuta al pulsar 'Ok'
func _on_ok_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Destruye la escena
	queue_free()
