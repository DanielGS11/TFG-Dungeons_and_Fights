class_name MapData
extends Resource

## Mapa de la mazmorra
@export var map: Array[Array]

## Habitación actual de la mazmorra
@export var actual_room: Room

## Niveles que sube el jefe
@export var boss_level: int

## Número de minijefes de la mazmorra
@export var total_minibosses: int

## Aumento de nivel de cada minijefe
@export var miniboss_grow: int

## Multiplicador del aumento de nivel de cada minijefe
@export var miniboss_multiplier = 1

## Genera el mapa de la mazmorra
func generate_map(difficulty: GameAPI.Difficulty):
	# Almacena en 2 variables la altura y anchura del mapa de la mazmorra según la dificultad
	var height: int
	var width: int
	
	match difficulty:
		# Si está en fácil, el mapa puede ser desde un 4x4 hasta un 5x5 y el nivel del jefe desde 12 hasta 20
		GameAPI.Difficulty.EASY:
			height = randi_range(4, 5)
			width = randi_range(4, 5)
			boss_level = randi_range(11, 19)
		
		# Si está en normal, el mapa puede ser desde un 6x6 hasta un 7x7 y el nivel del jefe desde 21 hasta 29
		GameAPI.Difficulty.MEDIUM:
			height = randi_range(6, 7)
			width = randi_range(6, 7)
			boss_level = randi_range(20, 28)
		
		# Si está en difícil, el mapa puede ser desde un 8x8 hasta un 9x9 y el nivel del jefe desde 30 hasta 40
		GameAPI.Difficulty.HARD:
			height = randi_range(8, 9)
			width = randi_range(8, 9)
			boss_level = randi_range(29, 39)
	
	# Le pide al generador de mapas que lo genere pasándole los datos y recoge la respuesta en una lista
	var data = MapGenerator.new().generate_map(height, width)
	
	# Asigna los datos recogidos a su variable correspondiente y configura el crecimiento de los minijefes, que será el nivel del jefe dividido entre la cantidad de minijefes de la mazmorra
	map = data[0]
	actual_room = data[1]
	total_minibosses = data[2]
	miniboss_grow = floori(float(boss_level) / total_minibosses)

## Cargar la sala a que se quiere desplazar
func go_to_room(position: Vector2i, difficulty: GameAPI.Difficulty, team_level: int) -> Room:
	# Carga la habitación del mapa, la asigna como habitación actual y marca la anterior como explorada
	var room: Room = map[position.x][position.y]
	actual_room.explored = true
	actual_room = room
	
	# Carga el enemigo según el tipo de habitación
	match room.room_type:
		# Si es una habitación normal o la de la cerradura y no está explorada o lo está y con una probabilidad del 50% genera un enemigo
		room.Type.NORMAL, Room.Type.LOCK:
			if (room.explored and randi_range(1, 2) == 1) or room.explored == false:
				room.enemy = GameAPI.get_enemy(Mode.Type.DUNGEON, "Normal")
				
				# Asigna el nivel del enemigo según la dificultad (Si el nivel del equipo es 2 o menos no cambia y se queda en 1) 
				if team_level > 2:
					var min_lv
					var max_lv
					
					match difficulty:
						# Si está en modo fácil, el enemigo podrá ser desde 2 niveles menos que el equipo (mínimo nivel 1) hasta el nivel del equipo
						GameAPI.Difficulty.EASY:
							max_lv = team_level - 1
							
							if team_level - 3 <= 2:
								min_lv = 0
							else:
								min_lv = team_level - 3
						
						# Si está en modo normal, el enemigo podrá ser desde 1 nivel menos que el equipo (mínimo nivel 1) hasta un nivel más
						GameAPI.Difficulty.MEDIUM:
							max_lv = team_level
							
							if team_level - 2 <= 2:
								min_lv = 1
							else:
								min_lv = team_level - 2
						
						# Si está en modo difícil, el enemigo podrá ser desde el mismo nivel del equipo hasta 2 más
						GameAPI.Difficulty.HARD:
							max_lv = team_level + 1
							min_lv = team_level - 1
					
					# Ahora hacemos que el enemigo crezca un número aleatorio de entre ese mínimo y máximo recogido
					room.enemy.grow_levels(randi_range(min_lv, max_lv))
			
			# Si no se cumple la condición, no habrá enemigo la vez que se explore esa habitación
			else:
				room.enemy = null
		
		# Si es la del tesoro y el enemigo no fué derrotado, sube los niveles corresondientes al crecimiento de cada minijefe multiplicado por el multiplicador de este, que aumenta con cada minijefe derrotado
		room.Type.TREASURE, room.Type.MINIBOSS:
			if room.enemy != null and room.enemy.health > 0:
				room.enemy.grow_levels(miniboss_grow * miniboss_multiplier)
		
		# Si es la habitación del jefe, le aplica el aumento de niveles y restaura su vida
		room.Type.BOSS:
			room.enemy.grow_levels(boss_level)
			room.enemy.health = room.enemy.max_health
	
	# Por último, devuelve la habitación ya configurada
	return room
