extends Button

## Texto de la línea de comandos
@onready var prompt_text: Label = $VBoxContainer/PromptContainer/Label

## Puntero que se encarga de indicar que se debe pulsar para seguir
@onready var pointer: Label = $VBoxContainer/PromptContainer/Cursor

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Simplemente inicia la animación del puntero
	pointer.start()

## Carga los datos de la escena
func load_prompt(prompt: String, pause) -> void:
	# Plasma el texto recibido en su variable correspondiente para mostrar
	prompt_text.text = prompt
	
	# Si no es un texto con pausa, se destruirá si no se pulsa a los 1.25 segundos
	if pause == false:
		await get_tree().create_timer(1.25).timeout
		_finish()

## Se ejecuta al pulsar en cualquier parte de la pantalla
func _on_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	_finish()

## Termina la línea de comandos
func _finish():
	# Se deshabilita para prevenir varios toques seguidos antes de destruirse
	disabled = true
	
	# Termina con el puntero, le dice a la API que avise de que se acabó la línea de comandos y se destruye
	pointer.terminate()
	GameAPI.prompt_end.emit()
	queue_free()
