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
	
	var map = GameAPI.get_map()
	
	map_view.columns = map.size()
	
	for i in map[0].size():
		for j in map.size():
			var room_button: TextureButton

func _animate(pos: Vector2):
	if GameAPI.get_config().animations:
		await create_tween().tween_property(self, "position", pos, 0.1).finished
