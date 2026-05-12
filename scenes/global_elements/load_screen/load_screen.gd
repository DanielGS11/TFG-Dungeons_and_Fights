extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.play("loading")
	await animation_player.animation_finished
	
	queue_free()
