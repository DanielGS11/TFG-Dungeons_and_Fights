extends Control

## Contiene los datos del modo actual
var mode_data: Mode

## Shader de brillo
@onready var bright: ColorRect = $Bright/ColorRect

## Muestra el nivel del equipo
@onready var team_level: Label = $ResultContainer/Elements/TeamLevel

## Lista de miembros del equipo
@onready var member_list = $ResultContainer/Elements/MemberList

## Muestra la cantidad de enemigos que se derrotó en la partida
@onready var enemies_defeated: Label = $ResultContainer/Elements/EnemiesDefeated

## Se ejecuta al cargar la escena
func _ready() -> void:
	MusicPlayer.play_music("Lose")
	
	# Configura el brillo y datos del modo actual
	bright.color.a = GameAPI.get_bright()
	mode_data = GameAPI.get_actual_mode()
	
	# Crea una variable para establecer el nivel del equipo que se usó en la partida, que primero suma el nivel de todos los integrantes del equipo y luego lo divide entre el número de integrantes y lo plasma en la variable que lo muestra
	var team_avg_level = 0
	
	# Recorremos el equipo del modo actual, plasmando su nombre y nivel en la lista de miembros del equipo y sumamos su nivel a la variable del nivel de equipo
	for i in mode_data.team_in_use.members.size():
		var member: Character = mode_data.team_in_use.members[i]
		var member_row = member_list.get_child(i)
		
		member_row.get_child(0).text = member.name
		member_row.get_child(1).text = "Lv " + str(member.level)
		
		team_avg_level += member.level
	
	team_level.text = "Nivel del equipo: " + str(ceili(float(team_avg_level) / mode_data.team_in_use.members.size()))
	
	# Plasma en la variable de 'enemigos derrotados' los enemigos derrotados en el modo actual
	enemies_defeated.text = "Enemigos derrotados: " + str(mode_data.enemies_defeated)

## Se ejecuta al pulsar en 'Menú principal'
func _on_back_to_menu_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Navega de nuevo al menú principal
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
