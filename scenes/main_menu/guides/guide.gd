extends Panel

var text: Label
var separator: HSeparator
var small_texture: TextureRect
var large_texture: TextureRect

@onready var guide_name: Label = %GuideTitle
@onready var content: VBoxContainer = %GuideContent

func _ready() -> void:
	# Duplicamos los elementos y limpiamos el nodo del contenido
	text = $ScrollContainer/GuideContent/Text.duplicate(true)
	separator = $ScrollContainer/GuideContent/HSeparator.duplicate(true)
	small_texture = $ScrollContainer/GuideContent/TextureSmall.duplicate(true)
	large_texture = $ScrollContainer/GuideContent/TextureLarge.duplicate(true)
	
	for i in content.get_children():
		i.queue_free()

## Carga la guía
func load_guide(key: String) -> void:
	guide_name.text = key
	
	for i in GameAPI.get_guide(key):
		var node
		
		match typeof(i):
			TYPE_STRING:
				node = text.duplicate(true)
				
				content.add_child(node)
				node.text = i
			
			TYPE_OBJECT:
				if i.get_height() < i.get_width():
					node = small_texture.duplicate(true)
				
				else:
					node = large_texture.duplicate(true)
				
				content.add_child(node)
				
				node.texture = i
			
			TYPE_NIL:
				node = separator.duplicate(true)
				
				content.add_child(node)


func _on_go_back_pressed() -> void:
	queue_free()
