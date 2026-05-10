## Controlador de pelea de los modos
class_name FightController
extends Resource

signal enemy_defeated(exp: int)
signal run_away

signal animate(target: String, animation: String, value: int)

signal refresh_data(entity: Entity)

@export var team: Team
@export var enemy: Enemy

var queue: Dictionary

var animation_target: int

## Añade las acciones del equipo a la cola y ejecuta las acciones
func set_queue(team_actions: Dictionary):
	queue.merge(team_actions)
	_execute_queue()

## Ejecuta las acciones de la cola
func _execute_queue():
	queue.merge(enemy.get_action(team))
	
	var order: Array = queue.keys()
	
	order.sort_custom(func(a, b): 
		var a_defends = queue[a][0] == Entity.Actions.DEFEND
		var b_defends = queue[b][0] == Entity.Actions.DEFEND
		
		if a_defends and b_defends == false:
			return true
		elif b_defends and a_defends == false:
			return false
		else:
			return a.speed > b.speed)
	
	for key in order:
		if key.health > 0:
			match queue[key][0]:
				Entity.Actions.ATTACK:
					await _attack(key, queue[key][1], null)
				
				Entity.Actions.DEFEND:
					await _defend(key)
				
				Entity.Actions.SKILL:
					await _skill(key,  queue[key][1],  queue[key][2])
		
		if enemy.health == 0:
			break
	
	queue.clear()
	_check_game_state()

func _check_game_state():
	if enemy.health == 0:
		enemy_defeated.emit(enemy.exp_drop)
		enemy = null
	
	else:
		var allies_alive = 0
		
		await enemy.check_modifiers()
		
		for member in team.members:
			if member.health > 0:
				allies_alive += 1
				await member.check_modifiers()
		
		if allies_alive == 0:
			GameAPI.end_game.emit(GameAPI.Result.LOSE, "Ya no queda nadie en pie, has perdido")

func _skill(user: Entity, target: Entity, skill: Skill):
	await GameAPI.send_prompt(user.name + " usó " + skill.name, false)
	
	user.consume_mana(skill.cost)
	
	match skill.skill_type:
		skill.Type.FISICAL, skill.Type.MAGIC:
			await _attack(user, target, skill)
		
		skill.Type.HEAL:
			await _heal(user, target, skill)
		
		skill.Type.BUFF, skill.Type.DEBUFF:
			await _apply_modifier(target, skill)

func _attack(user: Entity, target: Entity, skill: Skill):
	var damage: int
	
	if skill == null:
		await GameAPI.send_prompt(user.name + " ataca a " + target.name, false)
		if randi_range(1, 100) > target.evasion:
			if target is Character:
				animation_target = team.members.find(target)
			
			else:
				animation_target = -1
			
			damage = ceili(((user.get_attack() * 2) / (1 + (target.get_defense() / \
			(user.get_attack() * 1.5)))) * randf_range(0.85, 1))
			
			if randi_range(1, 100) <= user.critical_rate:
				damage *= 2
				
				await GameAPI.send_prompt("¡Golpe crítico!", false)
			
			
			target.take_damage(damage)
			refresh_data.emit(target)
			animate.emit(animation_target, "_damaged", damage)
			
			await GameAPI.send_prompt(target.name + " recibió " + str(damage) + " puntos de daño", false)
			
			if target.health <= 0:
				await GameAPI.send_prompt(target.name + " fue derrotado", true)
		
		else:
			await GameAPI.send_prompt(target.name + " lo esquivó", false)
	
	else:
		var user_stat_value: int
		
		match skill.skill_type:
			skill.Type.FISICAL:
				user_stat_value = user.get_attack()
			
			skill.Type.MAGIC:
				user_stat_value = user.get_magic_attack()
		
		if target is Character and skill.skill_target == skill.Target.ALL_ENEMIES:
			for member in team.members:
				if member.health > 0:
					if randi_range(1, 100) <= member.evasion:
						await GameAPI.send_prompt(member.name + " lo esquivó", false)
					
					else:
						damage = ceili((((user_stat_value + skill.power) * 2) / (1 + (member.get_defense() \
						 / (user_stat_value * 1.5)))) * randf_range(0.85, 1))
						
						if randi_range(1, 100) <= user.critical_rate:
							await GameAPI.send_prompt(member.name + " recibió un golpe crítico", false)
							
							damage *= 2
						
						
						member.take_damage(damage)
						animate.emit(team.members.find(member), "_damaged", damage)
						refresh_data.emit(member)
						await GameAPI.send_prompt(member.name + " recibió " + str(damage) + " puntos de daño", false)
						
						if member.health <= 0:
							await GameAPI.send_prompt(target.name + " fue derrotado", true)
			
		
		else:
			if randi_range(1, 100) > target.evasion:
				if target is Character:
					animation_target = team.members.find(target)
				else:
					animation_target = -1
				
				damage = ceili((((user_stat_value + skill.power) * 2) / (1 + (target.get_defense() \
				/ (user_stat_value * 1.5)))) * randf_range(0.85, 1))
				
				if randi_range(1, 100) <= user.critical_rate:
					damage *= 2
					
					await GameAPI.send_prompt("¡Golpe crítico!", false)
				
				target.take_damage(damage)
				refresh_data.emit(target)
				animate.emit(animation_target, "_damaged", damage)
				await GameAPI.send_prompt(target.name + " recibió " + str(damage) + " puntos de daño", false)
				
				if target.health <= 0:
					await GameAPI.send_prompt(target.name + " fue derrotado", true)
			
			else:
				await GameAPI.send_prompt(target.name + " lo esquivó", false)

