# Con esta etiqueta hago que las variables de skill cambien segun el tipo
@tool
## Hechizo que usan las entidades, sus variables cambian según el tipo
class_name Skill
extends Resource

## Tipo de hechizo
enum Type {FISICAL, MAGIC, HEAL, BUFF, DEBUFF}

## Objetivo del hechizo
enum Target {ALLY, ALL_ALLIES, SELF, ENEMY, ALL_ENEMIES}

@export var name: String
@export var description: String

@export var skill_type: Type:
# Aqui hago que cuando se cambie este valor se notifique para que el inspector mire qué 
# tiene que mostrar
	set(value):
		skill_type = value
		notify_property_list_changed()

@export var skill_target: Target
@export var cost: int

# Solo aparece si la skill es tipo buff o debuff
@export var modifier : GameAPI.Modifier

# Solo aparece si la skill es de ataque (fisico o magico) o curación
@export var power: int

## Configura qué variable desaparece y/o se muestra en el inspector según el tipo
func _validate_property(property: Dictionary):
	# Si la propiedad es modifier pero el tipo de skill no es buff ni debuff, no se muestra
	if property.name == "modifier":
		if skill_type == Type.BUFF or skill_type == Type.DEBUFF:
			property.usage = PROPERTY_USAGE_DEFAULT
		else:
			property.usage = PROPERTY_USAGE_NO_EDITOR
	
	# Con power lo mismo, solo que el tipo debe ser físico, mágico o curación para mostrarse
	if property.name == "power":
		if skill_type == Type.BUFF or skill_type == Type.DEBUFF:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		else:
			property.usage = PROPERTY_USAGE_DEFAULT
