class_name Mode
extends GDScript

# Señales para que la escena realice diferentes acciones, las 2 primeras pasan por el controlador de
# pelea, que es el que gestiona las acciones de la pelea
# Ejecutar el prompt en la escena
signal prompt(text: String, pause: bool)
# Terminar el juego, que tiene en un string el resultado ("win", "lose") y el mensaje (prompt)
signal finish_game(result: String, message: String)
# Esta señal la recibe la escena, no el controller, para ejecutar el siguiente paso, es decir
# cargar un nuevo enemigo si es el battlemode, o abrir el mapa si es dungeonmode, le envia la id
# del enum de abajo que dice que tipo de modo es, asi si se añaden mas modos se hace mas facil la 
# gestión
signal next_step(id: type)

enum type {BATTLE, DUNGEON}


@export var mode: type
@export var team_in_use: Team
@export var controller: FightController
@export var is_finished: bool = false

@export var enemies_defeated: int = 0

@export var can_escape: bool

func new_game(data: Array):
	pass

func loadController() -> FightController:
	controller = FightController.new()
	
	controller.team = team_in_use
	
	controller.finish_fight.connect(_on_fight_finished)
	
	return controller

func _on_fight_finished():
	pass
