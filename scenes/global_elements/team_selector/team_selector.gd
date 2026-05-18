extends Panel

## Avisa de que el equipo seleccionado cambió
signal team_changed

## Recoge el tipo de modo para el que se selecciona el equipo
var mode: Mode.Type

## Lista de equipos
@onready var list = %List

## Carga la lista de equippos y establece el modo para el que se selecciona
func load_teams(m: Mode.Type) -> void:
	mode = m
	
	# Recorre la lista de equipos creando una plantilla para cada uno con su índice correspondiente y contexto
	for i in GameAPI.get_all_teams().size():
		var team = preload("res://scenes/global_elements/team_template/team_template.tscn").instantiate()
		
		list.add_child(team)
		team.set_data(i, team.Context.MODE)
		
		# Conecta su señal al método correspondiente enviándole el índice del equipo seleccionado
		team.team_selected.connect(_on_team_selected.bind(i))

## Establece el equipo seleccionado
func _on_team_selected(index: int):
	MusicPlayer.play_sfx("Click")
	
	# Manda a la API el modo e índice del equipo que se establece, avisa de que se cambió el equipo y se destruye
	GameAPI.set_team_index(mode, index)
	team_changed.emit()
	queue_free()

## Establece que no se usará equipo
func _on_no_team_pressed() -> void:
	_on_team_selected(-1)

## Se ejecuta al pulsar el botón 'X' de la parte superior derecha de la pantalla
func _on_quit_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Se destruye la escena
	queue_free()
