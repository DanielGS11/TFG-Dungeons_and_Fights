extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bright: ColorRect = $Bright/ColorRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	bright.color.a = GameAPI.get_bright()
	
	animation_player.play("loading")
	await animation_player.animation_finished
	
	queue_free()
