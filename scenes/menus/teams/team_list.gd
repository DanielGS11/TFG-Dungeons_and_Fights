extends Control

## Shader de brillo
@onready var bright = $Bright/ColorRect

## Contador de equipos creados
@onready var counter : Label = %Counter

## Contenedor de la lista de equipos
@onready var list := %Teams

## Botón para añadir un equipo
@onready var button := %AddTeam

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Ajusto el brillo de pantalla y ejecuto el método que carga los equipos
	bright.color.a = GameAPI.get_bright()
	_load_teams()

## Carga los equipos creados
func _load_teams():
	# Guardo en una lista los equipos y limpio el contenedor de equipos procurando no borrrar el botón de añadir
	var teams: Array[Team] = GameAPI.get_all_teams()
	
	for i in list.get_children():
		if i.name != button.name:
			list.remove_child(i)
	
	# Por cada equipo creaod se crea una plantilla con el índice del equipo que contendrá para que muestre sus datos, se le da el contexto para que sepa cómo comportarte y se mueve el botón al final del contenedor
	for i in teams.size():
		var template = preload("res://scenes/global_elements/team_template/team_template.tscn").instantiate()
		
		list.add_child(template)
		
		list.move_child(button, -1)
		
		template.set_data(i, template.Context.LIST)
		
		# Se conectan las señales de borrado y selección de equipo a sus respectivos métodos
		template.team_deleted.connect(_delete_team)
		
		# Ya que la selección de equipo solo necesita cambiar de pantalla, no se crea un método especializado
		template.team_selected.connect(func(): 
			get_tree().change_scene_to_file("res://scenes/menus/teams/team_editor.tscn"))
	
	# Se establece el contador de equipos para la vista del usuario y se comprueba el estado del botón de añadir equipo
	counter.text = str(teams.size()) + "/5"
	_check_button_state()

## Borrar un equipo de la lista
func _delete_team (index: int):
	# Nos aseguramos de que no se pulsó sin querer el botón con un popup
	var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
	add_child(popup)
	
	popup.load_text("¿Seguro que quieres borrar este equipo?")
	
	# Si se confirma el borrado del equipo, manda a la API el índice del equipo a borrar, se recarga el la lista y se guarda partida
	if await popup.confirm:
		GameAPI.delete_team(index)
		
		_load_teams()
		
		GameAPI.save_game()

## Mira el estado del botón 'Añadir' y lo hace visible si hay menos de 5 equipos
func _check_button_state():
	button.visible = GameAPI.get_all_teams().size() < 5

## Al pulsar el botón 'Volver', navega al menú principal
func _on_return_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

## Al pulsar el botón '+ Añadir' crea un nuevo equipo y navega hacia la pantalla de edición
func _on_add_team_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	GameAPI.add_team()
	
	get_tree().change_scene_to_file("res://scenes/menus/teams/team_editor.tscn")
