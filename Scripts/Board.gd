extends Node2D

enum color {RED, WHITE}

# Enums on all possible variables a card can have
enum attributes {LIGHT, DARK, FIRE, EARTH, WATER, WIND}
enum card_types {DRAGON, SPELLCASTER, ZOMBIE, WARRIOR, BEAST_WARRIOR, BEAST, WINGED_BEAST, FIEND, FAIRY, INSECT, DINOSAUR, REPTILE, FISH, SEA_SERPENT, MACHINE, THUNDER, AQUA, PYRO, ROCK, PLANT, IMMORTAL, MAGIC, POWER_UP, TRAP_LIMITED, TRAP_FULL, RITUAL}
enum terrain {NORMAL, FOREST, WASTELAND, MOUNTAIN, SEA, DARK, TOON, CRUSH, LABYRINTH}

var matrix # Matrix for cards
var matrix_indicator # Matrix for indicators

# Ensures effects that trigger at start of turn occur by the oldest card first, and can be used as a general array for checking every card. Cards are popped when destroyed.
var card_age = []

# Decks have exactly 40 cards. These will contain pointers to the databases.
var deck_red = []
var deck_white = []

# Hands can have up to five cards, which are drawn immediately when the hand is opened for a summon.
var hand_red = []
var hand_red_num = 0
var hand_white = []
var hand_white_num = 0

var lp_red = 4000
var lp_white = 4000

# Cards popped from card_age end up here, and are public to both players.
var graveyard_red = []
var graveyard_white = []

var load_card = load("res://Scenes/Card_Placeholder.tscn")
var load_tile = preload("res://Scenes/Tile_Indicator.tscn")
var json_validator_script = load("res://Scripts/JSON_Validator.cs")
var json_validator = json_validator_script.new()
var valid_addons = []
var addons_file = File.new()
var addons_id = []

# Used to only allow summoning within the summoning range
var summon_x_range
var summon_y_range

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
	#print(matrix[x1-1][y1-1])
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
	card1.face_up = true
	card1.revealed = true
	card2.face_up = true
	card2.revealed = true
	if card1.team == card2.team:
		if card1.is_leader:
			destroy_card_at(x2, y2)
			move_card_to_empty(x1, y1, x2, y2)
		else:
			pass
	else:
		if card2.is_leader:
			calculate_damage(card1.atk, 0, card2.team) # Leaders are treated as having 0 ATK, and being in Attack Position at all times.
		else:
			if card2.card_type == card_types.MAGIC or \
			card2.card_type == card_types.RITUAL or \
			card2.card_type == card_types.TRAP_FULL or \
			card2.card_type == card_types.TRAP_LIMITED:
				destroy_card_at(x2, y2)
				move_card_to_empty(x1, y1, x2, y2)
				return
			if card2.in_attack_position:
				if card1.atk > card2.atk:
					calculate_damage(card1.atk, card2.atk, card2.team)
					destroy_card_at(x2, y2)
					move_card_to_empty(x1, y1, x2, y2)
				elif card1.atk == card2.atk:
					$Cursor.card_moving_destroyed = true
					destroy_card_at(x1, y1)
					destroy_card_at(x2, y2)
				else:
					calculate_damage(card1.atk, card2.atk, card1.team)
					$Cursor.card_moving_destroyed = true
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
	card_destroyed.can_move = false
	card_age.erase(get_card(x, y))
	if card_destroyed.team == 0:
		graveyard_red.append(card_destroyed.card_id)
	else:
		graveyard_white.append(card_destroyed.card_id)
	card_destroyed.despawning = true
	matrix[x-1][y-1] = null

func banish_at(x,y):
	var card_destroyed = get_node(get_card(x, y))
	card_destroyed.can_move = false
	card_age.erase(get_card(x, y))
	card_destroyed.queue_free()
	matrix[x-1][y-1] = null

func destroy_card_name(_name):
	pass

func add_to_graveyard(card_id):
	if $"Cursor".team == 0:
		graveyard_red.append(card_id)
	else:
		graveyard_white.append(card_id)

func calculate_damage(atk1, atk2, team):
	if team == 0:
		lp_red -= abs(atk1 - atk2)
	else:
		lp_white -= abs(atk1 - atk2)

func create_card(w, h):
	var new_card = load_card.instance()
	if $Cursor.team == color.WHITE: # If White
		new_card.team = color.WHITE
	else:
		new_card.team = color.RED
	add_child(new_card, true)
	add_to_matrix(new_card, w, h)
	get_node(get_card(w,h)).position = Vector2(75 + 150*w, 75 + 150*h)
	

func process_fusion(card_id1, card_id2):
	var data1 = get_card_data(card_id1)
	var data2 = get_card_data(card_id2)
	if data1.has("fusions") and data2.has("fusions"):
		for i in data1["fusions"]:
			for j in data2["fusions"]:
				pass
				if i["product"] == j["product"] and i["material"] != j["material"]:
					return str(card_id1.split(".")[0] + "." + card_id1.split(".")[1] + "." + i["product"])
	else:
		return null
	

func get_addons():
	var files = []
	var dir = Directory.new()
	dir.open("user://addons")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.ends_with(".json"):
			files.append(file)
	dir.list_dir_end()
	return files

func validate_addons(addons):
	for i in addons:
		if json_validator.ValidateJson("user://addons/" + i): # If addon is valid
			addons_file.open("user://addons/" + i, File.READ)
			var addons_text = addons_file.get_as_text()
			addons_file.close()
			valid_addons.append(JSON.parse(addons_text).result)
			addons_id.append(str(valid_addons[addons_id.size()].mod_creator + "." + valid_addons[addons_id.size()].mod_name))

