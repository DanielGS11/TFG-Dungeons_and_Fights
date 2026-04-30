class_name MapData
extends Resource

@export var map: Array[Array]
@export var initial_coordinates: Vector2i

func generate_map(height: int, width: int):
	var data = MapGenerator.new().generate_map(height, width)
	
	map = data[0]
	initial_coordinates = data[1]
