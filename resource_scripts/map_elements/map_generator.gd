class_name MapGenerator
extends GDScript

var rooms: Array[Vector2i]
var directions = [Vector2i.UP,Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

var total_rooms: int
var min_rooms: int

var total_minibossess: int

var treasure_generated = false
var boss_generated = false

func generateMap(height: int, width: int) -> Array:
	var map: Array[Array]
	var initial_room: _getInitialRoom()
	
	for i in range(width):
		map.append(i)
		
		for j in range(height):
			map.append(Room.new())
	
	return [map, initial_room]

func