func set_leader(x, y, team):
	var card = get_node(get_card(x, y))
	card.is_leader = true
	card.team = team
	if team == color.WHITE:
		card.rotation_degrees += 180

func change_team(x, y):
	var card = get_node(get_card(x, y))
	if card.team == 0:
		card.team+= 1
		card.rotation_degrees += 180
	else:
		card.team-= 1
		card.rotation_degrees -= 180

func show_move_tiles(tile_speed, x, y):
	# loop through the possible x and y positions
	for i in range (max(1, x - tile_speed), min(x + tile_speed + 1, 8)):
		for j in range (max(1, y - tile_speed), min(y + tile_speed + 1, 8)):
		  # check if the distance from the starting position is less than or equal to tile_speed
			if (abs(i - x) + abs(j - y)) <= tile_speed:
				if check_if_passable(i, j):
						# create a new move tile at the current position
						var new_move_tile = load_tile.instance()
						add_child(new_move_tile, true)
						matrix_indicator[i-1][j-1] = new_move_tile.name
						new_move_tile.position = Vector2(75 + 150*i, 75 + 150*j)


func clear_move_tiles():
	for i in range(0,7):
		for j in range(0,7):
			if matrix_indicator[i][j] != null:
				get_node(matrix_indicator[i][j]).despawning = true
				matrix_indicator[i][j] = null

func show_summon_tiles(x, y):
	# loop through the possible x and y positions
	summon_x_range = range(max(1, x - 1), min(x + 1 + 1, 8))
	summon_y_range = range(max(1, y - 1), min(y + 1 + 1, 8))
	for i in summon_x_range:
		for j in summon_y_range:
		  # check if the distance from the starting position is equal to 1 in each axis (Square)
			if abs(i - x) == 1 or abs(j - y) == 1:
				if check_if_summonable(i, j):
						# create a new move tile at the current position
						var new_move_tile = load_tile.instance()
						add_child(new_move_tile, true)
						new_move_tile.summon_tile = true
						matrix_indicator[i-1][j-1] = new_move_tile.name
						new_move_tile.position = Vector2(75 + 150*i, 75 + 150*j)

func check_if_summonable(x, y):
	# Double check on coords to prevent crashes
	if (x in summon_x_range) and (y in summon_y_range):
		# If tile is a Labyrinth (Add check for labyrinth crossing after effects are implemented)
		if $TileMap.get_cell(x, y) != terrain.LABYRINTH:
			# If tile is not empty
			if get_card(x, y) != null:
				# If card in tile is friendly and NOT a leader
				if get_node(get_card(x,y)).team == $Cursor.team and !get_node(get_card(x,y)).is_leader:
					return true
			else:
				return true
	return false

func check_if_passable(x, y):
	var card_held = get_node($Cursor.card_held)
	# Double check on coords to prevent crashes
	if (x >= 1 and x <= 7) and (y >= 1 and y <= 7):
		# If tile is a Labyrinth (Add check for labyrinth crossing after effects are implemented)
		if $TileMap.get_cell(x, y) != terrain.LABYRINTH:
			# If tile is not empty
			if get_card(x, y) != null:
				# If card is self
				if card_held == get_node(get_card(x,y)):
					return true
				# If card in tile is friendly
				if card_held.is_leader and get_node(get_card(x,y)).team == card_held.team:
					return true
				# If both held card and card in tile are leaders
				elif card_held.is_leader and get_node(get_card(x,y)).team != card_held.team and get_node(get_card(x,y)).is_leader:
					return false
				# If holding leader, and card checked is enemy
				elif card_held.is_leader and get_node(get_card(x,y)).team != card_held.team:
					return false
				# If card checked is own leader
				elif !card_held.is_leader and get_node(get_card(x,y)).team == card_held.team and get_node(get_card(x,y)).is_leader:
					return false
				# If card checked is enemy leader
				elif !card_held.is_leader and get_node(get_card(x,y)).team != card_held.team and get_node(get_card(x,y)).is_leader:
					return true
				# If both cards are not leaders, and of different teams
				elif get_node(get_card(x,y)).team != card_held.team:
					return true
			else:
				return true
	return false
	
func get_card_data(card_id):
	var mod_id = card_id.split(".")
	if addons_id.find(str(mod_id[0] + "." + mod_id[1])) != -1:
		for card in valid_addons[addons_id.find(str(mod_id[0] + "." + mod_id[1]))].cards:
			if card["number"] == str(mod_id[2]):
				return card

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	matrix = create_map(7,7)
	matrix_indicator = create_map(8,8)
	validate_addons(get_addons())
	print("This mod has the ID " + addons_id[0])
	print(get_card_data("Tasos500.TestMod.000"))
	
	# Create Red Leader (Goes first)
	create_card(4,7)
	set_leader(4,7, color.RED)
	
	# Create White Leader (Goes second)
	create_card(4,1)
	set_leader(4,1, color.WHITE)
	
	#Autoload DeckData, and shuffle (Duplicate copies the data instead of referencing it)
	deck_red = DeckData.deck_red.duplicate()
	deck_white = DeckData.deck_white.duplicate()
	deck_red.shuffle()
	deck_white.shuffle()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	get_node("HUD/%LP_Red").text=str(lp_red)
	get_node("HUD/%LP_White").text=str(lp_white)
