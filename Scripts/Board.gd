extends Node2D

enum color {RED, WHITE}
onready var cursor = $Cursor
onready var tilemap = $TileMap

# Enums on all possible variables a card can have
enum attributes {LIGHT, DARK, FIRE, EARTH, WATER, WIND}
enum card_types {DRAGON, SPELLCASTER, ZOMBIE, WARRIOR, BEAST_WARRIOR, BEAST, WINGED_BEAST, FIEND, FAIRY, INSECT, DINOSAUR, REPTILE, FISH, SEA_SERPENT, MACHINE, THUNDER, AQUA, PYRO, ROCK, PLANT, IMMORTAL, MAGIC, POWER_UP, TRAP_LIMITED, TRAP_FULL, RITUAL}
enum terrain {NORMAL, FOREST, WASTELAND, MOUNTAIN, SEA, DARK, TOON, CRUSH, LABYRINTH}
const triggers = ["passive", "battle_engagement", "flipped_face_up", "flipped_face_up_battle", "standby_face_up_defense", "movement_triggers_limited_trap", "damage_received", "battle_flipped_face_up", "flipped_face_up_voluntarily", "destroyed_battle", "destroyed", "opponent_is_x", "standby_counter_x", "moves_terrain_x", "moves_tile", "moves_per_turn", "opponent_destroyed", "standby_face_up", "flipped_face_up_card_played", "lp_over_x", "lp_equal_to_x", "lp_under_x", "leader_is_x", "adjacent_x", "turn_controller"]
const effects = ["battle_bonus_temporary", "battle_bonus_temporary_atk", "battle_bonus_temporary_def", "transform_terrain_current", "transform_terrain_range_x_distance", "transform_terrain_range_x_square", "terrain_immunity", "transform_to_x", "stat_change_x", "stat_change_x_atk", "stat_change_x_def", "stat_change_highest", "stat_change_highest_atk", "stat_change_highest_def", "stat_set_x_atk", "stat_set_x_def", "stat_set_x_to_y_times_num_z_graveyards", "spellbind", "spellbind_eternal", "effect_prevent_activation", "destroy", "battle_one_sided_destruction", "lp_own_change_x", "lp_own_set_x", "lp_own_set_up_to_x", "lp_own_multiply_x", "lp_own_divide_x", "lp_enemy_change_x", "lp_enemy_set_x", "lp_enemy_multiply_x", "lp_enemy_divide_x", "lp_enemy_set_up_to_x", "revive_type_x", "teleport_summoning_area", "power_up_effect_change_x", "power_up_effect_multiply_x", "power_up_effect_divide_x", "flip_face_up", "flip_face_down", "game_win", "game_lose", "battle_damage_set_x", "summon_power_change_x", "summon_power_set_x", "stat_change_nullify", "move_labyrinth", "summon_x", "prevent_revival", "banish_x_deck", "banish_x_hand", "banish_x_graveyard", "return_x_deck", "allow_card_play", "reveal_x_card_y_stat", "cannot_move", "movement_bonus_cancel", "change_controller", "change_controller_temporary"]
const targets = ["card_self", "opponent", "cards_all", "cards_own", "cards_enemy", "controller", "enemy", "leader_own", "leader_enemy", "range_x", "row_current", "row_x", "line_current", "line_x", "monsters", "magics", "powerups", "rituals", "traps", "traps_limited", "traps_full", "trap_activator", "card_type"]
var effects_active = []

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

var stars_red = 4
var stars_white = 1

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

var trap_activator = null
var opponent = null

