extends Control

# Cuando la pantalla se inicia, realiza una animación de entrada
# y carga la configuración y partida, además de establecer el brillo
func _ready() -> void:
	$AnimationPlayer.play("entry")
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("idle")

# Al pulsar cualquier lado de la pantalla, navega al menú principal
func _on_enter_pressed() -> void:
	if $AnimationPlayer.current_animation == "entry" and not $AnimationPlayer.is_playing():
		print("a")
