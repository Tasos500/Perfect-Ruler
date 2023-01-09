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
var cursor
# Can be boosted through terrain boosts
var tile_speed = 1

# Team based variables
var team
var is_leader = false
var can_move = true
var card_name
var card_id # The ID used to pull data from the database.
var in_attack_position = true
var face_up = false
var last_face_up = false
var revealed = false
var turns_spellbound = 0
var eternally_spellbound = false

# Monster based variables
# Ignored if is_leader == true
var atk = 0
var def = 0
var dc
var attribute
var card_type
var level

# Movement based arrays
# Basically the same as in the cursor
var movement_percentage = 0.0
const move_speed = 8
const tile_size = 150
var initial_position = Vector2(0,0)
var input_direction = Vector2(0,0)
var is_moving = false

# Spawning variables (Porting Tile Indicator code)
var spawning = true
var despawning = false

# Called when the node enters the scene tree for the first time.
func _ready():
	cursor = get_parent().get_node("Cursor")
	grid_x = cursor.grid_x
	grid_y = cursor.grid_y
	position = cursor.position
	team = cursor.team
	
	get_node("Card_Back").modulate.a8 = 0
	get_node("Card_Front_Frame").modulate.a8 = 0
	
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


func spellbind(turns):
	if turns == -1:
		eternally_spellbound = true
		turns_spellbound = 99
	else:
		turns_spellbound = turns

func spellbind_decrement():
	if !eternally_spellbound:
		turns_spellbound -= 1
		if turns_spellbound == 0:
			spellbind_cure()

func spellbind_cure():
	eternally_spellbound = false
	turns_spellbound = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !is_moving:
		initial_position = position
	elif input_direction != Vector2.ZERO:
		move(delta)
	else:
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
	
	if face_up != last_face_up:
		if !face_up:
			$Card_Front_Frame.hide()
			$Card_Back.show()
		else:
			$Card_Front_Frame.show()
			$Card_Back.hide()
			# Checks to display correct type of card
			if card_type == (card_types.MAGIC or card_types.POWER_UP or card_types.RITUAL):
				$Card_Front_Frame.animation = "Spell"
				$Card_Front_Frame/ATK.hide()
				$Card_Front_Frame/DEF.hide()
			elif card_type == (card_types.TRAP_FULL or card_types.TRAP_LIMITED):
				$Card_Front_Frame.animation = "Trap"
				$Card_Front_Frame/ATK.hide()
				$Card_Front_Frame/DEF.hide()
			else:
				$Card_Front_Frame.animation = "Monster_Normal"
				$Card_Front_Frame/ATK.show()
				$Card_Front_Frame/DEF.show()
		last_face_up = face_up
	
	if spawning:
		if get_node("Card_Back").modulate.a8 <= 255:
			get_node("Card_Back").modulate.a8 += 400 * delta
			get_node("Card_Front_Frame").modulate.a8 += 400 * delta
			if get_node("Card_Back").modulate.a8 >= 255:
				 spawning = false
	
	if despawning and !spawning:
		can_move = false
		if get_node("Card_Back").modulate.a8 >= 0:
			get_node("Card_Back").modulate.a8 -= 400 * delta
			get_node("Card_Front_Frame").modulate.a8 -= 400 * delta
			if get_node("Card_Back").modulate.a8 <= 0:
				queue_free()
	
	
	
	# Commented out until upgraded to Godot 4.0
	# Turns spellbound cards inverted
	# BUG: Makes EVERY card inverted. Godot 4.0 fixes that with instanced shader variables
	#material.set_shader_param("spellbound", turns_spellbound)
	
	
