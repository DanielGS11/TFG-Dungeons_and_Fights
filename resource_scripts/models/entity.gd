class_name Entity
extends Resource

# Esto es para la linea de comandos al combatir, informa de los diferentes estados de la
# entidad por una señal que llevará el valor a mostrar del comando
signal prompt(text: String, pause: bool)

enum Actions {ATTACK, DEFEND, SKILL}

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
	GameAPI.Modifier.ATTACK : ModifierState.new("Ataque"),
	GameAPI.Modifier.M_ATTACK : ModifierState.new("Ataque mágico"),
	GameAPI.Modifier.DEFENSE : ModifierState.new("Defensa")
}

# Esta variable es para la acción 'defender' (por el momento solo usada en el jugador).
# Como solo dura 1 turno y checkModifiers se usa al final de cada turno, la desactivará
# automaticamente
var is_defending := false

# Metodos para aplicar un buff o debuff. Si se aplica un buff del mismo tipo que uno que ya está 
# activo, se resetea el contador, si lo que está activo es un debuff del tipo del buff, lo anula y 
# viceversa
func apply_buff(skill: Skill):
	var buff: ModifierState = modifiers[skill.modifier]
	
	match buff.modifier_type:
		buff.Type.BUFF:
			buff.turn = 0
			
			prompt.emit("¡Su " + buff.stat + " se volvió a potenciar!", false)
		
		buff.Type.DEBUFF:
			buff.reset()
			
			prompt.emit("Su " + buff.stat + " volvió a la normalidad", false)
		
		buff.Type.NONE:
			buff.modifier_type = buff.Type.BUFF
			
			prompt.emit("Su " + buff.stat + " se potenció", false)

func apply_debuff(skill: Skill):
	var debuff: ModifierState = modifiers[skill.modifier]
	
	match debuff.modifier_type: 
		debuff.Type.DEBUFF:
			debuff.turn = 0
			
			prompt.emit("¡Su " + debuff.stat + " se volvió a reducir!", false)
		
		debuff.Type.BUFF:
			debuff.reset()
			
			prompt.emit("Su " + debuff.stat + " volvió a la normalidad", false)
			
		debuff.Type.NONE:
			debuff.modifier_type = debuff.type.DEBUFF
			
			prompt.emit("¡Su " + debuff.stat + " se redujo!", false)

# Con este método, ejecutado al terminar el turno del usuario, se suma 1 al contador de turnos
# activos de un buff y debuff, cuando el contador llegue a 4 (3 turnos mas el turno en el que se 
# activa) el (de)buff termina
func check_modifiers():
	if is_defending:
		is_defending = false
	
	if modifiers.values().any(func(a): a.modifier_type != a.Type.NONE):
		for i in modifiers:
			var modifier_value : ModifierState = modifiers[i]
			
			if modifier_value.modifier_type != modifier_value.Type.NONE:
				modifier_value.turn += 1
				
				if modifier_value.turn >= 4:
					modifier_value.reset()
					
					prompt.emit("Su " + modifier_value.stat + " volvió a la normalidad", false)

# Con este método, se limpian los buffs y debuffs, se ejecutaría al termiar un combate
func clear_modifiers():
	for i in modifiers:
		modifiers[i].reset()

# Getters de las stats, que devuelven el valor total de la stat por si hay que aplicarle algún
# modificador, estos métodos los pediran los métodos del controlador como el de atacar o curar
func get_attack() -> int:
	var atk_value = attack
	
	var atk_modifier : ModifierState = modifiers[GameAPI.Modifier.ATTACK]
	
	if atk_modifier.modifier_type == atk_modifier.Type.BUFF:
		atk_value *= 1.5
	
	elif atk_modifier.modifier_type == atk_modifier.Type.DEBUFF:
		atk_value *= 0.5
	
	return ceili(atk_value)

func get_magic_attack() -> int:
	var m_atk_value = magic_attack
	
	var m_atk_modifier : ModifierState = modifiers[GameAPI.Modifier.M_ATTACK]
	
	if m_atk_modifier.modifier_type == m_atk_modifier.Type.BUFF:
		m_atk_value *= 1.5
	
	elif m_atk_modifier.modifier_type == m_atk_modifier.Type.DEBUFF:
		m_atk_value *= 0.5
	
	return ceili(m_atk_value)

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
