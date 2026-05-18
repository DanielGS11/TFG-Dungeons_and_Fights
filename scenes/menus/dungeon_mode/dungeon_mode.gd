extends Control

## Índice del equipo que se usará, si no se quiere ninguno, se pondrá en -1
var team_index: int

## Shader de brillo
@onready var bright: ColorRect = $Bright/ColorRect

## Contenedor con el equipo a usar
@onready var team_container = $Content/TeamButton

## Aviso de debajo del contenedor del equipo, que aparecerá si no se selecciona equipo
@onready var warn: Label = $Content/Warn

## Contenedor con los botones de dificultad
@onready var difficulty_buttons = $Content/DifficultyButtons

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Carga el brillo, equipo seleccionado y dificultad del juego
	bright.color.a = GameAPI.get_bright()
	_load_team()
	var difficulty = GameAPI.get_difficulty()
	
	# Conecta los botones para mandar su dificultad (índice que el enum global de dificultad reconoce) a la API para que la establezca
	for i in difficulty_buttons.get_children().size():
		var button: TextureButton = difficulty_buttons.get_child(i)
		button.button_pressed = i == difficulty
		button.pressed.connect(_change_difficulty.bind(i))

## Carga el equipo seleccionado
func _load_team():
	# Recoge el índice del equipo seleccionado del modo y limpia el contenedor antes de establecerlo
	team_index = GameAPI.get_team_index(Mode.Type.DUNGEON)
	for i in team_container.get_children():
		team_container.remove_child(i)
	
	# Si el índice es -1 (Sin equipo), se establece un botón 'Sin equipo' en el contenedor y se avisa de que se asignará uno aleatorio
	if team_index <= -1:
		var no_team = TextureRect.new()
		
		team_container.add_child(no_team)
		
		no_team.texture = GameAPI.get_asset("others", "Sin equipo")
		no_team.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		no_team.stretch_mode = TextureRect.STRETCH_SCALE
		no_team.set_anchors_and_offsets_preset(team_container.PRESET_FULL_RECT)
		
		warn.text = "AVISO: Se asignará un equipo aleatorio"
	
	# De lo contrario, se carga la plantilla con los datos del equipo
	else:
		var team = preload("res://scenes/global_elements/team_template/team_template.tscn").instantiate()
		team_container.add_child(team)
		team.set_data(team_index, team.Context.MODE)
		
		warn.text = ""

## Cambia la dficultad del juego
func _change_difficulty(id: int):
	MusicPlayer.play_sfx("Click")
	
	# Manda el índice del botón a la API para que establezca la dificultad y hace que los otros botones de dificultad dejen de estar presionados
	GameAPI.set_difficulty(id)
	for i in difficulty_buttons.get_children().size():
		difficulty_buttons.get_child(i).button_pressed = i == id

## Se ejecuta al pulsar el botón del contenedor del equipo actual
func _on_team_button_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Carga el selector de equipos y le dice para qué modo es el equipo a seleccionar
	var selector = preload("res://scenes/global_elements/team_selector/team_selector.tscn").instantiate()
	add_child(selector)
	selector.load_teams(Mode.Type.DUNGEON)
	
	# Si no lo está, conecta la señal que emite cuando se selecciona un equipo al método que carga los datos del contenedor
	if not selector.team_changed.is_connected(_load_team):
		selector.team_changed.connect(_load_team)

## Se ejecuta al pulsar 'Jugar'
func _on_play_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Si el índice del equipo es -1 (Sin equipo), se establece el modo actual, se crea nueva partida y se va a la pantalla de juego
	if team_index <= -1:
		GameAPI.set_actual_mode(Mode.Type.DUNGEON)
		GameAPI.new_game([])
		
		get_tree().change_scene_to_file("res://scenes/in_game/fight_screen/fight_screen.tscn")
	
	# De lo contrario, se recogen los datos del equipo en una variable para comprobar si es válido
	else:
		var team: Team = GameAPI.get_team(team_index)
		
		# Antes de jugar, se debe comprobar si el equipo tiene todos sus integrantes configurados y con nombre, si no, se mandará un aviso al usuario
		if team.members.any(func(a: Character): return a == null or a.class_type.is_empty()):
			var warning = preload("res://scenes/global_elements/warning_popup/warning_popup.tscn").instantiate()
			
			add_child(warning)
			
			warning.load_warn("El equipo debe contar con 4 integrantes")
		
		elif team.members.any(func(a: Character): return a.name.is_empty()):
			var warning = preload("res://scenes/global_elements/warning_popup/warning_popup.tscn").instantiate()
			
			add_child(warning)
			
			warning.load_warn("Los integrantes del equipo deben tener un nombre")
		
		else:
			# Hechas estas comprobaciones y con el equipo ya configurado, se establece el modo actua, se crea nueva partida y se navega a la pantalla de juego
			GameAPI.set_actual_mode(Mode.Type.DUNGEON)
			GameAPI.new_game([])
			
			get_tree().change_scene_to_file("res://scenes/in_game/fight_screen/fight_screen.tscn")

## Se ejecuta al pulsar 'Volver'
func _on_return_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
