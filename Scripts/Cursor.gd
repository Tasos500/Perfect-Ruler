extends Node2D

enum color {RED, WHITE}
enum terrain {NORMAL, FOREST, WASTELAND, MOUNTAIN, SEA, DARK, TOON, CRUSH, LABYRINTH, MEADOW}
enum card_types {DRAGON, SPELLCASTER, ZOMBIE, WARRIOR, BEAST_WARRIOR, BEAST, WINGED_BEAST, FIEND, FAIRY, INSECT, DINOSAUR, REPTILE, FISH, SEA_SERPENT, MACHINE, THUNDER, AQUA, PYRO, ROCK, PLANT, IMMORTAL, MAGIC, POWER_UP, TRAP_LIMITED, TRAP_FULL, RITUAL}
const cursor_red = preload("res://Assets/Cursor/Cursor_Red.png")
const cursor_white = preload("res://Assets/Cursor/Cursor_White.png")
const load_tile = preload("res://Scenes/Tile_Indicator.tscn")
var fake_tile

# Hardcoded
export var team = color.RED
const move_speed = 8
var tile_size = 150

#Movement vars
var initial_position = Vector2(0,0)
var input_direction = Vector2(0,0)
var is_moving = false
var movement_percentage = 0.0
var can_move = true
var in_menu = false
var debug = true

# Current position
var grid_x = 4
var grid_y = 7

# Red's last position
var grid_x_red = 4
var grid_y_red = 7
# White's last position
var grid_x_white = 4
var grid_y_white = 1
# Next move's position
var grid_x_next = 4
var grid_y_next = 7


# Card holding variables
# Held card's original position
var grid_x_move
var grid_y_move
var holding_card = false
var card_held
var card_direction
var card_is_moving = false
var card_moving_destroyed = false

# Summoning variables
var summoning = false
var last_summoning = false
var has_summoned = false

# Turn End variables
var turn_ending = false
var end_turn_distance
var end_turn_direction = Vector2(0,0)
var reappearing = false

# Action Cancel variables
var cancelling = false
var grid_x_cancel
var grid_y_cancel
var cancel_distance
var cancel_direction = Vector2(0,0)

onready var board = $".."
onready var tilemap = $"../TileMap"
onready var hand = $"../HUD/Hand"
onready var hud_bottom = $"../HUD/HUD_Bottom"

# Movement stack, in order to hold moves to be done by a card once confirmed.
var movement_stack = []
var last_move = "none"
var next_move = "none"

# Called when the node enters the scene tree for the first time.
func _ready():
	initial_position = position

func _process(delta):
	if reappearing:
		reappear(delta)
	if cancelling:
		$Sprite.modulate.a8 = 0
		move_cancel(delta)
	if !in_menu:
		if turn_ending:
			$Sprite.modulate.a8 = 0
			end_turn(delta)
		elif card_is_moving:
			card_movement()
		else:
			if !is_moving and can_move and board.check_spawn_status():
				process_cursor_input()
			elif input_direction != Vector2.ZERO:
				move(delta)
			else:
				is_moving = false
			if !is_moving and !in_menu and board.check_spawn_status():
				process_button_input()
			if team == color.RED:
				get_node("Sprite").texture = cursor_red
			elif team == color.WHITE:
				get_node("Sprite").texture = cursor_white

