class_name Enemy
extends Entity

@export_enum("Jefe", "Minijefe", "Normal") var enemy_type: String

const enemy_augments := {
	"Jefe" : 80,
	"Minijefe" : 50,
	"Normal" : 20
}

var atk_augments: int

func growLevels(levels):
	level += levels
	
	max_health += enemy_augments[enemy_type] * levels
	health += enemy_augments[enemy_type] * levels
	
	# Compara la variable de aumentos con nivel menos 2. El ataque del enemigo aumenta en 1 cada 2 niveles, 
	# estos aumentos se reflejan en esa variable. Por ejemplo, al nivel 10 el ataque aumentaria 5 (10 / 2),
	# al subir al 12, lo que hace es que compara el aumento de ataque que ya hubo (5) con el que habria ahora (6),
	# y suma la diferencia (5 - 6)
	if atk_augments < floori(level / 2):
		attack += floori(level / 2) - atk_augments
		atk_augments = floori(level / 2)

# IA del enemigo
func getAction(team: Team) -> Dictionary:
	# Aqui almaceno los datos de la acción
	var action_data: Dictionary
	
	# Se guarda en un array de Characters (La clase de los personajes) aquellos que esten vivos
	var targets_available: Array[Character]
	for i in team.members:
		if i.health > 0:
			targets_available.append(i)
	
	# En ogra variable se guarda el objetivo a atacar, primero recorre la lista de los objetivos 
	# posibles y mira si es una clase tanque (Paladin o Bastión), para quienes tiene un 50% de 
	# probabilidad de atacar, si la tirara de dados dio 0 o no hay tanques, simplemente ataca a 1
	# objetivo aleatorio
	var target: Character
	
	if targets_available.any(func(a: Character): a.class_type == "Paladin" or a.class_type == "Bastión"):
		for member in targets_available:
			if member.class_type == "Paladin" or member.class_type == "Bastión":
				if randi_range(1,2) == 2:
					target = member
	
	if target == null:
		target = targets_available.pick_random()
	
	# Ahora el ataque en si, primero, si el enemigo no tiene ninguna skill, simplemente hace un 
	# ataque básico, si no, hace una tirada de dados, teniendo un 50% de probabilidad de usar una
	# skill
	if skills.is_empty():
		action_data = {actions.ATTACK : [self, target, false, 0]}
	
	else:
		if randi_range(1, 2) == 2:
			# Para usar una skill, el enemigo primero comprueba si tiene alguna disponible, 
			# filtrando en una lista aquellas que pueda usar (si tiene curas pero esta al máximo de 
			# vida, no usará esas skills)
			var available_skills: Array[Skill]
			
			for i in skills:
				if i.skill_type == i.type.HEAL and health < max_health:
					available_skills.append(i)
					
				else:
					available_skills.append(i)
			
			# Si no tiene ninguna skill disponible, ataque básico
			if available_skills.is_empty():
				action_data = {actions.ATTACK : [self, target, false, 0]}
			
			else:
				# Si tiene curas y su vida es igual o menor al 30%, hay un 75% de probabilidad de 
				# que use una cura
				if health <= max_health * 0.3 and available_skills.any(func(a: Skill): a.skill_type == a.type.HEAL):
					for skill in available_skills:
						if skill.skill_type == skill.type.HEAL:
							if randi_range(1, 4) >= 2:
								action_data = {actions.SKILL : [self, self, skill]}
								break
				
				# Esto es una comprobación para saber si seguir buscando una skill o ya eligió
				if action_data.is_empty():
					# Si tiene una skill de ataque, hay preferencia, por lo que tendrá un 50% de 
					# probabilidad de usarla
					for skill in available_skills:
						if skill.skill_type == skill.type.MAGIC or skill.skill_type == skill.type.FISICAL:
							if randi_range(1, 2) == 2:
								action_data = {actions.SKILL : [self, target, skill]}
								break
					
					# Misma comprobación para saber si seguir buscando
					if action_data.is_empty():
						# Si todo lo anterior no dió una acción, usará una skill aleatoria
						var skill : Skill = available_skills.pick_random()
						
						# Aqui comprueba que tipo de skill es para no tirarse un ataque a si mismo
						# ni una cura al enemigo, por ejemplo
						if skill.skill_type == skill.type.HEAL or skill.skill_type == skill.type.BUFF:
							action_data = {actions.SKILL : [self, self, skill]}
						
						else:
							action_data = {actions.SKILL : [self, target, skill]}
		else:
			action_data = {actions.ATTACK : [self, target, false, 0]}
	
	# Y por último, devolvemos a acción que hará
	return action_data
