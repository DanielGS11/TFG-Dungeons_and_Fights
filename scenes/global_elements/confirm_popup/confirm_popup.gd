extends Panel

## Señal que emite la respuesta
signal confirm(value: bool)

## Texto de aviso
@onready var label: Label = %Text

## Cargar texto de aviso
func load_text(text: String):
	label.text = text

# Botones que emiten el valor de la señal
## Se ejecuta al pulsar 'Si'
func _on_yes_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Manda la señal con la respuesta y se destruye
	confirm.emit(true)
	queue_free()

## Se ejecuta al pulsar 'No'
func _on_no_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Manda la señal con la respuesta y se destruye
	confirm.emit(false)
	queue_free()