func process_button_input():
	if Input.is_action_just_pressed("ui_summon"):
		if !holding_card and !cancelling and !turn_ending:
			if !summoning and !has_summoned:
				if board.get_card(grid_x, grid_y) != null:
					if board.get_node(board.get_card(grid_x, grid_y)).is_leader == true and board.get_node(board.get_card(grid_x, grid_y)).team == team:
						summoning = true
						process_summon()
			else:
				summoning = false
				process_summon()
	elif Input.is_action_just_pressed("ui_accept"):
		if !summoning and !cancelling and !turn_ending:
			if !holding_card:
				grab_card()
			else:
				release_card()
		elif summoning:
			summoning =false
			process_summon()
	elif Input.is_action_just_pressed("ui_cancel"):
		if (summoning or holding_card) and !cancelling:
			if holding_card:
				if board.get_node(card_held).original_face_up != board.get_node(card_held).face_up:
					board.get_node(card_held).face_up = board.get_node(card_held).original_face_up
					board.get_node(card_held).flipping = true
				if board.get_node(card_held).original_attack_position != board.get_node(card_held).in_attack_position:
					board.get_node(card_held).in_attack_position = board.get_node(card_held).original_attack_position
					board.get_node(card_held).rotating = true
			holding_card = false
			last_summoning = false
			summoning = false
			can_move = false
			movement_stack = []
			initial_position = position
			fake_tile = load_tile.instance()
			board.add_child(fake_tile, true)
			fake_tile.position = position
			fake_tile.clone_cursor = true
			cancel_distance = calculate_cancel_distance()
			cancel_direction = calculate_cancel_direction()
			board.clear_move_tiles()
			cancelling = true
	elif Input.is_action_just_pressed("ui_start"):
		if !get_node("../HUD/HUD_Layer").is_moving and !get_node("../HUD/HUD_Layer").going_down:
			get_node("../HUD/HUD_Layer").is_moving = true
			get_node("../HUD/HUD_Bottom").is_moving = true
			if team == color.WHITE:
				board.turn_counter -= 1
			if board.turn_counter == -1:
				pass
				# declare_winner()
				return
			if !holding_card and !summoning and !cancelling:
				has_summoned = false
				initial_position = position
				fake_tile = load_tile.instance()
				board.add_child(fake_tile, true)
				fake_tile.position = position
				fake_tile.clone_cursor = true
				end_turn_distance = calculate_end_turn_distance()
				end_turn_direction = calculate_end_turn_direction()
				turn_ending = true
				check_spellbound_cards()
	elif Input.is_action_just_pressed("debug_search") and debug:
		print(board.search(["card_type"],["DRAGON"], null, board.card_age))
	elif Input.is_action_just_pressed("debug_effects") and debug:
		if board.get_card(grid_x, grid_y) != null:
			print(board.get_node(board.get_card(grid_x, grid_y)).effect_list)
		else:
			pass
			#tilemap.set_cell(grid_x, grid_y, terrain["TOON"])
	elif holding_card and movement_stack.size() == 0:
		if Input.is_action_just_pressed("ui_l1"):
			if !board.get_node(card_held).is_leader and !(board.get_node(card_held).rotating or board.get_node(card_held).flipping):
				board.get_node(card_held).in_attack_position = true
				board.get_node(card_held).rotating = true
		elif Input. is_action_just_pressed("ui_r1"):
			if !board.get_node(card_held).is_leader and !(board.get_node(card_held).rotating or board.get_node(card_held).flipping):
				board.get_node(card_held).in_attack_position = false
				board.get_node(card_held).rotating = true
		elif Input.is_action_just_pressed("ui_l2"):
			if !board.get_node(card_held).is_leader and !(board.get_node(card_held).rotating or board.get_node(card_held).flipping) and !board.get_node(card_held).revealed:
				board.get_node(card_held).face_up = false
				board.get_node(card_held).flipping = true
		elif Input.is_action_just_pressed("ui_r2"):
			if !board.get_node(card_held).is_leader and !(board.get_node(card_held).rotating or board.get_node(card_held).flipping):
				board.get_node(card_held).face_up = true
				board.get_node(card_held).flipping = true

func process_cursor_input():
	if !can_move and is_moving:
		return
	if input_direction.y == 0:
		input_direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
		if team == color.WHITE: # Controls reverse when playing White
			input_direction.x = -input_direction.x
		grid_x_next = grid_x + input_direction.x
		grid_y_next = grid_y
		if (input_direction.x == -1 and grid_x == 1) or (input_direction.x == 1 and grid_x == 7):
			input_direction.x = 0
	if input_direction.x == 0:
		input_direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
		if team == color.WHITE: # Controls reverse when playing White
			input_direction.y = -input_direction.y
		grid_x_next = grid_x
		grid_y_next = grid_y + input_direction.y
		if (input_direction.y == -1 and grid_y == 1) or (input_direction.y == 1 and grid_y == 7):
			input_direction.y = 0
	
	next_move = tile_to_move_next()
	if (input_direction != Vector2.ZERO) and move_is_valid():
		initial_position = position
		if holding_card:
			process_movement_stack()
		is_moving = true
		can_move = false
	else:
		input_direction = Vector2.ZERO

