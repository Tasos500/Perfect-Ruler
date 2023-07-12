extends CanvasLayer

enum color {RED, WHITE}
enum attributes {LIGHT, DARK, FIRE, EARTH, WATER, WIND}
enum card_types {DRAGON, SPELLCASTER, ZOMBIE, WARRIOR, BEAST_WARRIOR, BEAST, WINGED_BEAST, FIEND, FAIRY, INSECT, DINOSAUR, REPTILE, FISH, SEA_SERPENT, MACHINE, THUNDER, AQUA, PYRO, ROCK, PLANT, IMMORTAL, MAGIC, POWER_UP, TRAP_LIMITED, TRAP_FULL, RITUAL}
enum terrain {NORMAL, FOREST, WASTELAND, MOUNTAIN, SEA, DARK, TOON, CRUSH, LABYRINTH}
const card_types_text = ["DRAGON", "SPELLCASTER", "ZOMBIE", "WARRIOR", "BEAST_WARRIOR", "BEAST", "WINGED_BEAST", "FIEND", "FAIRY", "INSECT", "DINOSAUR", "REPTILE", "FISH", "SEA_SERPENT", "MACHINE", "THUNDER", "AQUA", "PYRO", "ROCK", "PLANT", "IMMORTAL", "MAGIC", "POWER-UP", "TRAP (LIMITED)", "TRAP (FULL)", "RITUAL"]
const terrain_text = ["NORMAL", "FOREST", "WASTELAND", "MOUNTAIN", "SEA", "DARK", "TOON", "CRUSH", "LABYRINTH"]

var movement_percentage = 0.0
var move_speed = 1000
var initial_position = offset
var input_direction = Vector2(0,-1)
var is_moving = true
var can_move = false
var going_down = false
var hud_active = true
onready var board = get_node("../..")
onready var cursor = get_node("../../Cursor")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	initialize()


func move(delta):
	movement_percentage += 3 * delta
	if movement_percentage >= 1.0:
		offset = initial_position + (150 * input_direction)
		movement_percentage = 0.0
		is_moving = false
		going_down = !going_down
		initial_position = offset
	else:
		offset = initial_position + (150 * input_direction * movement_percentage)

func initialize(): # A bodge
	get_node("%Card_Name").show()
	get_node("%Card_Name").text = "Red Leader"
	get_node("%Type").hide()
	get_node("%Attribute").hide()
	get_node("%Effect").hide()
	get_node("%ATK").hide()
	get_node("%DEF").hide()
	get_node("%SB_Count").hide()
	get_node("%SB_Label").hide()
	get_node("Backgound").show()
	get_node("Terrain").text = "Terrain\n" + terrain_text[$"../../TileMap".get_cell(cursor.grid_x, cursor.grid_y)]
	get_node("%Movement_Boost").hide()
	get_node("%Terrain_Boost").hide()

