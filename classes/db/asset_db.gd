## Base de datos de los assets del juego
class_name AssetDB
extends Resource

@export var rooms : Dictionary[String, Variant]

@export var characters : Dictionary[String, Array]

@export var icons : Dictionary[String, Texture2D]

@export var others: Dictionary[String, Variant]
