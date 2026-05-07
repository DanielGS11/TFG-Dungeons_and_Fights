class_name SaveManager
extends RefCounted

# Las rutas en las que guarda serian las siguientes segun el SO:
# - Windows: %APPDATA%\Godot\app_userdata\[Nombre_del_proyecto]
# - Linux: ~/.local/share/godot/app_userdata/[Nombre_del_proyecto]
# - Android: /data/user/0/[paquete.del.juego]/files/ o /data/data/[paquete.del.juego]/files/
## Contiene las rutas de guardado para el juego y la configuración
static var SAVE_ROUTES := {
	"Game" : "user://save.res",
	"Config": "user://config.res"
}

## Guarda partida y sus datos
static func save_game():
	var save = SaveData.new()
	
	for id in GameManager.modes:
		save.game_data[id] = GameManager.modes[id].duplicate(true)
	
	save.teams = GameManager.teams.duplicate(true)
	
	ResourceSaver.save(save, SAVE_ROUTES["Game"])

## Guarda la configuración del juego
static func save_config():
	var save = ConfigData.new()
	
	save = GameManager.config.duplicate(true)
	
	ResourceSaver.save(save, SAVE_ROUTES["Config"])

## Carga datos del juego y la configuración
static func load_saves():
	var save
	
	# Primero comprueba la existencia de cada archivo y luego lo carga
	if ResourceLoader.exists(SAVE_ROUTES["Game"]):
		save = ResourceLoader.load(SAVE_ROUTES["Game"], "", ResourceLoader.CACHE_MODE_REPLACE)
		
		if save is SaveData:
			for id in save.game_data:
				GameManager.modes[id] = save.game_data[id]
			
			GameManager.teams = save.teams
	
	if ResourceLoader.exists(SAVE_ROUTES["Config"]):
		save = ResourceLoader.load(SAVE_ROUTES["Config"], "", ResourceLoader.CACHE_MODE_REPLACE)
		
		if save is ConfigData:
			GameManager.config = save
