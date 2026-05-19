## Controlador de pelea de los modos
class_name FightController
extends Resource

## Indica que se derrotó al enemigo y emite el valor de experiencia que suelta (Solo usado en el modo mazmorra)
signal enemy_defeated(exp: int)

## Indica que se huyó con éxito
signal run_away

## Emite el objetivo, tipo de animación y, si es de daño o cura, el valor de este para animar
signal animate(target: String, animation: String, value: int)

## Emite la entidad de la cual refrescar los datos en pantalla
signal refresh_data(entity: Entity)

## Equipo actual
@export var team: Team

## Enemigo a enfrentar
@export var enemy: Enemy

## Diccionario de acciones de todos
var queue: Dictionary

## Índice del objetivo de la animación
var animation_target: int

## Añade las acciones del equipo a la cola y ejecuta las acciones
func set_queue(team_actions: Dictionary):
	queue.merge(team_actions)
	await _execute_queue()

## Ejecuta las acciones de la cola
func _execute_queue():
	# Pide la acción del enemigo, la añade a la cola y en otra lista separa las claves, que será la propia entidad, para ordenarla y ver quién actua primero
	queue.merge(enemy.get_action(team))
	
	var order: Array = queue.keys()
	
	# El orden va asi: Primero el que se defienda, luego el más rápido
	order.sort_custom(func(a, b): 
		var a_defends = queue[a][0] == Entity.Actions.DEFEND
		var b_defends = queue[b][0] == Entity.Actions.DEFEND
		
		if a_defends and b_defends == false:
			return true
		elif b_defends and a_defends == false:
			return false
		else:
			return a.speed > b.speed)
	
	# Ejecuta en orden cada acción diempre y cuando el que la ejecuta siga vivo
	for key in order:
		if key.health > 0:
			# Dependiendo del tipo de acción ejecuta un método u otro
			match queue[key][0]:
				Entity.Actions.ATTACK:
					await _attack(key, queue[key][1], null)
				
				Entity.Actions.DEFEND:
					await _defend(key)
				
				Entity.Actions.SKILL:
					await _skill(key,  queue[key][1],  queue[key][2])
			
			# Por último, refresca en pantalla los datos del usuario
			refresh_data.emit(key)
		
		# Si el enemigo fué derrotado, se corta el recorrido
		if enemy.health == 0:
			break
	
	# Por último, se limpia la cola y se comprueba el estado del juego
	queue.clear()
	await _check_game_state()

## Comprueba el estado del juego
func _check_game_state():
	# Si el enemigo fué derrotado, revive a los miembros del equipo derrotados, les recupera un poco de maná y limpia sus modificadores, despues manda la señal de refresco de cada uno para ver gráficamente y avisa de que el enemigo fué derrotado
	if enemy.health == 0:
		for member in team.members:
			if member.health <= 0:
				member.revive(0.20)
			
			member.recover_mana()
			member.clear_modifiers()
			
			refresh_data.emit(member)
		
		enemy_defeated.emit(enemy.exp_drop)
		enemy = null
	
	# Si no, comprueba el estado del enemigo y comprueba si queda algun miembro vivo (Si no, fin de la partida) y les recupera maná y comprueba sus estados
	else:
		var allies_alive = 0
		
		await enemy.check_state()
		refresh_data.emit(enemy)
		
		for member in team.members:
			if member.health > 0:
				allies_alive += 1
				
				member.recover_mana()
				await member.check_state()
				
				refresh_data.emit(member)
		
		if allies_alive == 0:
			GameAPI.end_game.emit(GameAPI.Result.LOSE, "Ya no queda nadie en pie, has perdido")

## Uso de un hechizo
func _skill(user: Entity, target: Entity, skill: Skill):
	await GameAPI.send_prompt(user.name + " usó " + skill.name, false)
	
	# Primero consume el maná del usuario del hechizo (A un enemigo el método no le haría nada) y luego ejecuta el método correspondiente dependiendo del tipo de hechizo
	user.consume_mana(skill.cost)
	refresh_data.emit(user)
	
	match skill.skill_type:
		skill.Type.FISICAL, skill.Type.MAGIC:
			await _attack(user, target, skill)
		
		skill.Type.HEAL:
			await _heal(user, target, skill)
		
		skill.Type.BUFF, skill.Type.DEBUFF:
			await _apply_modifier(target, skill)

