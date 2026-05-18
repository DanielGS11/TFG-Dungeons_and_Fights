extends Control

## Shader de brillo
@onready var bright: ColorRect = $Bright/ColorRect

# Botones de la pantalla
## Botón 'Modo batalla'
@onready var battle_mode_button = $BattleMode

## Botón 'Modo mazmorra'
@onready var dungeon_mode_button = $DungeonMode

## Botón 'Equipos'
@onready var teams_button = $Teams

## Botón 'Salir'
@onready var exit_button = $Exit

## Botón 'Ajustes'
@onready var settings_button = $Settings

## Botón 'Guías'
@onready var guides_button = $Guides

## Se ejecuta al cargar la escena
func _ready() -> void:
	MusicPlayer.play_music("Menu")
	
	# Configuro el brillo y ejecuto la animación de entrada 
	bright.color.a = GameAPI.get_bright()
	await _animate("entry")

# Métodos de los botones
## Se ejecuta al pulsar el botón 'Modo batalla'
func _on_battle_mode_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Comprueba si hay una partida del modo sin terminar, en caso de que la haya, le pregunta al usuario si quiere reanudarla mediante un popup
	if GameManager.modes[Mode.Type.BATTLE].is_finished == false:
		var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
		add_child(popup)
		
		popup.load_text("Hay una partida de este modo en curso, ¿Quieres seguirla?")
		
		# Si pulsa en 'Si', establece el modo actual, carga la partida guardada y navega a la pantalla del juego
		if await popup.confirm:
			GameAPI.load_saves()
			GameAPI.set_actual_mode(Mode.Type.BATTLE)
			await _animate("exit")
			get_tree().change_scene_to_file("res://scenes/in_game/fight_screen/fight_screen.tscn")
		
		# Si pulsó en 'No' navega a la pantalla del modo para crear una nueva partida
		else:
			await _animate("exit")
			get_tree().change_scene_to_file("res://scenes/menus/battle_mode/battle_mode.tscn")
	
	# De lo contrario, va a la pantalla del modo para crear una partida nueva
	else:
		await _animate("exit")
		get_tree().change_scene_to_file("res://scenes/menus/battle_mode/battle_mode.tscn")

## Se ejecuta al pulsar el botón 'Modo mazmorra'
func _on_dungeon_mode_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Comprueba si hay una partida del modo sin terminar, en caso de que la haya, le pregunta al usuario si quiere reanudarla mediante un popup
	if GameManager.modes[Mode.Type.DUNGEON].is_finished == false:
		var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
		add_child(popup)
		
		popup.load_text("Hay una partida de este modo en curso, ¿Quieres seguirla?")
		
		# Si pulsa en 'Si', establece el modo actual, carga la partida guardada y navega a la pantalla del juego
		if await popup.confirm:
			GameAPI.load_saves()
			GameAPI.set_actual_mode(Mode.Type.DUNGEON)
			await _animate("exit")
			get_tree().change_scene_to_file("res://scenes/in_game/fight_screen/fight_screen.tscn")
		
		# Si pulsó en 'No' navega a la pantalla del modo para crear una nueva partida
		else:
			await _animate("exit")
			get_tree().change_scene_to_file("res://scenes/menus/dungeon_mode/dungeon_mode.tscn")
	
	# De lo contrario, va a la pantalla del modo para crear una partida nueva
	else:
		await _animate("exit")
		get_tree().change_scene_to_file("res://scenes/menus/dungeon_mode/dungeon_mode.tscn")

## Se ejecuta al pulsar el botón 'Equipos'
func _on_teams_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	await _animate("exit")
	
	# Navega a la pantalla de lista de equipos
	get_tree().change_scene_to_file("res://scenes/menus/teams/team_list.tscn")

## Se ejecuta al pulsar el botón 'Salir'
func _on_exit_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Sale del juego
	get_tree().quit()

