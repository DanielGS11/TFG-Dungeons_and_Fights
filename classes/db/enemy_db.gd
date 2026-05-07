## Base de datos de los enemigos de cada modo del juego
class_name EnemyDB
extends Resource

@export var all_enemies: Array[Enemy]

@export var battle_mode: Array[Enemy]

@export var dungeon_mode: Dictionary[String, Array]
