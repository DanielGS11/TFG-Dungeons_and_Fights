extends TextureButton

signal team_deleted(id: int)
signal team_selected()
signal member_selected(id: int)

enum Context {MODE, EDITOR, LIST}

var context: Context
var index: int

@onready var team_name: Label = %TeamName
@onready var member_slots = %Members
@onready var delete_button = %Delete

func set_data(team_index: int, scene_context: Context):
	index = team_index
	context = scene_context
	
	team_name.text= "Equipo " + str(index + 1)
	
	match context:
		Context.EDITOR:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		Context.MODE, Context.LIST:
			mouse_filter = Control.MOUSE_FILTER_PASS
			
	
	delete_button.visible = context == Context.LIST
	
	load_data()

func load_data() -> void:
	var team: Team = GameAPI.get_team(index)
	
	for i in team.members.size():
		var member: Character = team.members[i]
		
		var slot = member_slots.get_child(i)
		var member_sprite: TextureRect = slot.get_child(0).get_child(0)
		var member_label: Label = slot.get_child(1)
		
		var member_name: String
		var sprite: Texture2D
		
		if member == null:
			sprite = GameAPI.get_asset("others", "Sin integrante")
			member_name = ""
		
		else:
			if member.sprite == null:
				sprite = GameAPI.get_asset("others", "Sin integrante")
			
			else:
				sprite = member.sprite
			
			member_name = member.name
		
		member_sprite.texture = sprite
		member_label.text = member_name
		
		if not slot.get_child(0).pressed.is_connected(_on_member_selected):
			slot.get_child(0).pressed.connect(_on_member_selected.bind(i))

func _on_team_selected():
	MusicPlayer.play_sfx("Click")
	
	team_selected.emit()
	
	GameAPI.set_team_in_edition(index)

func _on_member_selected(member_index: int):
	MusicPlayer.play_sfx("Click")
	
	if context == Context.EDITOR:
		member_selected.emit(member_index)

func _on_delete_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	team_deleted.emit(index)
