class_name Character
extends Entity

# En un diccionario se guardan las clases de los personajes y un array con sus aumentos: Vida, Maná, Experiencia máxima, 
# Ataque, Ataque Mágico y Defensa respectivamente
const class_augments = {
	"Asesino" : [20, 20, 30, 3, 2, 2],
	"Berserker" : [20, 20, 30, 3, 3, 2],
	"Mago" : [10, 40, 35, 1, 1, 3],
	"Sabio" : [10, 40, 35, 1, 1, 3],
	"Clérigo" : [12, 40, 35, 1, 1, 3],
	"Druida" : [10, 40, 35, 1, 1, 3],
	"Bastión" : [50, 10, 45, 2, 4, 1],
	"Paladin" : [50, 12, 45, 2, 4, 2]
}

@export_enum("Asesino", "Berserker", "Mago", "Sabio", "Clérigo", "Druida", "Bastión", "Paladin") var class_type: String

@export var max_mana: int
@export var mana: int

@export var exp_next_level: int
@export var exp: int

func get_exp(exp_value: int):
	exp += exp_value
	
	while exp > exp_next_level:
		exp -= exp_next_level
		levelUp()

func levelUp():
	level += 1
	
	max_health += class_augments[class_type][0]
	if health > 0:
		health += class_augments[class_type][0]
	
	max_mana += class_augments[class_type][1]
	mana += class_augments[class_type][1]
	
	exp_next_level += class_augments[class_type][2]
	
	attack += class_augments[class_type][3]
	magic_attack += class_augments[class_type][4]
	defense += class_augments[class_type][5]
	
	prompt.emit(name + " subió de nivel", true)
