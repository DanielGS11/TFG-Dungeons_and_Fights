class_name MapGenerator
extends RefCounted

var map: Array[Array]
var map_height: int
var map_width: int

var rooms: Array[Vector2i]
var directions = [Vector2i.UP,Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

# Se inicia la variable de total de salas en 1 ya que cuenta la sala inicial, que se genera
# antes que cualquier otra
var total_rooms = 1
var min_rooms: int

var treasure_generated = false
var boss_generated = false

# Este método devuelve el mapa ya creado
func generate_map(height: int, width: int) -> Array:
	map_height = height
	map_width = width
	
	# Recojo, con un método auxiliar, las coordenadas de la sala inicial
	var initial_room := Room.new()
	initial_room.coordinates = _get_initial_room()
	
	# Configuro los datos de la sala inicial, que será una vacía
	initial_room.explored = true
	initial_room.room_type = initial_room.Type.EMPTY
	
	rooms.append(initial_room.coordinates)
	
	# Lleno el array del mapa con salas para configurar
	for i in range(map_width):
		map.append([])
		
		for j in range(map_height):
			map[i].append(Room.new())
	
	# Una vez llenado el mapa, pongo la habitación inicial en su lugar
	map[initial_room.coordinates.x][initial_room.coordinates.y] = initial_room
	
	# Aqui establezco el mínimo de salas que la mazmorra tendrá, que será un número aleatorio
	# entre el 40% del tamaño total de la mazmorra (ancho x alto) y el tamaño - el número de 
	# minijefes (ya que la sala del jefe ocuparia un espacio extra y hay que prevenir que las
	# salas de minijefes y tesoro tapen esos espacios)
	var total_size = map_height * map_width
	
	# Necesitamos saber cuántos minijefes (incluido el de la habitación del tesoro) habrá,
	# que será una séptima parte del tamaño del mapa (en modo fácil, tamaño total del mapa mas pequeño
	# es de 16 salas, por lo que habría 2 minijefes, que sería el de la sala del tesoro; y el más grande
	# del modo facil sería de 25 salas, 3 minijefes)
	var minibosses_to_generate = floori(float(total_size) / 7)
	
	
	min_rooms = randi_range(ceili(total_size * 0.4), total_size - minibosses_to_generate)
	
	# Una vez sacado el mínimo de salas a generar, hacemos un bucle que coja una posición aleatoria
	# de una habitación y genere al menos 1 en cualquier dirección pegada a esta. El bucle parará
	# al generar las salas necesarias
	while total_rooms < min_rooms:
		_generate_room(rooms.pick_random())
	
	# Cuando este bucle termina, pasamos a generar la habitación del tesoro y los minijefes.
	
	# Para evitar comprobaciones innecesarias, quitaremos las coordenadas de la sala inicial
	# temporalmente de la lista
	rooms.remove_at(rooms.find(initial_room.coordinates))
	
	# Ahora, con una lógica parecida a la de generar salas adyacentes, modificaremos una sala
	# ya configurada para que primero sea la del tesoro, y una vez generada, las siguientes sean
	# salas de minijefe
	var minibosses_generated = 0
	while minibosses_to_generate > minibosses_generated:
		minibosses_generated += _generate_miniboss(rooms.pick_random())
	
	# Por último, un bucle que genere la sala del jefe, que se generará adyacente a una sala en un
	# espacio sin configurar (pared) y convertirá la sala a la que se conectó en la sala de la
	# cerradura, haciéndola la unica sala por la que acceder al jefe
	while boss_generated == false:
		_generate_boss(rooms.pick_random())
	
	# Por último, añado de nuevo las coordenadas de la sala inicial a la lista y escaneo las 
	# adyacentes de todas las salas por si quedó alguna sin registrar alguna sala adyacente
	
	rooms.append(initial_room.coordinates)
	
	for position in rooms:
		_scan_adjacents(position)
		
	return [map, initial_room, minibosses_to_generate]

# Para definir la habitación de inicio, creamos un método que nos devuelva sus coordenadas
func _get_initial_room() -> Vector2i:
	var coordinates: Vector2i
	
	# Hacemos 2 tiradas de dados, en la primera vemos si empezamos en un extremo superior/inferior 
	# de la mazmorra (si sale 1) o lateral (si sale 2). La segunda tirada de dados es para ver en
	# qué coordenada de ese borde estará la habitación inicial
	if randi_range(1, 2) == 1:
		if randf_range(1, 2) == 1:
			coordinates = Vector2i(randi_range(0, map_width - 1), 0)
		
		else:
			coordinates = Vector2i(randi_range(0, map_width - 1), map_height - 1)
	
	else:
		if randf_range(1, 2) == 1:
			coordinates = Vector2i(0, randi_range(0, map_height - 1))
		
		else:
			coordinates = Vector2i(map_width - 1, randi_range(0, map_height - 1))
	
	return coordinates

# Con este método, establezco la lista de salas adyacentes a la posición de la sala dada
func _scan_adjacents(position: Vector2i):
	# Recojo la sala del mapa en una variable y limpio su lista de adyacentes ya que se puede 
	# escanear varias veces la sala
	var room : Room = map[position.x][position.y]
	room.adjacent_rooms.clear()
	
	# creo una variable que contendrá datos de una sala adyacente
	var adjacent_room: Room
	
	# Compruebo las habitaciones adyacentes, primero compruebo que la posición no salga del mapa,
	# luego recojo esa sala del mapa en la variable antes creada, miro si es accesible (si no, sería
	# una pared) y la añado a la lista de adyacentes de la sala
	for i in directions.size():
		var dir_pos = position + directions[i]
		
		if 0 <= dir_pos.x < map_width and 0 <= dir_pos.y < map_height:
			adjacent_room = map[dir_pos.x][dir_pos.y]
			
			if adjacent_room.accessible:
				room.adjacent_rooms.append(adjacent_room.coordinates)

# Con este método generamos una habitación adyacente
func _generate_room(position: Vector2i):
	_scan_adjacents(position)
	
	# Creamos un array con las posiciones que puede haber adyacentes, ya que si la sala está en una
	# esquina, solo habría 2, además, solo la añadiremos si la sala no la tiene de adyacente
	var positions_available: Array[Vector2i]
	
	for i in directions.size():
		var dir_pos = position + directions[i]
		
		if 0 <= dir_pos.x < map_width and 0 <= dir_pos.y < map_height:
			# Creamos una variable temporal de la sala actual para comprobar sus adyacentes y ver
			# si hay alguna posición libre para añadir a la lista de posiciones disponibles
			var room : Room = map[position.x][position.y]
			
			if room.adjacent_rooms.all(func(a): return a != dir_pos):
				positions_available.append(dir_pos)
	
	# Si hay alguna posición adyacente libre, empieza a generar
	if positions_available.size() > 0:
		# Ahora mezclo las direcciones para que busque generar la primera sala adyacente (que es
		# obligatoria para asegurar que no haya un bucle infinito) se genere en una posición 
		# adyacente aleatoria
		positions_available.shuffle()
		
		# Recorro las direcciones adyacentes a la sala y compruebo que no se salga del mapa
		for i in positions_available.size():
			# Recojo la habitación del mapa en una variable y miro si no era seleccionable 
			# (por lo que no estaba configurada y era una pared)
			var pos: Vector2i = positions_available[i]
			var next_room: Room = map[pos.x][pos.y]
				
			if next_room.accessible == false:
				# Si i (el índice de la dirección) está en 0, por lo que sería la primera vuelta
				# para ver si genera o no sala, genera una obligatoriamente, no hay que
				# preocuparse por generar las salas en una sola dirección ya que antes mezclamos
				# la lista de direcciones. Si no, hay un 50% de generar una habitación adyacente
				if i == 0 or randi_range(1, 2) == 1:
					next_room.accessible = true
					
					# La habitación generada tiene un 20% de ser una habitación vacía
					if randi_range(1,5) == 1:
						next_room.room_type = next_room.Type.EMPTY
					else:
						next_room.room_type = next_room.Type.NORMAL
					
					# Le asignamos sus coordenadas y su fondo
					next_room.coordinates = pos
					next_room.background = GameAPI.get_room_asset("Normal").pick_random()
						
					total_rooms += 1
					rooms.append(pos)
			
			if min_rooms <= total_rooms:
				break

# Con este método generamos las salas de minijefe y tesoro
func _generate_miniboss(position: Vector2i) -> int:
	# Recojemos la sala del mapa y comprobamos que no esté configurada como tesoro/minijefe
	var room: Room = map[position.x][position.y]
	
	if room.room_type != room.Type.TREASURE and room.room_type != room.Type.MINIBOSS:
		if treasure_generated:
			room.room_type = room.Type.MINIBOSS
		
		else:
			room.room_type = room.Type.TREASURE
			room.background = GameAPI.get_room_asset("Tesoro")[0]
			treasure_generated = true
		
		room.enemy = GameAPI.get_miniboss()
		
		return 1
	
	return 0

# Con este método generamos al jefe de la mazmorra
func _generate_boss(position: Vector2i):
	# Guardamos la sala actual en una variable y comprobamos antes de nada que no sea ni sala de
	# minijefe ni tesoro
	var room : Room = map[position.x][position.y]
	
	if room.room_type == room.Type.NORMAL or room.room_type == room.Type.EMPTY:
		# Al igual que en el método _generate_room, miramos que haya espacio para generar una sala
		# adyacente
		_scan_adjacents(position)
		
		var positions_available: Array[Vector2i]
		
		# Comprobamos las posiciones disponibles y las añadimos
		for i in directions.size():
			var dir_pos = position + directions[i]
			
			if 0 <= dir_pos.x < map_width and 0 <= dir_pos.y < map_height:
				if room.adjacent_rooms.all(func(a): return a != dir_pos):
					positions_available.append(dir_pos)
		
		
		# Comprobamos si hay alguna sala libre (pared)
		if positions_available.size() > 0:
			# Establecemos la sala como sala de cerradura
			room.room_type = room.Type.LOCK
			room.background = GameAPI.get_room_asset("Cerradura")[0]
			
			# Por último, recogemos la sala de una de las posiciones disponibles y la establecemos 
			# como sala del jefe
			var pos = positions_available.pick_random()
			var boss_room: Room = map[pos.x][pos.y]
			
			boss_room.room_type = boss_room.Type.BOSS
			boss_room.background = GameAPI.get_room_asset("Jefe")[0]
			boss_room.coordinates = pos
			boss_room.accessible = true
			boss_room.enemy = GameAPI.get_boss()
			
			boss_generated = true
