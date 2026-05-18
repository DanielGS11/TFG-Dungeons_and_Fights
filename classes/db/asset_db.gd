## Base de datos de los assets del juego
class_name AssetDB
extends Resource

## Diccionario de assets de las habitaciones
@export var rooms : Dictionary[String, Variant]

## Diccionario de assets de las clases
@export var characters : Dictionary[String, Array]

## Diccionario de assets de los iconos
@export var icons : Dictionary[String, Texture2D]

## Diccionario de otros assets
@export var others: Dictionary[String, Variant]
