## Contiene los datos y variables generales de los modos
class_name Mode
extends Resource

@warning_ignore("unused_signal")
## Avisa a la escena de que haga la siguiente acción según el modo (refrescarse, abrir el mapa...)
signal next_step()

## Contiene los tipos de modo que puede haber
enum Type {BATTLE, DUNGEON}

## Módo de juego
@export var mode: Type

## Equipo que se usa en este modo
@export var team_in_use: Team

## Índice del equipo que se usará, si es -1 será uno aleatorio
@export var team_index: int = -1

## Controlador de batalla
@export var controller: FightController

## Indica si la partida está terminada o no
@export var is_finished: bool = true

## Indica la cantidad de enemigos derrotados en esa partida
@export var enemies_defeated: int = 0

## Indica si el botón y función 'Huir' estarán habilitados
@export var can_escape: bool

## Reinicia las variables del modo para hacer una nueva partida
func new_game(_data: Array):
	pass

## Crea y carga el controlador y conecta su señal de enemigo derrotado
func load_controller():
	if controller == null:
		controller = FightController.new()
	
	if controller.team == null:
		controller.team = team_in_use
	
	if not controller.enemy_defeated.is_connected(_on_enemy_defeated):
		controller.enemy_defeated.connect(_on_enemy_defeated)

## Se ejecuta al recibir la señal de enemigo derrotado del controlador
func _on_enemy_defeated(_exp_value: int):
	pass

## Empieza el juego
func start():
	pass
