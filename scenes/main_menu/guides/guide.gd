extends Panel

## Texto de la guía
var text: Label

## Separador de elementos de la guía
var separator: HSeparator

## Imagen pequeña de la guía
var small_texture: TextureRect

## Imagen grande de la guía
var large_texture: TextureRect

## Nombre de la guía
@onready var guide_name: Label = %GuideTitle

## Contenido de la guía
@onready var content: VBoxContainer = %GuideContent

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Duplicamos los elementos prçara establecerles los datos de la guía y limpiamos el contenedor del contenido
	text = %Text.duplicate(true)
	separator = %HSeparator.duplicate(true)
	small_texture = %TextureSmall.duplicate(true)
	large_texture = $Elements/ScrollContainer/GuideContent/TextureLarge.duplicate(true)
	
	for i in content.get_children():
		i.queue_free()

## Carga la guía
func load_guide(key: String) -> void:
	# Pone el nombre de la guía arriba del todo y establece el contenido
	guide_name.text = key
	
	# Se recorre cada elemento de la guía
	for i in GameAPI.get_guide(key):
		# Esta variable contendrá un duplicado de los elementos antes duplicados pero con el contenido de la guía
		var node
		
		# Según su tipo de elemento se establece una cosa un otra en la variable anterior 
		# - Si es String, 'node' sera un duplicado de 'text'
		# - Si es Texture2D (Object en este caso), 'node' sera un duplicado de small o large texture dependiendo de su tamaño
		# - Si es Null (Nil), 'node' sera un duplicado de 'separator'
		# Una vez duplicado el elemento en node, se añade al contenedor de contenido de la guía y se le da el valor del elemento correspondiente de la guía
		match typeof(i):
			TYPE_STRING:
				node = text.duplicate(true)
				
				content.add_child(node)
				node.text = i
			
			TYPE_OBJECT:
				# En caso de ser una imagen, si su altura es menor que su anchura, será una imagen pequeña, si no, una grande
				if i.get_height() < i.get_width():
					node = small_texture.duplicate(true)
				
				else:
					node = large_texture.duplicate(true)
				
				content.add_child(node)
				
				node.texture = i
			
			TYPE_NIL:
				node = separator.duplicate(true)
				
				content.add_child(node)

## Se ejecuta al presionar la flecha de retroceso de la parte superior izquierda de la pantalla
func _on_go_back_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Destruye la pantalla de la guía
	queue_free()