## Ejecuta un ataque/hechizo ofensivo
func _attack(user: Entity, target: Entity, skill: Skill):
	# Se crea una variable donde se almacena el daño y se comprueba si se usa un hechizo o no (lo cual sería un ataque básico)
	var damage: int
	
	if skill == null:
		if target.health > 0:
			# En caso de ser un ataque básico, se comprueba si el objetivo evadió el ataque, si no, se define el objetivo de animación y se calcula el daño del ataque
			await GameAPI.send_prompt(user.name + " ataca a " + target.name, false)
			if randi_range(1, 100) > target.evasion:
				if target is Character:
					animation_target = team.members.find(target)
				
				else:
					animation_target = -1
				
				damage = ceili(((user.get_attack() * 2) / (1 + (target.get_defense() / \
				(user.get_attack() * 1.5)))) * randf_range(0.85, 1))
				
				# Una vez calculado el daño, se comprueba si fué golpe crítico y se aplica el daño al objetivo, luego se refrescan gráficamente sus datos y se emite la animación
				if randi_range(1, 100) <= user.critical_rate:
					damage *= 2
					
					await GameAPI.send_prompt("¡Golpe crítico!", false)
				
				target.take_damage(damage)
				refresh_data.emit(target)
				
				MusicPlayer.play_sfx("Hit")
				animate.emit(animation_target, "_damaged", damage)
				
				await GameAPI.send_prompt(target.name + " recibió " + str(int(damage)) + " puntos de daño", false)
				
				# Por último, avisa si el objetivo fué derrotado
				if target.health <= 0:
					await GameAPI.send_prompt(target.name + " fue derrotado", true)
			
			else:
				await GameAPI.send_prompt(target.name + " lo esquivó", false)
		
		else:
			await GameAPI.send_prompt("No tuvo efecto en " + target.name, false)
	
	# En caso de usar un hechizo, se recoge en una variable el valor de ataque o ataqué mágico del usuario en función del tipo de hechizo
	else:
		var user_stat_value: int
		
		match skill.skill_type:
			skill.Type.FISICAL:
				user_stat_value = user.get_attack()
			
			skill.Type.MAGIC:
				user_stat_value = user.get_magic_attack()
		
		# Luego se comprueba si es el enemigo el lanzador y es un hechizo en área, para lo cual se aplica la misma lógica del ataque básico por cada miembro del equipo individual: Ver si esquivó, asignar objetivo de animación, calcular daño, ver si es crítico, aplicar daño, refrescar, animar y comprobar si fué derrotado
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
						refresh_data.emit(member)
						
						MusicPlayer.play_sfx("Hit")
						animate.emit(team.members.find(member), "_damaged", damage)
						await GameAPI.send_prompt(member.name + " recibió " + str(int(damage)) + " puntos de daño", false)
						
						if member.health <= 0:
							await GameAPI.send_prompt(target.name + " fue derrotado", true)
		
		# Si es un hechizo de un solo objetivo, la acción es la misma que la del ataqe básico
		else:
			if target.health > 0:
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
					
					MusicPlayer.play_sfx("Hit")
					animate.emit(animation_target, "_damaged", damage)
					await GameAPI.send_prompt(target.name + " recibió " + str(int(damage)) + " puntos de daño", false)
					
					if target.health <= 0:
						await GameAPI.send_prompt(target.name + " fue derrotado", true)
				
				else:
					await GameAPI.send_prompt(target.name + " lo esquivó", false)
			
			else:
				await GameAPI.send_prompt("No tuvo efecto en " + target.name, false)

## Ejecuta la acción 'En guardia' o 'Defender'
func _defend(user: Entity):
	# Establece el estado del usuario en 'Está defendiendo' y lo comunica
	user.is_defending = true
	
	await GameAPI.send_prompt(user.name + " se defiende", false)

## Ejecuta una curación
func _heal(user: Entity, target: Entity, skill: Skill):
	# Calcula el valor de curación del hechizo 
	var healing = ((user.get_magic_attack() + skill.power) * user.heal_multiplier) + (user.max_health * 0.05)
	
	# Si el hechizo es en área y lo ejecuta un jugador, comprueba que se pueda curar al jugador
	if user is Character and skill.skill_target == skill.Target.ALL_ALLIES:
		for member in team.members:
			if member.health <= 0:
				await GameAPI.send_prompt("No tuvo efecto en " + member.name, false)
			
			elif member.health == member.max_health:
				await GameAPI.send_prompt("La vida de " + member.name + " ya está al máximo", false)
			
			# Si se puede curar, le aplica la curación, refresca en pantalla y emite la animación por cada jugador
			else:
				member.heal(healing)
				refresh_data.emit(member)
				
				MusicPlayer.play_sfx("Heal")
				animate.emit(team.members.find(member), "_healed", healing)
				await GameAPI.send_prompt(member.name + " recibió " + str(int(healing)) + " puntos de curación", false)
	
	# Si no es en área, se comprueba el objetivo para la animación y si el hechizo es propio o para un aliado
	else:
		if target is Character:
			animation_target = team.members.find(target)
		
		else:
			animation_target = -1
		
		# Comprobado esto, se aplica la curación (Si el objetivo no tiene su vida al máximo), se refresca la pantalla y se ejecuta la animación
		match skill.skill_target:
			skill.Target.ALLY:
				if target.health <= 0:
					await GameAPI.send_prompt("No tuvo efecto en " + target.name, false)
				
				elif target.health == target.max_health:
					await GameAPI.send_prompt("La vida de " + target.name + " ya está al máximo", false)
				
				else:
					target.heal(healing)
					refresh_data.emit(target)
					
					MusicPlayer.play_sfx("Heal")
					animate.emit(animation_target, "_healed", healing)
					await GameAPI.send_prompt(target.name + " recibió " + str(int(healing)) + " puntos de curación", false)
			
			skill.Target.SELF:
				if user.health == user.max_health:
					await GameAPI.send_prompt("La vida de " + user.name + " ya está al máximo", false)
				
				else:
					await user.heal(healing)
					refresh_data.emit(user)
					
					MusicPlayer.play_sfx("Heal")
					animate.emit(animation_target, "_healed", healing)
					await GameAPI.send_prompt(user.name + " recibió " + str(healing) + " puntos de curación", false)

