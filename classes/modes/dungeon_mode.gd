## Modo mazmorra
class_name DungeonMode
extends Mode

## Indica si tiene abierto el mapa de la azmorra
@export var is_on_map: bool

## Indica la dificultad de la partida
@export var difficulty := GameAPI.Difficulty.EASY

## Contiene los datos del mapa de la mazmorra
@export var dungeon_map : MapData

## Contiene los datos de la habitación actual
@export var actual_room: Room

## Indica si se consiguió la llave o no
@export var has_key: bool = false

## se ejecuta al crear el objeto
func _init():
	mode = Type.DUNGEON
	can_escape = true

func new_game(_data: Array):
	GameAPI.set_team(team_index)
	controller = null
	
	is_finished = false
	
	has_key = false
	
	dungeon_map = MapData.new()
	dungeon_map.generate_map(difficulty)
	is_on_map = true
	actual_room = dungeon_map.actual_room
	
	load_controller()

func start():
	load_controller()
	
	# Limpia los modificadores del enemigo y el equipo ya que se empieza el combate desde el principio
	if actual_room.enemy != null:
		actual_room.enemy.clear_modifiers()
	
	for member in team_in_use.members:
		member.clear_modifiers()
	
	# Conecta la señal de huida del controlador si no lo está y avisa de que se dé el siguiente paso
	if not controller.run_away.is_connected(load_map):
		controller.run_away.connect(load_map)
	
	next_step.emit()
	
	if is_on_map == false:
		await GameAPI.send_prompt(actual_room.enemy.name + " apareció", true)

func _on_enemy_defeated(exp_value: int):
	# Suma 1 a los enemigos derrotados, da experiencia a todo el equipo y según el tipo de habitación que se limpió, hace una acción u otra
	enemies_defeated += 1
	
	await GameAPI.send_prompt("El equipo recibió " + str(exp_value) + " puntos de experiencia", false)
	
	actual_room.enemy = null
	
	for member in team_in_use.members:
		await member.get_exp(exp_value)
		
		controller.refresh_data.emit(member)
	
	match actual_room.room_type:
		# Si se terminó con el jefe, se termina la partida
		Room.Type.BOSS:
			is_finished = true
			GameAPI.end_game.emit(GameAPI.Result.WIN, "¡Felicidades, has derrotado al jefe de la mazmorra y conseguido el tesoro!")
		
		# Si se terminó con un minijefe en la sala del tesoro, se informa de que se consiguió la llave y se hace a los minijefes mas fuertes
		Room.Type.TREASURE:
			MusicPlayer.play_sfx("Key")
			
			has_key = true
			dungeon_map.miniboss_multiplier += 1
			await GameAPI.send_prompt("¡Conseguiste la llave!", true)
		
		# Si solo se terminó con un minijefe, se hace a los minijefes mas fuertes
		Room.Type.MINIBOSS:
			dungeon_map.miniboss_multiplier += 1
	
	# Por último, si la partida no se terminó, se abre el mapa
	if is_finished == false:
		load_map()

## Abre el mapa, carga su estado y guarda
func load_map():
	is_on_map = true
	GameAPI.save_game()
	next_step.emit()

## Navega hacia una habitación
func go_to_room(pos: Vector2):
	# En una variable, guarda el nivel del equipo
	var team_level = 0
	
	for member in team_in_use.members:
		team_level += member.level
	
	# Establece que ya no se tiene el mapa abierto y se pide al mapa los datos de la nueva habitación actual mandándole el nivel del equipo para que calcule el nivel del enemigo si lo hay
	is_on_map = false
	
	actual_room = dungeon_map.go_to_room(pos, difficulty, ceili(float(team_level) / team_in_use.members.size()))
	
	# Si la habitación a la que se entra es la del tesoro y ya se recogió el tesoro, se cambia su fondo
	if actual_room.room_type == Room.Type.TREASURE and has_key:
		actual_room.background = GameAPI.get_asset("rooms", "Tesoro recogido")
	
	# Se carga al enemigo en el controlador, se emite la señal de siguiente paso a la escena y se informa de en qué sala nos encontramos
	controller.enemy = actual_room.enemy
	
	next_step.emit()
	
	match actual_room.room_type:
		Room.Type.TREASURE:
			await GameAPI.send_prompt("Entraste a la sala del tesoro", true)
		
		Room.Type.MINIBOSS:
			if actual_room.explored == false:
				await GameAPI.send_prompt("Entraste a una sala de minijefe", true)
		
		Room.Type.LOCK:
			if actual_room.explored == false:
				await GameAPI.send_prompt("Entraste a la sala de la puerta del jefe, ábrela si tienes la llave", true)
		
		Room.Type.BOSS:
			await GameAPI.send_prompt("Entraste a la sala del jefe, buena suerte", true)
	
	## Se informa de si hay o no un enemigo y si no está derrotado
	if actual_room.enemy != null and actual_room.enemy.health > 0:
		await GameAPI.send_prompt(actual_room.enemy.name + " apareció", true)
	
	# Si es una habitación vacía, se abre de nuevo el mapa
	else:
		await GameAPI.send_prompt("Aqui no hay nada", true)
		is_on_map = true
		next_step.emit()
	
	# Por último, se guarda partida
	GameAPI.save_game()