var turn_counter = 99

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
	var card1_name = card1.name
	var card2 = get_node(get_card(x2, y2))
	var card2_name = card2.name
	if card1.team != card2.team:
		# Defending card flips first.
		if !card2.despawning:
			if !card2.face_up:
				card2.just_flipped = true
			card2.face_up = true
			card2.revealed = true
			card2.flipping = true
			opponent = card1.name
			process_trigger(card2, ["flipped_face_up_battle", "flipped_face_up"])
		if !card1.face_up:
			card1.just_flipped = true
		card1.face_up = true
		card1.revealed = true
		card1.flipping = true
		opponent = card2.name
		process_trigger(card1, ["flipped_face_up_battle", "flipped_face_up"])
	opponent = null
	if card1.team == card2.team:
		if card1.is_leader:
			destroy_card_at(x2, y2)
			move_card_to_empty(x1, y1, x2, y2)
		else:
			# Placeholder for power-up functionality
			var has_power_up = false
			var power_1 = false
			if card1.card_type == card_types.POWER_UP:
				power_1 = true
				process_power_up(card1, card2)
				has_power_up = true
			elif card2.card_type == card_types.POWER_UP:
				process_power_up(card2, card1)
				has_power_up = true
			if has_power_up:
				if power_1:
					destroy_card_name(card1.name)
					card2.update_stats()
				else:
					destroy_card_name(card2.name)
					move_card_to_empty(x1, y1, x2, y2)
					card1.update_stats()
				return
				
			var fusion_result = process_fusion(card1.card_id, card2.card_id)
			if fusion_result != null:
				destroy_card_name(card1.name)
				destroy_card_name(card2.name)
				create_card(x2, y2)
				get_node(get_card(x2, y2)).card_id = fusion_result
			else:
				destroy_card_name(card2.name)
				move_card_to_empty(x1, y1, x2, y2)
			
	else:
		# Placeholder for power-up functionality
		var has_power_up = false
		var power_1 = false
		if card1.card_type == card_types.POWER_UP:
			power_1 = true
			process_power_up(card1, card2)
			has_power_up = true
		elif card2.card_type == card_types.POWER_UP:
			process_power_up(card2, card1)
			has_power_up = true
		if has_power_up:
			if power_1:
				destroy_card_name(card1.name)
				card2.update_stats()
			else:
				destroy_card_name(card2.name)
				move_card_to_empty(x1, y1, x2, y2)
				card1.update_stats()
			return
		
		if get_card(x1, y1) == null or get_card(x2, y2) == null \
		or get_card(x1, y1) != card1_name or get_card(x2, y2) != card2_name:
			return
		if get_card(x2, y2) != null:
			opponent = card1.name
			process_trigger(card2, ["battle_engagement"])
		if get_card(x1, y1) != null:
			opponent = card2.name
			process_trigger(card1, ["battle_engagement"])
		opponent = null
		if get_card(x1, y1) == card1_name or get_card(x2, y2) == card2_name:
			card1.update_stats()
			card2.update_stats()
		
		if get_card(x1, y1) == null or get_card(x2, y2) == null:
			return
		if get_card(x2, y2) == null or get_card(x1, y1) != card1_name:
			move_card_to_empty(x1, y1, x2, y2)
			return
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
					card2.destroyed_battle = true
					destroy_card_at(x2, y2)
					move_card_to_empty(x1, y1, x2, y2)
				elif card1.atk == card2.atk:
					$Cursor.card_moving_destroyed = true
					card1.destroyed_battle = true
					destroy_card_at(x1, y1)
					card2.destroyed_battle = true
					destroy_card_at(x2, y2)
				else:
					calculate_damage(card1.atk, card2.atk, card1.team)
					$Cursor.card_moving_destroyed = true
					card1.destroyed_battle = true
					destroy_card_at(x1, y1)
			else:
				if card1.atk > card2.def:
					card2.destroyed_battle = true
					destroy_card_at(x2, y2)
					move_card_to_empty(x1, y1, x2, y2)
				elif card1.atk < card2.def:
					calculate_damage(card1.atk, card2.def, card1.team)
		if get_card(x1, y1) != null:
			card1.battle_atk = 0
			card1.update_stats()
		if get_card(x2, y2) != null:
			card2.battle_atk = 0
			card2.update_stats()

func get_card(x, y):
	if not((x<1 or x>7) or (y<1 or y>7)):
		return matrix[x-1][y-1]

func destroy_card_at(x, y):
	var card_destroyed = get_node(get_card(x, y))
	if card_destroyed != null:
		if cursor.card_held != null:
			if card_destroyed == get_node(cursor.card_held):
				cursor.card_moving_destroyed = true
		card_destroyed.can_move = false
		card_age.erase(get_card(x, y))
		if card_destroyed.team == 0:
			graveyard_red.append(card_destroyed.card_id)
		else:
			graveyard_white.append(card_destroyed.card_id)
		card_destroyed.despawning = true
		matrix[x-1][y-1] = null
		process_trigger(card_destroyed, ["destroyed_battle", "destroyed"])
		
func destroy_card_at_nondestructive(x, y):
	var card_destroyed = get_node(get_card(x, y))
	if card_destroyed != null:
		if cursor.card_held != null:
			if card_destroyed == get_node(cursor.card_held):
				cursor.card_moving_destroyed = true
		card_destroyed.can_move = false
		card_age.erase(get_card(x, y))
		if card_destroyed.team == 0:
			graveyard_red.append(card_destroyed.card_id)
		else:
			graveyard_white.append(card_destroyed.card_id)
		card_destroyed.despawning = true
		matrix[x-1][y-1] = null
	

