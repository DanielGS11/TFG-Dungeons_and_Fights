## Se encarga de guardar el estado de un modificador de la entidad
class_name ModifierState
extends Resource

# Este enum no solo sirve para decir si es un buff o no, sino que tambien indica que está
# activo, ya que si no, estaria en valor NONE
enum Type {NONE, BUFF, DEBUFF}

var icon: Texture2D

var modifier_type: Type
var stat: String
var turn := 0

# Constructor
func _init(stat_name: String):
	stat = stat_name

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
