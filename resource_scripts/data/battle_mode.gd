class_name BattleMode
extends Mode

@export var enemy_id: int = 0
@export var enemies_quantity: int

func _init():
	mode = Type.BATTLE
	can_escape = false

func new_game(data: Array):
	team_in_use = data[0]
	is_finished = false
	enemies_quantity = data[1]
	enemy_id = 0
	
	enemies_defeated = 0
	
	loadNewEnemy()
	controller = loadController()

func _on_fight_finished(_exp_value: int):
	await _send_prompt("EL equipo subió de nivel", true)
	
	for member in team_in_use.members:
		member.level_up()
	
	loadNewEnemy()

func loadNewEnemy():
	if enemy_id >= enemies_quantity:
		is_finished = true
		finish_game.emit("Win", "¡Felicidades, has acabado con todos los enemigos!")
	else:
		enemy_id += 1
		enemies_defeated = enemy_id - 1
		
		controller.enemy = GameAPI.get_battle_mode_enemy()
		controller.enemy.growLevels(enemy_id - 1)
		
		next_step.emit(mode)
		
		await _send_prompt(controller.enemy.name + " apareció", true)
