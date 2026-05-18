extends Panel

## Botón de una guía
var guide_button: Button

## Separador de las guías
var separator: HSeparator

## Lista de guías
@onready var list: VBoxContainer = %List

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Ejecuta una animación con un tween si se configuraron las animaciones que traíga la escena desde debajo de la pantalla
	if GameAPI.get_config().animations:
		var tween = get_tree().create_tween()
		
		global_position.y = get_global_rect().size.y
		tween.tween_property(self, "global_position:y", 0, 0.1)
	
	# Hace una copia del separador y el botón de guía para hacer varios duplicados para cada guía en la lista y limpia la lista
	guide_button = %Guide.duplicate(true)
	separator = %HSeparator.duplicate(true)
	
	for i in list.get_children():
		i.queue_free()
	
	# Por último, carga la lista de guías
	_load_guides()

## Carga la lista de guías
func _load_guides():
	# Guarda la lista en una variable
	var guides_keys = GameAPI.get_guide_keys()
	
	# Recorre por indice creando un duplicado del botón y asignando el título de la guía al texto del botón
	for i in guides_keys.size():
		var guide: Button = guide_button.duplicate(true)
		list.add_child(guide)
		guide.text = guides_keys[i]
		
		# Conecta el botón al método encargado de mostrar la guía correspondiente mandándole el título de la guía recogida (su clave)
		guide.pressed.connect(_on_guide_selected.bind(guide.text))
		
		# Si el índice es el último (lista.size() - 1) no genera un separador
		if i < guides_keys.size() - 1:
			list.add_child(separator.duplicate(true))

## Carga la guía seleccionada
func _on_guide_selected(key: String):
	MusicPlayer.play_sfx("Click")
	
	# Creamos una variable que contendrá una u otra pantalla según la guía seleccionada para mostrar
	var guide_screen: Node
	
	# Las guías 'Clases' y 'Enemigos' son diferentes, por lo que cargarían otra escena
	if key == "Clases" or key == "Enemigos":
		guide_screen = preload("res://scenes/global_elements/entity_guide/entity_guide.tscn").instantiate()
		add_child(guide_screen)
		
		# Le damos la guía a mostrar y su contexto
		guide_screen.load_parameters(key, guide_screen.Context.GUIDES)
	
	# En otro caso, cargamos la guía normal, la añadimos y le damos la clave para que la cargue
	else:
		guide_screen = preload("res://scenes/main_menu/guides/guide.tscn").instantiate()
		
		add_child(guide_screen)
		
		guide_screen.load_guide(key)

## Se ejecuta al pulsar la 'X' de la parte superior derecha de la pantalla
func _on_exit_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Se crea una animación si se configuró donde la guía, antes de desaparecer, se vaya para abajo de la pantalla
	if GameAPI.get_config().animations:
		var tween = get_tree().create_tween() 
		await tween.tween_property(self, "global_position:y", get_viewport_rect().size.y, 0.1).finished
	
	queue_free()
