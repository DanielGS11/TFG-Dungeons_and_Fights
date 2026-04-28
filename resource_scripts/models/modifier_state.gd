class_name ModifierState
extends Resource

# Este enum no solo sirve para decir si es un buff o no, sino que tambien indica que está
# activo, ya que si no, estaria en valor NONE
enum type {NONE, BUFF, DEBUFF}

var icon: Texture2D

var modifier_type: type
var stat: String
var turn := 0

# Constructor
func _init(stat_name: String):
	stat = stat_name

# Aqui reseteamos a los valores predeterminados
func reset():
	modifier_type = type.NONE
	turn = 0
