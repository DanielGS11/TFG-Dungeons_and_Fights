## Habitación de mazmorra
class_name Room
extends Resource

## Posibles tipos de habitación
enum Type {NORMAL, EMPTY, MINIBOSS, TREASURE, LOCK, BOSS}

## Fondo de la habitación
@export var background : Texture2D

## Tipo de habitación
@export var room_type: Type

## Indica si es accesible o no (Pared)
@export var accessible : bool = false

## Indica si ya fué explorada
@export var explored : bool = false

## Coordenadas de la habitación
@export var coordinates: Vector2i

## Coordenadas de las habitaciones adyacentes
@export var adjacent_rooms: Array

## Enemigo de la habitación
@export var enemy: Enemy
