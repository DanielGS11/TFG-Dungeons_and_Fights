## Se encarga de guardar el estado de un modificador de la entidad
class_name ModifierState
extends Resource

## Contiene los posibles tipos de modificador (NONE es que no tiene tipo, no está activo)
enum Type {NONE, BUFF, DEBUFF}

## Icono del modificador
var icon: Texture2D

## Tipo de modificador
var modifier_type: Type

## Estadística que modifica
var stat: String

## Turnos que lleva activo
var turn := 0

## Constructor
func _init(stat_name: String):
	stat = stat_name

## Establece el tipo de modificador y su icono
func set_type(type: Type):
	modifier_type = type
	
	match type:
		Type.BUFF:
			GameAPI.get_asset("icons", stat + " +")
		
		Type.DEBUFF:
			GameAPI.get_asset("icons", stat + " -")

## Reinicia los valores predeterminados
func reset():
	modifier_type = Type.NONE
	turn = 0
