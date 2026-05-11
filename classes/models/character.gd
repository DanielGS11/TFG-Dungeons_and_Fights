class_name Character
extends Entity

# En un diccionario se guardan las clases de los personajes y un array con sus aumentos: Vida, Maná, Experiencia máxima, 
# Ataque, Ataque Mágico y Defensa respectivamente
const class_augments = {
	"Asesino" : [20, 20, 30, 3, 2, 2],
	"Berserker" : [20, 20, 30, 3, 3, 2],
	"Mago" : [10, 50, 35, 1, 1, 3],
	"Sabio" : [10, 50, 35, 1, 1, 3],
	"Clérigo" : [12, 40, 35, 1, 1, 3],
	"Druida" : [10, 40, 35, 1, 1, 3],
	"Bastión" : [50, 10, 45, 2, 4, 1],
	"Paladin" : [50, 12, 45, 2, 4, 2]
}

@export_enum("Asesino", "Berserker", "Mago", "Sabio", "Clérigo", "Druida", "Bastión", "Paladin") var class_type: String

@export var max_mana: int = 0
@export var mana: int = 0

@export var exp_next_level: int
@export var actual_exp: int

func _init():
	heal_multiplier = 0.7

## Obtener experiencia al derrotar a un enemigo
func get_exp(exp_value: int):
	if level >= 50:
		await GameAPI.send_prompt(name + " no puede subir más de nivel", true)
	
	else:
		actual_exp += exp_value
		
		var level_grow = 0
		
		while actual_exp > exp_next_level:
			actual_exp -= exp_next_level
			level_up()
			level_grow += 1
		
		if level_grow > 1:
			await GameAPI.send_prompt(name + " subió " + str(level_grow) + " niveles", true)
			
		elif level_grow == 1:
			await GameAPI.send_prompt(name + " subió " + str(level_grow) + " nivel", true)

## Subir de nivel
func level_up():
	if level < 50:
		level += 1
		
		max_health += class_augments[class_type][0]
		health += class_augments[class_type][0]
		
		max_mana += class_augments[class_type][1]
		mana += max_mana
		
		exp_next_level += class_augments[class_type][2]
		
		attack += class_augments[class_type][3]
		magic_attack += class_augments[class_type][4]
		defense += class_augments[class_type][5]

func consume_mana(value: int):
	mana -= value

func recover_mana(value: int):
	if value > max_mana - mana:
		mana = max_mana
	
	else:
		mana += value

func revive(percentage: float):
	if health <= 0:
		health = ceili(float(max_health) * percentage)
