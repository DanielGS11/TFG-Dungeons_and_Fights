## Modo mazmorra
class_name DungeonMode
extends Mode
@export var is_on_map: bool

@export var difficulty := GameAPI.Difficulty.EASY
@export var dungeon_map : MapData
@export var actual_room: Room

@export var has_key: bool = false

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
	
	if not controller.run_away.is_connected(load_map):
		controller.run_away.connect(load_map)
	
	next_step.emit()
	
	if is_on_map == false:
		await GameAPI.send_prompt(actual_room.enemy.name + " apareció", true)

func _on_enemy_defeated(exp_value: int):
	enemies_defeated += 1
	
	await GameAPI.send_prompt("El equipo recibió " + str(exp_value) + " puntos de experiencia", false)
	
	actual_room.enemy = null
	
	if actual_room.room_type == Room.Type.MINIBOSS or actual_room.room_type == Room.Type.MINIBOSS:
		dungeon_map.miniboss_multiplier += 1
	
	for member in team_in_use.members:
		if member.health > 0:
			await member.get_exp(exp_value)
		
		else:
			if member.health <= 0:
				member.revive(0.20)
	
	var room: Room = dungeon_map.actual_room
	
	match room.room_type:
		room.Type.BOSS:
			is_finished = true
			GameAPI.end_game.emit(GameAPI.Result.WIN, "¡Felicidades, has derrotado al jefe de la mazmorra y conseguido el tesoro!")
		
		room.Type.TREASURE:
			await GameAPI.send_prompt("¡Conseguiste la llave!", true)
			has_key = true
	
	if is_finished == false:
		load_map()

## Al abrir el mapa, carga su estado y guarda
func load_map():
	is_on_map = true
	
	GameAPI.save_game()
	
	next_step.emit()

func go_to_room(pos: Vector2):
	var team_level = 0
	
	for member in team_in_use.members:
		team_level += member.level
	
	is_on_map = false
	
	actual_room = dungeon_map.go_to_room(pos, difficulty, ceili(float(team_level) / team_in_use.members.size()))
	
	if actual_room.room_type == Room.Type.TREASURE and has_key:
		actual_room.background = GameAPI.get_asset("rooms", "Tesoro recogido")
	
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
	
	if actual_room.enemy != null and actual_room.enemy.health > 0:
		await GameAPI.send_prompt(actual_room.enemy.name + " apareció", true)
	
	else:
		await GameAPI.send_prompt("Aqui no hay nada", true)
		is_on_map = true
		next_step.emit()
	
	GameAPI.save_game()
