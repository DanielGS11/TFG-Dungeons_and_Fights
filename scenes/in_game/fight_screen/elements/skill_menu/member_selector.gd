extends VBoxContainer

signal target_selected(target: Character)

var team: Team

@onready var pointers = %Pointers
@onready var members = %Members

func _ready() -> void:
	team = GameAPI.get_controller().team
	
	for i in team.members.size():
		var member = team.members[i]
		
		var member_button: Button = members.get_child(i)
		
		if member.health == 0:
			member_button.get_child(0).text = "X"
			
		else:
			pointers.get_child(i).text = "V"
		
		member_button.disabled = member.health == 0
		member_button.pressed.connect(func(): 
			target_selected.emit(member)
			queue_free()
			)

func _on_cancel_pressed() -> void:
	target_selected.emit(null)
	queue_free()
