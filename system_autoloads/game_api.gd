extends Node

# Las señales globales se ubican en la api
## Envía una línea de comando
signal prompt(text: String, pause: bool)
## Avisa de que la línea de comando terminó de mostrarse
signal prompt_end()
## Avisa de que el juego terminó y da un mensaje final
@warning_ignore("unused_signal")
signal end_game(result: Result, message: String)

# Al ser algo que manejan varias clases, algunos enums irán en la API
## Estadística a modificar
enum Modifier {ATTACK, M_ATTACK, DEFENSE}

## Dificultad de partida
enum Difficulty {EASY, MEDIUM, HARD}

## Resultado de la partida
enum Result {WIN, LOSE}

# DB
var assets_db : AssetDB = load("res://resources/db/asset_db.tres")
var enemies_db : EnemyDB = load("res://resources/db/enemy_db.tres")
var characters_db : CharacterDB = load("res://resources/db/character_db.tres")
var guides_db: GuidesDB = load("res://resources/db/guides_db.tres")

## Manda una línea de comando
func send_prompt(text: String, pause: bool):
	prompt.emit(text, pause)
	
	await prompt_end

func get_difficulty() -> int:
	return GameManager.modes[Mode.Type.DUNGEON].difficulty

func set_difficulty(id: int):
	GameManager.modes[Mode.Type.DUNGEON].difficulty = id

## Establecer modo de juego
func set_actual_mode(id: Mode.Type):
	GameManager.actual_mode = GameManager.modes[id]

func get_actual_mode() -> Mode:
	return GameManager.actual_mode

## Devuelve una lista con todos los equipos
func get_all_teams() -> Array[Team]: 
	return GameManager.teams

## Devuelve un equipo según su índice
func get_team(index: int) -> Team:
	return GameManager.teams[index]

## Carga un equipo en el modo de juego actual
func set_team(index: int):
	var team: Team
	
	if index == -1:
		team = Team.new()
		
		for i in team.members.size():
			team.members[i] = characters_db.characters.pick_random().duplicate(true)
			team.members[i].name = "Player " + str(i + 1)
	
	else:
		team = GameManager.teams[index].duplicate(true)
	
	GameManager.actual_mode.team_in_use = team

## Añade un equipo
func add_team():
	GameManager.teams.append(Team.new())
	
	GameManager.team_in_edition = GameManager.teams.size() - 1

## Devuelve en índice del equipo en uso
func get_team_index(mode: Mode.Type) -> int:
	return GameManager.modes[mode].team_index

## Configura el índice del equipo en uso
func set_team_index(mode: Mode.Type, index: int):
	GameManager.modes[mode].team_index = index

## Borra un equipo
func delete_team(index: int):
	for key in GameManager.modes:
		if index == GameManager.modes[key].team_index:
			GameManager.modes[key].team_index = -1
	
	GameManager.teams.remove_at(index)

## Asigna el id del equipo en edición
func set_team_in_edition(index: int):
	GameManager.team_in_edition = index

## Devuelve el id equipo en edición
func get_team_in_edition() -> int:
	return GameManager.team_in_edition

## Añade/Modifica un miembro de un equipo
func set_member(team_index: int, member_index: int, member: Character):
	GameManager.teams[team_index].members[member_index] = member

func new_game(data: Array):
	GameManager.actual_mode.new_game(data)

func get_controller() -> FightController:
	return GameManager.actual_mode.controller

func get_map_data() -> MapData:
	return GameManager.actual_mode.dungeon_map

## Recoge 1 o más assets según la categoria y nombre de este
func get_asset(category: String, key: String) -> Variant:
	var asset_dictionary = assets_db.get(category)
	var asset: Variant
	
	if asset_dictionary == null or not asset_dictionary.has(key):
		push_error("Asset '" + key + "' de la categoría '" + category + "' no encontrado")
		
		asset = assets_db.others["Sin textura"]
		
	else:
		asset = asset_dictionary[key]
	
	return asset

## Pedir un enemigo aleatorio según el modo y categoría si la hay
func get_enemy(mode: Mode.Type, category: Variant) -> Enemy:
	var enemy_list: Array
	
	match mode:
		Mode.Type.BATTLE:
			enemy_list = enemies_db.battle_mode
		
		Mode.Type.DUNGEON:
			enemy_list = enemies_db.dungeon_mode[category]
	
	return enemy_list.pick_random().duplicate(true)

## Pide la lista de todos los enemigos
func get_all_enemies() -> Array:
	return enemies_db.all_enemies

## Pide la lista de clases
func get_classes() -> Array:
	return characters_db.characters

## Pedir una guía según su clave
func get_guide(key: String) -> Array:
	var data: Array
	if not guides_db.guides.has(key):
		data = ["No se encontró una guía con el título '" + key + "'"]
	
	else:
		data = guides_db.guides[key]
	
	return data

## Pedir claves de las guías
func get_guide_keys() -> Array:
	return guides_db.guides.keys()
 
## Devuelve la configuración del juego
func get_config() -> ConfigData:
	return GameManager.config

## Configurar volumen general
func set_volume(volume: float):
	GameManager.config.volume = clamp(volume, 0, 100)
	
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), GameManager.config.mute)
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(GameManager.config.volume / 100.0))

## Configurar brillo del juego
func set_bright(bright: float):
	GameManager.config.bright = clamp(bright, 0, 100)

## Configurar silencio del volumen general
func set_mute(mute: bool):
	GameManager.config.mute = mute
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), GameManager.config.mute)

## Devuelve el brillo ya formateado
func get_bright() -> float:
	return clampf(((100 - GameManager.config.bright) / 100) * 0.8, 0.0, 0.8)

## Configurar la reproducción de animaciones del juego
func set_animations(value: bool):
	GameManager.config.animations = value

## Guarda partida y sus datos
func save_game():
	SaveManager.save_game()

## Guarda la configuración del juego
func save_config():
	SaveManager.save_config()

## Carga datos del juego y la configuración
func load_saves():
	SaveManager.load_saves()