func check_spawn_status():
	var card
	for item in card_age:
		card = get_node(item)
		if card.spawning or card.despawning:
			return false
	return true

func banish_at(x,y):
	var card_destroyed = get_node(get_card(x, y))
	card_destroyed.can_move = false
	card_age.erase(get_card(x, y))
	card_destroyed.queue_free()
	matrix[x-1][y-1] = null

func destroy_card_name(_name):
	destroy_card_at(get_node(_name).grid_x, get_node(_name).grid_y)

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
				# If card checked is own leader
				if !card_held.is_leader and get_node(get_card(x,y)).team == card_held.team and get_node(get_card(x,y)).is_leader:
					return false
				# If card in tile is friendly
				elif card_held.is_leader and get_node(get_card(x,y)).team == card_held.team or (get_node(get_card(x,y)).team == card_held.team):
					return true
				# If both held card and card in tile are leaders
				elif card_held.is_leader and get_node(get_card(x,y)).team != card_held.team and get_node(get_card(x,y)).is_leader:
					return false
				# If holding leader, and card checked is enemy
				elif card_held.is_leader and get_node(get_card(x,y)).team != card_held.team:
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

func search(criteria, attributes, triggered):
	var results = []
	var attribute_counter = 0
	for card in card_age:
		attribute_counter = 0
		var card_found = true
		for item in criteria:
			if !card_found:
				break
			if item == "cards_all":
				continue
			elif item == "cards_own":
				if get_node(card).team == get_node(triggered).team and !get_node(card).is_leader:
					continue
				else:
					card_found = false
			elif item == "cards_enemy":
				if get_node(card).team != get_node(triggered).team and !get_node(card).is_leader:
					continue
				else:
					card_found = false
			elif item == "leader_own":
				if get_node(card).team == get_node(triggered).team and get_node(card).is_leader:
					continue
				else:
					card_found = false
			elif item == "leader_enemy":
				if get_node(card).team != get_node(triggered).team and get_node(card).is_leader:
					continue
				else:
					card_found = false
			elif item == "monsters":
				if get_node(card).card_type != card_types.MAGIC and \
				get_node(card).card_type != card_types.POWER_UP and \
				get_node(card).card_type != card_types.TRAP_FULL and \
				get_node(card).card_type != card_types.TRAP_LIMITED and \
				get_node(card).card_type != card_types.RITUAL and !get_node(card).is_leader:
					continue
				else:
					card_found = false
			elif item == "magics":
				if get_node(card).card_type == card_types.MAGIC and !get_node(card).is_leader:
					continue
				else:
					card_found = false
			elif item == "powerups":
				if get_node(card).card_type == card_types.POWER_UP and !get_node(card).is_leader:
					continue
				else:
					card_found = false
			elif item == "rituals":
				if get_node(card).card_type == card_types.RITUAL and !get_node(card).is_leader:
					continue
				else:
					card_found = false
			elif item == "traps":
				if (get_node(card).card_type == card_types.TRAP_FULL or get_node(card).card_type == card_types.TRAP_LIMITED) and !get_node(card).is_leader:
					continue
				else:
					card_found = false
			elif item == "traps_limited":
				if get_node(card).card_type == card_types.TRAP_LIMITED and !get_node(card).is_leader:
					continue
				else:
					card_found = false
			elif item == "traps_full":
				if get_node(card).card_type == card_types.TRAP_FULL and !get_node(card).is_leader:
					continue
				else:
					card_found = false
			elif item == "card_type":
				if get_node(card).card_type == card_types.get(attributes[attribute_counter]) and !get_node(card).is_leader:
					attribute_counter += 1
					continue
				else:
					card_found = false
					attribute_counter += 1
			elif item == "row_x":
					if get_node(card).grid_y == attributes[attribute_counter] and !get_node(card).is_leader:
						attribute_counter += 1
						continue
					else:
						card_found = false
						attribute_counter += 1
			elif item == "line_x":
				if get_node(card).grid_x == attributes[attribute_counter] and !get_node(card).is_leader:
					attribute_counter += 1
					continue
				else:
					card_found = false
					attribute_counter += 1
			elif item == "range_x":
				var triggered_pos = Vector2(get_node(triggered).grid_x, get_node(triggered).grid_y)
				var checked_pos = Vector2(get_node(card).grid_x, get_node(card).grid_y)
				if (abs(triggered_pos.x - checked_pos.x) + abs(triggered_pos.y - checked_pos.y)) <= attributes[attribute_counter] \
				and !get_node(card).is_leader:
					attribute_counter += 1
					continue
				else:
					card_found = false
					attribute_counter += 1
			elif item == "trap_activator":
				if trap_activator != card:
					card_found = false
			elif item == "card_self":
				if card != triggered.name:
					card_found = false
			elif item == "opponent":
				if card != opponent:
					card_found = false
			elif item == "atk_over_x":
				if get_node(card).atk > attributes[attribute_counter] and !get_node(card).is_leader:
					attribute_counter += 1
					continue
				else:
					card_found = false
					attribute_counter += 1
			elif item == "atk_equal_to_x":
				if get_node(card).atk == attributes[attribute_counter] and !get_node(card).is_leader:
					attribute_counter += 1
					continue
				else:
					card_found = false
					attribute_counter += 1
			elif item == "atk_under_x":
				if get_node(card).atk < attributes[attribute_counter] and !get_node(card).is_leader:
					attribute_counter += 1
					continue
				else:
					card_found = false
					attribute_counter += 1
			elif item == "def_over_x":
				if get_node(card).def > attributes[attribute_counter] and !get_node(card).is_leader:
					attribute_counter += 1
					continue
				else:
					card_found = false
					attribute_counter += 1
			elif item == "def_equal_to_x":
				if get_node(card).def == attributes[attribute_counter] and !get_node(card).is_leader:
					attribute_counter += 1
					continue
				else:
					card_found = false
					attribute_counter += 1
			elif item == "def_equal_to_x":
				if get_node(card).def == attributes[attribute_counter] and !get_node(card).is_leader:
					attribute_counter += 1
					continue
				else:
					card_found = false
					attribute_counter += 1
		if card_found:
			results.append(card)
	return results
				
				
