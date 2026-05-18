extends CanvasLayer

## Reproductor de animaciones
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Ejecuta la animación de carga y se destruye al terminar
	animation_player.play("loading")
	await animation_player.animation_finished
	queue_free()
