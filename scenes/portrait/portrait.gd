extends Control

# Reproductor de animaciones
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Shader de brillo
@onready var bright: ColorRect = $Bright/ColorRect

# Al cargar la pantalla
func _ready() -> void:
	# Carga archivos de guardado si los hay
	GameAPI.load_saves()
	
	# Ajusto el brillo de pantalla
	bright.color.a = GameAPI.get_bright()
	
	# Animación de inicio
	if GameManager.config.animations:
		animation_player.play("entry")
		await animation_player.animation_finished
	
	# Animación de las letras, ejecutada despues de la de inicio
	animation_player.play("idle")

## Al pulsar cualquier lado de la pantalla, navega al menú principal
func _on_enter_pressed() -> void:
	# Comprueba que no esté la animación de entrada ejecutándose
	if animation_player.current_animation != "entry":
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
