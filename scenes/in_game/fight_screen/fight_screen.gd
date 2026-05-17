extends Control

var actual_mode: Mode
var controller: FightController
var member_turn := 0
var queue: Dictionary
var modifier_sprite: TextureRect

var team: Team
var enemy: Enemy

@onready var bright: ColorRect = $Bright/ColorRect
@onready var background: TextureRect = $Background
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var enemy_sprite: TextureRect = %EnemySprite
@onready var enemy_data := %EnemyData

@onready var team_sprites := %TeamSprites
@onready var team_data := %TeamData
@onready var team_bars := %HealthAndMana

@onready var cursor: Label
@onready var run_button: TextureButton = %Run

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(preload("res://scenes/global_elements/load_screen/load_screen.tscn").instantiate())
	
	await get_tree().process_frame
	modifier_sprite = team_data.get_child(0).get_child(2).get_child(0).duplicate(true)
	
	actual_mode = GameAPI.get_actual_mode()
	
	bright.color.a = GameAPI.get_bright()
	
	controller = GameAPI.get_controller()
	team = controller.team
	enemy = controller.enemy
	
	controller.enemy_defeated.connect(func(_a): 
		enemy = null
		enemy_data.visible = false
		enemy_sprite.visible = false
		)
	
	controller.refresh_data.connect(_load_entity_data)
	controller.animate.connect(_on_animate)
	
	if not GameAPI.prompt.is_connected(_show_prompt):
		GameAPI.prompt.connect(_show_prompt)
	
	if not GameAPI.end_game.is_connected(_on_game_ended):
		GameAPI.end_game.connect(_on_game_ended)
	
	for i in team.members.size():
		var member_sprite: TextureRect = team_sprites.get_child(i).get_child(0)
		member_sprite.texture = team.members[i].sprite
	
	run_button.disabled = actual_mode.mode == Mode.Type.BATTLE
	
	if not actual_mode.next_step.is_connected(_on_continue):
		actual_mode.next_step.connect(_on_continue)
	
	cursor = preload("res://scenes/in_game/fight_screen/elements/cursor/cursor.tscn").instantiate()
	add_child(cursor)
	
	_move_cursor()
	
	actual_mode.start()

func _load_all_data():
	enemy = controller.enemy
	
	if enemy == null or enemy.health == 0:
		enemy_sprite.visible = false
		enemy_data.visible = false
	
	else:
		enemy_sprite.texture = enemy.sprite
		enemy_sprite.visible = true
		enemy_data.visible = true
		
		_load_entity_data(enemy)
	
	for member in team.members:
		_load_entity_data(member)

func _load_entity_data(entity: Entity):
	if entity is Enemy:
		var level: Label = enemy_data.get_child(0).get_child(0)
		var health_bar: TextureProgressBar = enemy_data.get_child(0).get_child(1)
		
		var modifier_list := enemy_data.get_child(1)
		
		for i in modifier_list.get_children():
			i.queue_free()
		
		for i in entity.get_modifiers():
			var modifier = modifier_sprite.duplicate(true)
			modifier_list.add_child(modifier)
			
			modifier.texture = i
		
		level.text = "Lv " + str(entity.level)
		
		health_bar.max_value = entity.max_health
		health_bar.value = entity.health
		
		health_bar.get_child(0).text = str(int(health_bar.value)) + "/" + str(int(health_bar.max_value))
	
	else:
		var id = team.members.find(entity)
		
		var level: Label = team_data.get_child(id).get_child(0)
		var member_name: Label = team_data.get_child(id).get_child(1)
		var health_bar: TextureProgressBar = team_bars.get_child(id).get_child(0)
		var mana_bar: TextureProgressBar = team_bars.get_child(id).get_child(1)
		
		var modifier_list := team_data.get_child(id).get_child(2)
		
		for i in modifier_list.get_children():
			i.queue_free()
		
		for i in team.members[id].get_modifiers():
			var modifier = modifier_sprite.duplicate(true)
			modifier_list.add_child(modifier)
			
			modifier.texture = i
		
		level.text = "Lv " + str(entity.level)
		member_name.text = entity.name
		
		health_bar.max_value = entity.max_health
		health_bar.value = entity.health
		
		mana_bar.max_value = entity.max_mana
		mana_bar.value = entity.mana
		
		health_bar.get_child(0).text = str(int(health_bar.value)) + "/" + str(int(health_bar.max_value))
		mana_bar.get_child(0).text = str(int(mana_bar.value)) + "/" + str(int(mana_bar.max_value))

func _move_cursor():
	var member_sprite = team_sprites.get_child(member_turn).get_child(0)
	cursor.move_to(member_sprite.global_position + Vector2(member_sprite.size.x / 2.3, - 80))

