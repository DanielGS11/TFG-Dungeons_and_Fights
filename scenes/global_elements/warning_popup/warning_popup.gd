extends Panel

@onready var warning_text: Label = %Text

func load_warn(text: String):
	warning_text.text = text

func _on_ok_pressed() -> void:
	queue_free()
