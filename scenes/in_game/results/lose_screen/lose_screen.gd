extends Control

var mode_data: Mode

@onready var bright: ColorRect = $Bright/ColorRect

@onready var team_level: Label = $ResultContainer/Elements/TeamLevel
@onready var member_list = $ResultContainer/Elements/MemberList
@onready var enemies_defeated: Label = $ResultContainer/Elements/EnemiesDefeated

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicPlayer.play_music("Lose")
	
	bright.color.a = GameAPI.get_bright()
	mode_data = GameAPI.get_actual_mode()
	
	var team_avg_level = 0
	
	for i in mode_data.team_in_use.members.size():
		var member: Character = mode_data.team_in_use.members[i]
		var member_row = member_list.get_child(i)
		
		member_row.get_child(0).text = member.name
		member_row.get_child(1).text = "Lv " + str(member.level)
		
		team_avg_level += member.level
	
	team_level.text = "Nivel del equipo: " + str(ceili(float(team_avg_level) / mode_data.team_in_use.members.size()))
	enemies_defeated.text = "Enemigos derrotados: " + str(mode_data.enemies_defeated)

func _on_back_to_menu_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
