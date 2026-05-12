extends Panel

var actual_mode: DungeonMode

@onready var map_view: GridContainer = $Content/Map/GridContainer
@onready var key_obtained: Label = $Content/Key/Obtained

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameAPI.get_config().animations:
		position = Vector2(0, 900)
		await _animate(Vector2(0, 0))
	
	actual_mode = GameAPI.get_actual_mode()
	
	if actual_mode.has_key:
		key_obtained.add_theme_color_override("font_color", Color.GREEN)
	
	else:
		key_obtained.add_theme_color_override("font_color", Color.RED)
	
	_load_map()

func _load_map():
	for i in map_view.get_children():
		i.queue_free()
	
	var dungeon_data = GameAPI.get_map_data()
	var map = dungeon_data.map
	
	map_view.columns = map.size()
	
	for i in map[0].size():
		for j in map.size():
			var room_button := TextureButton.new()
			room_button.custom_minimum_size = Vector2(30, 30)
			room_button.ignore_texture_size = true
			room_button.stretch_mode = TextureButton.STRETCH_SCALE
			room_button.disabled = true
			
			var room: Room = map[j][i]
			var icon: Texture2D
			
			if room.accessible:
				var actual_room: Room = dungeon_data.actual_room
				if room.coordinates == actual_room.coordinates:
					icon = GameAPI.get_asset("icons", "Actual")
				
				elif actual_room.adjacent_rooms.any(func (c): return c == room.coordinates):
					if room.room_type == Room.Type.BOSS:
						if  actual_room.room_type == Room.Type.LOCK:
							room.explored = true
						
							if actual_mode.has_key:
								room_button.disabled = false
								room_button.pressed.connect(go_to_room.bind(room.coordinates))
								icon = GameAPI.get_asset("icons", "Jefe accesible")
							
							else:
								icon = GameAPI.get_asset("icons", "Jefe")
					
					else:
						room_button.disabled = false
						room_button.pressed.connect(go_to_room.bind(room.coordinates))
						icon = GameAPI.get_asset("icons", "Accesible")
				
				elif room.explored:
					match room.room_type:
						Room.Type.LOCK:
							icon = GameAPI.get_asset("icons", "Cerradura")
						
						Room.Type.BOSS:
							icon = GameAPI.get_asset("icons", "Jefe")
						
						Room.Type.TREASURE:
							if actual_mode.has_key:
								icon = GameAPI.get_asset("icons", "Tesoro recogido")
							
							else:
								icon = GameAPI.get_asset("icons", "Tesoro")
						
						Room.Type.NORMAL, Room.Type.EMPTY, Room.Type.MINIBOSS:
							icon = GameAPI.get_asset("icons", "Explorado")
			
			room_button.texture_normal = icon
			room_button.texture_disabled = icon
			
			map_view.add_child(room_button)

func go_to_room(coordinates: Vector2):
	actual_mode.go_to_room(coordinates)
	queue_free()

func _animate(pos: Vector2):
	if GameAPI.get_config().animations:
		await create_tween().tween_property(self, "position", pos, 0.1).finished
