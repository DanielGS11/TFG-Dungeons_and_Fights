extends Panel

signal bright_changed()

var old_config := ConfigData.new()

var config : ConfigData
var changed = false

@onready var volume := %Volume
@onready var bright := %Bright
@onready var mute: CheckBox = $Panel/VBoxContainer/Mute/CheckBox
@onready var animations: CheckBox = $Panel/VBoxContainer/Animations/CheckBox

# Al cargar la escena, se establecen los valores de configuración
func _ready() -> void:
	config = GameAPI.get_config()
	
	old_config = config.duplicate(true)
	
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

func _on_volume_changed(value: float) -> void:
	volume.get_child(1).value = value
	volume.get_child(2).text = str(int(value))
	mute.button_pressed = false
	
	GameAPI.set_volume(value)
	
	changed = true

func _on_bright_changed(value: float) -> void:
	bright.get_child(1).value = value
	bright.get_child(2).text = str(int(value))
	
	GameAPI.set_bright(value)
	
	changed = true
	bright_changed.emit()

func _on_mute_toggled(toggled_on: bool) -> void:
	MusicPlayer.play_sfx("Click")
	
	mute.button_pressed = toggled_on
	
	GameAPI.set_mute(toggled_on)
	
	changed = true

func _on_animations_toggled(toggled_on: bool) -> void:
	MusicPlayer.play_sfx("Click")
	
	animations.button_pressed = toggled_on
	
	GameAPI.set_animations(toggled_on)
	
	changed = true

func _on_confirm_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	GameAPI.save_config()
	
	await _animate(get_global_rect().size.y)
	queue_free()

func _on_cancel_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	if changed:
		var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
		add_child(popup)
		
		popup.load_text("Hay cambios sin guardar, ¿Seguro que quieres cancelarlos?")
		
		if await popup.confirm:
			GameAPI.set_animations(old_config.animations)
			GameAPI.set_mute(old_config.mute)
			GameAPI.set_bright(old_config.bright)
			GameAPI.set_volume(old_config.volume)
			
			await _animate(get_global_rect().size.y)
			queue_free()
		
	else:
		await _animate(get_global_rect().size.y)
		queue_free()

func _animate(pos: float):
	if config.animations:
		var tween = get_tree().create_tween()
		await tween.tween_property(self, "global_position:y", pos, 0.1).finished