## Se ejecuta al pulsar el botón 'Ajustes'
func _on_settings_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Carga la pantalla de ajustes del juego
	var settings = preload("res://scenes/global_elements/settings/settings.tscn").instantiate()
	add_child(settings)
	
	# Se conecta a la señal de cambio de brillo si no lo estaba para que se cambie el brillo en pantalla conforme se cambia en los ajustes
	if not settings.bright_changed.is_connected(func(): bright.color.a = GameAPI.get_bright()):
		settings.bright_changed.connect(func(): bright.color.a = GameAPI.get_bright())
	
	# Una vez la pantalla de ajustes se va, configura el brillo en pantalla
	await settings.tree_exited
	bright.color.a = GameAPI.get_bright()

## Se ejecuta al pulsar el botón 'Guías'
func _on_guides_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Carga la pantalla de lista de guías
	add_child(preload("res://scenes/main_menu/guides/guide_list.tscn").instantiate())

## Ejecuta una animación y espera a que termine
func _animate(animation: String):
	# Solo hace la animación si se configuró el uso de animaciones en los ajustes
	if GameAPI.get_config().animations:
		# Se crea un tween (animación independiente para cada botón
		var battle_mode_tween = battle_mode_button.create_tween()
		var dungeon_mode_tween = dungeon_mode_button.create_tween()
		var teams_tween = teams_button.create_tween()
		var exit_tween = exit_button.create_tween()
		var settings_tween = settings_button.create_tween()
		var guides_tween = guides_button.create_tween()
		
		# Se guarda la posición actual de los botones, que será donde terminará el tween
		var battle_mode_pos = battle_mode_button.position.x
		var dungeon_mode_pos = dungeon_mode_button.position.x
		var teams_pos = teams_button.position.x
		var exit_pos = exit_button.position.x
		var settings_pos = settings_button.position.y
		var guides_pos = guides_button.position.y
		
		# Según la animación (entry = entrada, exit = salida) los botones entran en la pantalla o se van
		match animation:
			# Si es la de entrada, se configura la posición de los botones fuera de la pantalla
			"entry":
				battle_mode_button.position.x += get_viewport_rect().size.x
				dungeon_mode_button.position.x += get_viewport_rect().size.x
				teams_button.position.x += get_viewport_rect().size.x
				exit_button.position.x += get_viewport_rect().size.x
				settings_button.position.y += get_viewport_rect().size.y
				guides_button.position.y += get_viewport_rect().size.y
				
				# Establecemos en el tween de cada botón que se moverán hacia la posición del botón antes guardada en un tiempo diferente para cada uno, así no entran todos a la vez
				battle_mode_tween.tween_property(battle_mode_button, "position:x", battle_mode_pos, 0.1)
				dungeon_mode_tween.tween_property(dungeon_mode_button, "position:x", dungeon_mode_pos, 0.15)
				teams_tween.tween_property(teams_button, "position:x", teams_pos, 0.2)
				exit_tween.tween_property(exit_button, "position:x", exit_pos, 0.25)
				settings_tween.tween_property(settings_button, "position:y", settings_pos, 0.15)
				guides_tween.tween_property(guides_button, "position:y", guides_pos, 0.2)
			
			# Si es la de salida, se mueven todos los botones mediante sus tweens en diferente tiempo hacia fuera de la pantalla para que no se vayan todos a la vez
			"exit":
				battle_mode_tween.tween_property(battle_mode_button, "position:x", battle_mode_pos + get_viewport_rect().size.x, 0.1)
				dungeon_mode_tween.tween_property(dungeon_mode_button, "position:x", battle_mode_pos + get_viewport_rect().size.x, 0.15)
				teams_tween.tween_property(teams_button, "position:x", battle_mode_pos + get_viewport_rect().size.x, 0.2)
				exit_tween.tween_property(exit_button, "position:x", battle_mode_pos + get_viewport_rect().size.x, 0.25)
				settings_tween.tween_property(settings_button, "position:y", battle_mode_pos + get_viewport_rect().size.y, 0.15)
				guides_tween.tween_property(guides_button, "position:y", battle_mode_pos + get_viewport_rect().size.y, 0.2)
		
		# Se espera a que la animació termine
		await exit_tween.finished