func update_grid_x():
	grid_x += input_direction.x
	if team == color.RED:
		grid_x_red = grid_x
	elif team == color.WHITE:
		grid_x_white = grid_x

func update_grid_y():
	grid_y += input_direction.y
	if team == color.RED:
		grid_y_red = grid_y
	elif team == color.WHITE:
		grid_y_white = grid_y

func grab_card():
	if !board.is_empty(grid_x, grid_y) and !holding_card:
		if !board.get_node(board.get_card(grid_x, grid_y)).despawning:
			if !board.get_node(board.get_card(grid_x, grid_y)).has_moved and board.get_node(board.get_card(grid_x, grid_y)).team == team and !board.get_node(board.get_card(grid_x, grid_y)).is_spellbound():
				grid_x_move = grid_x
				grid_y_move = grid_y
				grid_x_cancel = grid_x
				grid_y_cancel = grid_y
				holding_card = true
				card_held = board.get_card(grid_x, grid_y)
				board.show_move_tiles(board.get_node(card_held).tile_speed, grid_x, grid_y)
				board.get_node(card_held).original_face_up = board.get_node(card_held).face_up
				board.get_node(card_held).original_attack_position = board.get_node(card_held).in_attack_position

func release_card():
	if holding_card:
		if board.get_node(card_held).tile_speed >= (abs(grid_x_move-grid_x)+abs(grid_y_move-grid_y)): # Speed check
			card_is_moving = true
			board.clear_move_tiles()
		if board.get_node(card_held).face_up:
			board.get_node(card_held).revealed = true
		if board.get_node(card_held).original_face_up != board.get_node(card_held).face_up:
			board.get_node(card_held).just_flipped = true


func card_movement():
	if movement_stack.size() != 0 and !board.get_node(card_held).is_moving:
		card_direction = stack_to_vector()
		board.get_node(card_held).input_direction = card_direction
		board.move_card(grid_x_move, grid_y_move, grid_x_move+card_direction.x, grid_y_move+card_direction.y)
		if board.get_card(grid_x_move, grid_y_move) != card_held:
			board.get_node(card_held).is_moving = true
			grid_x_move += card_direction.x
			grid_y_move += card_direction.y
	elif movement_stack.size() == 0:
		if board.get_node_or_null(card_held) != null:
			if !board.get_node(card_held).is_moving or card_moving_destroyed:
				board.process_trigger(board.get_node(card_held), ["flipped_face_up", "flipped_face_up_voluntarily"])
				board.get_node(card_held).just_flipped = false
				if board.get_node(card_held).card_type == card_types.RITUAL and board.get_node(card_held).face_up:
					board.process_ritual(board.get_node(card_held))
				process_card_terrain(card_held)
				card_is_moving = false
				holding_card = false
				board.get_node(card_held).has_moved = true
				card_held = null
				movement_stack = []
				if board.get_card(grid_x, grid_y) != null:
					get_node("../HUD/HUD_Bottom").update(board.get_node_or_null(board.get_card(grid_x, grid_y)))
				else:
					get_node("../HUD/HUD_Bottom").update(null)