func process_trigger(card, triggers):
	var effects_list = card.effect_list
	var triggered = false
	for item in effects_list:
		if triggers.find(item.get("trigger")) != -1:
			if item.get("trigger") == "standby_face_up_defense":
				if card.face_up and !card.in_attack_position:
					triggered = true
			elif item.get("trigger") == "flipped_face_up":
				if card.just_flipped:
					triggered = true
					card.just_flipped = false
			elif item.get("trigger") == "flipped_face_up_battle":
				if card.just_flipped:
					triggered = true
					card.just_flipped = false
			elif item.get("trigger") == "destroyed":
				triggered = true
			elif item.get("trigger") == "destroyed_battle":
				if card.destroyed_battle:
					triggered = true
			elif item.get("trigger") == "battle_engagement":
				triggered = true
		if triggered:
			process_effect(item.get("effect"), item.get("target"), item.get("attribute_effect"), item.get("attribute_target"), card)


func process_effect(effect, target, attribute_effect, attribute_target, card):
	var effect_targets
	var attribute_counter = 0
	if target != null:
		effect_targets = search(target, attribute_target, card)
	for item in effect:
		if item == "destroy":
			for card in effect_targets:
				destroy_card_name(card)
		elif item == "stat_change_x":
			for card in effect_targets:
				get_node(card).modifier_stat += attribute_effect[attribute_counter]
			attribute_counter += 1
		elif item == "stat_change_x_atk":
			for card in effect_targets:
				get_node(card).modifier_atk += attribute_effect[attribute_counter]
			attribute_counter += 1
		elif item == "stat_change_x_def":
			for card in effect_targets:
				get_node(card).modifier_def += attribute_effect[attribute_counter]
			attribute_counter += 1
		elif item == "spellbind":
			for card in effect_targets:
				get_node(card).spellbind(attribute_effect[attribute_counter])
			attribute_counter += 1
		elif item == "spellbind_eternal":
			for card in effect_targets:
				get_node(card).spellbind(-1)
			attribute_counter += 1
		elif item == "transform_terrain_current":
			var center = Vector2(card.grid_x, card.grid_y)
			tilemap.set_cell(center.x, center.y, terrain[attribute_effect[attribute_counter]])
			attribute_counter += 1
		elif item == "transform_terrain_range_x_distance":
			var center = Vector2(card.grid_x, card.grid_y)
			for i in range (max(1, center.x - attribute_effect[attribute_counter]), min(center.x + attribute_effect[attribute_counter] + 1, 8)):
				for j in range (max(1, center.y - attribute_effect[attribute_counter]), min(center.y + attribute_effect[attribute_counter] + 1, 8)):
					if (abs(i - center.x) + abs(j - center.y)) <= attribute_effect[attribute_counter]:
						if tilemap.get_cell(i, j) != terrain.LABYRINTH:
							tilemap.set_cell(i, j, terrain[attribute_effect[attribute_counter + 1]])
			attribute_counter += 2
		elif item == "transform_monster_to_x":
			var position = Vector2.ZERO
			for card in effect_targets:
				position = Vector2(get_node(card).grid_x, get_node(card).grid_y)
				destroy_card_at_nondestructive(position.x, position.y)
				create_card(position.x, position.y)
				get_node(get_card(position.x, position.y)).card_id = attribute_effect[attribute_counter]
			attribute_counter += 1
		elif item == "battle_one_sided_destruction":
			var position = Vector2.ZERO
			for card in effect_targets:
				position = Vector2(get_node(card).grid_x, get_node(card).grid_y)
				destroy_card_at(position.x, position.y)
		elif item == "battle_bonus_temporary":
			for card in effect_targets:
				get_node(card).battle_atk = attribute_effect[attribute_counter]
				get_node(card).battle_def = attribute_effect[attribute_counter]
			attribute_counter += 1
		elif item == "battle_bonus_temporary_atk":
			for card in effect_targets:
				get_node(card).battle_atk = attribute_effect[attribute_counter]
			attribute_counter += 1
		elif item == "battle_bonus_temporary_def":
			for card in effect_targets:
				get_node(card).battle_def = attribute_effect[attribute_counter]
			attribute_counter += 1

