extends Panel

## Contiene los posibles contextos en los que se invoca la escena
enum Context {GUIDES, EDITOR}

## Contiene el contexto en el que se invoca la escena
var context: Context

## Contiene la lista de personajes/Enemigos de los que mostrar los datos
var entity_list: Array

## Índice del elemento de la lista al que mirar
var index = 0

## Botón de 'Volver' o 'Cerrar' según el contexto
@onready var button: TextureButton = $Header/Return

## Tñitulo de la guía
@onready var title: Label = %GuideTitle

## Tipo de personaje/enemigo que se muestra
@onready var entity_type: Label = %ClassName

## Sprite del personaje/enemigo
@onready var sprite: TextureRect = %Sprite

## Descripción del personaje/enemigo
@onready var description: Label = $Content/ScrollContainer/Description

## Estadísticas base del personaje/enemigo
@onready var stats: GridContainer = $Content/Stats/GridContainer

## Carga los datos de la guía
func load_parameters(guide: String, c: Context):
	context = c
	
	# Si se invocó mediante la lista de guías, el botón será 'Volver', si se invocó mediante el botón 'Clases' del editor, el botón será 'Cerrar' y hará una animación de entrada
	match context:
		Context.GUIDES:
			button.texture_normal = GameAPI.get_asset("others", "Volver")
			button.custom_minimum_size.y -= 10
			button.texture_pressed = null
		
		Context.EDITOR:
			if GameAPI.get_config().animations:
				global_position.y = get_global_rect().size.y
				_animate(0)
			
			var boton_recogido = GameAPI.get_asset("others", "Cerrar")
			
			if boton_recogido is Array and boton_recogido.size() >= 2:
				button.texture_normal = boton_recogido[0]
				button.texture_pressed = boton_recogido[1]
	
	# Se establece el título de la guía y el contenido de la lista dependiendo si se quiere mirar los personajes o los enemigos
	title.text = guide
	match guide:
		"Enemigos":
			entity_list = GameAPI.get_all_enemies()
		
		"Clases":
			entity_list = GameAPI.get_classes()
	
	# Hecho esto, se cargan los datos
	_load_data()

## Carga los datos de un personaje/enemigo
func _load_data():
	# Recoge el personaje/enemigo del elemento de la lista con el índice correspondiente
	var entity: Entity = entity_list[index]
	
	# Se comprueba si mostrar la clase o el nombre dependiendo si es un personaje o un enemigo
	if entity is Character:
		entity_type.text = entity.class_type
	else:
		entity_type.text = entity.name
	
	# Se configuran su sprite, descripción y stats
	sprite.texture = entity.sprite
	description.text = entity.description
	
	stats.get_child(0).text = "Vida: " + str(entity.max_health)
	
	# Si es un enemigo, como no tiene maná, su valor será '-'
	if entity is Enemy:
		stats.get_child(1).text = "Maná: -"
	else:
		stats.get_child(1).text = "Maná: " + str(entity.max_mana)
	
	stats.get_child(2).text = "Ataque: " + str(entity.attack)
	stats.get_child(3).text = "Ataque M.: " + str(entity.magic_attack)
	stats.get_child(4).text = "Defensa: " + str(entity.defense)
	stats.get_child(5).text = "Velocidad: " + str(entity.speed)

## Se ejecuta al pulsar la flecha izquierda del sprite
func _on_previous_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Para evitar que pare de retroceder, si el índice llega al principio de la lista, vuelve al final
	if index - 1 <= 0:
		index = entity_list.size() - 1
	else:
		index -= 1
	
	# Se cargan los datos del nuevo personaje/enemigo
	_load_data()

## Se ejecuta al pulsar la flecha derecha del sprite
func _on_next_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Para evitar que pare de retroceder, si el índice llega al final de la lista, vuelve al principio
	if index + 1 >= entity_list.size():
		index = 0
	else:
		index += 1
	
	# Se cargan los datos del nuevo personaje/enemigo
	_load_data()

## Se ejecuta al pulsar el botón 'Volver' o 'Cerrar' de la parte superior izquierda de la escena
func _on_return_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Si el se invocó en el editor (por lo que el botón es 'Cerrar', hace una animación de salida y se destruye
	if context == Context.EDITOR:
		await _animate(get_global_rect().size.y)
	
	queue_free()

## Ejecuta una animación
func _animate(pos: float):
	# Ejecuta una animación como tween (animación por código) solo si se activaron
	if GameAPI.get_config().animations:
		var tween = get_tree().create_tween() 
		await tween.tween_property(self, "global_position:y", pos, 0.1).finished