# Aplica un modificador
func _apply_modifier(target: Entity, skill: Skill):
	# Comprueba si es un potenciador (Buff) o reductor (Debuff) y hace las mismas acciones en los 2
	match skill.skill_type:
		# Si es un buff, comprueba si el lanzador es un jugador y el hechizo es en área y aplica al objetivo o, si son varios, a cada objetivo, el potenciador, refresca sus datos gráfocamente y ejecuta la animación por cada objetivo
		skill.Type.BUFF:
			if target is Character and skill.skill_target == skill.Target.ALL_ALLIES:
				for member in team.members:
					if member.health > 0:
						MusicPlayer.play_sfx("Buff")
						animate.emit(team.members.find(member), "_buffed", 0)
						await member.apply_buff(skill)
						refresh_data.emit(member)
			
			# Si es de un solo objetivo, se comprueba quién es el objetivo para la animación, se aplica el buff, se refrescan sus datos gráficos y se ejecuta la animación
			else:
				if target.health > 0:
					if target is Character:
						animation_target = team.members.find(target)
					else:
						animation_target = -1
					
						MusicPlayer.play_sfx("Buff")
						animate.emit(animation_target, "_buffed", 0)
						await target.apply_buff(skill)
						refresh_data.emit(target)
				
				else:
					await GameAPI.send_prompt("No tuvo efecto en " + target.name, false)
		
		# Con el debuff el proceso es el mismo, solo que si es en área, se comprueba si el lanzador es el enemigo, ya que el objetivo del hechizo serían los miembros del equipo
		skill.Type.DEBUFF:
			if target is Character and skill.skill_target == skill.Target.ALL_ENEMIES:
				
				for member in team.members:
					if member.health > 0:
						MusicPlayer.play_sfx("Debuff")
						animate.emit(team.members.find(member), "_debuffed", 0)
						await member.apply_debuff(skill)
						refresh_data.emit(member)
			
			# Y si no, se comprueba a qué enemigo o miembro se lanza el reductor
			else:
				if target.health > 0:
					if target is Character:
						animation_target = team.members.find(target)
					else:
						animation_target = -1
					
					MusicPlayer.play_sfx("Debuff")
					animate.emit(animation_target, "_debuffed", 0)
					await target.apply_debuff(skill)
					refresh_data.emit(target)
				
				else:
					await GameAPI.send_prompt("No tuvo efecto en " + target.name, false)

## Ejecuta la acción 'Huir'
func run():
	# Crea 2 variables, en una recoge el valor de huída del equipo y en otra calcula el nivel del equipo
	var run_away_value: int
	
	var team_avg_level = 0
	
	for member in team.members:
		team_avg_level += member.level
	
	team_avg_level = ceili(float(team_avg_level) / team.members.size())
	
	# La variable de huída varía en función del tipo de enmigo y si es de mayor o menor nivel al del equipo (Haciendo que si tiene más nivel sea más dificil huir)
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
	
	# Por último, se comprueba, con una tirada de dados, si se logró escapar o no
	if randi_range(1, run_away_value) == 1:
		# Si se escapó, limpia los modificadores de todos, cura al enemigo ya que no se le derrotó, recupera maná del equipo y limpia la cola
		await GameAPI.send_prompt("Escapaste a salvo", true)
		
		enemy.health = enemy.max_health
		enemy.clear_modifiers()
		
		for member in team.members:
			if member.health <= 0:
				member.revive(0.20)
			
			member.recover_mana()
			member.clear_modifiers()
			
			refresh_data.emit(member)
		
		queue.clear()
		run_away.emit()
	
	# Si no se escapó, limpia la cola y ejecuta el método que la ejecuta, haciendo que sólo ataque el enemigo
	else:
		queue.clear()
		await GameAPI.send_prompt("No se pudo escapar", false)
		
		_execute_queue()
