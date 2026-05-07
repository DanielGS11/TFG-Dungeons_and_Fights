## Contiene las variables de los datos de los modos y los equipos para guardar
class_name SaveData
extends Resource

@export var game_data = {
	Mode.Type.BATTLE: BattleMode,
	Mode.Type.DUNGEON: DungeonMode,
}

@export var teams: Array[Team]
