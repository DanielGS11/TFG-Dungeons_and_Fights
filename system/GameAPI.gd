extends Node
# Al ser algo que manejan 2 clases, lo pongo en la API ya que es global
enum modifier {ATTACK, M_ATTACK, DEFENSE}

var assets : AssetDB = load("res://resources/db/asset_db.tres")

# Pedir un asset, devuelve array de assets ya que puede haber 1 o mas
func get_room_asset(asset_key: String) -> Array[Texture2D]:
	var asset_array: Array[Texture2D]
	
	if assets.rooms.has(asset_key):
		asset_array = assets.rooms[asset_key]
	
	else:
		push_error("Asset '" + asset_key + "' no encontrado")
		asset_array = [preload("res://assets/asset_not_found.png")]
	
	return asset_array

func get_icon_asset(asset_key: String) -> Array[Texture2D]:
	var asset_array: Array[Texture2D]
	
	if assets.icons.has(asset_key):
		asset_array = assets.icons[asset_key]
	
	else:
		push_error("Asset '" + asset_key + "' no encontrado")
		asset_array = [preload("res://assets/asset_not_found.png")]
	
	return asset_array

func get_character_asset(asset_key: String) -> Array[Texture2D]:
	var asset_array: Array[Texture2D]
	
	if assets.characters.has(asset_key):
		asset_array = assets.characters[asset_key]
	
	else:
		push_error("Asset '" + asset_key + "' no encontrado")
		asset_array = [preload("res://assets/asset_not_found.png")]
	
	return asset_array

# Manejo de partida y configuración
# Las rutas en las que guarda serian las siguientes segun el SO:
# - Windows: %APPDATA%\Godot\app_userdata\[Nombre_del_proyecto]
# - Linux: ~/.local/share/godot/app_userdata/[Nombre_del_proyecto]
# - Android: /data/user/0/[paquete.del.juego]/files/ o /data/data/[paquete.del.juego]/files/
var saveRoutes := {
	"Game" : "user://save.res",
	"Config": "user://config.res"
}

# Variable que se encarga del guardado
var save

# Separo el guardado de partida y configuración para evitar guardados de configuración o
# partida cuando no son necesarios
func saveGame():
	save = GameData.new()
	
	ResourceSaver.save(save, saveRoutes["Game"])

func saveConfig():
	save = ConfigData.new()
	
	ResourceSaver.save(save, saveRoutes["Config"])

func loadSaves():
	if ResourceLoader.exists(saveRoutes["Game"]):
		save = ResourceLoader.load(saveRoutes["Game"], "", ResourceLoader.CACHE_MODE_REPLACE)
	
	if ResourceLoader.exists(saveRoutes["Config"]):
		save = ResourceLoader.load(saveRoutes["Config"], "", ResourceLoader.CACHE_MODE_REPLACE)