func _defend(user: Entity):
	user.is_defending = true
	
	await GameAPI.send_prompt(user.name + " se defiende", false)

func _heal(user: Entity, target: Entity, skill: Skill):
	var healing = ((user.get_magic_attack() + skill.power) * user.heal_multiplier) + (user.max_health * 0.05)
	
	if user is Character and skill.skill_target == skill.Target.ALL_ALLIES:
		for member in team.members:
			if member.health == member.max_health:
				await GameAPI.send_prompt("La vida de " + member.name + " ya está al máximo", false)
			
			else:
				await member.heal(healing)
				refresh_data.emit(member)
				animate.emit(team.members.find(member), "_healed", healing)
				await GameAPI.send_prompt(member.name + " recibió " + str(healing) + " puntos de curación", false)
	
	else:
		if target is Character:
			animation_target = team.members.find(target)
		
		else:
			animation_target = -1
		
		match skill.skill_target:
			skill.Target.ALLY:
				if target.health == target.max_health:
					await GameAPI.send_prompt("La vida de " + target.name + " ya está al máximo", false)
				
				else:
					await target.heal(healing)
					refresh_data.emit(target)
					await GameAPI.send_prompt(target.name + " recibió " + str(healing) + " puntos de curación", false)
			
			skill.Target.SELF:
				if user.health == user.max_health:
					await GameAPI.send_prompt("La vida de " + user.name + " ya está al máximo", false)
				
				else:
					await user.heal(healing)
					refresh_data.emit(user)
					await GameAPI.send_prompt(user.name + " recibió " + str(healing) + " puntos de curación", false)
	
		animate.emit(animation_target, "_healed", healing)

func _apply_modifier(target: Entity, skill: Skill):
	match skill.skill_type:
		skill.Type.BUFF:
			if target is Character and skill.skill_target == skill.Target.ALL_ALLIES:
				for member in team.members:
					await member.apply_buff(skill)
					refresh_data.emit(member)
					animate.emit(team.members.find(member), "_buffed", 0)
			
			else:
				if target is Character:
					animation_target = team.members.find(target)
				else:
					animation_target = -1
				
				await target.apply_buff(skill)
				refresh_data.emit(target)
				
				animate.emit(animation_target, "_buffed", 0)
		
		skill.Type.DEBUFF:
			if target is Character and skill.skill_target == skill.Target.ALL_ENEMIES:
				
				for member in team.members:
					await member.apply_debuff(skill)
					refresh_data.emit(member)
					animate.emit(team.members.find(member), "_debuffed", 0)
			
			else:
				if target is Character:
					animation_target = team.members.find(target)
				else:
					animation_target = -1
				
				await target.apply_debuff(skill)
				refresh_data.emit(target)
				
				animate.emit(animation_target, "_debuffed", 0)

func run():
	var run_away_value: int
	
	var team_avg_level = 0
	
	for member in team.members:
		team_avg_level += member.level
	
	team_avg_level = ceili(float(team_avg_level) / team.members.size())
	
	match enemy.enemy_type:
		"Jefe":
			run_away_value = 10
		
		"Minijefe":
			run_away_value = 5
		
		"Normal":
			run_away_value = 3
	
	if enemy.level > team_avg_level:
		run_away_value += 1
	
	elif enemy.level < team_avg_level:
		run_away_value -= 1
	
	if randi_range(1, run_away_value) == 1:
		await GameAPI.send_prompt("Escapaste a salvo", true)
		queue.clear()
		run_away.emit()
	
	else:
		queue.clear()
		await GameAPI.send_prompt("No se pudo escapar", false)
		
	_execute_queue()
