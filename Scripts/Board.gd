extends Node2D

var matrix

# Ensures effects that trigger at start of turn occur by the oldest card first, and can be used as a general array for checking every card. Cards are popped when destroyed.
var card_age = []

#Decks have exactly 40 cards. These will contain pointers to the databases.
var deck_red = []
var deck_white = []

var lp_red = 4000
var lp_white = 4000

# Cards popped from card_age end up here, and are public to both players.
var graveyard_red = []
var graveyard_white = []

var load_card = load("res://Scenes/Card_Placeholder.tscn")
var json_validator_script = load("res://Scripts/JSON_Validator.cs")
var json_validator = json_validator_script.new()

func create_map(w, h):
	var map = []

	for _x in range(w):
		var col = []
		col.resize(h)
		map.append(col)

	return map

func is_empty(w, h):
	if not((w<1 or w>7) or (h<1 or h>7)):
		if matrix[w-1][h-1] == null:
			return true
		else:
			return false

func add_to_matrix(card, w, h):
	if is_empty(w, h):
		matrix[w-1][h-1] = card.name
		card_age.append(card.name)
		#print(matrix)

func move_card_to_empty(x1, y1, x2, y2):
	print(matrix[x1-1][y1-1])
	matrix[x2-1][y2-1] = matrix[x1-1][y1-1]
	matrix[x1-1][y1-1] = null

func move_card(x1, y1, x2, y2):
	if get_card(x2, y2) == null:
		move_card_to_empty(x1, y1, x2, y2)
		return
	elif get_card(x1, y1) == get_card(x2, y2):
		return
	# Target tile is neither empty nor the starting tile, so it's another card.
	var card1 = get_node(get_card(x1, y1))
	var card2 = get_node(get_card(x2, y2))
	if card1.team == card2.team:
		if card1.is_leader:
			destroy_card_at(x2, y2)
			move_card_to_empty(x1, y1, x2, y2)
	else:
		if card2.is_leader:
			calculate_damage(card1.atk, 0, card2.team) # Leaders are treated as having 0 ATK, and being in Attack Position at all times.
		else:
			if card2.in_attack_position:
				if card1.atk > card2.atk:
					calculate_damage(card1.atk, card2.atk, card2.team)
					destroy_card_at(x2, y2)
					move_card_to_empty(x1, y1, x2, y2)
				elif card1.atk == card2.atk:
					destroy_card_at(x1, y1)
					destroy_card_at(x2, y2)
				else:
					calculate_damage(card1.atk, card2.atk, card1.team)
					destroy_card_at(x1, y1)
			else:
				if card1.atk > card2.def:
					destroy_card_at(x2, y2)
					move_card_to_empty(x1, y1, x2, y2)
				elif card1.atk < card2.def:
					calculate_damage(card1.atk, card2.def, card1.team)

func get_card(x, y):
	if not((x<1 or x>7) or (y<1 or y>7)):
		return matrix[x-1][y-1]

func destroy_card_at(x, y):
	var card_destroyed = get_node(get_card(x, y))
	card_age.erase(card_destroyed)
	if card_destroyed.team == 0:
		graveyard_red.append(card_destroyed.card_id)
	else:
		graveyard_white.append(card_destroyed.card_id)
	card_destroyed.queue_free()
	matrix[x-1][y-1] = null

func destroy_card_name(_name):
	pass

func calculate_damage(atk1, atk2, team):
	if team == 0:
		lp_red -= abs(atk1 - atk2)
	else:
		lp_white -= abs(atk1 - atk2)

func create_card(w, h):
	var new_card = load_card.instance()
	add_child(new_card, true)
	add_to_matrix(new_card, w, h)
	card_age.append(get_card(w, h))
	get_node(get_card(w,h)).position = Vector2(75 + 150*w, 75 + 150*h)

func get_addons():
	var files = []
	var dir = Directory.new()
	dir.open("user://addons")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	dir.list_dir_end()
	return files

func validate_addons(addons):
	for i in addons:
		print(json_validator.ValidateJson("user://addons/" + i))

func set_leader(x, y):
	var card = get_node(get_card(x, y))
	card.is_leader = true

func change_team(x, y):
	var card = get_node(get_card(x, y))
	if card.team == 0:
		card.team+= 1
		card.rotation_degrees += 180
	else:
		card.team-= 1
		card.rotation_degrees -= 180
	

# Called when the node enters the scene tree for the first time.
func _ready():
	matrix = create_map(7,7)
	validate_addons(get_addons())
	
	# Create Red Leader (Goes first)
	create_card(4,7)
	set_leader(4,7)
	
	# Create White Leader (Goes second)
	create_card(4,1)
	change_team(4,1)
	set_leader(4,1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	get_node("HUD/CanvasLayer/LP_Red").text=str(lp_red)
	get_node("HUD/CanvasLayer/LP_White").text=str(lp_white)
