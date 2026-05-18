extends Panel

## Contiene los datos del modo actual, que siempre sera del tipo 'Modo mazmorra'
var actual_mode: DungeonMode

## Contiene el contenedor de casillas del mapa
@onready var map_view: GridContainer = %GridContainer

## Contiene el indicador de obtención de la llave de la mazmorra
@onready var key_obtained: Label = %Obtained

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Realiza una animación de entrada si se activaron las animaciones
	if GameAPI.get_config().animations:
		global_position.y = get_viewport_rect().size.y
		
		var tween = get_tree().create_tween() 
		await tween.tween_property(self, "global_position:y", 0, 0.1).finished
	
	# Recoge el modo actual y configura el indicador de si se obtuvo la llave o no
	actual_mode = GameAPI.get_actual_mode()
	
	if actual_mode.has_key:
		key_obtained.add_theme_color_override("font_color", Color.GREEN)
	
	else:
		key_obtained.add_theme_color_override("font_color", Color.RED)
	
	# Por último, ejecuta el método que carga el mapa
	_load_map()

## Carga las casillas del mapa
func _load_map():
	# Crea un duplicado del botón de casilla que viene por defecto en el contenedor de casillas del mapa y limpia el contenedor
	var button: TextureButton = map_view.get_child(0).duplicate(true)
	
	for i in map_view.get_children():
		i.queue_free()
	
	# Recoge los datos del mapa y el propio mapa y guarda la habitación actual del mapa
	var dungeon_data = GameAPI.get_map_data()
	var map = dungeon_data.map
	var actual_room: Room = dungeon_data.actual_room
	
	# Establece las columnas del contenedor en función del tamaño del mapa
	map_view.columns = map.size()
	
	# Recorre el mapa para establecer las casillas
	# NOTA: Al añadir una casilla el contenedor lo añade todo en la misma fila, pasa a la siguiente cuando una se llena, por lo que tenemos que recorrer el mapa por fila, no por columnas, por lo que se recorre i como map[0] que es una columna y j como map que es una fila
	for i in map[0].size():
		for j in map.size():
			# Crea una variable que será el botón de la casilla de la sala del mapa, otra que es la habitación correspondiente para ver sus datos, y otra que es el icono que tendrá el botón
			var room_button := button.duplicate(true)
			
			var room: Room = map[j][i]
			var icon: Texture2D
			
			# Comprueba primero si la habitación es accesible, si no, sería una pared, por lo que no se debe ver en el mapa
			if room.accessible:
				# Si la habitación que se carga es la actual, establecemos el icono
				if room.coordinates == actual_room.coordinates:
					icon = GameAPI.get_asset("icons", "Actual")
				
				# Si la habitación que se carga figura entre las adyacentes a la actual
				elif actual_room.adjacent_rooms.any(func (c): return c == room.coordinates):
					# Se comprueba si la habitación es la del jefe
					if room.room_type == Room.Type.BOSS:
						# Se comprueba si la habitación actual es la de la cerradura y, si es asi, se marca como explorada para verla en el mapa y se comprueba si se tiene la llave
						if  actual_room.room_type == Room.Type.LOCK:
							room.explored = true
							
							# Si se tiene la llave, se habilita la habitación para acceder a ella y se pone su icono correspondiente
							if actual_mode.has_key:
								room_button.disabled = false
								room_button.pressed.connect(_go_to_room.bind(room.coordinates))
								icon = GameAPI.get_asset("icons", "Jefe accesible")
							
							# Si no, solo se pone el icono de la habitación del jefe
							else:
								icon = GameAPI.get_asset("icons", "Jefe")
					
					# Si no, se habilita la casilla para pulsar y se conecta al método que navega hacia esa habitación y se establece su icono
					else:
						room_button.disabled = false
						room_button.pressed.connect(_go_to_room.bind(room.coordinates))
						icon = GameAPI.get_asset("icons", "Accesible")
				
				# Si la habitación fué explorada
				elif room.explored:
					# Se pone el icono de la habitación según su tipo
					match room.room_type:
						Room.Type.LOCK:
							icon = GameAPI.get_asset("icons", "Cerradura")
						
						Room.Type.BOSS:
							icon = GameAPI.get_asset("icons", "Jefe")
						
						Room.Type.TREASURE:
							# El icono de la habitación del tesoro cambia según si se recogió la llave o no
							if actual_mode.has_key:
								icon = GameAPI.get_asset("icons", "Tesoro recogido")
							
							else:
								icon = GameAPI.get_asset("icons", "Tesoro")
						
						Room.Type.NORMAL, Room.Type.EMPTY, Room.Type.MINIBOSS:
							icon = GameAPI.get_asset("icons", "Explorado")
			
			# Se establecen los iconos y se añade el botón al contenedor
			room_button.texture_normal = icon
			room_button.texture_disabled = icon
			
			map_view.add_child(room_button)

## Navega a la habitación seleccionada
func _go_to_room(coordinates: Vector2):
	MusicPlayer.play_sfx("Click")
	
	# Llama al método del modo actual que carga la habitación dándole las coordenadas y se destruye
	actual_mode.go_to_room(coordinates)
	queue_free()