func process_card_terrain(card):
	var terrain_current = tilemap.get_cell(board.get_node(card).grid_x, board.get_node(card).grid_y)
	var card_type = board.get_node(card).card_type
	if terrain_current == terrain.NORMAL or terrain_current == terrain.LABYRINTH:
		board.get_node(card).modifier_terrain = 0
	elif terrain_current == terrain.MEADOW:
		if card_type == card_types.WARRIOR or card_type == card_types.BEAST_WARRIOR:
			board.get_node(card).modifier_terrain = 1
		elif card_type == card_types.SPELLCASTER:
			board.get_node(card).modifier_terrain = -1
		else:
			board.get_node(card).modifier_terrain = 0
	elif terrain_current == terrain.FOREST:
		if card_type == card_types.PLANT or card_type == card_types.BEAST or\
		card_type == card_types.BEAST_WARRIOR or card_type == card_types.INSECT or card_type == card_types.PYRO:
			board.get_node(card).modifier_terrain = 1
		elif card_type == card_types.FIEND:
			board.get_node(card).modifier_terrain = -1
		else:
			board.get_node(card).modifier_terrain = 0
	elif terrain_current == terrain.WASTELAND:
		if card_type == card_types.ROCK or card_type == card_types.DINOSAUR or\
		card_type == card_types.ZOMBIE or card_type == card_types.MACHINE:
			board.get_node(card).modifier_terrain = 1
		elif card_type == card_types.AQUA or card_type == card_types.PLANT or\
		 card_type == card_types.SEA_SERPENT or card_type == card_types.FISH:
			board.get_node(card).modifier_terrain = -1
		else:
			board.get_node(card).modifier_terrain = 0
	elif terrain_current == terrain.MOUNTAIN:
		if card_type == card_types.FAIRY or card_type == card_types.DRAGON or\
		card_type == card_types.THUNDER or card_type == card_types.WINGED_BEAST:
			board.get_node(card).modifier_terrain = 1
		elif card_type == card_types.ZOMBIE:
			board.get_node(card).modifier_terrain = -1
		else:
			board.get_node(card).modifier_terrain = 0
	elif terrain_current == terrain.SEA:
		if card_type == card_types.AQUA or card_type == card_types.THUNDER or\
		card_type == card_types.SEA_SERPENT:
			board.get_node(card).modifier_terrain = 1
		elif card_type == card_types.PYRO or card_type == card_types.MACHINE:
			board.get_node(card).modifier_terrain = -1
		else:
			board.get_node(card).modifier_terrain = 0
	elif terrain_current == terrain.DARK:
		if card_type == card_types.SPELLCASTER or card_type == card_types.FIEND or\
		card_type == card_types.ZOMBIE:
			board.get_node(card).modifier_terrain = 1
		elif card_type == card_types.FAIRY:
			board.get_node(card).modifier_terrain = -1
		else:
			board.get_node(card).modifier_terrain = 0
	elif terrain_current == terrain.CRUSH:
		if card_type == card_types.IMMORTAL:
			board.get_node(card).modifier_terrain = 1
		else:
			board.get_node(card).modifier_terrain = 0
			board.get_node(card).update_stats()
			if board.get_node(card).atk >= 1500:
				board.destroy_card_at(board.get_node(card).grid_x, board.get_node(card).grid_y)
	elif terrain_current == terrain.TOON:
		if board.get_node(card).toon:
			board.get_node(card).modifier_terrain = 1
		else:
			board.get_node(card).modifier_terrain = -1

func process_movement_stack():
	movement_stack.append(tile_to_move_next())
	
	simplify_stack()
	
	if movement_stack.size() != 0 and !board.get_node(card_held).in_attack_position:
		board.get_node(card_held).in_attack_position = true
		board.get_node(card_held).rotating = true
	#print(movement_stack)
	#print("Stack size: ", movement_stack.size())
	return

func tile_to_move_next():
	if input_direction.x == 1:
		return("right")
	elif input_direction.x == -1:
		return("left")
	elif input_direction.y == 1:
		return("down")
	elif input_direction.y == -1:
		return("up")

func stack_to_vector():
	card_direction = movement_stack.pop_front()
	if card_direction == "right":
		return(Vector2(1, 0))
	elif card_direction == "left":
		return(Vector2(-1, 0))
	elif card_direction == "down":
		return(Vector2(0, 1))
	elif card_direction == "up":
		return(Vector2(0, -1))

