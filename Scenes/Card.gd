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



# Called when the node enters the scene tree for the first time.
func _ready():
	get_node()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
