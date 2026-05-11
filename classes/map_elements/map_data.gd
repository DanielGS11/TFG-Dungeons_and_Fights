class_name MapData
extends Resource

# Variables del mapa y las coordenadas de la sala en la que se encuentra actualmente el jugador
@export var map: Array[Array]
@export var actual_room: Room

# La cantidad de niveles que sube el jefe de la mazmorra (de base siempre es Lv 1, asi que se 
# ejecuta su método grow_levels para que sume los niveles de esta variable y escale su vida y ataque
@export var boss_level: int

@export var total_minibosses: int
@export var miniboss_grow: int
@export var miniboss_multiplier = 1

## Cargar la sala a que se quiere desplazar
func go_to_room(position: Vector2i, difficulty: GameAPI.Difficulty, team_level: int) -> Room:
	var room: Room = map[position.x][position.y]
	actual_room.explored = true
	
	actual_room = room
	
	match room.room_type:
		room.Type.NORMAL, Room.Type.LOCK:
			if (room.explored and randi_range(1, 3) == 1) or room.explored == false:
				room.enemy = GameAPI.get_enemy(Mode.Type.DUNGEON, "Normal")
				
				if team_level > 2:
					var min_lv
					var max_lv
					
					match difficulty:
						GameAPI.Difficulty.EASY:
							max_lv = team_level
							
							if team_level - 2 <= 2:
								min_lv = 1
							else:
								min_lv = team_level - 2
						
						GameAPI.Difficulty.MEDIUM:
							max_lv = team_level + 1
							
							if team_level - 1 <= 2:
								min_lv = 1
							else:
								min_lv = team_level - 1
						
						GameAPI.Difficulty.HARD:
							max_lv = team_level + 2
							min_lv = team_level
					
					room.enemy.grow_levels(randi_range(min_lv, max_lv))
				
			else:
				room.enemy = null
		
		room.Type.TREASURE, room.Type.MINIBOSS:
			if room.enemy != null and room.enemy.health > 0:
				room.enemy.grow_levels(miniboss_grow * miniboss_multiplier)
		
		room.Type.BOSS:
			room.enemy.grow_levels(boss_level)
			room.enemy.health = room.enemy.max_health
	
	return room

## Generar el mapa de la mazmorra
func generate_map(difficulty: GameAPI.Difficulty):
	var height: int
	var width: int
	match difficulty:
		GameAPI.Difficulty.EASY:
			height = randi_range(4, 5)
			width = randi_range(4, 5)
			boss_level = randi_range(11, 19)
		
		GameAPI.Difficulty.MEDIUM:
			height = randi_range(6, 7)
			width = randi_range(6, 7)
			boss_level = randi_range(20, 28)
		
		GameAPI.Difficulty.HARD:
			height = randi_range(8, 9)
			width = randi_range(8, 9)
			boss_level = randi_range(29, 39)
	
	var data = MapGenerator.new().generate_map(height, width)
	
	map = data[0]
	actual_room = data[1]
	total_minibosses = data[2]
	miniboss_grow = floori(float(boss_level) / total_minibosses)
