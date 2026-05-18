## Modo batalla
class_name BattleMode
extends Mode

## Índice del enemigo actual
@export var enemy_id: int = 0

## Cantidad de enemigos a enfrentar
@export var enemies_to_defeat: int

## Enemigo actual
@export var current_enemy: Enemy

## Se ejecuta al cargar la clase
func _init():
	mode = Type.BATTLE
	can_escape = false

# En este caso, data tiene la cantidad de enemigos a enfrentar
func new_game(data: Array):
	GameAPI.set_team(team_index)
	
	controller = null
	current_enemy = null
	is_finished = false
	enemies_to_defeat = data[0]
	enemy_id = 0
	
	enemies_defeated = 0
	
	load_controller()

func start():
	load_controller()
	
	# Se limpia el estado de todos
	for member in team_in_use.members:
		member.clear_modifiers()
	
	# Si no hay ningún enemigo a enfrentar, se carga uno nuevo
	if current_enemy == null or current_enemy.health == 0:
		await load_new_enemy()
	
	else:
		current_enemy.clear_modifiers()
		next_step.emit()
		await GameAPI.send_prompt(controller.enemy.name + " apareció", true)

func _on_enemy_defeated(_exp_value: int):
	# Se suma 1 a los enemigos derrotados, el equipo sube de nivel y se carga un nuevo enemigo
	enemies_defeated += 1
	
	for member in team_in_use.members:
		member.level_up()
		
		controller.refresh_data.emit(member)
	
	MusicPlayer.play_sfx("Level Up")
	await GameAPI.send_prompt("El equipo subió de nivel", true)
	
	current_enemy = null
	
	await load_new_enemy()

## Carga el siguiente enemigo o termina la partida si se terminó con todos
func load_new_enemy():
	# Si el índice del enemigo derrotado es igual o mayor al número de enemigos a derrotar, significa que se acabó la partida, por lo que se emite la señal para acabar el juego
	if enemy_id >= enemies_to_defeat:
		enemies_defeated = enemy_id
		is_finished = true
		GameAPI.end_game.emit(GameAPI.Result.WIN, "¡Felicidades, has acabado con todos los enemigos!")
	
	# Si no, se carga un nuevo enemigo y se le sube de nivel
	else:
		enemies_defeated = enemy_id
		
		current_enemy = GameAPI.get_enemy(mode, null)
		current_enemy.grow_levels(enemy_id)
		
		enemy_id += 1
		controller.enemy = current_enemy
		
		next_step.emit()
		
		await GameAPI.send_prompt(controller.enemy.name + " apareció", true)
	
	# Por último, se guarda la partida
	GameAPI.save_game()
