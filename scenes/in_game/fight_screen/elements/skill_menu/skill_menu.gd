extends Panel

## Indica si está o no en el selector de objetivo
signal on_selector

## Devuelve la acción del miembro
signal skill_selected(queue: Dictionary)

## Miembro del equipo
var member: Character

## Fila que contendrá el propio hechizo y el botón 'info' ('?') del hechizo
var skill_row: HBoxContainer

## Muestra la descripción del hechizo
@onready var skill_description: Label = %Description

## Muestra el poder del hechizo
@onready var skill_power: Label = %Power

## Muestra el coste del hechizo
@onready var skill_cost: Label = %Cost

## Lista de hechizos
@onready var skill_list = %SkillList

## Se ejecuta al cargar la escena
func _ready() -> void:
	# Se hace un duplicado de la fila que ya hay por defecto en la lista y se limpia la lista
	skill_row = skill_list.get_child(0).duplicate(true)
	
	for i in skill_list.get_children():
		i.queue_free()

## Carga los hechizos de un miembro
func load_skills(m: Character):
	# Se establece el miembro del que cargar los hechizos
	member = m
	
	# Se crea una fila por cada hechizo y se habilita la selección de esté si se tiene maná suficiente
	for skill in member.skills:
		var row = skill_row.duplicate(true)
		
		skill_list.add_child(row)
		
		var skill_button: Button = row.get_child(0)
		skill_button.text = skill.name
		skill_button.disabled = member.mana < skill.cost
		
		# Se conectan los botones del propio hechizo y su botón '?' a sus respectivos métodos
		skill_button.pressed.connect(_on_skill_selected.bind(skill))
		row.get_child(1).pressed.connect(_on_skill_info_pressed.bind(skill))

## Se ejecuta al seleccionar un hechizo
func _on_skill_selected(skill: Skill):
	MusicPlayer.play_sfx("Click")
	
	# Comprueba para qué objetivo es la skill
	match skill.skill_target:
		# Si es para el propio usuario o todos los aliados, manda la señal con los datos y se destruye
		Skill.Target.SELF, Skill.Target.ALL_ALLIES:
			skill_selected.emit({member: [Entity.Actions.SKILL, member, skill]})
			queue_free()
		
		# Si es para uno o todos los enemigos, manda la señal con los datos y se destruye
		Skill.Target.ENEMY, Skill.Target.ALL_ENEMIES:
			skill_selected.emit({member: [Entity.Actions.SKILL, GameAPI.get_controller().enemy, skill]})
			queue_free()
		
		# Si es para un alidao, carga el selector de objetivos y emite la señal de que está en el selector
		Skill.Target.ALLY:
			var selector = preload("res://scenes/in_game/fight_screen/elements/skill_menu/member_selector.tscn").instantiate()
			add_child(selector)
			on_selector.emit()
			
			# Guarda en una variable el objetivo seleccionado y emite de nuevo la señal anterior para indicar que ya no está en la selección de equipos
			var target = await selector.target_selected
			on_selector.emit()
			
			# Si el objetivo recogido no null, por lo que se seleccionó a alguien, manda una señal con los datos de la acción y se destruye
			if target != null:
				skill_selected.emit({member: [Entity.Actions.SKILL, target, skill]})
				queue_free()

## Se ejecuta al pulsar el botón '?' del hechizo
func _on_skill_info_pressed(skill: Skill):
	MusicPlayer.play_sfx("Click")
	
	# Plasma los datos del hechizo en las variables correspondientes (descripción, poder si es un hechizo de daño o curación, y su coste
	skill_description.text = skill.description
	
	if skill.get("power") != null:
		skill_power.text = "Poder: " + str(skill.power)
	
	skill_cost.text = "Coste: " + str(skill.cost)

## Se ejecuta al pulsar en 'Volver'
func _on_return_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	# Manda una señal con una acción vacía para indicar que se canceló y se destruye
	skill_selected.emit({})
	queue_free()
