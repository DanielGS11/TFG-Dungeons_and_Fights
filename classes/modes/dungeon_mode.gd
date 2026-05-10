## Modo mazmorra
class_name DungeonMode
extends Mode
@export var is_on_map: bool

@export var difficulty := GameAPI.Difficulty.EASY
@export var dungeon_map : MapData

@export var has_key: bool = false

func _init():
	mode = Type.DUNGEON
	can_escape = true

func new_game(_data: Array):
	is_finished = false
	
	has_key = false
	
	dungeon_map = MapData.new()
	dungeon_map.generate_map(difficulty)
	is_on_map = true
	
	load_controller()
	
	if not controller.run_away.is_connected(load_map):
		controller.run_away.connect(load_map)

func start():
	pass

func _on_enemy_defeated(exp_value: int):
	await GameAPI.send_prompt("El equipo recibió " + str(exp) + " puntos de experiencia", false)
	
	for member in team_in_use.members:
		if member.health > 0:
			await member.get_exp(exp_value)
		
		else:
			member.health += 20
	
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
	
	#next_step.emit(mode)
