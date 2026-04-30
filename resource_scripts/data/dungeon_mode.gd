class_name DungeonMode
extends Mode

enum GameMode {EASY, MEDIUM, HARD}

@export var is_on_map: bool

@export var difficulty := GameMode.EASY
@export var dungeon_map : MapData

@export var has_key: bool = false

func _init():
	mode = Type.DUNGEON
	can_escape = true

func _on_fight_finished():
	pass
