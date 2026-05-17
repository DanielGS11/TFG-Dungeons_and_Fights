extends Button

@onready var prompt_text: Label = $VBoxContainer/PromptContainer/Label
@onready var pointer: Label = $VBoxContainer/PromptContainer/Cursor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pointer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func load_prompt(prompt: String, pause) -> void:
	prompt_text.text = prompt
	
	if pause == false:
		await get_tree().create_timer(1.25).timeout
		_finish()

func _on_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	_finish()

func _finish():
	disabled = true
	
	pointer.terminate()
	GameAPI.prompt_end.emit()
	queue_free()
