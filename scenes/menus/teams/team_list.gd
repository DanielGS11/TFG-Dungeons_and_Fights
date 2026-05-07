extends Control

@onready var counter : Label = %Counter
@onready var list := %Teams
@onready var button := %AddTeam

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_load_teams()

## Carga los equipos disponibles
func _load_teams():
	var teams: Array[Team] = GameAPI.get_all_teams()
	
	for i in list.get_children():
		if not i is TextureButton:
			i.queue_free()
	
	for i in teams.size():
		var template = preload("res://scenes/global_elements/team_template/team_template.tscn").instantiate()
		
		list.add_child(template)
		
		list.move_child(button, -1)
		
		template.index = i
		template.team_deleted.connect(_delete_team.bind(template.index))
		template.context = template.Context.LIST
		template.load_data()
		
	
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

## Mira el estado del botón 'Añadir' y lo hace visible si hay menos de 5 equipos
func _check_button_state():
	button.visible = list.get_children().size() - 1 < 5
