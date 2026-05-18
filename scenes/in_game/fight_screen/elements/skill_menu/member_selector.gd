extends Panel

## Señal que emite el objetivo seleccionado de la animación
signal target_selected(target: Character)

## Contiene el equipo y sus datos
var team: Team

## Punteros que muestran a qué miembros se puede elegir
@onready var pointers = %Pointers

## Botones correspondientes a cada miembro para elegir con quién usar el hechizo
@onready var members = %Members

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Carga el equipo actual
	team = GameAPI.get_controller().team
	
	# Recorre cada miembro del equipo y establece qué puntero se muestra y qué botón del miembro se habilita para seleccionarlo. Solo se pueden seleccionar los que no fueron derrotados
	for i in team.members.size():
		var member = team.members[i]
		
		var member_button: Button = members.get_child(i)
		
		if member.health == 0:
			member_button.get_child(0).text = "X"
			
		else:
			pointers.get_child(i).text = "V"
		
		member_button.disabled = member.health == 0
		
		# Según el miembro que se seleccione, manda su objeto en la señal
		member_button.pressed.connect(func(): 
				MusicPlayer.play_sfx("Click")
				
				target_selected.emit(member)
				queue_free()
				)

## Se ejecuta al pulsar el botón 'X' en la parte derecha de la selección de objetivo
func _on_cancel_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Manda null en la señal de objetivo seleccionado y se desrtuye
	target_selected.emit(null)
	queue_free()
