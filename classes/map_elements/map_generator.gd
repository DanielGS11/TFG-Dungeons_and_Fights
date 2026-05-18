## Generador de mapas procedural
class_name MapGenerator
extends RefCounted

## Mapa
var map: Array[Array]

## Altura
var map_height: int

## Anchura
var map_width: int

## Habitaciones
var rooms: Array[Vector2i]

## Direcciones
var directions = [Vector2i.UP,Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

## Total de salas generadas, inicia en 1 ya que cuenta la sala inicial que se genera aparte
var total_rooms = 1

## Habitaciones a generar
var rooms_to_generate: int

## Indica si se generó la habitación del tesoro
var treasure_generated = false

## Indica si se generó la habitación del jefe
var boss_generated = false

## Genera y devuelve el mapa ya creado
func generate_map(height: int, width: int) -> Array:
	map_height = height
	map_width = width
	
	# Establezce con un método auxiliar la habitación inicial
	var initial_room := _get_initial_room()
	
	rooms.append(initial_room.coordinates)
	
	# Llena el array del mapa con habitaciones para configurar y pongo la inicial en su sitio 
	for i in range(map_width):
		map.append([])
		
		for j in range(map_height):
			map[i].append(Room.new())
	
	map[initial_room.coordinates.x][initial_room.coordinates.y] = initial_room
	
	# Establece las habitaciones a generar que será un número aleatorio entre el 40% del total de habitaciones y el total - la cantidad de minijefes, asi se evita que las salas de minijefes tapen las casillas vacías donde se puede generar el jefe, que necesita una casilla vacía y una habitación normal o vacía (EMPTY)
	var total_size = map_height * map_width
	
	# El número de minijefes de la mazmorra será el total de habitaciónes entre 7, por lo que la mazmorra más pequeña, de 16 casillas, tendrá 2 minijefes, 1 para el tesoro y los demas repartidos por el mapa
	var minibosses_to_generate = floori(float(total_size) / 7)
	rooms_to_generate = randi_range(ceili(total_size * 0.4), total_size - minibosses_to_generate)
	
	# Establecido lo anterior, se generan habitaciones en el mapa hasta llegar al mínimo de habitaciones a generar
	while total_rooms < rooms_to_generate:
		_generate_room(rooms.pick_random())
	
	# Tras terminar, se quita temporalmente la habitación inicial de la lista de habitaciones generadas ara evitar que se sobreescriba
	rooms.remove_at(rooms.find(initial_room.coordinates))
	
	# Ahora se generarán los minijefes y la sala del tesoro del mapa, se sobreescribirán habitaciones aleatorias para establecer estos datos y no se parará hasta generar todos los minijefes y el tesoro. Por cada habitación generada, se suma 1 a la variable de minijefes generados y se cortará el bucle cuando se generen todas
	var minibosses_generated = 0
	while minibosses_to_generate > minibosses_generated:
		minibosses_generated += _generate_miniboss(rooms.pick_random())
	
	# Por último, se generará la habitación del jefe y de cerradura, se necesita una habitación normal y una adyacente sin configurar
	while boss_generated == false:
		_generate_boss(rooms.pick_random())
	
	# Al terminar todo, se añade de nuevo la habitación inicial y se escanean las adyacentes de todas las habitaciones de la lista y se devuelven los datos pedidos
	rooms.append(initial_room.coordinates)
	
	for position in rooms:
		_scan_adjacents(position)
		
	return [map, initial_room, minibosses_to_generate]

## Devuelve las coordenadas de la habitación inicial
func _get_initial_room() -> Room:
	var initial_room = Room.new()
	initial_room.explored = true
	initial_room.accessible = true
	initial_room.room_type = initial_room.Type.EMPTY
	initial_room.background = GameAPI.get_asset("rooms", "Normal").pick_random()
	
	# 2 tiradas de dados:
	# - La primera: Dice si la habitación inicial empieza en un borde vertical (1) u horizontal (2)
	# - La segunda: Dice si la habitación inicial estará en una casilla aleatoria del principio (1) o final (2) de ese borde
	if randi_range(1, 2) == 1:
		if randf_range(1, 2) == 1:
			initial_room.coordinates = Vector2i(randi_range(0, map_width - 1), 0)
		
		else:
			initial_room.coordinates = Vector2i(randi_range(0, map_width - 1), map_height - 1)
	
	else:
		if randf_range(1, 2) == 1:
			initial_room.coordinates = Vector2i(0, randi_range(0, map_height - 1))
		
		else:
			initial_room.coordinates = Vector2i(map_width - 1, randi_range(0, map_height - 1))
	
	# Hecho esto se devuelve la habitación generada
	return initial_room

## Escanea las habitaciones adyacentes de la habitación en la posición recogida
func _scan_adjacents(position: Vector2i):
	# Recoje la habitación de la posición del mapa en una variable y limpio su lista de adyacentes
	var room : Room = map[position.x][position.y]
	room.adjacent_rooms.clear()
	
	# Se crea una variable temporal para la habitación adyacente
	var adjacent_room: Room
	
	# Se recorre la lista de direcciones y por cada dirección se comprueba si no se sale del mapa
	for i in directions.size():
		var dir_pos = position + directions[i]
		
		if 0 <= dir_pos.x and dir_pos.x < map_width and 0 <= dir_pos.y and dir_pos.y < map_height:
			# Luego se recoge en la variable antes creada la habitación de esa posición y, si es una habitación (Es accesible), se añade a la lista de adyacentes
			adjacent_room = map[dir_pos.x][dir_pos.y]
			
			if adjacent_room.accessible:
				room.adjacent_rooms.append(adjacent_room.coordinates)

## Genera una habitación adyacente
func _generate_room(position: Vector2i):
	# Se escanean las habitaciones adyacentes a la de la posición y en una lista se escanean las direcciones adyacentes sin habitaciones de la actual
	_scan_adjacents(position)
	var positions_available: Array[Vector2i]
	
	for i in directions.size():
		var dir_pos = position + directions[i]
		
		if 0 <= dir_pos.x and dir_pos.x < map_width and 0 <= dir_pos.y and dir_pos.y < map_height:
			# Creamos una variable temporal de la sala actual para comprobar sus adyacentes y ver
			# si hay alguna posición libre para añadir a la lista de posiciones disponibles
			var room : Room = map[position.x][position.y]
			
			if room.adjacent_rooms.all(func(a): return a != dir_pos):
				positions_available.append(dir_pos)
	
	# Si hay alguna posición adyacente libre, mezcla las posiciones para no generar siempre en el mismo sitio y recorre la lista de posiciones válidad
	if positions_available.size() > 0:
		positions_available.shuffle()
		
		for i in positions_available.size():
			# Se crea una habitación que podrá ser o no una habitación nueva y se comprueba si era una pared (No accesible)
			var pos: Vector2i = positions_available[i]
			var next_room: Room = map[pos.x][pos.y]
				
			if next_room.accessible == false:
				# Si lo es, se comprueba si se genera o no la habitación nueva, si es el primer recorrido (i = 0), se genera la habitación, o si en una tirada de dados de 1 o 2 sale 1 también, asi se evita hacer recorridos sin generar ni una habitación
				if i == 0 or randi_range(1, 2) == 1:
					next_room.accessible = true
					
					# Se hace otra tirada de dados donde hay un 80% de que la habitación generada sea normal y no vacía
					if randi_range(1,5) == 1:
						next_room.room_type = next_room.Type.EMPTY
					else:
						next_room.room_type = next_room.Type.NORMAL
					
					# Por último la configuramos, sumamos 1 al total de habitaciones y añadimos su posición a la lista
					next_room.coordinates = pos
					next_room.background = GameAPI.get_asset("rooms", "Normal").pick_random()
						
					total_rooms += 1
					rooms.append(pos)
			
			# Si ya se generaron todas las habitaciones, se corta el recorrido
			if rooms_to_generate <= total_rooms:
				break

## Genera las habitaciones de minijefe y tesoro
func _generate_miniboss(position: Vector2i) -> int:
	# Recoje la sala del mapa y comprobamos que no esté configurada como tesoro/minijefe para configurarla
	var room: Room = map[position.x][position.y]
	
	if room.room_type != room.Type.TREASURE and room.room_type != room.Type.MINIBOSS:
		if treasure_generated:
			room.room_type = room.Type.MINIBOSS
		
		else:
			room.room_type = room.Type.TREASURE
			room.background = GameAPI.get_asset("rooms", "Tesoro")
			treasure_generated = true
		
		room.enemy = GameAPI.get_enemy(Mode.Type.DUNGEON, "Minijefe")
		
		# Si se generó, devuelve 1 para que se sume a las habitaciones de minijefe generadas, si no, devuelve 0
		return 1
	
	return 0

## Genera el jefe de la mazmorra y la habitación de la cerradura
func _generate_boss(position: Vector2i):
	# Recogemos la habitación de la posición correspondiente y comprobamos que sea una habitación normal
	var room : Room = map[position.x][position.y]
	
	if room.room_type == room.Type.NORMAL or room.room_type == room.Type.EMPTY:
		# Al igual que el método '_generate_room', escaneo los adyacentes y compruebo que exista alguna dirección en la que no haya una habitación adyacentey la guardo en una lista
		_scan_adjacents(position)
		var positions_available: Array[Vector2i]
		
		for i in directions.size():
			var dir_pos = position + directions[i]
			
			if 0 <= dir_pos.x and dir_pos.x < map_width and 0 <= dir_pos.y and dir_pos.y < map_height:
				if room.adjacent_rooms.all(func(a): return a != dir_pos):
					positions_available.append(dir_pos)
		
		# Si hay alguna habitación sin configurar, convierte la actual en la de la cerradura y cualquiera de las libres en la del jefe y las configura
		if positions_available.size() > 0:
			room.room_type = room.Type.LOCK
			room.background = GameAPI.get_asset("rooms", "Cerradura")
			
			var pos = positions_available.pick_random()
			var boss_room: Room = map[pos.x][pos.y]
			
			boss_room.room_type = boss_room.Type.BOSS
			boss_room.background = GameAPI.get_asset("rooms", "Jefe")
			boss_room.coordinates = pos
			boss_room.accessible = true
			boss_room.enemy = GameAPI.get_enemy(Mode.Type.DUNGEON, "Jefe")
			
			boss_generated = true
			
			rooms.append(boss_room.coordinates)
