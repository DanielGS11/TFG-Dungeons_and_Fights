class_name Enemy
extends Entity

## Tipo de enemigo
@export_enum("Jefe", "Minijefe", "Normal") var enemy_type: String

## Contiene las stats iniciales (Lv 1)
var initial_stats = []

## Aumento de vida según la clase de enemigo
const enemy_augments := {
	"Jefe" : 80,
	"Minijefe" : 50,
	"Normal" : 15
}

## Experiencia que da al derrotar al enemigo
@export var exp_drop: int = 0

## Se ejecuta al cargar la clase
func _init():
	heal_multiplier = 5.0

func reset():
	if initial_stats.is_empty():
		initial_stats.append_array([max_health, attack, magic_attack, exp_drop])
	
	level = 1
	
	level = 1
	max_health = initial_stats[0]
	health = max_health
	attack = initial_stats[1]
	magic_attack = initial_stats[2]
	exp_drop = initial_stats[3]

## Subir x niveles
func grow_levels(levels):
	reset()
	
	level += levels
	
	max_health = initial_stats[0] + (enemy_augments[enemy_type] * levels)
	health = max_health
	
	attack += levels
	magic_attack += levels
	
	exp_drop += ceili(exp_drop * 0.4) * levels

## Recibir la acción a realizar del enemigo
func get_action(team: Team) -> Dictionary:
	# Almacena los datos de la acción
	var action_data: Dictionary
	
	# Se guarda en un array de Characters aquellos que esten vivos del equipo
	var targets_available: Array[Character]
	for i in team.members:
		if i.health > 0:
			targets_available.append(i)
	
	# Se guarda el objetivo a atacar, el cual es más probable que sea, si lo hay, la clase defensiva del equipo
	var target: Character
	
	if targets_available.any(func(a: Character): return a.class_type == "Paladin" or a.class_type == "Bastión"):
		for member in targets_available:
			if member.class_type == "Paladin" or member.class_type == "Bastión":
				if randi_range(1,2) == 2:
					target = member
					break
	
	if target == null:
		target = targets_available.pick_random()
	
	# Si no cuenta con hechizos, hace un ataque básico, de lo contrario, tirará un dado para ver si usa una magia o ataca
	if skills.is_empty():
		action_data = {self : [Actions.ATTACK , target]}
	
	else:
		var use_skill_probability = 2
		
		# Si tiene más ataque mágico que ataque, es más probable que use magias
		if attack < magic_attack:
			use_skill_probability += 2
		
		if randi_range(1, use_skill_probability) >= 2:
			# Separa en 2 listas los hechizos de ataque con los de curación y modificadores
			var attack_skills: Array[Skill]
			var utils_skills: Array[Skill]
			
			for i in skills:
				if i.skill_type == i.Type.HEAL and health < max_health or i.skill_type != i.Type.MAGIC and i.skill_type != i.Type.FISICAL:
					utils_skills.append(i)
					
				else:
					attack_skills.append(i)
			
			# Si no tiene ninguna skill disponible, ataque básico
			if attack_skills.is_empty() and utils_skills.is_empty():
				action_data = {self : [Actions.ATTACK, target]}
			
			else:
				var skill: Skill
				# Si tiene curas y su vida es igual o menor al 30%, hay un 75% de probabilidad de que use una cura
				if health <= max_health * 0.3 and utils_skills.any(func(a: Skill):
					return a.skill_type == a.Type.HEAL):
						if randi_range(1, 4) >= 2:
							skill = utils_skills.filter(func(a: Skill): \
							return a.skill_type == a.Type.HEAL).pick_random()
							
							action_data = {self : [Actions.SKILL, self, skill]}
				
				# Si no eligió ningún hechizo, busca una de nuevo
				if action_data.is_empty():
					if not attack_skills.is_empty() and not utils_skills.is_empty():
						if randi_range(1, 6) >= 3:
							skill = attack_skills.pick_random()
						else:
							skill = utils_skills.pick_random()
					
					else:
						skill = (attack_skills + utils_skills).pick_random()
					
					# Una vez elegido, establece el objetivo del hechizo en función de su tipo y el objetivo recogido
					if skill.skill_type == skill.Type.HEAL or skill.skill_type == skill.Type.BUFF:
						action_data = {self: [Actions.SKILL, self, skill]}
					
					else:
						action_data = {self : [Actions.SKILL, target, skill]}
		
		else:
			action_data = {self : [Actions.ATTACK, target]}
	
	# Por último, devolvemos la acción que hará
	return action_data
