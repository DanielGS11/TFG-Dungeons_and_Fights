extends Control

# Reproductor de animaciones
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Shader de brillo
@onready var bright: ColorRect = $Bright/ColorRect

# Al cargar la pantalla
func _ready() -> void:
	# Ajusto el brillo de pantalla
	bright.color.a = GameAPI.get_bright()
	
	# Ya que varias clases usan la misma animación, creo un método que ejecute animaciones
	await _animate("entry")

# Botones
func _on_battle_mode_pressed() -> void:
	# Si la partida no terminó, salta un aviso y comprueba si se quiere seguir
	if GameManager.modes[Mode.Type.BATTLE].is_finished == false:
		var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
		add_child(popup)
		
		popup.load_text("Hay una partida de este modo en curso, ¿Quieres seguirla?")
		
		# Esperamos que la notificación envie la señal
		if await popup.confirm:
			GameAPI.set_actual_mode(Mode.Type.BATTLE)
			await _animate("exit")
			get_tree().change_scene_to_file("res://scenes/in_game/fight_screen/fight_screen.tscn")
		
		else:
			get_tree().change_scene_to_file("res://scenes/menus/battle_mode/battle_mode.tscn")
	
	else:
		get_tree().change_scene_to_file("res://scenes/menus/battle_mode/battle_mode.tscn")
	
	await _animate("exit")

func _on_dungeon_mode_pressed() -> void:
	# Si la partida no terminó, salta un aviso y comprueba si se quiere seguir
	if GameManager.modes[Mode.Type.DUNGEON].is_finished == false:
		var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
		add_child(popup)
		
		popup.load_text("Hay una partida de este modo en curso, ¿Quieres seguirla?")
		
		# Esperamos que la notificación envie la señal
		if await popup.confirm:
			GameAPI.set_actual_mode(Mode.Type.DUNGEON)
			await _animate("exit")
			get_tree().change_scene_to_file("res://scenes/in_game/fight_screen/fight_screen.tscn")
		
		else:
			print("no")
			await _animate("exit")
	
	else:
		await _animate("exit")

func _on_teams_pressed() -> void:
	await _animate("exit")
	
	get_tree().change_scene_to_file("res://scenes/menus/teams/team_list.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	var settings = preload("res://scenes/global_elements/settings/settings.tscn").instantiate()
	
	add_child(settings)
	
	if not settings.bright_changed.is_connected(func(value): bright.color.a = value):
		settings.bright_changed.connect(func(value): bright.color.a = value)
	
	await settings.tree_exited
	bright.color.a = GameAPI.get_bright()

func _on_guides_pressed() -> void:
	add_child(preload("res://scenes/main_menu/guides/guide_list.tscn").instantiate())

# Ejecuta una animación y espera a que termine
func _animate(animation: String):
	if GameAPI.get_config().animations:
		animation_player.play(animation)
		animation_player.advance(0)
		await animation_player.animation_finished
