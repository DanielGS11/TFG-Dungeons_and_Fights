extends Panel

## Avisa de que el brillo cambió
signal bright_changed()

## Guarda la configuración anterior
var old_config := ConfigData.new()

## Contiene la configuración actual
var config : ConfigData

## Indica si hubo cambios o no
var changed = false

## Valor del volumen
@onready var volume := %Volume

## Valor del brillo
@onready var bright := %Bright

## Valor del volumen silenciado
@onready var mute: CheckBox = $Panel/VBoxContainer/Mute/CheckBox

## Valor de las animaciones activadas
@onready var animations: CheckBox = $Panel/VBoxContainer/Animations/CheckBox

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Recoge la configuración actual y le hace una copia para guardar la configuración anterior por si se cambia
	config = GameAPI.get_config()
	old_config = config.duplicate(true)
	
	# Se plasman los valores en las variables correspondientes
	if config.animations:
		global_position.y = get_global_rect().size.y
		_animate(0)
	
	volume.get_child(1).value = config.volume
	volume.get_child(2).text = str(int(config.volume))
	
	bright.get_child(1).value = config.bright
	bright.get_child(2).text = str(int(config.bright))
	
	mute.button_pressed = config.mute
	
	animations.button_pressed = config.animations
	
	changed = false

## Se ejecuta al cambiar el volumen
func _on_volume_changed(value: float) -> void:
	# Se plasman los cambios y se dice a la API que cambie el volumen
	volume.get_child(1).value = value
	volume.get_child(2).text = str(int(value))
	mute.button_pressed = false
	GameAPI.set_volume(value)
	
	# Se establece si hubo cambios o no en función de si la configuración de volumen actual y anterior son diferentes o no
	changed = config.volume != old_config.volume

## Se ejecuta al cambiar el brillo
func _on_bright_changed(value: float) -> void:
	# Se plasman los cambios y se dice a la API que cambie el volumen
	bright.get_child(1).value = value
	bright.get_child(2).text = str(int(value))
	GameAPI.set_bright(value)
	
	# Se establece si hubo cambios o no en función de si la configuración de volumen actual y anterior son diferentes o no y se avisa de que el brillo cambió
	changed = config.bright != old_config.bright
	bright_changed.emit()

## Se ejecuta al cambiar el silencio del juego
func _on_mute_toggled(toggled_on: bool) -> void:
	MusicPlayer.play_sfx("Click")
	
	# Se plasman los cambios y se dice a la API que cambie el volumen
	mute.button_pressed = toggled_on
	GameAPI.set_mute(toggled_on)
	
	# Se establece si hubo cambios o no en función de si la configuración de volumen actual y anterior son diferentes o no y se avisa de que el brillo cambió
	changed = config.mute != old_config.mute

## Se ejecuta al activar/desactivar las animaciones del juego
func _on_animations_toggled(toggled_on: bool) -> void:
	MusicPlayer.play_sfx("Click")
	
	# Se plasman los cambios y se dice a la API que cambie el volumen
	animations.button_pressed = toggled_on
	GameAPI.set_animations(toggled_on)
	
	# Se establece si hubo cambios o no en función de si la configuración de volumen actual y anterior son diferentes o no y se avisa de que el brillo cambió
	changed = config.animations != old_config.animations

## se ejecuta al pulsar 'Confirmar'
func _on_confirm_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Se guarda la configuración, se ejecuta la animación de salida y se destruye la escena
	GameAPI.save_config()
	await _animate(get_global_rect().size.y)
	queue_free()

## se ejecuta al pulsar 'Cancelar'
func _on_cancel_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# SI hubo cambios, se pregunta mediante un popup al usuario si desea descartarlos
	if changed:
		var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
		add_child(popup)
		
		popup.load_text("Hay cambios sin guardar, ¿Seguro que quieres cancelarlos?")
		
		# Si presiona 'Si', se ponen los valores como estaban guardados en la configuración anterior
		if await popup.confirm:
			GameAPI.set_animations(old_config.animations)
			GameAPI.set_mute(old_config.mute)
			GameAPI.set_bright(old_config.bright)
			GameAPI.set_volume(old_config.volume)
			
			await _animate(get_global_rect().size.y)
			queue_free()
	
	# Si no hubo cambios, la escena se va
	else:
		await _animate(get_global_rect().size.y)
		queue_free()

## Ejecuta una animación
func _animate(pos: float):
	# Solo anima si se activaron las animaciones
	if config.animations:
		var tween = get_tree().create_tween()
		await tween.tween_property(self, "global_position:y", pos, 0.1).finished
