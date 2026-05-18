class_name Character
extends Entity

## Contiene la lista de aumentos según la clase en este orden: Vida,  Experiencia máxima, Ataque, Ataque Mágico, Defensa y Recuperación de maná respectivamente
const class_augments = {
	"Asesino" : [2, 30, 3, 1, 2, 7],
	"Berserker" : [2, 30, 4, 2, 2, 7],
	"Mago" : [2, 35, 1, 4, 1, 22],
	"Sabio" : [2, 35, 1, 3, 2, 22],
	"Clérigo" : [3, 35, 1, 2, 2, 20],
	"Druida" : [3, 35, 1, 2, 3, 20],
	"Bastión" : [5, 45, 2, 1, 4, 5],
	"Paladin" : [5, 45, 2, 2, 4, 13]
}

## Clase del personaje
@export_enum("Asesino", "Berserker", "Mago", "Sabio", "Clérigo", "Druida", "Bastión", "Paladin") var class_type: String

## Maná máximo
@export var max_mana: int = 0

## Maná actual
@export var mana: int = 0

## Experiencia necesaria para subir de nivel
@export var exp_next_level: int

## Cantidad de experiencia actual
@export var actual_exp: int

## Se ejecuta al cargar la clase
func _init():
	heal_multiplier = 0.7

## Obtener experiencia al derrotar a un enemigo
func get_exp(exp_value: int):
	if level >= 50:
		await GameAPI.send_prompt(name + " no puede subir más de nivel", true)
	
	else:
		actual_exp += exp_value
		
		# Guarda en una variable los niveles que sube y procede a aplicar la experiencia y subir de nivel en función de cuántas veces la experiencia actual sobrepase la necesaria para subir de nivel
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

## Recupera maná según la clase
func recover_mana():
	if class_augments[class_type][5] > max_mana - mana:
		mana = max_mana
	
	else:
		mana += class_augments[class_type][5]

## Revive con un porcentaje de la vida máxima
func revive(percentage: float):
	if health <= 0:
		health = ceili(float(max_health) * percentage)
