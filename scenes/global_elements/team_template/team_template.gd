extends Panel

signal team_deleted
signal team_selected(id: int)

enum Context {MODE, EDITOR, LIST}

var context: Context
var index: int

@onready var members = %Members
@onready var delete_button = %Delete

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	match context:
		Context.EDITOR:
			pass
		Context.MODE, Context.LIST:
			mouse_filter = Control.MOUSE_FILTER_STOP


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
