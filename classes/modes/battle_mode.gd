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
	team_in_use = data[0]
	is_finished = false
	enemies_to_defeat = data[1]
	enemy_id = 0
	
	enemies_defeated = 0
	
	controller = load_controller()
	load_new_enemy()

func _on_enemy_defeated(_exp_value: int):
	await GameAPI.send_prompt("EL equipo subió de nivel", true)
	
	for member in team_in_use.members:
		member.level_up()
	
	load_new_enemy()

## Carga el siguiente enemigo o termina la partida si se terminó con todos
func load_new_enemy():
	if enemy_id >= enemies_to_defeat:
		is_finished = true
		GameAPI.end_game.emit("Win", "¡Felicidades, has acabado con todos los enemigos!")
	else:
		enemy_id += 1
		enemies_defeated = enemy_id - 1
		
		current_enemy = GameAPI.get_battle_mode_enemy()
		current_enemy.growLevels(enemy_id - 1)
		
		controller.enemy = current_enemy
		
		next_step.emit(mode)
		
		await GameAPI.send_prompt(controller.enemy.name + " apareció", true)
