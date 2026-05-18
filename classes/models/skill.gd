# Con esta etiqueta hago que las variables de skill cambien segun el tipo
@tool
## Hechizo que usan las entidades, sus variables cambian según el tipo
class_name Skill
extends Resource

## Contiene los posibles tipos de hechizo
enum Type {FISICAL, MAGIC, HEAL, BUFF, DEBUFF}

## Contiene los posibles objetivos del hechizo
enum Target {ALLY, ALL_ALLIES, SELF, ENEMY, ALL_ENEMIES}

## Nombre del hechizo
@export var name: String

## Descripción del hechizo
@export var description: String

## Tipo de hechizo
@export var skill_type: Type:
# Aqui hago que cuando se cambie este valor se notifique para que el inspector mire qué tiene que mostrar
	set(value):
		skill_type = value
		notify_property_list_changed()

## Objetivo del hechizo
@export var skill_target: Target

## Coste del hechizo
@export var cost: int

## Modificador del hechizo (Solo si es un Buff o Debuff)
@export var modifier : GameAPI.Modifier

## Poder del hechizo (Solo si es de Curación, Físico o Mágico)
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
