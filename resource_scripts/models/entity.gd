class_name Entity
extends Resource

# Este enum define qué tipo de acción hace el personaje, aunque la usen esta clase y el controlador,
# no está en la API ya que es exlusiva de esas 2 clases, las de la API se podrían implementar en 
# futuras clases
enum Actions {ATTACK, DEFEND, SKILL}

var prompt: Variant

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

# Metodos para aplicar un buff o debuff. Si se aplica un buff del mismo tipo que uno que ya está 
# activo, se resetea el contador, si lo que está activo es un debuff del tipo del buff, lo anula y 
# viceversa
func apply_buff(skill: Skill) -> String:
	var buff: ModifierState = modifiers[skill.modifier]
	
	var word: String
	
	if buff.stat == "Defensa":
		word = "La "
	
	else:
		word = "El "
	
	match buff.modifier_type:
		buff.Type.BUFF:
			buff.turn = 0
			
			prompt = "¡" + word + buff.stat + " de " + name + " se volvió a potenciar!"
		
		buff.Type.DEBUFF:
			buff.reset()
			
			prompt = word + buff.stat + " de " + name + " volvió a la normalidad"
		
		buff.Type.NONE:
			buff.modifier_type = buff.Type.BUFF
			
			prompt = "¡" + word + buff.stat + " de " + name + " se potenció!"
	
	return prompt

func apply_debuff(skill: Skill) -> String:
	var debuff: ModifierState = modifiers[skill.modifier]
	
	var word: String
	
	if debuff.stat == "Defensa":
		word = "La "
	
	else:
		word = "El "
	
	match debuff.modifier_type: 
		debuff.Type.DEBUFF:
			debuff.turn = 0
			
			prompt = "¡" + word + debuff.stat + " de " + name + " se volvió a reducir!"
		
		debuff.Type.BUFF:
			debuff.reset()
			
			prompt = word + debuff.stat + " de " + name + " volvió a la normalidad"
			
		debuff.Type.NONE:
			debuff.modifier_type = debuff.Type.DEBUFF
			
			prompt = "¡" + word + debuff.stat + " de " + name + " se redujo!"
	
	return prompt

# Métodos para recibir daño, curar y gastar maná (solo la clase Character)
func take_damage(damage: int) -> Array:
	prompt = [name + " recibió " + str(damage) + " puntos de daño"]
	
	if damage > health:
		health = 0
		clear_modifiers()
		prompt.append(name + " fué derrotado")
	
	else:
		health -= damage
	
	return prompt

func heal(healing: int) -> String:
	if health == max_health:
		prompt = "La vida de " + name + " ya estaba al máximo"
	
	else:
		if max_health - health < healing:
			health = max_health
		
		else:
			health += healing
		
		prompt = name + " recibió " + str(healing) + " puntos de curación"
	
	return prompt

func consume_mana(value: int):
	pass

# Con este método, ejecutado al terminar el turno del usuario, se suma 1 al contador de turnos
# activos de un buff y debuff, cuando el contador llegue a 4 (3 turnos mas el turno en el que se 
# activa) el (de)buff termina
func check_modifiers() -> Array:
	if is_defending:
		is_defending = false
	
	prompt = []
	
	if modifiers.values().any(func(a): a.modifier_type != a.Type.NONE):
		
		for i in modifiers:
			var modifier_value : ModifierState = modifiers[i]
			
			if modifier_value.modifier_type != modifier_value.Type.NONE:
				modifier_value.turn += 1
				
				if modifier_value.turn >= 4:
					modifier_value.reset()
					
					if modifier_value.stat == "Defensa":
						prompt.append("La " + modifier_value.stat + " de " + name + " volvió a la normalidad")
						
					else:
						prompt.append("El " + modifier_value.stat + " de " + name + " volvió a la normalidad")
	
	return prompt

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
