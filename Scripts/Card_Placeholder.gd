extends Node2D

# 0 = Red, 1 = White
# Red always goes first in a duel
enum color {RED, WHITE}

# Enums on all possible variables a card can have
enum attributes {LIGHT, DARK, FIRE, EARTH, WATER, WIND}
enum card_types {DRAGON, SPELLCASTER, ZOMBIE, WARRIOR, BEAST_WARRIOR, BEAST, WINGED_BEAST, FIEND, FAIRY, INSECT, DINOSAUR, REPTILE, FISH, SEA_SERPENT, MACHINE, THUNDER, AQUA, PYRO, ROCK, PLANT, IMMORTAL, MAGIC, POWER_UP, TRAP_LIMITED, TRAP_FULL, RITUAL}
const triggers = ["passive", "battle_engagement", "flipped_face_up", "flipped_face_up_battle", "standby_face_up_defense", "movement_triggers_limited_trap", "damage_received", "battle_flipped_face_up", "flipped_face_up_voluntarily", "destroyed_battle", "destroyed", "opponent_is_x", "standby_counter_x", "moves_terrain_x", "moves_tile", "moves_per_turn", "opponent_destroyed", "standby_face_up", "flipped_face_up_card_played", "lp_over_x", "lp_equal_to_x", "lp_under_x", "leader_is_x", "adjacent_x", "turn_controller"]
const effects = ["battle_bonus_temporary", "battle_bonus_temporary_atk", "battle_bonus_temporary_def", "transform_terrain_current", "transform_terrain_range_x_distance", "transform_terrain_range_x_square", "terrain_immunity", "transform_to_x", "stat_change_x", "stat_change_x_atk", "stat_change_x_def", "stat_change_highest", "stat_change_highest_atk", "stat_change_highest_def", "stat_set_x_atk", "stat_set_x_def", "stat_set_x_to_y_times_num_z_graveyards", "spellbind", "spellbind_eternal", "effect_prevent_activation", "destroy", "battle_one_sided_destruction", "lp_own_change_x", "lp_own_set_x", "lp_own_set_up_to_x", "lp_own_multiply_x", "lp_own_divide_x", "lp_enemy_change_x", "lp_enemy_set_x", "lp_enemy_multiply_x", "lp_enemy_divide_x", "lp_enemy_set_up_to_x", "revive_type_x", "teleport_summoning_area", "power_up_effect_change_x", "power_up_effect_multiply_x", "power_up_effect_divide_x", "flip_face_up", "flip_face_down", "game_win", "game_lose", "battle_damage_set_x", "summon_power_change_x", "summon_power_set_x", "stat_change_nullify", "move_labyrinth", "summon_x", "prevent_revival", "banish_x_deck", "banish_x_hand", "banish_x_graveyard", "return_x_deck", "allow_card_play", "reveal_x_card_y_stat", "cannot_move", "movement_bonus_cancel", "change_controller", "change_controller_temporary"]
const targets = ["card_self", "opponent", "cards_all", "cards_own", "cards_enemy", "controller", "enemy", "leader_own", "leader_enemy", "range_x", "row_current", "row_x", "line_current", "line_x", "monsters", "magics", "powerups", "rituals", "traps", "traps_limited", "traps_full", "trap_activator", "card_type"]

# Position
var grid_x
var grid_y
var cursor
# Can be boosted through terrain boosts
var tile_speed = 1

# Team based variables
var team
var is_leader = false
var can_move = true
var card_name = "Dummy"
var card_id = null # The ID used to pull data from the database.
var in_attack_position = true
var face_up = false
var last_face_up = false
var revealed = false
var turns_spellbound = 0
var eternally_spellbound = false
var just_spellbound = false
var just_flipped = false
var spellbound_counter

# Monster based variables
# Ignored if is_leader == true
var atk = 0
var atk_base = 0
var def = 0
var def_base = 0
var dc
var attribute
var card_type
var level
var toon = false
var effect_list = []
var modifier_stat = 0
var modifier_atk = 0
var modifier_def = 0
var modifier_terrain = 0
var battle_atk = 0
var battle_def = 0

# Movement based arrays
# Basically the same as in the cursor
var movement_percentage = 0.0
const move_speed = 8
const tile_size = 150
var initial_position = Vector2(0,0)
var input_direction = Vector2(0,0)
var is_moving = false
var has_moved = false
var flipping = false
var rotating = false
var original_face_up = false
var original_attack_position = false

# Spawning variables (Porting Tile Indicator code)
var spawning = true
var despawning = false
var last_card_id = null
var default_card_art = preload("res://Assets/Card/CardArtTemplate.png")

onready var board = $".."

# Called when the node enters the scene tree for the first time.
func _ready():
	cursor = get_parent().get_node("Cursor")
	grid_x = cursor.grid_x
	grid_y = cursor.grid_y
	position = cursor.position
	team = cursor.team
	if team == color.WHITE:
		rotation_degrees = 180
	modulate.a8 = 8
	get_node("Card_Front_Frame").modulate.a8 = 0
	
