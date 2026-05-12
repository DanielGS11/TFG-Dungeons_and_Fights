extends Control

# Shader de brillo
@onready var bright: ColorRect = $Bright/ColorRect

@onready var battle_mode_button = $BattleMode
@onready var dungeon_mode_button = $DungeonMode
@onready var teams_button = $Teams
@onready var exit_button = $Exit
@onready var settings_button = $Settings
@onready var guides_button = $Guides

# Al cargar la pantalla
func _ready() -> void:
	# Ajusto el brillo de pantalla
	bright.color.a = GameAPI.get_bright()
	
	# Ya que varias clases usan la misma animación, creo un método que ejecute animaciones
	await _animate("entry")

# Botones
func _on_battle_mode_pressed() -> void:
	# Si la partida no terminó, salta un aviso y comprueba si se quiere seguir
	if GameManager.modes[Mode.Type.BATTLE].is_finished == false:
		var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
		add_child(popup)
		
		popup.load_text("Hay una partida de este modo en curso, ¿Quieres seguirla?")
		
		# Esperamos que la notificación envie la señal
		if await popup.confirm:
			GameAPI.set_actual_mode(Mode.Type.BATTLE)
			await _animate("exit")
			get_tree().change_scene_to_file("res://scenes/in_game/fight_screen/fight_screen.tscn")
		
		else:
			await _animate("exit")
			get_tree().change_scene_to_file("res://scenes/menus/battle_mode/battle_mode.tscn")
	
	else:
		await _animate("exit")
		get_tree().change_scene_to_file("res://scenes/menus/battle_mode/battle_mode.tscn")

func _on_dungeon_mode_pressed() -> void:
	# Si la partida no terminó, salta un aviso y comprueba si se quiere seguir
	if GameManager.modes[Mode.Type.DUNGEON].is_finished == false:
		var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
		add_child(popup)
		
		popup.load_text("Hay una partida de este modo en curso, ¿Quieres seguirla?")
		
		# Esperamos que la notificación envie la señal
		if await popup.confirm:
			GameAPI.set_actual_mode(Mode.Type.DUNGEON)
			await _animate("exit")
			get_tree().change_scene_to_file("res://scenes/in_game/fight_screen/fight_screen.tscn")
		
		else:
			await _animate("exit")
			get_tree().change_scene_to_file("res://scenes/menus/dungeon_mode/dungeon_mode.tscn")
	
	else:
		await _animate("exit")
		get_tree().change_scene_to_file("res://scenes/menus/dungeon_mode/dungeon_mode.tscn")

func _on_teams_pressed() -> void:
	await _animate("exit")
	
	get_tree().change_scene_to_file("res://scenes/menus/teams/team_list.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	var settings = preload("res://scenes/global_elements/settings/settings.tscn").instantiate()
	
	add_child(settings)
	
	if not settings.bright_changed.is_connected(func(value): bright.color.a = value):
		settings.bright_changed.connect(func(value): bright.color.a = value)
	
	await settings.tree_exited
	bright.color.a = GameAPI.get_bright()

func _on_guides_pressed() -> void:
	add_child(preload("res://scenes/main_menu/guides/guide_list.tscn").instantiate())

# Ejecuta una animación y espera a que termine
func _animate(animation: String):
	if GameAPI.get_config().animations:
		var battle_mode_tween = battle_mode_button.create_tween()
		var dungeon_mode_tween = dungeon_mode_button.create_tween()
		var teams_tween = teams_button.create_tween()
		var exit_tween = exit_button.create_tween()
		var settings_tween = settings_button.create_tween()
		var guides_tween = guides_button.create_tween()
		
		var battle_mode_pos = battle_mode_button.position.x
		var dungeon_mode_pos = dungeon_mode_button.position.x
		var teams_pos = teams_button.position.x
		var exit_pos = exit_button.position.x
		var settings_pos = settings_button.position.y
		var guides_pos = guides_button.position.y
		
		match animation:
			"entry":
				battle_mode_button.position.x += get_viewport_rect().size.x
				dungeon_mode_button.position.x += get_viewport_rect().size.x
				teams_button.position.x += get_viewport_rect().size.x
				exit_button.position.x += get_viewport_rect().size.x
				settings_button.position.y += get_viewport_rect().size.y
				guides_button.position.y += get_viewport_rect().size.y
				
				battle_mode_tween.tween_property(battle_mode_button, "position:x", battle_mode_pos, 0.1)
				dungeon_mode_tween.tween_property(dungeon_mode_button, "position:x", dungeon_mode_pos, 0.15)
				teams_tween.tween_property(teams_button, "position:x", teams_pos, 0.2)
				exit_tween.tween_property(exit_button, "position:x", exit_pos, 0.25)
				settings_tween.tween_property(settings_button, "position:y", settings_pos, 0.15)
				guides_tween.tween_property(guides_button, "position:y", guides_pos, 0.2)
			
			"exit":
				battle_mode_tween.tween_property(battle_mode_button, "position:x", battle_mode_pos + get_viewport_rect().size.x, 0.1)
				dungeon_mode_tween.tween_property(dungeon_mode_button, "position:x", battle_mode_pos + get_viewport_rect().size.x, 0.15)
				teams_tween.tween_property(teams_button, "position:x", battle_mode_pos + get_viewport_rect().size.x, 0.2)
				exit_tween.tween_property(exit_button, "position:x", battle_mode_pos + get_viewport_rect().size.x, 0.25)
				settings_tween.tween_property(settings_button, "position:y", battle_mode_pos + get_viewport_rect().size.y, 0.15)
				guides_tween.tween_property(guides_button, "position:y", battle_mode_pos + get_viewport_rect().size.y, 0.2)
		
		await exit_tween.finished