func simplify_stack():
	var size = movement_stack.size() - 1
	
	#if size >= 2:
		#if is_opposite(movement_stack[size-2], movement_stack[size]):
			#movement_stack.pop_back()
			#movement_stack.pop_at(size-2)
	
	#size = movement_stack.size() - 1
	
	if size >= 1:
		if is_opposite(movement_stack[size-1], movement_stack[size]):
			movement_stack.pop_back()
			movement_stack.pop_back()

func is_opposite(last, next):
	if (last == "right" and next == "left") \
	or (last == "left" and next == "right") \
	or (last == "up" and next == "down") \
	or (last == "down" and next == "up"):
		return true
	else:
		return false

func move_is_valid():
	if !holding_card:
		return true
	# The following movements are illegal:
	# If going outside of movement range
	if board.get_node(card_held).tile_speed < (abs(grid_x_move-grid_x_next)+abs(grid_y_move-grid_y_next)):
		return false
	if board.get_node(card_held).tile_speed == movement_stack.size() and !is_opposite(next_move, movement_stack.back()):
		return false
	if board.get_node(card_held).is_leader:
		# Check if next card is not itself and not empty
		if (board.get_card(grid_x_next, grid_y_next) != null and card_held != board.get_card(grid_x_next, grid_y_next)):
			# If leader attempts to move to enemy card
			if board.get_node(card_held).team != board.get_node(board.get_card(grid_x_next, grid_y_next)).team:
				return false
	# Check if next card is not itself and not empty
	if (board.get_card(grid_x_next, grid_y_next) != null and card_held != board.get_card(grid_x_next, grid_y_next)):
		# If card attempts to move to own leader
		if board.get_node(board.get_card(grid_x_next, grid_y_next)).is_leader \
		and board.get_node(card_held).team == board.get_node(board.get_card(grid_x_next, grid_y_next)).team:
			return false
	# If trying to pass through a card, be it friend or enemy (to attempt attack or fusion)
	# Is the cursor on a non-self card?
	if board.get_card(grid_x, grid_y) != null \
	and card_held != board.get_card(grid_x, grid_y) \
	and !is_opposite(last_move, next_move):
		return false
	# If the next tile is a Labyrinth (Labyrinth index is 8) (NOTE: When Effects are added, check for "can pass through Labyrinth" effect)
	if tilemap.get_cell(grid_x_next, grid_y_next) == 8:
		return false
	return true

func process_summon():
	can_move = false
	if board.get_card(grid_x, grid_y) != null:
		if has_summoned and board.get_node_or_null(board.get_card(grid_x, grid_y)).is_leader:
			in_menu = true
			get_node("../HUD/Hand").move_hand()
			hand.can_move = true
			can_move = true
			return
	if last_summoning != summoning:
		if summoning == true:
			board.show_summon_tiles(grid_x, grid_y)
			grid_x_cancel = grid_x
			grid_y_cancel = grid_y
			last_summoning = true
		else:
			if board.check_if_summonable(grid_x, grid_y):
				#board.clear_move_tiles()
				in_menu = true
				get_node("../HUD/Hand").move_hand()
				"""
				if board.get_card(grid_x, grid_y) != null:
					board.destroy_card_at(grid_x, grid_y) # Temporary until fusions are implemented
				board.create_card(grid_x, grid_y)
				"""
				#last_summoning = false
				#has_summoned = true
				summoning = true
			else:
				summoning = true
	can_move = true
	

func calculate_end_turn_distance(): # Calculates distance between current and other player's last position
	if team == color.RED:
		return position.distance_to(Vector2(75 + 150*grid_x_white, 75 + 150*grid_y_white))
	elif team == color.WHITE:
		return position.distance_to(Vector2(75 + 150*grid_x_red, 75 + 150*grid_y_red))

func calculate_end_turn_direction():
	if team == color.RED:
		return position.direction_to(Vector2(75 + 150*grid_x_white, 75 + 150*grid_y_white))
	elif team == color.WHITE:
		return position.direction_to(Vector2(75 + 150*grid_x_red, 75 + 150*grid_y_red))

