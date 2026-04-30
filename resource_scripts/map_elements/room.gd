class_name Room
extends Resource

enum Type {NORMAL, EMPTY, MINIBOSS, TREASURE, LOCK, BOSS}

@export var background : Texture2D

@export var room_type: Type
@export var accessible : bool = false
@export var explored : bool = false

@export var coordinates: Vector2i
@export var adjacent_rooms: Array

@export var enemy: Enemy
