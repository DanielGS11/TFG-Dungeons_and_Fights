extends Panel

signal on_selector
signal skill_selected(queue: Dictionary)

var member: Character
var skill_row: HBoxContainer


@onready var skill_description: Label = %Description
@onready var skill_power: Label = %Power
@onready var skill_cost: Label = %Cost
@onready var skill_list = %SkillList

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	skill_row = skill_list.get_child(0)
	
	for i in skill_list.get_children():
		i.queue_free()


func load_skills(m: Character):
	member = m
	
	for skill in member.skills:
		var row = skill_row.duplicate(true)
		
		skill_list.add_child(row)
		
		var skill_button: Button = row.get_child(0)
		skill_button.text = skill.name
		skill_button.disabled = member.mana < skill.cost
		skill_button.pressed.connect(_on_skill_selected.bind(skill))
		row.get_child(1).pressed.connect(_on_skill_info_pressed.bind(skill))

func _on_skill_selected(skill: Skill):
	MusicPlayer.play_sfx("Click")
	
	match skill.skill_target:
		Skill.Target.SELF, Skill.Target.ALL_ALLIES:
			skill_selected.emit({member: [Entity.Actions.SKILL, member, skill]})
			queue_free()
		
		Skill.Target.ENEMY, Skill.Target.ALL_ENEMIES:
			skill_selected.emit({member: [Entity.Actions.SKILL, GameAPI.get_controller().enemy, skill]})
			queue_free()
		
		Skill.Target.ALLY:
			var selector = preload("res://scenes/in_game/fight_screen/elements/skill_menu/member_selector.tscn").instantiate()
			
			add_child(selector)
			on_selector.emit()
			
			var target = await selector.target_selected
			on_selector.emit()
			
			if target != null:
				skill_selected.emit({member: [Entity.Actions.SKILL, target, skill]})
				queue_free()

func _on_skill_info_pressed(skill: Skill):
	MusicPlayer.play_sfx("Click")
	
	skill_description.text = skill.description
	
	if skill.get("power") != null:
		skill_power.text = "Poder: " + str(skill.power)
	
	skill_cost.text = "Coste: " + str(skill.cost)

func _on_return_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	skill_selected.emit({})
	queue_free()
