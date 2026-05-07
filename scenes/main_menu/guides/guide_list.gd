extends Panel

var guide_button: Button
var separator: HSeparator

# Lista
@onready var list: VBoxContainer = $ScrollContainer/List

# Al cargar la escena
func _ready() -> void:
	if GameManager.config.animations:
		# Creo una animación por código
		var tween = get_tree().create_tween()
		
		position = Vector2(0, 900)
		tween.tween_property(self, "position", Vector2(0,0), 0.1)
	
	# Hago una copia del botón de guía y del separador
	guide_button = $ScrollContainer/List/Guide.duplicate(true)
	separator = $ScrollContainer/List/HSeparator.duplicate(true)
	
	# Limpio los placeholders ya duplicados
	for i in list.get_children():
		i.queue_free()
	
	# Cargo las guias
	load_guides()

## Carga la lista de guías
func load_guides():
	# Guarda la lista en una variable
	var guides_keys = GameAPI.get_guide_keys()
	
	# Recorre por indice creando un duplicado del botón y asignando datos
	for i in guides_keys.size():
		var guide: Button = guide_button.duplicate(true)
		
		list.add_child(guide)
		
		guide.text = guides_keys[i]
		# Conectamos al método que carga la guía y le damos la clave al pulsar
		guide.pressed.connect(_on_guide_selected.bind(guide.text))
		
		# Si el índice es el último (lista.size() - 1) no genera un separador
		if i < guides_keys.size() - 1:
			list.add_child(separator.duplicate(true))

## Carga la guía seleccionada
func _on_guide_selected(key: String):
	var guide_screen: Node
	
	# Las guías "Clases" y "Enemigos" son diferentes, por lo que cargarían otra escena
	if key == "Clases" or key == "Enemigos":
		pass
		guide_screen = preload("res://scenes/global_elements/entity_guide/entity_guide.tscn").instantiate()
		
		add_child(guide_screen)
		
		guide_screen.load_parameters(key, guide_screen.Context.GUIDES)
	
	# En otro caso, cargamos la guía normal, la añadimos y le damos la clave para que la cargue
	else:
		guide_screen = preload("res://scenes/main_menu/guides/guide.tscn").instantiate()
		
		add_child(guide_screen)
		
		guide_screen.load_guide(key)

## Al pulsar la 'X' hace su animación de salida y muere
func _on_exit_pressed() -> void:
	if GameManager.config.animations:
		# Cada animación es de un solo uso, por lo que hay que crearlo de nuevo cada vez
		var tween = get_tree().create_tween() 
		await tween.tween_property(self, "position", Vector2(0,900), 0.1).finished
	queue_free()
