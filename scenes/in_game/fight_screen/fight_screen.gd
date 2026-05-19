extends Control

## Contiene el modo actual
var actual_mode: Mode

## Contiene el controlador de batalla del modo actual
var controller: FightController

## Índice del miembro al que le toca actuar
var member_turn := -1

## Diccionario con las acciones a realizar por cada miembro
var queue: Dictionary

## Contiene un duplicado del contenedor de sprite de modificador para establecer varios modicficadores en los personajes sin tener que establecer un tamaño y que pueda variar según el tamaño de pantalla
var modifier_sprite: TextureRect

## Equipo en uso
var team: Team

## Enemigo al que se enfrenta el equipo
var enemy: Enemy

## Shader de brillo
@onready var bright: ColorRect = $Bright/ColorRect

## Fondo del juego
@onready var background: TextureRect = $Background

## Reproductor de animaciones
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## Sprite del enemigo
@onready var enemy_sprite: TextureRect = %EnemySprite

## Datos del enemigo (Vida, nivel, modificadores...)
@onready var enemy_data := %EnemyData

## Sprites del equipo
@onready var team_sprites := %TeamSprites

## Datos del equipo (nombre y nivel)
@onready var team_data := %TeamData

## Barras de maná y vida del equipo
@onready var team_bars := %HealthAndMana

## Cursor que indica de qué miembro elegir la acción
@onready var cursor: Label

## Botón de huir
@onready var run_button: TextureButton = %Run

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Carga una pantalla de carga para que se terminen de cargar los elementos sin congelar la pantalla
	add_child(preload("res://scenes/global_elements/load_screen/load_screen.tscn").instantiate())
	await get_tree().process_frame
	
	# Configuramos el contenedor del sprite de modificador, el brillo, modo actual, controlador y el equipo asignado en el controlador
	modifier_sprite = team_data.get_child(0).get_child(2).get_child(0).duplicate(true)
	actual_mode = GameAPI.get_actual_mode()
	bright.color.a = GameAPI.get_bright()
	controller = GameAPI.get_controller()
	team = controller.team
	
	# Conecta las señales de enemigo derrotado, refrescar dato de un personaje y animación del controlador a sus respectivos métodos, la primera no necesita un método especializado ya que no varía según el dato
	controller.enemy_defeated.connect(func(_a): 
		enemy = null
		enemy_data.visible = false
		enemy_sprite.visible = false
		)
	controller.refresh_data.connect(_load_entity_data)
	controller.animate.connect(_on_animate)
	
	# Conecta, si no lo están, las señales de la línea de comandos y termniar partida de la API
	if not GameAPI.prompt.is_connected(_show_prompt):
		GameAPI.prompt.connect(_show_prompt)
	
	if not GameAPI.end_game.is_connected(_on_game_ended):
		GameAPI.end_game.connect(_on_game_ended)
	
	# Carga los sprites del equipo y dehabilita el botón de huir si está en modo batalla 
	for i in team.members.size():
		var member_sprite: TextureRect = team_sprites.get_child(i).get_child(0)
		member_sprite.texture = team.members[i].sprite
	
	run_button.disabled = actual_mode.mode == Mode.Type.BATTLE
	
	# Conecta la señal de siguiente paso del modo actual si no lo está y crea el cursor
	if not actual_mode.next_step.is_connected(_on_continue):
		actual_mode.next_step.connect(_on_continue)
	
	cursor = preload("res://scenes/in_game/fight_screen/elements/cursor/cursor.tscn").instantiate()
	add_child(cursor)
	
	# Por último, carga el turno del miembro a actuar, mueve el cursor a su posición y le dice al modo que empiece la partida
	_next_turn()
	actual_mode.start()

