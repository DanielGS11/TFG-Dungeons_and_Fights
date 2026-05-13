extends Control

@onready var bright = $Bright/ColorRect

@onready var counter : Label = %Counter
@onready var list := %Teams
@onready var button := %AddTeam

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ajusto el brillo de pantalla
	bright.color.a = GameAPI.get_bright()
	
	_load_teams()

## Carga los equipos disponibles
func _load_teams():
	var teams: Array[Team] = GameAPI.get_all_teams()
	
	for i in list.get_children():
		if i.name != button.name:
			list.remove_child(i)
	
	for i in teams.size():
		var template = preload("res://scenes/global_elements/team_template/team_template.tscn").instantiate()
		
		list.add_child(template)
		
		list.move_child(button, -1)
		
		template.set_data(i, template.Context.LIST)
		template.team_deleted.connect(_delete_team)
		template.team_selected.connect(func(): 
			get_tree().change_scene_to_file("res://scenes/menus/teams/team_editor.tscn"))
		
	
	counter.text = str(teams.size()) + "/5"
	
	_check_button_state()

## Borrar un equipo
func _delete_team (index: int):
	var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
	add_child(popup)
	
	popup.load_text("¿Seguro que quieres borrar este equipo?")
	
	# Esperamos que la notificación envie la señal
	if await popup.confirm:
		GameAPI.delete_team(index)
		
		_load_teams()
		
		GameAPI.save_game()

## Mira el estado del botón 'Añadir' y lo hace visible si hay menos de 5 equipos
func _check_button_state():
	button.visible = GameAPI.get_all_teams().size() < 5

func _on_return_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _on_add_team_pressed() -> void:
	GameAPI.add_team()
	
	get_tree().change_scene_to_file("res://scenes/menus/teams/team_editor.tscn")
