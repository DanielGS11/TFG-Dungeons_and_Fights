class_name FightController
extends Resource

signal show_prompt(text: String, pause: bool)
signal end_prompt

signal finish_fight(exp: int)
signal run_away

signal animate(target: String, animation: String)

signal refresh_data(id: int)

signal end_game(result: String, text: String)

var team: Team
var enemy: Enemy

var queue: Dictionary

var animation_target: String

func connect_signals():
	if not GameAPI.actual_mode.prompt.is_connected(_show_prompt):
		GameAPI.actual_mode.prompt.connect(_show_prompt)
	
	if not GameAPI.actual_mode.finish_game.is_connected(_end_game):
		GameAPI.actual_mode.finish_game.connect(_end_game)
	
	for member in team.members:
		if not member.prompt.is_connected(_show_prompt):
			member.prompt.connect(_show_prompt)
	
	if enemy != null and enemy.prompt.is_connected(_show_prompt):
		enemy.prompt.connect(_show_prompt)

func execute_queue():
	var enemy_action = enemy.get_action(team)
	queue[enemy_action.keys()[0]] = enemy_action[enemy_action.keys()[0]]
	
	var order: Array[Entity] = queue.keys()
	
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
					await _show_prompt(key.name + " ataca a " + queue[key][1].name, false)
					await _attack(key, queue[key][1], null)
				
				Entity.Actions.DEFEND:
					await _defend(key)
				
				Entity.Actions.SKILL:
					await _skill(key,  queue[key][1],  queue[key][2])
			
			refresh_data.emit(team.members.find(key))
		
		if enemy.health == 0:
			break
	
	queue.clear()
	
	if enemy.health == 0:
		finish_fight.emit(enemy.exp_drop)
		
		for member in team.members:
			member.clear_modifiers()
	
	else:
		var allies_alive = 0
		
		await enemy.check_modifiers()
		
		for member in team.members:
			if member.health > 0:
				allies_alive += 1
				await member.check_modifiers()
		
		if allies_alive == 0:
			_end_game("lose", "Ya no queda nadie en pie, has perdido")
	

func _skill(user: Entity, target: Entity, skill: Skill):
	await _show_prompt(user.name + " usó " + skill.name, false)
	
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
		if randi_range(1, 100) > target.evasion:
			if target is Character:
				animation_target = "player_" + str(team.members.find(target))
			
			else:
				animation_target = "enemy"
			
			damage = ceili(((user.get_attack() * 2) / (1 + (target.get_defense() / \
			(user.get_attack() * 1.5)))) * randf_range(0.85, 1))
			
			if randi_range(1, 100) <= user.critical_rate:
				damage *= 2
				
				await _show_prompt("¡Golpe crítico!", false)
			
			await target.take_damage(damage)
			
			animate.emit(animation_target, "_damaged")
		
		else:
			await _show_prompt(target.name + " lo esquivó", false)
	
	else:
		var user_stat_value: int
		
		match skill.skill_type:
			skill.Type.FISICAL:
				user_stat_value = user.get_attack()
			
			skill.Type.MAGIC:
				user_stat_value = user.get_magic_attack()
		
		if target is Character and skill.skill_target == skill.Target.ALL_ENEMIES:
			animation_target = "all"
			
			var is_critical: bool = randi_range(1, 100) <= user.critical_rate
			
			if is_critical:
				await _show_prompt("¡Golpe crítico!", false)
			
			for member in team.members:
				if member.health > 0:
					if randi_range(1, 100) <= member.evasion:
						await _show_prompt(member.name + " lo esquivó", false)
					
					else:
						damage = ceili((((user_stat_value + skill.power) * 2) / (1 + (member.get_defense() \
						 / (user_stat_value * 1.5)))) * randf_range(0.85, 1))
						
						await member.take_damage(damage)
			
			animate.emit(animation_target, "_damaged")
		
		else:
			if randi_range(1, 100) > target.evasion:
				if target is Character:
					animation_target = "player_" + str(team.members.find(target))
				else:
					animation_target = "enemy"
				
				damage = ceili((((user_stat_value + skill.power) * 2) / (1 + (target.get_defense() \
				/ (user_stat_value * 1.5)))) * randf_range(0.85, 1))
				
				if randi_range(1, 100) <= user.critical_rate:
					damage *= 2
					
					await _show_prompt("¡Golpe crítico!", false)
				
				await target.take_damage(damage)
				
				animate.emit(animation_target, "_damaged")
			
			else:
				await _show_prompt(target.name + " lo esquivó", false)

func _defend(user: Entity):
	user.is_defending = true
	
	await _show_prompt(user.name + " se defiende", false)

func _heal(user: Entity, target: Entity, skill: Skill):
	var healing = ((user.get_magic_attack() + skill.power) * user.heal_multiplier) + (user.max_health * 0.05)
	
	if user is Character and skill.skill_target == skill.Target.ALL_ALLIES:
		animation_target = "all"
		
		for member in team.members:
			await member.heal(healing)
	
	else:
		if target is Character:
			animation_target = "player_" + str(team.members.find(target))
		
		else:
			animation_target = "enemy"
		
		match skill.skill_target:
			skill.Target.ALLY:
				await target.heal(healing)
			
			skill.Target.SELF:
				await user.heal(healing)
	
	animate.emit(animation_target, "_healed")

func _apply_modifier(target: Entity, skill: Skill):
	match skill.skill_type:
		skill.Type.BUFF:
			if target is Character and skill.skill_target == skill.Target.ALL_ALLIES:
				animation_target = "all"
				
				for member in team.members:
					await member.apply_buff(skill)
			
			else:
				if target is Character:
					animation_target = "player_" + str(team.members.find(target))
				else:
					animation_target = "enemy"
				
				await target.apply_buff(skill)
			
			animate.emit(animation_target, "_buffed")
		
		skill.Type.DEBUFF:
			if target is Character and skill.skill_target == skill.Target.ALL_ENEMIES:
				animation_target = "all"
				
				for member in team.members:
					await member.apply_debuff(skill)
			
			else:
				if target is Character:
					animation_target = "player_" + str(team.members.find(target))
				else:
					animation_target = "enemy"
				
				await target.apply_debuff(skill)
			
			animate.emit(animation_target, "_debuffed")

func _run_away():
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
		await _show_prompt("Escapaste a salvo", true)
		queue.clear()
		run_away.emit()
	
	else:
		queue.clear()
		await _show_prompt("No se pudo escapar", false)
		
		execute_queue()

func _show_prompt(text: String, pause: bool):
	show_prompt.emit(text, pause)
	await end_prompt

func _end_game(result: String, text: String):
	end_game.emit(result, text)
