extends TextureButton

## Emite el equipo que se borra
signal team_deleted(id: int)

## Avisa que se seleccionó un equipo
signal team_selected()

## Emite el miembro seleccionado
signal member_selected(id: int)

## Contiene los posibles contextos en los que se crea esta escena
enum Context {MODE, EDITOR, LIST}

## Contiene el contexto en el que se crea la escena
var context: Context

## Índice del equipo que contiene
var index: int

## Nombre del equipo
@onready var team_name: Label = %TeamName

## Espacios de los miembros del equipo
@onready var member_slots = %Members

## Botón de borrar equipo
@onready var delete_button = %Delete

## Establece el índice de equipo y contexto de la escena
func set_data(team_index: int, scene_context: Context):
	index = team_index
	context = scene_context
	
	# EL nombre es índice + 1 ya que el primer índice es 0 y quedaría como 'Equipo 0'
	team_name.text= "Equipo " + str(index + 1)
	
	# Si el contexto es que está en el editor, solo detecta los clicks de los espacios de los miembros del equipo, si no, detecta el click en cualquier parte
	match context:
		Context.EDITOR:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		Context.MODE, Context.LIST:
			mouse_filter = Control.MOUSE_FILTER_PASS
	
	# El botón de borrado de equipo solo será visible en la lista de equipos
	delete_button.visible = context == Context.LIST
	
	# Carga los datos del equipo de la escena
	load_data()

## Carga los datos del equipo
func load_data() -> void:
	# Recoge el equipo en una variable
	var team: Team = GameAPI.get_team(index)
	
	# Recorre sus miembros y establece su sprite y nombre
	for i in team.members.size():
		var member: Character = team.members[i]
		
		var slot = member_slots.get_child(i)
		var member_sprite: TextureRect = slot.get_child(0).get_child(0)
		var member_label: Label = slot.get_child(1)
		
		var member_name: String
		var sprite: Texture2D
		
		# Si el miembro no existe porque todavía no está configurado, pone los datos por defecto en su espacio
		if member == null:
			sprite = GameAPI.get_asset("others", "Sin integrante")
			member_name = ""
		
		else:
			# Si existe pero no tiene sprite, pone el sprite por defecto
			if member.sprite == null:
				sprite = GameAPI.get_asset("others", "Sin integrante")
			
			else:
				sprite = member.sprite
			
			member_name = member.name
		
		# Plasma los datos recogidos en la escena
		member_sprite.texture = sprite
		member_label.text = member_name
		
		# Conecta la pulsación del miembro al método correspondiente
		if not slot.get_child(0).pressed.is_connected(_on_member_selected):
			slot.get_child(0).pressed.connect(_on_member_selected.bind(i))

## Se ejecuta al seleccionar el equipo
func _on_team_selected():
	MusicPlayer.play_sfx("Click")
	
	# Emite la señal de equipo seleccionado y establece su índice como equipo en edición si se seleccionó desde la lista de equipos
	team_selected.emit()
	
	if context == Context.LIST:
		GameAPI.set_team_in_edition(index)

## Se ejecuta al seleccionar a un miembro del equipo
func _on_member_selected(member_index: int):
	MusicPlayer.play_sfx("Click")
	
	# Emita la señal del miembro seleccionado con su índice
	if context == Context.EDITOR:
		member_selected.emit(member_index)

## Se ejecuta al pulsar el botón de borrar (La papelera de la parte superior derecha de la escena del equipo)
func _on_delete_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Emite la señal de equipo borrado con el indice del equipo a borrar
	team_deleted.emit(index)
