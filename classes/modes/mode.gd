## Contiene los datos y variables generales de los modos
class_name Mode
extends Resource

# Esta señal la recibe la escena, no el controller, para ejecutar el siguiente paso, es decir
# cargar un nuevo enemigo si es el battlemode, o abrir el mapa si es dungeonmode, le envia la id
# del enum de abajo que dice que tipo de modo es, asi si se añaden mas modos se hace mas facil la 
# gestión
@warning_ignore("unused_signal")
## Avisa a la escena de que haga la siguiente acció según el modo (refrescarse, abrir el mapa...)
signal next_step(id: Type)

## Indica qué modo es
enum Type {BATTLE, DUNGEON}

@export var mode: Type
@export var team_in_use: Team
@export var controller: FightController
@export var is_finished: bool = true

@export var enemies_defeated: int = 0

@export var can_escape: bool

## Reinicia las variables del modo para hacer una nueva partida
func new_game(_data: Array):
	pass

## Crea y carga el controlador y conecta su señal
func load_controller() -> FightController:
	controller = FightController.new()
	
	controller.team = team_in_use
	
	controller.enemy_defeated.connect(_on_enemy_defeated)
	
	return controller

## Se ejecuta al recibir la señal de enemigo derrotado del controlador
func _on_enemy_defeated(_exp_value: int):
	pass
