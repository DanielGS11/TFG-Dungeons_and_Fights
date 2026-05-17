extends Control

var team_index: int

@onready var bright: ColorRect = $Bright/ColorRect

@onready var team_container = $Content/TeamButton
@onready var warn: Label = $Content/Warn

@onready var difficulty_buttons = $Content/DifficultyButtons

func _ready() -> void:
	bright.color.a = GameAPI.get_bright()
	
	_load_team()
	
	var difficulty = GameAPI.get_difficulty()
	
	for i in difficulty_buttons.get_children().size():
		var button: TextureButton = difficulty_buttons.get_child(i)
		button.button_pressed = i == difficulty
		
		button.pressed.connect(change_difficulty.bind(i))

func _load_team():
	team_index = GameAPI.get_team_index(Mode.Type.DUNGEON)
	
	for i in team_container.get_children():
		team_container.remove_child(i)
	
	if team_index <= -1:
		var no_team = TextureRect.new()
		
		team_container.add_child(no_team)
		
		no_team.texture = GameAPI.get_asset("others", "Sin equipo")
		no_team.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		no_team.stretch_mode = TextureRect.STRETCH_SCALE
		no_team.set_anchors_and_offsets_preset(team_container.PRESET_FULL_RECT)
		
		warn.text = "AVISO: Se asignará un equipo aleatorio"
	
	else:
		var team = preload("res://scenes/global_elements/team_template/team_template.tscn").instantiate()
		
		team_container.add_child(team)
		
		team.set_data(team_index, team.Context.MODE)
		
		warn.text = ""

func change_difficulty(id: int):
	MusicPlayer.play_sfx("Click")
	
	GameAPI.set_difficulty(id)
	
	for i in difficulty_buttons.get_children().size():
		difficulty_buttons.get_child(i).button_pressed = i == id
		

func _on_team_button_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	var selector = preload("res://scenes/global_elements/team_selector/team_selector.tscn").instantiate()
	
	add_child(selector)
	
	selector.load_teams(Mode.Type.DUNGEON)
	
	if not selector.team_changed.is_connected(_load_team):
		selector.team_changed.connect(_load_team)

func _on_play_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	if team_index <= -1:
		GameAPI.set_actual_mode(Mode.Type.DUNGEON)
		GameAPI.new_game([])
		
		get_tree().change_scene_to_file("res://scenes/in_game/fight_screen/fight_screen.tscn")
	
	else:
		var team: Team = GameAPI.get_team(team_index)
		
		if team.members.any(func(a: Character): return a == null or a.class_type.is_empty()):
			var warning = preload("res://scenes/global_elements/warning_popup/warning_popup.tscn").instantiate()
			
			add_child(warning)
			
			warning.load_warn("El equipo debe contar con 4 integrantes")
		
		elif team.members.any(func(a: Character): return a.name.is_empty()):
			var warning = preload("res://scenes/global_elements/warning_popup/warning_popup.tscn").instantiate()
			
			add_child(warning)
			
			warning.load_warn("Los integrantes del equipo deben tener un nombre")
		
		else:
			GameAPI.set_actual_mode(Mode.Type.DUNGEON)
			GameAPI.new_game([])
			
			get_tree().change_scene_to_file("res://scenes/in_game/fight_screen/fight_screen.tscn")

func _on_return_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
