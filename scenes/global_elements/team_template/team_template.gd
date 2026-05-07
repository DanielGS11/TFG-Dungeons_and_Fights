extends TextureButton

signal team_deleted(id: int)
signal team_selected(id: int)

enum Context {MODE, EDITOR, LIST}

var context: Context
var index: int

@onready var team_name: Label = %TeamName
@onready var members = %Members
@onready var delete_button = %Delete

func load_data() -> void:
	team_name.text= "Equipo " + str(index + 1)
	
	match context:
		Context.EDITOR:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		Context.MODE, Context.LIST:
			mouse_filter = Control.MOUSE_FILTER_PASS

func _on_team_selected():
	print("a")