func calculate_end_turn_position():
	if team == color.RED:
		return Vector2(75 + 150*grid_x_white, 75 + 150*grid_y_white)
	elif team == color.WHITE:
		return Vector2(75 + 150*grid_x_red, 75 + 150*grid_y_red)

func calculate_cancel_distance(): # Calculates distance between current and original position
	return position.distance_to(Vector2(75 + 150*grid_x_cancel, 75 + 150*grid_y_cancel))

func calculate_cancel_direction():
	return position.direction_to(Vector2(75 + 150*grid_x_cancel, 75 + 150*grid_y_cancel))

func calculate_cancel_position():
	return Vector2(75 + 150*grid_x_cancel, 75 + 150*grid_y_cancel)

func end_turn(delta):
	move_turn_end(delta)
	if !turn_ending:
		if team == color.RED:
			team = color.WHITE
			grid_x = grid_x_white
			grid_y = grid_y_white
			board.stars_white += 3
		else:
			team = color.RED
			grid_x = grid_x_red
			grid_y = grid_y_red
			board.stars_red += 3
		get_node("../HUD/HUD_Layer").is_moving = true
		get_node("../HUD/HUD_Bottom").is_moving = true
		upkeep()
		hand.hand_pos = 1
		hand.fusion_queue = []
		hand.clear_fusion_counters()
		hand.reset_cards_position()
		hand.turn_end_update_hand()
		get_node("../HUD/HUD_Bottom").update(board.get_node_or_null(board.get_card(grid_x, grid_y)))
	

func move(delta):
	movement_percentage += move_speed * delta
	if movement_percentage >= 1.0:
		position = initial_position + (tile_size * input_direction)
		movement_percentage = 0.0
		is_moving = false
		can_move = true
		last_move = next_move
		update_grid_x()
		update_grid_y()
		if board.get_card(grid_x, grid_y) != null:
			hud_bottom.update(board.get_node_or_null(board.get_card(grid_x, grid_y)))
		else:
			hud_bottom.update(null)
	else:
		position = initial_position + (tile_size * input_direction * movement_percentage)

func move_turn_end(delta):
	movement_percentage += 1.2 * delta
	if movement_percentage >= 1.0:
		position = calculate_end_turn_position()
		board.rotation_degrees = 180 * (team - 1)
		movement_percentage = 0.0
		can_move = true
		turn_ending = false
		reappearing = true
		fake_tile.despawning = true
	else:
		position = initial_position + (end_turn_distance * end_turn_direction * movement_percentage)
		board.rotation_degrees += 180 * delta * 1.2

func move_cancel(delta):
	movement_percentage += 2 * delta
	if movement_percentage >= 1.0:
		position = calculate_cancel_position()
		movement_percentage = 0.0
		can_move = true
		cancelling = false
		reappearing = true
		fake_tile.despawning = true
		grid_x = grid_x_cancel
		grid_y = grid_y_cancel
	else:
		position = initial_position + (cancel_distance * cancel_direction * movement_percentage)

func reappear(delta):
	if get_node("Sprite").modulate.a8 <= 255:
		get_node("Sprite").modulate.a8 += 300 * delta
		if get_node("Sprite").modulate.a8 >= 255:
			get_node("Sprite").modulate.a8 = 255
			reappearing = false

func upkeep():
	for card in board.card_age: # Spellbound decrementation loop
		if card != null:
			if board.get_node(card).team == team:
				if !board.get_node(card).is_spellbound():
					board.get_node(card).has_moved = false
	
	for card in board.card_age: # Standby face-up defense trigger check
		if card != null and !board.get_node(card).is_leader and board.get_node(card).team == team:
			board.process_trigger(board.get_node(card), ["standby_face_up_defense"])

func check_spellbound_cards():
	for card in board.card_age:
		if card != null:
			if board.get_node(card).just_spellbound:
				board.get_node(card).just_spellbound = false
			elif board.get_node(card).team == team and board.get_node(card).is_spellbound():
				board.get_node(card).spellbind_decrement()
