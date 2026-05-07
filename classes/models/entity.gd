## Entidad, que puede ser un personaje (Character) o enemigo (Enemy)
class_name Entity
extends Resource

## Acción del personaje
enum Actions {ATTACK, DEFEND, SKILL}

@export var sprite: Texture2D

@export var level: int = 0
@export var name: String = ""

@export var max_health: int = 0
@export var health: int = 0

@export var attack: int = 0
@export var magic_attack: int = 0
@export var defense: int = 0
@export var speed: int = 0

@export var critical_rate: int = 0
@export var evasion: int = 0

@export var skills: Array[Skill]

@export var description: String = ""

# Ya que la fórmula de curación es la misma para todos y los enemigos tienen mucha más vida,
# es necesaria esta variable para que se curen más con el ataque mágico que tienen, ya que si le
# ponemos una cantidad que haga que haya una buena curación, tambien tendría hechizos mas fuertes
var heal_multiplier: float

var modifiers := {
	GameAPI.Modifier.ATTACK : ModifierState.new("Ataque"),
	GameAPI.Modifier.M_ATTACK : ModifierState.new("Ataque mágico"),
	GameAPI.Modifier.DEFENSE : ModifierState.new("Defensa")
}

# Esta variable es para la acción 'defender' (por el momento solo usada en el jugador).
# Como solo dura 1 turno y checkModifiers se usa al final de cada turno, la desactivará
# automaticamente
var is_defending := false

## Aplica un potenciador
func apply_buff(skill: Skill):
	var buff: ModifierState = modifiers[skill.modifier]
	
	var word: String
	
	if buff.stat == "Defensa":
		word = "La "
	
	else:
		word = "El "
	
	match buff.modifier_type:
		buff.Type.BUFF:
			buff.turn = 0
			
			await GameAPI.send_prompt("¡" + word + buff.stat + " de " + name + " se volvió a potenciar!", false)
		
		buff.Type.DEBUFF:
			buff.reset()
			
			await GameAPI.send_prompt(word + buff.stat + " de " + name + " volvió a la normalidad", false)
		
		buff.Type.NONE:
			buff.modifier_type = buff.Type.BUFF
			
			await GameAPI.send_prompt("¡" + word + buff.stat + " de " + name + " se potenció!", false)

## Aplica un reductor
func apply_debuff(skill: Skill):
	var debuff: ModifierState = modifiers[skill.modifier]
	
	var word: String
	
	if debuff.stat == "Defensa":
		word = "La "
	
	else:
		word = "El "
	
	match debuff.modifier_type: 
		debuff.Type.DEBUFF:
			debuff.turn = 0
			
			await GameAPI.send_prompt("¡" + word + debuff.stat + " de " + name + " se volvió a reducir!", false)
		
		debuff.Type.BUFF:
			debuff.reset()
			
			await GameAPI.send_prompt(word + debuff.stat + " de " + name + " volvió a la normalidad", false)
			
		debuff.Type.NONE:
			debuff.modifier_type = debuff.Type.DEBUFF
			
			await GameAPI.send_prompt("¡" + word + debuff.stat + " de " + name + " se redujo!", false)

## Recibir daño de un ataque
func take_damage(damage: int):
	await GameAPI.send_prompt(name + " recibió " + str(damage) + " puntos de daño", false)
	
	if damage > health:
		health = 0
		clear_modifiers()
		await GameAPI.send_prompt(name + " fué derrotado", true)
	
	else:
		health -= damage

## Recibir una curación
func heal(healing: int):
	if health == max_health:
		await GameAPI.send_prompt("La vida de " + name + " ya estaba al máximo", false)
	
	else:
		if max_health - health < healing:
			health = max_health
		
		else:
			health += healing
		
		await GameAPI.send_prompt(name + " recibió " + str(healing) + " puntos de curación", false)

## Consumir maná al usar un hechizo
func consume_mana(_value: int):
	pass

## Al terminar un turno, mira el estado de la entidad
func check_modifiers():
	if is_defending:
		is_defending = false
	
	if modifiers.values().any(func(a): return a.modifier_type != a.Type.NONE):
		
		for i in modifiers:
			var modifier_value : ModifierState = modifiers[i]
			
			if modifier_value.modifier_type != modifier_value.Type.NONE:
				modifier_value.turn += 1
				
				if modifier_value.turn >= 4:
					modifier_value.reset()
					
					if modifier_value.stat == "Defensa":
						await GameAPI.send_prompt("La " + modifier_value.stat + " de " + name + " volvió a la normalidad", false)
						
					else:
						await GameAPI.send_prompt("El " + modifier_value.stat + " de " + name + " volvió a la normalidad", false)

## Limpia el estado de la entidad
func clear_modifiers():
	for i in modifiers:
		modifiers[i].reset()

# Getters de las stats, que devuelven el valor total de la stat con sus
# modificadores aplicados si los hay
## Devuelve el valor total de ataque
func get_attack() -> int:
	var atk_value = attack
	
	var atk_modifier : ModifierState = modifiers[GameAPI.Modifier.ATTACK]
	
	if atk_modifier.modifier_type == atk_modifier.Type.BUFF:
		atk_value *= 1.5
	
	elif atk_modifier.modifier_type == atk_modifier.Type.DEBUFF:
		atk_value *= 0.5
	
	return ceili(atk_value)

## Devuelve el valor total de ataque mágico
func get_magic_attack() -> int:
	var m_atk_value = magic_attack
	
	var m_atk_modifier : ModifierState = modifiers[GameAPI.Modifier.M_ATTACK]
	
	if m_atk_modifier.modifier_type == m_atk_modifier.Type.BUFF:
		m_atk_value *= 1.5
	
	elif m_atk_modifier.modifier_type == m_atk_modifier.Type.DEBUFF:
		m_atk_value *= 0.5
	
	return ceili(m_atk_value)

## Devuelve el valor total de defensa
func get_defense() -> int:
	var def_value = defense
	
	var def_modifier : ModifierState = modifiers[GameAPI.Modifier.DEFENSE]
	
	if def_modifier.modifier_type == def_modifier.Type.BUFF:
		def_value *= 1.5
	
	elif def_modifier.modifier_type == def_modifier.Type.DEBUFF:
		def_value *= 0.5
	
	if is_defending:
		def_value += round(defense * 3)
		
	return ceili(def_value)
