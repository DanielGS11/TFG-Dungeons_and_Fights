extends Panel

enum Context {GUIDES, EDITOR}

var context: Context
var entity_list: Array
var index = 0

@onready var button: TextureButton = $Header/Return
@onready var title: Label = %GuideTitle

@onready var character_class: Label = %ClassName

@onready var sprite: TextureRect = %Sprite

@onready var description: Label = $Content/ScrollContainer/Description

@onready var stats: GridContainer = $Content/Stats/GridContainer

# Called when the node enters the scene tree for the first time.
func load_parameters(guide: String, c: Context):
	context = c
	
	match context:
		Context.GUIDES:
			button.texture_normal = GameAPI.get_asset("buttons", "Volver")
			button.custom_minimum_size = Vector2(30, 30)
			button.texture_pressed = null
		
		Context.EDITOR:
			if GameAPI.get_config().animations:
				position = Vector2(0, 900)
				_animate(Vector2(0, 0))
			
			button.custom_minimum_size = Vector2(45, 45)
			
			var boton_recogido = GameAPI.get_asset("others", "Cerrar")
			
			if boton_recogido is Array and boton_recogido.size() >= 2:
				button.texture_normal = boton_recogido[0]
				button.texture_pressed = boton_recogido[1]
	
	title.text = guide
	
	match guide:
		"Enemigos":
			entity_list = GameAPI.get_all_enemies()
		
		"Clases":
			entity_list = GameAPI.get_classes()
	
	_load_data()

func _load_data():
	var entity: Entity = entity_list[index]
	
	if entity.get("class_type") == null:
		character_class.text = entity.name
	else:
		character_class.text = entity.class_type
	
	sprite.texture = entity.sprite
	description.text = entity.description
	
	stats.get_child(0).text = "Vida: " + str(entity.max_health)
	
	if entity.get("max_mana") == null:
		stats.get_child(1).text = "Maná: -"
	else:
		stats.get_child(1).text = "Maná: " + str(entity.max_mana)
	
	stats.get_child(2).text = "Ataque: " + str(entity.attack)
	stats.get_child(3).text = "Ataque M.: " + str(entity.magic_attack)
	stats.get_child(4).text = "Defensa: " + str(entity.defense)
	stats.get_child(5).text = "Velocidad: " + str(entity.speed)

func _on_previous_pressed() -> void:
	if index - 1 <= 0:
		index = 0
	else:
		index -= 1
	
	_load_data()

func _on_next_pressed() -> void:
	if index + 1 >= entity_list.size():
		index = 0
	else:
		index += 1
	_load_data()

func _on_return_pressed() -> void:
	if context == Context.EDITOR:
		await _animate(Vector2(0, 900))
	
	queue_free()

func _animate(pos: Vector2):
	if GameAPI.get_config().animations:
		# Cada animación es de un solo uso, por lo que hay que crearlo de nuevo cada vez
		var tween = get_tree().create_tween() 
		await tween.tween_property(self, "position", pos, 0.1).finished
