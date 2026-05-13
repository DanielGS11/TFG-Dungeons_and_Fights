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
	
	for member in team_in_use.members:
		member.clear_modifiers()
	
	if current_enemy == null or current_enemy.health == 0:
		await load_new_enemy()
	
	else:
		current_enemy.clear_modifiers()
		next_step.emit()
		await GameAPI.send_prompt(controller.enemy.name + " apareció", true)

func _on_enemy_defeated(_exp_value: int):
	enemies_defeated += 1
	
	for member in team_in_use.members:
		if member.health <= 0:
			member.revive(0.20)
		
		member.level_up()
		member.clear_modifiers()
		
		controller.refresh_data.emit(member)
	
	await GameAPI.send_prompt("El equipo subió de nivel", true)
	
	current_enemy = null
	
	await load_new_enemy()

## Carga el siguiente enemigo o termina la partida si se terminó con todos
func load_new_enemy():
	if enemy_id >= enemies_to_defeat:
		enemies_defeated = enemy_id
		is_finished = true
		GameAPI.end_game.emit(GameAPI.Result.WIN, "¡Felicidades, has acabado con todos los enemigos!")
	else:
		enemies_defeated = enemy_id
		
		current_enemy = GameAPI.get_enemy(mode, null)
		current_enemy.grow_levels(enemy_id)
		
		enemy_id += 1
		controller.enemy = current_enemy
		
		next_step.emit()
		
		await GameAPI.send_prompt(controller.enemy.name + " apareció", true)
	
	GameAPI.save_game()
