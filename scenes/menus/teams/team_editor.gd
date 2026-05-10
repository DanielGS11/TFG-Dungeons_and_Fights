extends Control

var member_index = 0
var class_index: int = -1
var sprite_index = 0
var class_list: Array[Character]
var sprite_list: Array

var member: Character

@onready var bright: ColorRect = $Bright/ColorRect

@onready var team = %TeamContainer
@onready var character_class: Label = %ClassName
@onready var sprite: TextureRect = %Sprite
@onready var name_field: LineEdit = $Content/LineEdit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ajusto el brillo de pantalla
	bright.color.a = GameAPI.get_bright()
	
	class_list = GameAPI.get_classes()
	
	var team_container = preload("res://scenes/global_elements/team_template/team_template.tscn").instantiate()
	
	team.add_child(team_container)
	
	team_container.set_data(GameAPI.get_team_in_edition(), team_container.Context.EDITOR)
	team_container.member_selected.connect(_load_member)
	
	team = team.get_child(0)
	
	_load_member(member_index)

func _load_member(index: int):
	member_index = index
	member = GameAPI.get_team(GameAPI.get_team_in_edition()).members[member_index]
	
	if member == null:
		member = Character.new()
		class_index = -1
		sprite_index = 0
		character_class.text = "Ninguno"
		sprite.texture = GameAPI.get_asset("others", "Sin integrante")
		sprite_list = []
		name_field.text = ""
	
	else:
		class_index = class_list.map(func (a): return a.class_type).find(member.class_type)
				
		character_class.text = class_list[class_index].class_type
		sprite_list = GameAPI.get_asset("characters", class_list[class_index].class_type)
		sprite_index = sprite_list.find(member.sprite)
		
		name_field.text = member.name
		sprite.texture = member.sprite

func _on_previous_sprite_pressed() -> void:
	if not sprite_list.is_empty():
		if sprite_index <= 0:
			sprite_index = sprite_list.size() - 1
		
		else:
			sprite_index -= 1
		
		member.sprite = sprite_list[sprite_index]
		sprite.texture = member.sprite
		
		_on_member_changed()

func _on_next_sprite_pressed() -> void:
	if not sprite_list.is_empty():
		if sprite_index >= sprite_list.size() - 1:
			sprite_index = 0
		
		else:
			sprite_index += 1
		
		member.sprite = sprite_list[sprite_index]
		sprite.texture = member.sprite
		
		_on_member_changed()

func _on_previous_class_pressed() -> void:
	if class_index <= 0:
		class_index = class_list.size() - 1
	
	else:
		class_index -= 1
	
	character_class.text = class_list[class_index].class_type
	sprite_index = 0
	sprite_list = GameAPI.get_asset("characters", class_list[class_index].class_type)
	
	member = class_list[class_index].duplicate(true)
	member.sprite = sprite_list[sprite_index]
	sprite.texture = member.sprite
	member.name = name_field.text
	
	_on_member_changed()

func _on_next_class_pressed() -> void:
	if class_index >= class_list.size() - 1:
		class_index = 0
	
	else:
		class_index += 1
	
	character_class.text = class_list[class_index].class_type
	sprite_index = 0
	sprite_list = GameAPI.get_asset("characters", class_list[class_index].class_type)
	
	member = class_list[class_index].duplicate(true)
	member.sprite = sprite_list[sprite_index]
	sprite.texture = member.sprite
	member.name = name_field.text
	
	_on_member_changed()

func _on_line_edit_text_changed(new_text: String) -> void:
	member.name = new_text
	
	_on_member_changed()

func _on_member_changed():
	GameAPI.set_member(GameAPI.get_team_in_edition(), member_index, member)
	team.load_data()

func _on_confirm_pressed() -> void:
	GameAPI.save_game()
	
	get_tree().change_scene_to_file("res://scenes/menus/teams/team_list.tscn")

func _on_classes_pressed() -> void:
	var guide = preload("res://scenes/global_elements/entity_guide/entity_guide.tscn").instantiate()
	
	add_child(guide)
	
	guide.load_parameters("Clases", guide.Context.EDITOR)
