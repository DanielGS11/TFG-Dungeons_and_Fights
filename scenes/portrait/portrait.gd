extends Control

# Reproductor de animaciones
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var logo = $Logo
@onready var screen = $Enter

# Shader de brillo
@onready var bright: ColorRect = $Bright/ColorRect

# Al cargar la pantalla
func _ready() -> void:
	await get_tree().process_frame
	
	MusicPlayer.play_music("Menu")
	
	# Carga archivos de guardado si los hay
	GameAPI.load_saves()
	
	# Ajusto el brillo de pantalla
	bright.color.a = GameAPI.get_bright()
	
	GameAPI.set_volume(GameAPI.get_config().volume)
	
	# Animación de inicio
	if GameManager.config.animations:
		var final_pos = logo.position.x
		logo.position.x -= get_viewport_rect().size.x + 50
		
		await get_tree().create_timer(0.2).timeout
		
		var tween_logo = logo.create_tween()
		tween_logo.tween_property(logo, "position:x", final_pos, 0.3)
		
		await tween_logo.finished
		
		animation_player.play("entry")
		await animation_player.animation_finished
	
	screen.disabled = false
	
	# Animación de las letras, ejecutada despues de la de inicio
	animation_player.play("idle")

## Al pulsar cualquier lado de la pantalla, navega al menú principal
func _on_enter_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