## Carga todos los datos de los personajes
func _load_all_data():
	# Configura el enemigo a mostrar y cargar datos
	enemy = controller.enemy
	
	# Si el enemigo no existe o ya está derrotado, no se verá nada en pantalla
	if enemy == null or enemy.health == 0:
		enemy_sprite.visible = false
		enemy_data.visible = false
	
	# De lo contrario, carga su sprite, lo hace visible y carga sus datos
	else:
		enemy_sprite.texture = enemy.sprite
		enemy_sprite.visible = true
		enemy_data.visible = true
		
		_load_entity_data(enemy)
	
	# Seguido a esto, carga los datos de los miembros del equipo
	for member in team.members:
		_load_entity_data(member)

# Carga los datos de un personaje
func _load_entity_data(entity: Entity):
	# Si es un enemigo, carga su nivel, vida y sus modificadores activos
	if entity is Enemy:
		# Recogemos los nodos en una variable para plasmar sus datos
		var level: Label = enemy_data.get_child(0).get_child(0)
		var health_bar: TextureProgressBar = enemy_data.get_child(0).get_child(1)
		var modifier_list := enemy_data.get_child(1)
		
		# Limpiamos la lista de modificadores por si hay alguno que ya no esté activo y añadimos duplicados del contenedor de sprite de modificador antes recogido por cada modificador activo
		for i in modifier_list.get_children():
			i.queue_free()
		
		for i in entity.get_modifiers():
			var modifier = modifier_sprite.duplicate(true)
			modifier_list.add_child(modifier)
			
			modifier.texture = i
		
		# Plasmamos los valores del nivel y la vida del enemigo
		level.text = "Lv " + str(entity.level)
		
		health_bar.max_value = entity.max_health
		health_bar.value = entity.health
		
		health_bar.get_child(0).text = str(int(health_bar.value)) + "/" + str(int(health_bar.max_value))
	
	# Si es un miembro del equipo, además, establecemos tambien su maná 
	else:
		# El procedimiento es el mismo que con el enemigo, pero primero recogemos el índice del miembro del equipo para saber qué elemento de cada contenedor modificar
		var id = team.members.find(entity)
		
		var level: Label = team_data.get_child(id).get_child(0)
		var member_name: Label = team_data.get_child(id).get_child(1)
		var health_bar: TextureProgressBar = team_bars.get_child(id).get_child(0)
		var mana_bar: TextureProgressBar = team_bars.get_child(id).get_child(1)
		
		var modifier_list := team_data.get_child(id).get_child(2)
		
		for i in modifier_list.get_children():
			i.queue_free()
		
		for i in team.members[id].get_modifiers():
			var modifier = modifier_sprite.duplicate(true)
			modifier_list.add_child(modifier)
			
			modifier.texture = i
		
		level.text = "Lv " + str(entity.level)
		member_name.text = entity.name
		
		health_bar.max_value = entity.max_health
		health_bar.value = entity.health
		
		mana_bar.max_value = entity.max_mana
		mana_bar.value = entity.mana
		
		health_bar.get_child(0).text = str(int(health_bar.value)) + "/" + str(int(health_bar.max_value))
		mana_bar.get_child(0).text = str(int(mana_bar.value)) + "/" + str(int(mana_bar.max_value))

## Mueve el cursor al miembro que le toque actuar
func _move_cursor():
	# Recoge el sprite del miembro al que le toque actuar y le dice al cursor a dónde tiene que moverse
	var member_sprite = team_sprites.get_child(member_turn).get_child(0)
	cursor.move_to(member_sprite.global_position + Vector2(member_sprite.size.x / 2.3, - 80))

## se ejecuta al pulsar el botón 'Volver' para volver a seleccionar la acción del anterior miembro del equipo
func _on_go_back_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Si el índice del miembro al que le toca actuar es mayor que 0, por lo que ya hay al menos una acción que se seleccionó
	if member_turn > 0:
		# Se mueve el cursor y turno al anterior miembro y se borra su acción para elegirla de nuevo
		member_turn -= 1
		queue.erase(team.members[member_turn])
		
		_move_cursor()