func _on_go_back_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	if member_turn > 0:
		member_turn -= 1
		queue.erase(team.members[member_turn])
	
	_move_cursor()

func _next_turn():
	var allies_alive = -1
	
	for member in team.members:
		if member.health > 0:
			allies_alive += 1
	
	if member_turn == allies_alive:
		cursor.visible = false
		
		await controller.set_queue(queue)
		queue.clear()
		member_turn = 0
		cursor.visible = true
		_move_cursor()
		
	else:
		member_turn += 1
		
		if team.members[member_turn].health <= 0:
			_next_turn()
		
		else:
			_move_cursor()

func _show_prompt(prompt: String, pause: bool):
	var command_prompt = preload("res://scenes/in_game/fight_screen/elements/command_prompt/command_prompt.tscn").instantiate()
	
	add_child(command_prompt)
	
	if animation_player.is_playing():
		command_prompt.disabled = true
		await animation_player.animation_finished
	
	command_prompt.load_prompt(prompt, pause)
	await GameAPI.prompt_end

func _on_attack_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	queue[team.members[member_turn]] = [Entity.Actions.ATTACK, enemy]
	
	_next_turn()

func _on_magic_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	var skill_menu = preload("res://scenes/in_game/fight_screen/elements/skill_menu/skill_menu.tscn").instantiate()
	
	add_child(skill_menu)
	
	skill_menu.on_selector.connect(func(): cursor.visible = not cursor.visible)
	skill_menu.load_skills(team.members[member_turn])
	
	var member_action: Dictionary = await skill_menu.skill_selected
	
	if not member_action.is_empty():
		queue.merge(member_action)
		_next_turn()

func _on_defend_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	queue[team.members[member_turn]] = [Entity.Actions.DEFEND]
	_next_turn()

func _on_run_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	controller.run()
	member_turn = 0
	_move_cursor()

func _on_game_ended(result: GameAPI.Result, text: String):
	MusicPlayer.play_sfx("Click")
	
	
	await _show_prompt(text, true)
	
	match result:
		GameAPI.Result.WIN:
			get_tree().change_scene_to_file("res://scenes/in_game/results/win_screen/win_screen.tscn")
		
		GameAPI.Result.LOSE:
			get_tree().change_scene_to_file("res://scenes/in_game/results/lose_screen/lose_screen.tscn")


func _on_settings_pressed() -> void:
	MusicPlayer.play_sfx("Click")
	
	var settings = preload("res://scenes/global_elements/settings/settings.tscn").instantiate()
	
	add_child(settings)
	
	if not settings.bright_changed.is_connected(func(): bright.color.a = GameAPI.get_bright()):
		settings.bright_changed.connect(func(): bright.color.a = GameAPI.get_bright())
	
	await settings.tree_exited
	bright.color.a = GameAPI.get_bright()

func _on_exit_pressed() -> void:
	var popup = preload("res://scenes/global_elements/confirm_popup/confirm_popup.tscn").instantiate()
	
	add_child(popup)
	
	popup.load_text("Si abandonas la partida, perderás el progreso de la pelea actual y tendrás que\
	 empezarla de nevo")
	
	if await popup.confirm:
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _on_continue():
	match actual_mode.mode:
		Mode.Type.BATTLE:
			MusicPlayer.play_music("Battle mode")
			
			_load_all_data()
		
		Mode.Type.DUNGEON:
			if actual_mode.is_on_map:
				MusicPlayer.play_music("Dungeon mode")
				
				add_child(preload("res://scenes/in_game/fight_screen/elements/map/dungeon_map.tscn").instantiate())
			
			else:
				var room: Room = actual_mode.actual_room
				
				if room.room_type == Room.Type.BOSS:
					MusicPlayer.play_music("Dungeon boss")
				
				else:
					MusicPlayer.play_music("Dungeon mode")
				
				_load_all_data()
				background.texture = room.background

func _on_animate(id: int, type: String, value):
	if GameAPI.get_config().animations:
		var target: String
		var pos: Vector2
		
		var value_label = preload("res://scenes/in_game/fight_screen/elements/healing_damage_tween/healing_damage_tween.tscn").instantiate()
		
		if id == -1:
			target = "enemy"
			pos = enemy_sprite.global_position + Vector2(enemy_sprite.size.x / 1.2, 0)
		else:
			var member_sprite = team_sprites.get_child(id).get_child(0)
			target = "player_" + str(id + 1)
			pos = member_sprite.global_position + Vector2(member_sprite.size.x / 2, 0)
		
		match type:
			"_damaged":
				add_child(value_label)
				
				value_label.start(value, pos, Color.RED)
			
			"_healed":
				add_child(value_label)
				
				value_label.start(value, pos, Color.GREEN)
		
		animation_player.play(target + type)
		await animation_player.animation_finished
		
		if is_instance_valid(value_label):
			await value_label.tree_exited
