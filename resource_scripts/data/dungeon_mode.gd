class_name DungeonMode
extends Mode

enum game_mode {EASY, MEDIUM, HARD}

@export var is_on_map: bool

@export var difficulty := game_mode.EASY
@export var dungeon_map : MapData

@export var has_key: bool = false

func _init():
	mode = type.DUNGEON
	can_escape = true

func _on_fight_finished():
	if dungeon_map