## Carga el turno del siguiente miembro
func _next_turn():
	# Suma 1 al turno del miembro
	member_turn += 1
	
	# Si el turno ya es igual o mayor al tamaño de la lista de miembros del equipo, por lo que ya se habría seleccionado la acción de todos los miembros del equipo
	if member_turn >= team.members.size():
		# Hace invisible el cursor, manda las acciones del equipo al controlador para que las ejecute y espera a que termine
		cursor.visible = false
		
		await controller.set_queue(queue)
		
		# por último, borra la cola y comprueba si queda alguien con vida para mirar el siguiente turno y mover el cursor
		queue.clear()
		if team.members.any(func (member): return member.health > 0):
			cursor.visible = true
			
			member_turn = -1
			_next_turn()
			
			_move_cursor()
	
	# De lo contrario, se comrpueba si el miembro al que le toca actuar sigue con vida
	else:
		# Si está derrotado, se pasa al siguiente miembro ejecutando el método de nuevo
		if team.members[member_turn].health <= 0:
			_next_turn()
		
		# Si no, se mueve el cursor a la posición correspondiente
		else:
			_move_cursor()

## Muestra la línea de comando con la acción que se está realizando
func _show_prompt(prompt: String, pause: bool):
	# Crea la escena de la línea de comandos
	var command_prompt = preload("res://scenes/in_game/fight_screen/elements/command_prompt/command_prompt.tscn").instantiate()
	add_child(command_prompt)
	
	# Si el reproductor está reproduciendo alguna animación, espera antes de poder pulsarse y mostrar el mensaje
	if animation_player.is_playing():
		command_prompt.disabled = true
		await animation_player.animation_finished
	
	# Muestra el mensaje de lo que está pasando y le dice si se debe quedar parado o irse con el tiempo y espera a que termine la línea de comandos para pasar a la siguiente
	command_prompt.load_prompt(prompt, pause)
	await GameAPI.prompt_end

## Al pulsar el botón 'Atacar'
func _on_attack_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Define la acción del miembro del equipo y pasa al siguiente turno
	queue[team.members[member_turn]] = [Entity.Actions.ATTACK, enemy]
	_next_turn()

## Al pulsar el botón 'Magia'
func _on_magic_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# abre el menú de hechizos disponibles del miembro del equipo
	var skill_menu = preload("res://scenes/in_game/fight_screen/elements/skill_menu/skill_menu.tscn").instantiate()
	add_child(skill_menu)
	
	# Conecta la señal que dice si está en el selector de miembro o no y hace invisible el cursor si lo está
	skill_menu.on_selector.connect(func(): cursor.visible = not cursor.visible)
	
	# Le manda al menú el miembro del que cargar los hechizos
	skill_menu.load_skills(team.members[member_turn])
	
	# Recoge en un diccionario la acción del miembro y comprueba si se escogió un hechizo o no para saber si pasar al siguiente miembro
	var member_action: Dictionary = await skill_menu.skill_selected
	if not member_action.is_empty():
		queue.merge(member_action)
		_next_turn()

## Al pulsar el botón 'Defender'
func _on_defend_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Define la acción del miembro del equipo y pasa al siguiente turno
	queue[team.members[member_turn]] = [Entity.Actions.DEFEND]
	_next_turn()

## Al pulsar el botón 'Huir'
func _on_run_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Manda la acción al controlador y resetea el cursor
	controller.run()
	member_turn = -1
	_next_turn()

## Se ejecuta al terminar el la partida
func _on_game_ended(result: GameAPI.Result, text: String):
	MusicPlayer.play_sfx("Click")
	
	# Muestra el mensaje con el resultado de la partida
	await _show_prompt(text, true)
	
	# Dependiendo el resultado, navega a la pantalla de victoria o derrota
	match result:
		GameAPI.Result.WIN:
			get_tree().change_scene_to_file("res://scenes/in_game/results/win_screen/win_screen.tscn")
		
		GameAPI.Result.LOSE:
			get_tree().change_scene_to_file("res://scenes/in_game/results/lose_screen/lose_screen.tscn")

