class_name Entity
extends Resource

# Esto es para la linea de comandos al combatir, informa de los diferentes estados de la
# entidad por una señal que llevará el valor a mostrar del comando
signal prompt(text: String, pause: bool)

enum actions {ATTACK, DEFEND, SKILL}

@export var sprite: Texture2D

@export var level: int
@export var name: String

@export var max_health: int
@export var health: int

@export var attack: int
@export var magic_attack: int
@export var defense: int
@export var speed: int

@export var critical_rate: int
@export var evasion: int

@export var skills: Array[Skill]

@export var description: String

var state: ModifierState

var modifiers := {
	GameAPI.modifier.ATTACK : ModifierState.new("Ataque"),
	GameAPI.modifier.M_ATTACK : ModifierState.new("Ataque mágico"),
	GameAPI.modifier.DEFENSE : ModifierState.new("Defensa")
}

# Esta variable es para la acción 'defender' (por el momento solo usada en el jugador).
# Como solo dura 1 turno y checkModifiers se usa al final de cada turno, la desactivará
# automaticamente
var is_defending := false

func applyBuff(skill: Skill):
	var buff: ModifierState = modifiers[skill.modifier]
	
	if buff.modifier_type == buff.type.BUFF:
		buff.turn = 0
		
		prompt.emit("¡Su " + buff.stat + " se volvió a potenciar!", false)
	
	elif buff.modifier_type == buff.type.DEBUFF:
		buff.reset()
		
		prompt.emit("Su " + buff.stat + " volvió a la normalidad", false)
	
	else:
		buff.modifier_type = buff.type.BUFF
		
		prompt.emit("Su " + buff.stat + " se potenció", false)

func applyDebuff(skill: Skill):
	var debuff: ModifierState = modifiers[skill.modifier]
	
	if debuff.modifier_type == debuff.type.DEBUFF:
		debuff.turn = 0
		
		prompt.emit("¡Su " + debuff.stat + " se volvió a reducir!", false)
	
	elif debuff.modifier_type == debuff.type.BUFF:
		debuff.reset()
		
		prompt.emit("Su " + debuff.stat + " volvió a la normalidad", false)
	
	else:
		debuff.modifier_type = debuff.type.DEBUFF
		
		prompt.emit("¡Su " + debuff.stat + " se redujo!", false)

func checkModifiers():
	if is_defending:
		is_defending = false
	
	if modifiers.values().any(func(a): a.modifier_type != a.type.NONE):
		for i in modifiers:
			var modifier_value : ModifierState = modifiers[i]
			
			if modifier_value.modifier_type != modifier_value.type.NONE:
				modifier_value.turn += 1
				
				if modifier_value.turn >= 4:
					modifier_value.reset()
					
					prompt.emit("Su " + modifier_value.stat + " volvió a la normalidad", false)

func clearModifiers():
	for i in modifiers:
		modifiers[i].reset()

func getAttack() -> int:
	var atk_value = attack
	
	var atk_modifier : ModifierState = modifiers[GameAPI.modifier.ATTACK]
	
	if atk_modifier.modifier_type == atk_modifier.type.BUFF:
		atk_value *= 1.5
	
	elif atk_modifier.modifier_type == atk_modifier.type.DEBUFF:
		atk_value *= 0.5
	
	return ceili(atk_value)

func getMagicAttack() -> int:
	var m_atk_value = magic_attack
	
	var m_atk_modifier : ModifierState = modifiers[GameAPI.modifier.M_ATTACK]
	
	if m_atk_modifier.modifier_type == m_atk_modifier.type.BUFF:
		m_atk_value *= 1.5
	
	elif m_atk_modifier.modifier_type == m_atk_modifier.type.DEBUFF:
		m_atk_value *= 0.5
	
	return ceili(m_atk_value)

func getDefense() -> int:
	var def_value = defense
	
	var def_modifier : ModifierState = modifiers[GameAPI.modifier.DEFENSE]
	
	if def_modifier.modifier_type == def_modifier.type.BUFF:
		def_value *= 1.5
	
	elif def_modifier.modifier_type == def_modifier.type.DEBUFF:
		def_value *= 0.5
	
	if is_defending:
		def_value += round(defense * 3)
		
	return ceili(def_value)