func move(delta):
	if can_move:
		movement_percentage += move_speed * delta
		if movement_percentage >= 1.0:
			position = initial_position + (tile_size * input_direction)
			movement_percentage = 0.0
			is_moving = false
			initial_position = position
			grid_x += input_direction.x
			grid_y += input_direction.y
			input_direction = Vector2.ZERO
			board.check_adjacent_tiles_for_limited_trap(grid_x, grid_y)
		else:
			position = initial_position + (tile_size * input_direction * movement_percentage)

func data_copy():
	return [team, atk, def, dc, attribute, card_type, level, face_up, last_face_up, in_attack_position, revealed, turns_spellbound, eternally_spellbound, just_spellbound, tile_speed, has_moved, can_move]

func data_paste(data):
	team = data[0]
	atk = data[1]
	def = data[2]
	dc = data[3]
	attribute = data[4]
	card_type = data[5]
	level = data[6]
	face_up = false
	last_face_up = false
	in_attack_position = data[9]
	revealed = false
	turns_spellbound = data[11]
	eternally_spellbound = data[12]
	just_spellbound = data[13]
	tile_speed = data[14]
	has_moved = data[15]
	can_move =  data[16]

func spellbind(turns):
	has_moved = true
	if turns == -1:
		eternally_spellbound = true
		turns_spellbound = 99
	else:
		turns_spellbound = turns
	just_spellbound = true

func spellbind_decrement():
	if !eternally_spellbound:
		if !just_spellbound:
			turns_spellbound -= 1
			if turns_spellbound <= 0:
				spellbind_cure()

func is_spellbound():
	return(eternally_spellbound or turns_spellbound != 0)

func spellbind_cure():
	eternally_spellbound = false
	turns_spellbound = 0

func flip():
	if face_up: 
		if get_node("%Card_Front_Frame").modulate.a8 != 255:
			get_node("%Card_Front_Frame").modulate.a8 += 17
		else:
			flipping = false
	else:
		if get_node("%Card_Front_Frame").modulate.a8 != 0:
			get_node("%Card_Front_Frame").modulate.a8 -= 17
		else:
			flipping = false
	

