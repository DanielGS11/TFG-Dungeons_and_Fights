extends Control

## Índice del miembro a editar
var member_index = 0

## Índice de la clase del miembro, por defecto estará en -1 si no hay clase seleccionada
var class_index: int = -1

## Índice del sprite del miembro
var sprite_index = 0

## Lista de clases disponibles
var class_list: Array[Character]

## Lista de sprites de la clase actual
var sprite_list: Array

## Contiene los datos del miembro a editar
var member: Character

## Shader de brillo
@onready var bright: ColorRect = $Bright/ColorRect

## Contenedor del equipo
@onready var team = %TeamContainer

## Contiene la clase seleccionada del miembro
@onready var character_class: Label = %ClassName

## Contiene el sprite seleccionado del miembro
@onready var sprite: TextureRect = %Sprite

## Contiene el nombre del miembro
@onready var name_field: LineEdit = $MarginContainer/Content/LineEdit

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Configura el brillo en pantalla y la lista de clases disponibles
	bright.color.a = GameAPI.get_bright()
	class_list = GameAPI.get_classes()
	
	# Crea la plantilla con los datos del equipo y lo pone en su contenedor con la configuración (Índice y contexto para el comportamiento) necesaria
	var team_container = preload("res://scenes/global_elements/team_template/team_template.tscn").instantiate()
	
	team.add_child(team_container)
	
	team_container.set_data(GameAPI.get_team_in_edition(), team_container.Context.EDITOR)
	
	# Conecta la señal de miembro seleccionado, que establecerá el índice del miembro del equipo a editar
	team_container.member_selected.connect(_load_member)
	
	# Establece la variable para que su valor ahora sea el equipo cargado y carga el miembro 0 del equipo
	team = team.get_child(0)
	_load_member(member_index)

## Carga los datos del miembro del equipo según su índice
func _load_member(index: int):
	# Configura el índice del miembro seleccionado y recoge sus datos
	member_index = index
	member = GameAPI.get_team(GameAPI.get_team_in_edition()).members[member_index]
	
	# Si no se configuró el miembro, por lo que es null, se cargan los datos predeterminados
	if member == null:
		member = Character.new()
		class_index = -1
		sprite_index = 0
		character_class.text = "Ninguno"
		sprite.texture = GameAPI.get_asset("others", "Sin integrante")
		sprite_list = []
		name_field.text = ""
	
	# De lo contrario, se cargan los datos del miembro
	else:
		# Buscamos el índice de la clase del miembro para mostrarla en pantalla y se lo damo
		class_index = class_list.map(func (a): return a.class_type).find(member.class_type)
		character_class.text = class_list[class_index].class_type
		
		# Hacemos lo mismo con el índice, que al cambiar de clase volverá a ser el primer sprite de la lista
		sprite_list = GameAPI.get_asset("characters", class_list[class_index].class_type)
		sprite_index = sprite_list.find(member.sprite)
		sprite.texture = member.sprite
		
		# Por último, el nombre
		name_field.text = member.name

## Se ejecuta a pulsar la flecha izquierda en el sprite del miembro
func _on_previous_sprite_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Comprueba primero que haya sprites en la lista (Estará vacía si no tiene clase)
	if not sprite_list.is_empty():
		# Establecemos que al llegar al índice 0 y pulsar, vaya al final de la lista para evitar que no haga nada en ese caso
		if sprite_index <= 0:
			sprite_index = sprite_list.size() - 1
		
		else:
			sprite_index -= 1
		
		# Carga el sprite en el miembro y la pantalla según el índice y ejecuta el método que establece los cambios
		member.sprite = sprite_list[sprite_index]
		sprite.texture = member.sprite
		_on_member_changed()

## Se ejecuta a pulsar la flecha derecha en el sprite del miembro
func _on_next_sprite_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Comprueba primero que haya sprites en la lista (Estará vacía si no tiene clase)
	if not sprite_list.is_empty():
		# Establecemos que al llegar al último índice y pulsar, vaya al principio de la lista para evitar que no haga nada en ese caso
		if sprite_index >= sprite_list.size() - 1:
			sprite_index = 0
		
		else:
			sprite_index += 1
		
		# Carga el sprite en el miembro y la pantalla según el índice y ejecuta el método que establece los cambios
		member.sprite = sprite_list[sprite_index]
		sprite.texture = member.sprite
		_on_member_changed()

## Se ejecuta a pulsar la flecha izquierda en la clase del miembro
func _on_previous_class_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Evitamos que al llegar al primer índice de la lista deje de navegar poniendo el índice al final de la lista
	if class_index <= 0:
		class_index = class_list.size() - 1
	
	else:
		class_index -= 1
	
	# Carga los datos de la clase del miembro (sprite, nombre de clase, lista de sprites de la clase...), los muestra por pantalla y ejecuta el método que aplica los cambios
	character_class.text = class_list[class_index].class_type
	sprite_index = 0
	sprite_list = GameAPI.get_asset("characters", class_list[class_index].class_type)
	
	member = class_list[class_index].duplicate(true)
	member.sprite = sprite_list[sprite_index]
	sprite.texture = member.sprite
	member.name = name_field.text
	
	_on_member_changed()

## Se ejecuta a pulsar la flecha derecha en la clase del miembro
func _on_next_class_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Evitamos que al llegar al último índice de la lista deje de navegar poniendo el índice al principio de la lista
	if class_index >= class_list.size() - 1:
		class_index = 0
	
	else:
		class_index += 1
	
	# Carga los datos de la clase del miembro (sprite, nombre de clase, lista de sprites de la clase...), los muestra por pantalla y ejecuta el método que aplica los cambios
	character_class.text = class_list[class_index].class_type
	sprite_index = 0
	sprite_list = GameAPI.get_asset("characters", class_list[class_index].class_type)
	
	member = class_list[class_index].duplicate(true)
	member.sprite = sprite_list[sprite_index]
	sprite.texture = member.sprite
	member.name = name_field.text
	
	_on_member_changed()

## Se ejecuta al haber algún cambio en el campo de texto
func _on_line_edit_text_changed(new_text: String) -> void:
	# Establece el nombre en los datos del miembro y ejecuta el método para aplicar los cambios
	member.name = new_text
	
	_on_member_changed()

## Aplica los cambios en la api y el contenedor del equipo
func _on_member_changed():
	# Manda a la api el índice y datos del miembro a los que se le han hecho cambios y le dice al contenedor del equipo que recargue sus datos para mostrarlos
	GameAPI.set_member(GameAPI.get_team_in_edition(), member_index, member)
	team.load_data()

## Se ejecuta la pulsar en 'Confirmar'
func _on_confirm_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Guarda partida y navega de nuevo a la lista de equipos
	GameAPI.save_game()
	get_tree().change_scene_to_file("res://scenes/menus/teams/team_list.tscn")

## Se ejecuta al pulsar en 'clases'
func _on_classes_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Carga la guía de clases en la pantalla y le da el contexto
	var guide = preload("res://scenes/global_elements/entity_guide/entity_guide.tscn").instantiate()
	add_child(guide)
	guide.load_parameters("Clases", guide.Context.EDITOR)
