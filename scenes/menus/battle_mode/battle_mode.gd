extends Control

var team_index: int
var enemy_counter := 1
var button_down := false

@onready var bright: ColorRect = $Bright/ColorRect

@onready var team_container = $Content/TeamButton
@onready var warn: Label = $Content/Warn
@onready var enemy_count: Label = $Content/EnemiesNumber/Number/Text

@onready var minus: TextureButton = $Content/EnemiesNumber/Minus
@onready var plus: TextureButton = $Content/EnemiesNumber/Plus

func _ready() -> void:
	bright.color.a = GameAPI.get_bright()
	
	enemy_count.text = str(enemy_counter)
	
	_load_team()

func _load_team():
	team_index = GameAPI.get_team_index(Mode.Type.BATTLE)
	
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

func _on_team_button_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	var selector = preload("res://scenes/global_elements/team_selector/team_selector.tscn").instantiate()
	
	add_child(selector)
	
	selector.load_teams(Mode.Type.BATTLE)
	
	if not selector.team_changed.is_connected(_load_team):
		selector.team_changed.connect(_load_team)

func _on_minus_button_down() -> void:
	MusicPlayer.play_sfx("Click")
	
	if button_down:
		return
	
	button_down = true
	
	while minus.button_pressed:
		enemy_counter = clamp(enemy_counter - 1, 1, 50)
		
		enemy_count.text = str(enemy_counter)
		
		await get_tree().create_timer(0.2).timeout
	
	button_down = false


func _on_plus_button_down() -> void:
	MusicPlayer.play_sfx("Click")
	
	if button_down:
		return
	
	button_down = true
	
	while plus.button_pressed:
		enemy_counter = clamp(enemy_counter + 1, 1, 50)
		
		enemy_count.text = str(enemy_counter)
		
		await get_tree().create_timer(0.2).timeout
	
	button_down = false

func _on_play_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	if team_index <= -1:
		GameAPI.set_actual_mode(Mode.Type.BATTLE)
		GameAPI.new_game([enemy_counter])
		
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
			GameAPI.set_actual_mode(Mode.Type.BATTLE)
			GameAPI.new_game([enemy_counter])
			
			get_tree().change_scene_to_file("res://scenes/in_game/fight_screen/fight_screen.tscn")

func _on_return_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