func update_stats():
	if !is_leader:
		atk = atk_base + 300*modifier_terrain + modifier_atk + modifier_stat
		$Card_Front_Frame/ATK.text = str(atk)
		def = def_base + 300*modifier_terrain + modifier_def + modifier_stat
		$Card_Front_Frame/DEF.text = str(def)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !is_moving:
		initial_position = position
	elif input_direction != Vector2.ZERO:
		move(delta)
	else:
		is_moving = false
	if rotating and !is_leader:
		if in_attack_position:
			if team == color.RED:
				if rotation_degrees >= 5:
					rotation_degrees -= 5
				else:
					rotation_degrees = 0
			else:
				if rotation_degrees >= 185:
					rotation_degrees -= 5
				else:
					rotation_degrees = 180
			if (rotation_degrees == 0 and team == color.RED) or (rotation_degrees == 180 and team == color.WHITE):
				rotating = false
		else:
			if team == color.RED:
				if rotation_degrees <= 90:
					rotation_degrees += 5
				else:
					rotation_degrees = 90
			else:
				if rotation_degrees <= 270:
					rotation_degrees += 5
				else:
					rotation_degrees = 270
			if (rotation_degrees == 90 and team == color.RED) or (rotation_degrees == 270 and team == color.WHITE):
				rotating = false
	
	if flipping and !is_leader:
		flip()
	
	if face_up != last_face_up and !is_leader:
		if face_up:
			# Checks to display correct type of card
			if (card_type == card_types.MAGIC) or (card_type == card_types.POWER_UP) or (card_type == card_types.RITUAL):
				$Card_Front_Frame.animation = "Spell"
				$Card_Front_Frame/ATK.hide()
				$Card_Front_Frame/DEF.hide()
			elif card_type == (card_types.TRAP_FULL) or (card_type == card_types.TRAP_LIMITED):
				$Card_Front_Frame.animation = "Trap"
				$Card_Front_Frame/ATK.hide()
				$Card_Front_Frame/DEF.hide()
			else:
				$Card_Front_Frame/ATK.show()
				$Card_Front_Frame/DEF.show()
		last_face_up = face_up
		
	
	if spawning:
		if modulate.a8 <= 255:
			modulate.a8 += 450 * delta
			#get_node("Card_Front_Frame").modulate.a8 += 400 * delta
			if modulate.a8 >= 255:
				 spawning = false
	
	if despawning and !spawning:
		can_move = false
		if modulate.a8 >= 0:
			modulate.a8 -= 450 * delta
			get_node("Card_Front_Frame").modulate.a8 -= 450 * delta
			if modulate.a8 <= 0:
				queue_free()
	
	if card_id != last_card_id:
		card_name = board.get_card_data(card_id)["name"]
		$Card_Front_Frame/Card_Name.text = str(card_name)
		card_type = card_types.get(board.get_card_data(card_id)["card_type"])
		if card_type != card_types.MAGIC and \
		card_type != card_types.POWER_UP and \
		card_type != card_types.TRAP_FULL and \
		card_type != card_types.TRAP_LIMITED and \
		card_type != card_types.RITUAL:
			atk_base = board.get_card_data(card_id)["atk"]
			atk = atk_base
			$Card_Front_Frame/ATK.text = str(atk)
			def_base = board.get_card_data(card_id)["def"]
			def = def_base
			$Card_Front_Frame/DEF.text = str(def)
			level = board.get_card_data(card_id)["level"]
			$Card_Front_Frame/Level.frame = level
			toon = board.get_card_data(card_id)["toon"]
		else:
			level = 0
		dc = board.get_card_data(card_id)["dc"]
		if "attribute" in board.get_card_data(card_id):
			attribute = attributes.get(board.get_card_data(card_id)["attribute"])
			$Card_Front_Frame/Attribute.frame = attribute
		else:
			get_node("%Attribute").hide()
		get_node("%ATK").hide()
		get_node("%DEF").hide()
		get_node("%Level").hide()
		if card_type == card_types.MAGIC or card_type == card_types.RITUAL or card_type == card_types.POWER_UP:
			get_node("%Card_Front_Frame").animation = "Spell"
			$Card_Front_Frame/Attribute.frame = 6
			get_node("%Attribute").show()
		elif card_type == card_types.TRAP_FULL or card_type == card_types.TRAP_LIMITED:
			get_node("%Card_Front_Frame").animation = "Trap"
			$Card_Front_Frame/Attribute.frame = 7
			get_node("%Attribute").show()
		elif "effects" in board.get_card_data(card_id):
			get_node("%Card_Front_Frame").animation = "Monster_Effect"
			get_node("%ATK").show()
			get_node("%DEF").show()
			get_node("%Level").show()
			get_node("%Attribute").show()
		else:
			get_node("%Card_Front_Frame").animation = "Monster_Normal"
			get_node("%ATK").show()
			get_node("%DEF").show()
			get_node("%Level").show()
			get_node("%Attribute").show()
		if "effects" in board.get_card_data(card_id):
			effect_list = board.get_card_data(card_id)["effects"]
		last_card_id = card_id
		
		#Grabbing card art texture
		var split_id = card_id.split(".")
		var file_png = "user://addons/" + split_id[0] + "/" + split_id[1] + "/cards/" + split_id[2] + ".png"
		var file_jpg = "user://addons/" + split_id[0] + "/" + split_id[1] + "/cards/" + split_id[2] + ".jpg"
		var file_jpeg = "user://addons/" + split_id[0] + "/" + split_id[1] + "/cards/" + split_id[2] + ".jpeg"
		var file = File.new()
		var file_location
		if file.file_exists(file_png):
			file_location = file_png
		elif file.file_exists(file_jpg):
			file_location = file_jpg
		elif file.file_exists(file_jpeg):
			file_location = file_jpeg
		else:
			get_node("%Card_Art").texture = default_card_art
			return
		file = Image.new()
		file.load(file_location)
		var new_texture = ImageTexture.new()
		new_texture.create_from_image(file)
		get_node("%Card_Art").texture = new_texture
	
	update_stats()
	
	if !spawning and !despawning:
		cursor.process_card_terrain(name)
	
	if is_leader:
		face_up = true
		revealed = true
		if team == color.RED:
			$Card_Back.texture = load("res://Assets/Card/Leader_Red.png")
			#card_id = "Tasos500.TestMod.294"
		else:
			$Card_Back.texture = load("res://Assets/Card/Leader_White.png")
		$Card_Back.scale = Vector2(150/128, 150/128) # Scaled for 150x150 tiles, as cards are normally shrunk to 25%
	
	if !face_up:
		spellbound_counter = get_node("Spellbound Counter Front")
		get_node("Spellbound Counter Back").hide()
	else:
		spellbound_counter = get_node("Spellbound Counter Back")
		get_node("Spellbound Counter Front").hide()
			
	if turns_spellbound != 0 and !is_leader:
			spellbound_counter.show()
			if eternally_spellbound:
				spellbound_counter.text = "∞"
			else:
				spellbound_counter.text = str(turns_spellbound)
	else:
		spellbound_counter.hide()
	
	# Commented out until upgraded to Godot 4.0
	# Turns spellbound cards inverted
	# BUG: Makes EVERY card inverted. Godot 4.0 fixes that with instanced shader variables
	#material.set_shader_param("spellbound", turns_spellbound)
	
	
