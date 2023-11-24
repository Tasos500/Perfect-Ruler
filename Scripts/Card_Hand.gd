extends Node2D

# 0 = Red, 1 = White
# Red always goes first in a duel
enum color {RED, WHITE}

# Enums on all possible variables a card can have
enum attributes {LIGHT, DARK, FIRE, EARTH, WATER, WIND}
enum card_types {DRAGON, SPELLCASTER, ZOMBIE, WARRIOR, BEAST_WARRIOR, BEAST, WINGED_BEAST, FIEND, FAIRY, INSECT, DINOSAUR, REPTILE, FISH, SEA_SERPENT, MACHINE, THUNDER, AQUA, PYRO, ROCK, PLANT, IMMORTAL, MAGIC, POWER_UP, TRAP_LIMITED, TRAP_FULL, RITUAL}

# Position
var grid_x
var grid_y
# Can be boosted through terrain boosts
var tile_speed = 1

# Team based variables
var team
var is_leader = false
var can_move = true
var card_name = "Dummy"
var card_id = null # The ID used to pull data from the database.
var in_attack_position = true
var face_up = true
var last_face_up = false
var revealed = false
var turns_spellbound = 0
var eternally_spellbound = false
var just_spellbound = false

# Monster based variables
# Ignored if is_leader == true
var atk = 0
var atk_base = 0
var def = 0
var def_base = 0
var dc
var attribute
var card_type
var level = 0
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
var is_moving_to_hand = false
var default_position
var center_position = Vector2(1280/2, 960/2)
var is_moving_to_center = false
var is_moving_down = false
var is_moving_up = false
var is_moving_to_default = false
var is_moving_horizontally = false
var horizontal_distance
var position_confirm
var is_knocked_offscreen = false
var is_first_in_queue = false
var is_second_in_queue = false
var touching_final = false
var is_moving_to_first = false
var is_moving_to_field = false
var has_moved_card = false

# Spawning variables (Porting Tile Indicator code)
var spawning = true
var despawning = false
var last_card_id = null
var default_card_art = preload("res://Assets/Card/CardArtTemplate.png")

onready var board = $"../../.."
onready var hand = $".."
onready var hud = $"../.."
onready var cursor = board.get_node("Cursor")
#HUD is always a child of Board, so this will always point to the Board for Hand Cards.

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Card_Back").modulate.a8 = 255
	get_node("Card_Front_Frame").modulate.a8 = 255
	default_position = position
	
func move(delta):
	if can_move:
		movement_percentage += move_speed * delta
		if movement_percentage >= 1.0:
			position = initial_position + (tile_size * input_direction)
			movement_percentage = 0.0
			is_moving = false
			initial_position = position
		else:
			position = initial_position + (tile_size * input_direction * movement_percentage)

func move_to_hand(delta):
	if can_move:
		movement_percentage += 10 * delta
		if movement_percentage >= 1.0:
			position = initial_position + (1280 * Vector2(-1,0))
			movement_percentage = 0.0
			is_moving_to_hand = false
			has_moved = true
			initial_position = position
		else:
			position = initial_position + (1280 * Vector2(-1,0) * movement_percentage)

func move_to_center(delta):
	if can_move:
		movement_percentage += 8 * delta
		if movement_percentage >= 1.0:
			position = initial_position + ((center_position - initial_position).abs() * input_direction)
			movement_percentage = 0.0
			is_moving_to_center = false
			has_moved = true
			initial_position = position
		else:
			position = initial_position + ((center_position - initial_position).abs() * input_direction * movement_percentage)

func move_to_default(delta):
	if can_move:
		movement_percentage += 8 * delta
		if movement_percentage >= 1.0:
			position = initial_position + ((default_position - initial_position).abs() * input_direction)
			movement_percentage = 0.0
			is_moving_to_default = false
			has_moved = true
			initial_position = position
		else:
			position = initial_position + ((default_position - initial_position).abs() * input_direction * movement_percentage)

func move_down(delta):
	if can_move:
		movement_percentage += 8 * delta
		if movement_percentage >= 1.0:
			position = initial_position + (1000 * Vector2(0,1))
			movement_percentage = 0.0
			is_moving_down = false
			has_moved = true
			initial_position = position
		else:
			position = initial_position + (1000 * Vector2(0,1) * movement_percentage)

func move_up(delta):
	if can_move:
		movement_percentage += 8 * delta
		if movement_percentage >= 1.0:
			position = initial_position + (1000 * Vector2(0,-1))
			movement_percentage = 0.0
			is_moving_up = false
			has_moved = true
			initial_position = position
		else:
			position = initial_position + (1000 * Vector2(0,-1) * movement_percentage)

func move_horizontally(delta):
	if can_move:
		movement_percentage += 8 * delta
		if movement_percentage >= 1.0:
			position = initial_position + (horizontal_distance * input_direction)
			movement_percentage = 0.0
			is_moving_horizontally = false
			has_moved = true
			initial_position = position
			position_confirm = position
		else:
			position = initial_position + (horizontal_distance * input_direction * movement_percentage)

func knock_offscreen(delta):
	if can_move:
		movement_percentage += 5* delta
		if movement_percentage >= 1.0:
			position = initial_position + (500 * Vector2(-1, -0.8))
			rotation_degrees = -80
			movement_percentage = 0.0
			is_knocked_offscreen = false
			has_moved = true
			initial_position = position
			position_confirm = position
			board.add_to_graveyard(card_id)
			despawning = true
		else:
			position = initial_position + (500 * Vector2(-1, -0.8) * movement_percentage)
			rotation_degrees =  0 - 80 * movement_percentage

