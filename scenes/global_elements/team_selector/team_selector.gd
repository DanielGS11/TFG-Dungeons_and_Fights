extends Panel

signal team_changed

var mode: Mode.Type

@onready var list = %List

func load_teams(m: Mode.Type) -> void:
	mode = m
	
	for i in GameAPI.get_all_teams().size():
		var team = preload("res://scenes/global_elements/team_template/team_template.tscn").instantiate()
		
		list.add_child(team)
		
		team.team_selected.connect(_on_team_selected.bind(i))
		team.set_data(i, team.Context.MODE)

func _on_team_selected(index: int):
	MusicPlayer.play_sfx("Click")
	
	GameAPI.set_team_index(mode, index)
	team_changed.emit()
	queue_free()

func _on_no_team_pressed() -> void:
	_on_team_selected(-1)

func _on_quit_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	queue_free()
