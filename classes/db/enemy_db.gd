## Base de datos de los enemigos de cada modo del juego
class_name EnemyDB
extends Resource

## Lista de todos los enemigos
@export var all_enemies: Array[Enemy]

## Lista de enemigos del modo batalla
@export var battle_mode: Array[Enemy]

## Diccionario de enemigos del modo mazmorra según su tipo (Jefe, Minijefe, Normal)
@export var dungeon_mode: Dictionary[String, Array]