func process_power_up(power_up, affected_card):
	var effects_list = power_up.effect_list
	for effects in effects_list:
		var attribute_effect = effects.get("attribute_effect")
		var attribute_target = effects.get("attribute_target")
		var target = effects.get("target")
		var effect_targets
		var attribute_counter = 0
		if target != null:
			effect_targets = search(target, attribute_target, power_up)
		if effect_targets.has(affected_card.name):
			for item in effects.get("effect"):
				if item == "stat_change_x":
					affected_card.modifier_stat += attribute_effect[attribute_counter]
					attribute_counter += 1
				elif item == "stat_change_x_atk":
					affected_card.modifier_atk += attribute_effect[attribute_counter]
					attribute_counter += 1
				elif item == "stat_change_x_def":
					affected_card.modifier_def += attribute_effect[attribute_counter]
					attribute_counter += 1
				elif item == "spellbind":
					affected_card.spellbind(attribute_effect[attribute_counter])
					attribute_counter += 1
				elif item == "spellbind_eternal":
					affected_card.spellbind(-1)
					attribute_counter += 1
	

func check_adjacent_tiles_for_limited_trap(x, y):
	var lim_trap_found = false
	var coords = Vector2(0,0)
	var card
	var oldest_name
	var oldest = card_age.size()
	for i in range (1, 8):
		for j in range (1, 8):
			coords = Vector2(i, j)
			if (coords.x in range (1, 8) and (coords.y in range (1,8))):
				if coords.distance_to(Vector2(x, y)) == 1:
					if get_card(coords.x, coords.y) != null:
						card = get_node(get_card(coords.x, coords.y))
						if card != null:
							if card.card_type == card_types.TRAP_LIMITED and card.team != cursor.team:
								lim_trap_found = true
								if oldest > card_age.find(card.name):
									oldest = card_age.find(card.name)
									oldest_name = card.name
	if lim_trap_found:
		print("Limited trap found at " + str(get_node(card_age[oldest]).grid_x) + "," + str(get_node(card_age[oldest]).grid_y))
		var effects_list = card.effect_list
		destroy_card_name(oldest_name)
		for item in effects_list:
			process_effect(item.get("effect"), item.get("target"), item.get("attribute_effect"), item.get("attribute_target"), card)
	trap_activator = null
			

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	matrix = create_map(7,7)
	matrix_indicator = create_map(8,8)
	validate_addons(get_addons())
	print("This mod has the ID " + addons_id[0])
	print(get_card_data("Tasos500.TestMod.417"))
	if get_card_data("Tasos500.TestMod.417")["effects"][0].get("trigger") == "flipped_face_up_battle" and cursor.debug:
		print("Effect triggers when card flipped in battle.")
	
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
	get_node("HUD/%LP_Red").text=str(lp_red) + " LP"
	get_node("HUD/%LP_White").text="LP " + str(lp_white)
	if turn_counter >= 0:
		get_node("HUD/%Turn_Counter").text = "%02d" % [turn_counter]
	else:
		get_node("HUD/%Turn_Counter").text = "00"
	if stars_red > 12:
		stars_red = 12
	if stars_white > 12:
		stars_white = 12
	
	if cursor.team == color.RED:
		get_node("HUD/%Stars_Red").text = str(stars_red) + " ✭✭✭✭✭✭✭✭✭★"
		get_node("HUD/%Stars_White").text = "??"
	else:
		get_node("HUD/%Stars_Red").text = "??"
		get_node("HUD/%Stars_White").text = "★ ✭" + str(stars_white)
