extends Control

## Reproductor de animaciones
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## Logo del juego
@onready var logo = $Logo

## Sensor de pulsación de la pantalla para entrar al juego
@onready var screen = $Enter

## Shader de brillo
@onready var bright: ColorRect = $Bright/ColorRect

## Se ejecuta al cargar la pantalla
func _ready() -> void:
	# Espera a que se carguen los elementos de la escena
	await get_tree().process_frame
	
	# Reproduce la música del menú
	MusicPlayer.play_music("Menu")
	
	# Ejecuto la carga de los archivos de guardado y establezco el brillo y volumen
	GameAPI.load_saves()
	bright.color.a = GameAPI.get_bright()
	GameAPI.set_volume(GameAPI.get_config().volume)
	
	# Se deshabilita el toque en pantalla por si hay animación
	screen.disabled = false
	
	# Ejecuta la animación de inicio si se configuraron las animaciones del juego
	if GameManager.config.animations:
		# La animación es una entrada por la izquierda del logo y un parpadeo blanco
		var final_pos = logo.position.x
		logo.position.x -= get_viewport_rect().size.x + 50
		
		# Pequeña espera para que se posicione correctamente
		await get_tree().create_timer(0.2).timeout
		
		# Se crea un tween para el logo, que es una animación independiente del reproductor
		var tween_logo = logo.create_tween()
		tween_logo.tween_property(logo, "position:x", final_pos, 0.3)
		
		# Esperamos a que el tween termine su animación para ejecutar el destello de entrada y se espera a que termine dicho destello antes de seguir
		await tween_logo.finished
		
		animation_player.play("entry")
		await animation_player.animation_finished
	
	# Animación de las letras, ejecutada despues de la de inicio si se ejecutó antes
	animation_player.play("idle")

## Al pulsar cualquier lado de la pantalla, navega al menú principal
func _on_enter_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
