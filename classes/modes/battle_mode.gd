## Modo batalla
class_name BattleMode
extends Mode

@export var enemy_id: int = 0
@export var enemies_to_defeat: int
@export var current_enemy: Enemy

func _init():
	mode = Type.BATTLE
	can_escape = false

func new_game(data: Array):
	current_enemy = null
	is_finished = false
	enemies_to_defeat = data[0]
	enemy_id = 0
	
	enemies_defeated = 0
	
	load_controller()

func start():
	if current_enemy == null or current_enemy.health == 0:
		load_new_enemy()
	
	else:
		await GameAPI.send_prompt(controller.enemy.name + " apareció", true)

func _on_enemy_defeated(_exp_value: int):
	for member in team_in_use.members:
		member.level_up()
		member.clear_modifiers()
		
		controller.refresh_data.emit(member)
	
	await GameAPI.send_prompt("El equipo subió de nivel", true)
	
	load_new_enemy()

## Carga el siguiente enemigo o termina la partida si se terminó con todos
func load_new_enemy():
	if enemy_id >= enemies_to_defeat:
		enemies_defeated = enemy_id
		is_finished = true
		GameAPI.end_game.emit(GameAPI.Result.WIN, "¡Felicidades, has acabado con todos los enemigos!")
	else:
		enemy_id += 1
		enemies_defeated = enemy_id - 1
		
		current_enemy = GameAPI.get_enemy(mode, null)
		current_enemy.grow_levels(enemy_id - 1)
		
		controller.enemy = current_enemy
		
		await GameAPI.send_prompt(controller.enemy.name + " apareció", true)
		
		next_step.emit(mode)
	
	GameAPI.save_game()
