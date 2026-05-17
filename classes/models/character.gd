class_name Character
extends Entity

## En un diccionario se guardan las clases de los personajes y un array con sus aumentos: Vida,  Experiencia máxima, 
## Ataque, Ataque Mágico, Defensa y recuperación de maná respectivamente
const class_augments = {
	"Asesino" : [2, 30, 3, 1, 2, 5],
	"Berserker" : [2, 30, 4, 2, 2, 5],
	"Mago" : [2, 35, 1, 4, 1, 15],
	"Sabio" : [2, 35, 1, 3, 2, 15],
	"Clérigo" : [3, 35, 1, 2, 2, 15],
	"Druida" : [3, 35, 1, 2, 3, 15],
	"Bastión" : [5, 45, 2, 1, 4, 5],
	"Paladin" : [5, 45, 2, 2, 4, 10]
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
			MusicPlayer.play_sfx("Level Up")
			
			await GameAPI.send_prompt(name + " subió " + str(level_grow) + " niveles", true)
			
		elif level_grow == 1:
			MusicPlayer.play_sfx("Level Up")
			
			await GameAPI.send_prompt(name + " subió " + str(level_grow) + " nivel", true)

## Subir de nivel
func level_up():
	if level < 50:
		level += 1
		
		max_health += class_augments[class_type][0]
		health += class_augments[class_type][0]
		
		exp_next_level += class_augments[class_type][1]
		
		attack += class_augments[class_type][2]
		magic_attack += class_augments[class_type][3]
		defense += class_augments[class_type][4]

func consume_mana(value: int):
	mana -= value

func recover_mana():
	if class_augments[class_type][5] > max_mana - mana:
		mana = max_mana
	
	else:
		mana += class_augments[class_type][5]

func revive(percentage: float):
	if health <= 0:
		health = ceili(float(max_health) * percentage)
