extends Node2D

# 0 = Red, 1 = White
# Red always goes first in a duel
enum color {RED, WHITE}

# Enums on all possible variables a card can have
enum attributes {DARK, DIVINE, EARTH, FIRE, LIGHT, WATER, WIND}
enum card_types {MONSTER, SPELL, TRAP, POWER_UP}
# If it's a MONSTER, it should have one of the following monster types:
enum monster_types {NULL, AQUA, BEAST, BEAST_WARRIOR, DINOSAUR, DRAGON, FAIRY, FIEND, FISH, INSECT, MACHINE, PLANT, PYRO, REPTILE, ROCK, SEA_SERPENT, SPELLCASTER, WARRIOR, WINGED_BEAST, ZOMBIE}

# Position
var grid_x
var grid_y
var cursor
# Can be boosted through terrain boosts
var tile_speed = 1

# Team based variables
var team
var is_leader
var can_move
var card_name

# Monster based variables
# Ignored if is_leader == true
var atk = 0
var def = 0
var attribute
var card_type
var monster_type = monster_types.NULL
var level

# Movement based arrays
# Basically the same as in the cursor
var movement_percentage = 0.0
const move_speed = 8
const tile_size = 150
var initial_position = Vector2(0,0)
var input_direction = Vector2(0,0)
var is_moving = false

# Called when the node enters the scene tree for the first time.
func _ready():
	cursor = get_parent().get_node("Cursor")
	grid_x = cursor.grid_x
	grid_y = cursor.grid_y
	position = cursor.position
	team = cursor.team
	is_leader = false
	pass
	
func move(delta):
	movement_percentage += move_speed * delta
	if movement_percentage >= 1.0:
		position = initial_position + (tile_size * input_direction)
		movement_percentage = 0.0
		is_moving = false
		initial_position = position
	else:
		position = initial_position + (tile_size * input_direction * movement_percentage)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !is_moving:
		initial_position = position
	elif input_direction != Vector2.ZERO:
		move(delta)
	else:
		is_moving = false