func move_to_first(delta):
	if can_move:
		movement_percentage += 8 * delta
		if movement_percentage >= 1.0:
			position = initial_position + (1280/4 * Vector2(-1, 0))
			movement_percentage = 0.0
			is_moving_to_first = false
			has_moved = true
			initial_position = position
		elif movement_percentage >= 0.8 and !touching_final and !hand.valid_fusion and !hand.valid_power_up:
			touching_final = true
			hand.fusion1.is_knocked_offscreen = true
			hand.fusion1.has_moved = false
		else:
			position = initial_position + (1280/4 * Vector2(-1, 0) * movement_percentage)

func move_to_field(delta):
	if can_move:
		movement_percentage += 4 * delta
		if movement_percentage >= 1.0:
			position = initial_position + (1280/4 * Vector2(1, 0))
			scale = Vector2(1, 1)
			movement_percentage = 0.0
			is_moving_to_field = false
			initial_position = position
			team = cursor.team
			board.create_card(cursor.grid_x, cursor.grid_y)
			board.get_node(board.get_card(cursor.grid_x, cursor.grid_y)).card_id = card_id
			hand.final_card = data_copy()
			despawning = true
			hand.reset_start = true
			hand.remove_child(self)
			board.add_child(self)
			position = $"../Cursor".position
			if $"../Cursor".team == 1:
				rotation_degrees = 180
			update_stats()
			get_node("../HUD/HUD_Bottom").update(self)
		else:
			position = initial_position + (1280/4 * Vector2(1, 0) * movement_percentage)
			scale = Vector2(2, 2) + (Vector2(-1, -1) * movement_percentage)

func is_in_center():
	if position == Vector2(1280/2, 960/2):
		return true
	else:
		return false

func data_copy():
	return [team, atk, def, dc, attribute, card_type, level, face_up, last_face_up, in_attack_position, revealed, turns_spellbound, eternally_spellbound, just_spellbound, tile_speed, has_moved_card, can_move, effect_list, modifier_stat, modifier_atk, modifier_def]

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
	has_moved_card = data[15]
	can_move =  data[16]
	effect_list = data[17]
	modifier_stat = data[18]
	modifier_atk = data[19]
	modifier_def = data[20]
	

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

func update_stats():
	if !is_leader:
		atk = atk_base + 300*modifier_terrain + modifier_atk + modifier_stat + battle_atk
		$Card_Front_Frame/ATK.text = str(atk)
		def = def_base + 300*modifier_terrain + modifier_def + modifier_stat + battle_def
		$Card_Front_Frame/DEF.text = str(def)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_moving_to_hand and !has_moved and !is_moving:
		move_to_hand(delta)
		is_moving = false
	elif is_moving_to_center and !has_moved and !is_moving:
		move_to_center(delta)
		is_moving = false
	elif is_moving_down and !has_moved and !is_moving:
		move_down(delta)
		is_moving = false
	elif is_moving_up and !has_moved and !is_moving:
		move_up(delta)
		is_moving = false
	elif is_moving_to_default and !has_moved and !is_moving:
		move_to_default(delta)
		is_moving = false
	elif is_moving_horizontally and !has_moved and !is_moving:
		move_horizontally(delta)
		is_moving = false
	elif is_knocked_offscreen and !has_moved and !is_moving:
		knock_offscreen(delta)
		is_moving = false
	elif is_moving_to_first and !has_moved and !is_moving:
		move_to_first(delta)
		is_moving = false
	elif is_moving_to_field and !has_moved and !is_moving:
		move_to_field(delta)
		is_moving = false
	if in_attack_position:
		if team == color.RED:
			if rotation_degrees > 5:
				rotation_degrees -= 5
		else:
			if rotation_degrees > 185:
				rotation_degrees -= 5
	else:
		if team == color.RED:
			if rotation_degrees < 90:
				rotation_degrees += 5
		else:
			if rotation_degrees < 270:
				rotation_degrees += 5
	
	if face_up != last_face_up and !is_leader:
		if !face_up:
			$Card_Front_Frame.hide()
			$Card_Back.show()
		else:
			$Card_Front_Frame.show()
			$Card_Back.hide()
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
				$Card_Front_Frame.animation = "Monster_Normal"
				$Card_Front_Frame/ATK.show()
				$Card_Front_Frame/DEF.show()
		last_face_up = face_up
		
	
	if spawning:
		get_node("Card_Back").modulate.a8 = 255
		spawning = false
	
	if despawning and !spawning:
		can_move = false
		if get_node("Card_Back").modulate.a8 >= 0:
			get_node("Card_Back").modulate.a8 -= 400 * delta
			get_node("Card_Front_Frame").modulate.a8 -= 400 * delta
			if get_node("Card_Back").modulate.a8 <= 0:
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
	
	if is_leader:
		face_up = true
		revealed = true
		if team == color.RED:
			$Card_Back.texture = load("res://Assets/Card/Leader_Red.png")
			#card_id = "Tasos500.TestMod.294"
		else:
			$Card_Back.texture = load("res://Assets/Card/Leader_White.png")
		$Card_Back.scale = Vector2(150/128, 150/128) # Scaled for 150x150 tiles, as cards are normally shrunk to 25%
	
	
	
	# Commented out until upgraded to Godot 4.0
	# Turns spellbound cards inverted
	# BUG: Makes EVERY card inverted. Godot 4.0 fixes that with instanced shader variables
	#material.set_shader_param("spellbound", turns_spellbound)
	
	