## Se ejecuta al pulsar el botón de ajustes (engranaje de la parte superior izquierda de la pantalla)
func _on_settings_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Al igual que en el menú principal, carga la pantalla de ajustes, cambia el brillo conforme lo haga en los ajustes y, una vez salga dicha pantalla, se carga el brillo actual
	var settings = preload("res://scenes/global_elements/settings/settings.tscn").instantiate()
	add_child(settings)
	
	if not settings.bright_changed.is_connected(func(): bright.color.a = GameAPI.get_bright()):
		settings.bright_changed.connect(func(): bright.color.a = GameAPI.get_bright())
	
	await settings.tree_exited
	bright.color.a = GameAPI.get_bright()

## Se ejecuta al pulsar 'Salir'
func _on_exit_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Pregunta al usuario si quiere salir de la partida y le avisa que perderá el progreso del combate actual mediante un popup
	var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
	add_child(popup)
	popup.load_text("Si abandonas la partida, perderás el progreso de la pelea actual y tendrás que empezarla de nevo")
	
	# Si el usuario pulsó en 'Si', se navega de nuevo al menú principal
	if await popup.confirm:
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

## Se ejecuta al recibir la señal 'next step' (siguiente paso) del modo actual
func _on_continue():
	# Comprueba qué modo es
	match actual_mode.mode:
		# Si es el modo batalla, reproduce (si no lo estaba) su música y carga todos los datos de los personajes
		Mode.Type.BATTLE:
			MusicPlayer.play_music("Battle mode")
			
			_load_all_data()
		
		# Si es el modo mazmorra, comprueba si está en el mapa o no
		Mode.Type.DUNGEON:
			# Si está en el mapa, reproduce la música dle modo mazmorra y abre le mapa
			if actual_mode.is_on_map:
				MusicPlayer.play_music("Dungeon mode")
				
				add_child(preload("res://scenes/in_game/fight_screen/elements/map/dungeon_map.tscn").instantiate())
			
			# Si no, carga la habitación en la que está, su fondo y los datos de los personajes
			else:
				var room: Room = actual_mode.actual_room
				
				# Si la habitación actual es la del jefe, reproduce la música del jefe, si no, la del modo mazzmorra
				if room.room_type == Room.Type.BOSS:
					MusicPlayer.play_music("Dungeon boss")
				
				else:
					MusicPlayer.play_music("Dungeon mode")
				
				background.texture = room.background
				_load_all_data()

## Ejecuta una animación
func _on_animate(id: int, type: String, value):
	# Solo se ejecuta la animación si se configuraron las animaciones en los ajustes
	if GameAPI.get_config().animations:
		# Se guarda el objetivo de la animación y su posicion (esto solo se usará si se necesita mostrar el valor de algo como el daño o curación)
		var target: String
		var pos: Vector2
		
		var value_label = preload("res://scenes/in_game/fight_screen/elements/healing_damage_tween/healing_damage_tween.tscn").instantiate()
		
		# Si el id recogido es -1, se refiere al enemigo, si no, es el índice del miembro del equipo, y se establecen su posición y objetivo de la animación
		if id == -1:
			target = "enemy"
			pos = enemy_sprite.global_position + Vector2(enemy_sprite.size.x / 1.2, 0)
		else:
			var member_sprite = team_sprites.get_child(id).get_child(0)
			target = "player_" + str(id + 1)
			pos = member_sprite.global_position + Vector2(member_sprite.size.x / 2, 0)
		
		# Si el tipo de animacion es curación o daño, se crea el tween (animación independiente por código) que mostrará el valor y se le dará los datos necesarios (posición en la que crearse, valor y color)
		match type:
			"_damaged":
				add_child(value_label)
				
				value_label.start(value, pos, Color.RED)
			
			"_healed":
				add_child(value_label)
				
				value_label.start(value, pos, Color.GREEN)
		
		# Por último, se reproduce la animación correspondiente y se espera a que la animación y, si existe, el elemento que dice el valor de cura/daño desaparezcan
		animation_player.play(target + type)
		await animation_player.animation_finished
		
		if is_instance_valid(value_label):
			await value_label.tree_exited