func update(card):
	get_node("Backgound/ColorRect").show()
	get_node("Terrain").text = "Terrain\n" + terrain_text[$"../../TileMap".get_cell(cursor.grid_x, cursor.grid_y)]
	if card == null:
		get_node("%Card_Name").hide()
		get_node("%ATK").hide()
		get_node("%DEF").hide()
		get_node("%SB_Count").hide()
		get_node("%SB_Label").hide()
		get_node("%Type").hide()
		get_node("%Effect").hide()
		get_node("%Attribute").hide()
		get_node("Backgound/ColorRect").hide()
		get_node("%Movement_Boost").hide()
		get_node("%Terrain_Boost").hide()
		return
	elif !card.is_leader:
		get_node("%Card_Name").show()
		get_node("%Type").show()
		if !card.card_type == null:
			get_node("%Type").text = str(card_types_text[card.card_type])
		get_node("%Attribute").show()
	else:
		get_node("%Card_Name").show()
		if card.team == color.RED:
			get_node("%Card_Name").text = "Red Leader"
		else:
			get_node("%Card_Name").text = "White Leader"
		get_node("%Type").hide()
		get_node("%Attribute").hide()
		get_node("%Effect").hide()
		get_node("%ATK").hide()
		get_node("%DEF").hide()
		get_node("%Movement_Boost").hide()
		get_node("%Terrain_Boost").hide()
		return
	if card.team == cursor.team:
		get_node("%Card_Name").text = str(card.card_name)
		if (card.card_type == card_types.MAGIC) or (card.card_type == card_types.POWER_UP) or (card.card_type == card_types.RITUAL):
			get_node("%Attribute").frame = 6
		elif (card.card_type == card_types.TRAP_FULL) or (card.card_type == card_types.TRAP_LIMITED):
			get_node("%Attribute").frame = 7
		else: # It's a monster
			get_node("%ATK").show()
			get_node("%ATK").text = "A " + str(card.atk)
			get_node("%DEF").show()
			get_node("%DEF").text = "D " + str(card.def)
			if !card.attribute == null:
				get_node("%Attribute").frame = card.attribute
			if card.effect_list != []:
				get_node("%Effect").show()
		if card.turns_spellbound != 0:
			get_node("%SB_Count").show()
			get_node("%SB_Count").text = str(card.turns_spellbound)
			get_node("%SB_Label").show()
			if card.eternally_spellbound:
				get_node("%SB_Count").text = str("∞")
		if card.tile_speed > 1:
			get_node("%Movement_Boost").show()
		else:
			get_node("%Movement_Boost").hide()
		if card.modifier_terrain > 0:
			get_node("%Terrain_Boost").show()
			get_node("%Terrain_Boost").text = "T+"
		elif card.modifier_terrain < 0:
			get_node("%Terrain_Boost").show()
			get_node("%Terrain_Boost").text = "T-"
		else:
			get_node("%Terrain_Boost").hide()
	else:
		if card.is_leader:
			get_node("%Card_Name").show()
			if card.team == color.RED:
				get_node("%Card_Name").text = "Red Leader"
			else:
				get_node("%Card_Name").text = "White Leader"
			get_node("%Type").hide()
			get_node("%Attribute").hide()
			get_node("%Effect").hide()
			get_node("%ATK").hide()
			get_node("%DEF").hide()
			return
		else:
			if card.face_up: #The same as a friendly card. It's revealed.
					get_node("%Card_Name").text = str(card.card_name)
					if (card.card_type == card_types.MAGIC) or (card.card_type == card_types.POWER_UP) or (card.card_type == card_types.RITUAL):
						get_node("%Attribute").frame = 6
					elif (card.card_type == card_types.TRAP_FULL) or (card.card_type == card_types.TRAP_LIMITED):
						get_node("%Attribute").frame = 7
					else: # It's a monster
						get_node("%ATK").show()
						get_node("%ATK").text = "A " + str(card.atk)
						get_node("%DEF").show()
						get_node("%DEF").text = "D " + str(card.def)
						get_node("%Attribute").frame = card.attribute
						if card.effect_list != []:
							get_node("%Effect").show()
					if card.turns_spellbound != 0:
						get_node("%SB_Count").show()
						get_node("%SB_Count").text = str(card.turns_spellbound)
						get_node("%SB_Label").show()
						if card.eternally_spellbound:
							get_node("%SB_Count").text = str("∞")
					if card.modifier_terrain > 0:
						get_node("%Terrain_Boost").show()
						get_node("%Terrain_Boost").text = "T+"
					elif card.modifier_terrain < 0:
						get_node("%Terrain_Boost").show()
						get_node("%Terrain_Boost").text = "T-"
					else:
						get_node("%Terrain_Boost").hide()
			else:
				get_node("%Card_Name").show()
				get_node("%Card_Name").text = "?????"
				get_node("%ATK").hide()
				get_node("%DEF").hide()
				get_node("%SB_Count").hide()
				get_node("%SB_Label").hide()
				get_node("%Type").show()
				get_node("%Type").text = "?????"
				get_node("%Effect").hide()
				get_node("%Attribute").hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_moving:
		input_direction.y = int(-1 + 2 * int(going_down))
		move(delta)
		
