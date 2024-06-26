extends CanvasLayer

enum color {RED, WHITE}
enum card_types {DRAGON, SPELLCASTER, ZOMBIE, WARRIOR, BEAST_WARRIOR, BEAST, WINGED_BEAST, FIEND, FAIRY, INSECT, DINOSAUR, REPTILE, FISH, SEA_SERPENT, MACHINE, THUNDER, AQUA, PYRO, ROCK, PLANT, IMMORTAL, MAGIC, POWER_UP, TRAP_LIMITED, TRAP_FULL, RITUAL}
var card_num = 0
var hand_pos = 1
var hand_active = false
var current_hand
var current_deck
var fusion_queue = []
var fusion_queue_confirm = []
var current_stars = 0
var highest_stars = 0

var movement_percentage = 0.0
var move_speed = 1000
var initial_position = offset
var input_direction = Vector2(0,-1)
var is_moving = false
var can_move = false
var going_down = false

var first_is_board = false
var confirm_step = false
var queue_empty = false
var mid_animation = false
var ready_to_split = false
var cancelling = false
var processing_final = false
var final_nodes = []
var valid_fusion = false
var valid_power_up = false
var valid_checked = false
var fusion1
var fusion2
var reset_start = false
var is_resetting = false
var board_card
var final_card
var first_was_board = false

var card_anim_active = false
var card_anim_current = 6
var card_anim_done = false

var power_card
var affected_card

# Prevents mashing the confirm button, to avoid crash.
var confirm_timer = 0

onready var board  = $"../.."
onready var cursor = $"../../Cursor"

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	setup_hand()

func move_hand():
	move_cursor()
	initial_position = offset
	if going_down:
		input_direction = Vector2(0,1)
	else:
		input_direction = Vector2(0,-1)
		if cursor.has_summoned:
			draw_post_summon()
		else:
			draw()
	is_moving = true
	can_move = false
	hand_active = false
	place_undrawn_cards_offscreen()

func place_undrawn_cards_offscreen():
	if card_num < current_hand.size():
		for i in range (card_num+1, current_hand.size()+1):
			get_node("Hand"+str(i)).position.x = get_node("Hand"+str(i)).default_position.x + 1280 
			get_node("Hand"+str(i)).initial_position = get_node("Hand"+str(i)).position
			get_node("Hand"+str(i)).has_moved = false
			get_node("Hand"+str(i)).is_moving = false
		card_anim_current = card_num + 1

func animate_draw_cards():
	if card_anim_current != 6:
		if !get_node("Hand"+str(card_anim_current)).has_moved and !get_node("Hand"+str(card_anim_current)).is_moving_to_hand:
			get_node("Hand"+str(card_anim_current)).is_moving_to_hand = true
		elif get_node("Hand"+str(card_anim_current)).has_moved:
			card_anim_current += 1
	else:
		card_anim_active = false
		can_move = true
		card_num = 5

func reset_cards_position():
	for i in range (1, 6):
		get_node("Hand"+str(i)).position = get_node("Hand"+str(i)).default_position

func move_cursor():
	get_node("Hand_Cursor").position.x = 180 + 230*(hand_pos-1)

func move(delta):
	movement_percentage += 6 * delta
	if movement_percentage >= 1.0:
		offset = initial_position + (1000 * input_direction)
		movement_percentage = 0.0
		is_moving = false
		if !going_down:
			hand_active = true
			if !cursor.has_summoned:
				card_anim_active = true
		else:
			cursor.in_menu = false
		going_down = !going_down
	else:
		offset = initial_position + (1000 * input_direction * movement_percentage)

func process_button_input():
	if mid_animation or processing_final:
		return
	else:
		if Input.is_action_just_pressed("ui_cancel") and !mid_animation:
			if !confirm_step:
				move_hand()
			elif confirm_step and !mid_animation:
				reverse_fusion_queue()
		elif Input.is_action_just_pressed("ui_right") and !confirm_step and !mid_animation:
			if hand_pos != 5 and hand_pos < current_hand.size():
				hand_pos += 1
			move_cursor()
		elif Input.is_action_just_pressed("ui_left") and !confirm_step and !mid_animation:
			if hand_pos != 1:
				hand_pos -= 1
			move_cursor()
		elif Input.is_action_just_pressed("ui_up") and !confirm_step and !mid_animation and !cursor.has_summoned:
			if fusion_queue.size() != 5 and !fusion_queue.has(hand_pos) and (get_node("Hand" + str(hand_pos)).level <= current_stars\
			 or get_node("Hand" + str(hand_pos)).card_type == card_types.MAGIC \
			or get_node("Hand" + str(hand_pos)).card_type == card_types.TRAP_FULL \
			or get_node("Hand" + str(hand_pos)).card_type == card_types.TRAP_LIMITED\
			or get_node("Hand" + str(hand_pos)).card_type == card_types.RITUAL\
			or get_node("Hand" + str(hand_pos)).card_type == card_types.POWER_UP):
				fusion_queue.push_back(hand_pos)
				process_fusion_counters()
		elif Input.is_action_just_pressed("ui_down") and !confirm_step and !mid_animation and !cursor.has_summoned:
			if fusion_queue.size() != 0:
				fusion_queue.erase(hand_pos)
				process_fusion_counters()
		elif Input.is_action_just_pressed("ui_accept") and !mid_animation and !cursor.has_summoned and confirm_timer >= 0.4:
			confirm_timer = 0
			if !confirm_step and !processing_final and !cancelling:
				process_fusion_queue()
			elif confirm_step and !mid_animation and !cancelling and !processing_final:
				processing_final = true
				mid_animation = true
			

# Draws cards into the Cursor's hand, until it reaches 5.
func draw():
	if cursor.team == color.RED:
		current_hand = board.hand_red
		current_deck = board.deck_red
	else:
		current_hand = board.hand_white
		current_deck = board.deck_white
	card_num = current_hand.size()
	while current_hand.size() != 5 and current_deck.size() != 0:
		current_hand.push_back(str(current_deck.pop_front()))
		get_node("Hand"+str(current_hand.size())).card_id = current_hand[current_hand.size() - 1]
	for i in range (1, current_hand.size() + 1):
			get_node("Hand"+str(i)).show()
	for i in range (current_hand.size()+1, 6):
			get_node("Hand"+str(i)).hide()

func draw_post_summon():
	if cursor.team == color.RED:
		current_hand = board.hand_red
		current_deck = board.deck_red
	else:
		current_hand = board.hand_white
		current_deck = board.deck_white
	card_num = current_hand.size()
	if card_num != 0:
		for i in range (1, current_hand.size()+1):
			get_node("Hand"+str(i)).card_id = current_hand[i - 1]
		for i in range (current_hand.size()+1, 6):
			get_node("Hand"+str(i)).hide()

func process_fusion_counters():
	if fusion_queue.size() > 0:
		for i in range (0, fusion_queue.size()):
			get_node("Fusion_Counter"+str(i+1)).position = Vector2(180 + 230*(fusion_queue[i]-1), 250)
			get_node("Fusion_Counter"+str(i+1)).show()
		if fusion_queue.size() < 5:
			for i in range(fusion_queue.size(), 5):
				get_node("Fusion_Counter"+str(i+1)).hide()
	else:
		for i in range (1, 5):
			get_node("Fusion_Counter"+str(i)).hide()
	for i in range (1,5):
		get_node("Fusion_Counter"+str(i) + "/Label").text=str(i)

func clear_fusion_counters():
	for i in range (1, 6):
		get_node("Fusion_Counter"+str(i)).hide()

func turn_end_update_hand():
	if cursor.team == color.RED:
		current_hand = board.hand_red
		current_deck = board.deck_red
	else:
		current_hand = board.hand_white
		current_deck = board.deck_white
	for i in range (1, current_hand.size()+1):
		if current_hand.size() != 0:
			get_node("Hand"+str(i)).card_id = current_hand[i - 1]

func process_fusion_queue():
	mid_animation = true
	fusion_queue_confirm = []
	if fusion_queue.size() == 0:
		if get_node("Hand" + str(hand_pos)).level <= current_stars \
		or get_node("Hand" + str(hand_pos)).card_type == card_types.MAGIC \
		or get_node("Hand" + str(hand_pos)).card_type == card_types.TRAP_FULL \
		or get_node("Hand" + str(hand_pos)).card_type == card_types.TRAP_LIMITED\
		or get_node("Hand" + str(hand_pos)).card_type == card_types.RITUAL\
		or get_node("Hand" + str(hand_pos)).card_type == card_types.POWER_UP:
			fusion_queue.push_back(hand_pos)
			fusion_queue_confirm.push_back(get_hand_card_id(hand_pos))
			queue_empty = true
		else:
			mid_animation = false
			return
	else:
		for i in fusion_queue:
			fusion_queue_confirm.push_back(get_hand_card_id(i))
	highest_stars = 0
	for card in fusion_queue:
		if get_node("Hand" + str(card)).level > highest_stars:
			highest_stars = get_node("Hand" + str(card)).level
	if !board.is_empty(cursor.grid_x, cursor.grid_y):
		first_is_board = true
		board_card = board.get_node(board.get_card(cursor.grid_x, cursor.grid_y))
		fusion_queue_confirm.push_front(board.get_node(board.get_card(cursor.grid_x, cursor.grid_y)).card_id)
	else:
		first_is_board = false
	#print(fusion_queue_confirm)
	for i in range(1, 6):
		get_node("Hand"+str(i)).initial_position = get_node("Hand"+str(i)).position
		get_node("Hand"+str(i)).has_moved = false
		get_node("Hand"+str(i)).is_moving = false
		if fusion_queue.has(i):
			get_node("Hand"+str(i)).z_index += 5 - fusion_queue.find(i)
			if get_node("Hand"+str(i)).position.x < 1280/2:
				get_node("Hand"+str(i)).input_direction = Vector2(1,0)
			elif get_node("Hand"+str(i)).position.x > 1280/2:
				get_node("Hand"+str(i)).input_direction = Vector2(-1,0)
			get_node("Hand"+str(i)).is_moving_to_center = true
		else:
			get_node("Hand"+str(i)).is_moving_down = true
	$Hand_Cursor.hide()
	for j in range (1, 6):
		get_node("Fusion_Counter"+str(j)).hide()
	ready_to_split = true

func reverse_fusion_queue():
	cancelling = true
	mid_animation = true
	first_is_board = false
	
	# These fix a possible crash when mashing the confirm button 
	# during the combine-split animation before the confirm step, then returning.
	# This happened due to the game thinking the queue was confirmed then cancelled at the same time,
	# resulting in final_nodes[] being empty when looking to reverse the process.
	processing_final = false
	confirm_step = false
	cursor.has_summoned = false
	
	highest_stars = 0
	var fusion_card
	final_nodes = []
	for i in range (1, fusion_queue_confirm.size()+1):
		fusion_card = get_node("Fusion_Card"+str(i))
		fusion_card.initial_position = fusion_card.position
		if fusion_card.position.x > (1280/2):
			fusion_card.input_direction = Vector2(-1, 0)
		elif fusion_card.position.x < (1280/2):
			fusion_card.input_direction = Vector2(1, 0)
		fusion_card.is_moving_to_center = true
		fusion_card.has_moved = false
	ready_to_split = true

func return_to_hand():
	if board_card != null:
		board_card.show()
	for i in range (1, current_hand.size() + 1):
		get_node("Hand"+str(i)).show()
		get_node("Hand"+str(i)).initial_position = get_node("Hand"+str(i)).position
		if fusion_queue.has(i):
			get_node("Hand"+str(i)).is_moving_to_default = true
			if i < 3:
				get_node("Hand"+str(i)).input_direction = Vector2(-1,0)
			elif i > 3:
				get_node("Hand"+str(i)).input_direction = Vector2(1,0)
		else:
			get_node("Hand"+str(i)).is_moving_up = true
		get_node("Hand"+str(i)).has_moved = false
	for i in range (1, fusion_queue_confirm.size()+1):
		get_node("Fusion_Card"+str(i)).queue_free()
	$Hand_Cursor.show()
	confirm_step = false
	mid_animation = false
	if queue_empty:
		queue_empty = false
		fusion_queue = []
	if fusion_queue.size() != 0:
		for i in range (1, fusion_queue.size()+1):
			get_node("Fusion_Counter"+str(i)).show()
	cancelling = false

func prepare_confirm_screen():
	if board_card != null and first_is_board:
		board_card.hide()
	var fusion_card
	for i in range (1, fusion_queue_confirm.size()+1):
		fusion_card = load("res://Scenes/Card_Hand.tscn").instance()
		fusion_card.name = "Fusion_Card"+str(i)
		fusion_card.card_id = fusion_queue_confirm[i-1]
		fusion_card.scale = Vector2(2, 2)
		add_child(fusion_card, false)
		final_nodes.push_back(fusion_card.name)
		fusion_card.position = fusion_card.center_position
		if first_is_board:
			fusion_card.data_paste(board.get_node(board.get_card(cursor.grid_x, cursor.grid_y)).data_copy())
		fusion_card.horizontal_distance = 1280/4
		if i == 1:
			fusion_card.input_direction = Vector2(-1, 0)
		else:
			fusion_card.input_direction = Vector2(1, 0)
			fusion_card.horizontal_distance += 20*i
		fusion_card.is_moving_horizontally = true
		fusion_card.initial_position = fusion_card.position
		fusion_card.z_index = 4-i
		if i == fusion_queue_confirm.size():
			for j in range (1, 6):
				get_node("Hand"+str(j)).hide()
	mid_animation = false
	confirm_step = true

func process_final():
	mid_animation = true
	if fusion_queue_confirm.size() > 1:
		if get_node_or_null(final_nodes[0]) == null:
			final_nodes.pop_front()
			fusion_queue_confirm.pop_front()
			return
		fusion1 = get_node(final_nodes[0])
		fusion1.is_first_in_queue = true
		fusion1.is_second_in_queue = false
		
		fusion2 = get_node(final_nodes[1])
		fusion2.is_first_in_queue = false
		fusion2.is_second_in_queue = true
		if !fusion2.is_in_center() \
		and fusion2.position.x > 1280/2 and !fusion2.is_moving_horizontally:
			valid_checked = false
			valid_fusion = false
			valid_power_up = false
			fusion2.is_moving_horizontally = true
			fusion2.horizontal_distance = abs(1280/2 - fusion2.position.x)
			fusion2.input_direction = Vector2(-1,0)
			fusion2.has_moved = false
		elif fusion2.is_in_center() and !valid_checked:
			valid_checked = true
			if board.process_fusion(fusion1.card_id, fusion2.card_id) != null:
				valid_fusion = true
				# Fusion checks take priority, for cards such as Elegant Egotist,
				# which are Power-Ups used as Fusion material.
			elif fusion1.card_type == card_types.POWER_UP:
				if board.search(fusion1.effect_list[0].get("target"), fusion1.effect_list[0].get("attribute_target"), fusion1, ["HUD/Hand/" + fusion2.name]) != null:
					valid_power_up = true
					power_card = fusion1
					affected_card = fusion2
			elif fusion2.card_type == card_types.POWER_UP:
				if board.search(fusion2.effect_list[0].get("target"), fusion2.effect_list[0].get("attribute_target"), fusion2, ["HUD/Hand/" + fusion1.name]) != null:
					valid_power_up = true
					power_card = fusion2
					affected_card = fusion1
			else:
				valid_fusion = false
				valid_power_up = false
				power_card = null
				affected_card = null
			fusion2.is_moving_to_first = true
			fusion2.has_moved = false
		# Add an extra elif for when a valid power-up can occur (valid_power_up)
		# Basically do the same animations for a successful fusion, but update the
		# affected card's stats
		elif fusion1.position == fusion2.position and !valid_fusion and valid_power_up and !fusion1.despawning:
			board.process_power_up_hand(power_card, affected_card)
			if fusion1 == power_card:
				fusion1.despawning = true
			else:
				fusion2.card_id = fusion1.card_id
				fusion2.data_paste(fusion1.data_copy())
				fusion1.despawning = true
			board.add_to_graveyard(power_card)
			affected_card.update_stats()
		elif fusion1.position == fusion2.position and valid_fusion and !valid_power_up and !fusion1.despawning:
			var id1 = fusion1.card_id
			var id2 = fusion2.card_id
			fusion2.card_id = board.process_fusion(id1, id2)
			fusion2.has_moved_card = false
			board.add_to_graveyard(id1)
			board.add_to_graveyard(id2)
			fusion1.despawning = true
	else:
		if first_is_board:
			board.banish_at(cursor.grid_x, cursor.grid_y)
			first_was_board = true
			first_is_board = false
		fusion1 = get_node(final_nodes[0])
		fusion1.is_moving_to_field = true
		fusion1.has_moved = false
		mid_animation = false
		cursor.has_summoned = true
		if cursor.team == color.RED:
			board.stars_red -= highest_stars
		else:
			board.stars_white -= highest_stars

func reset_hand():
	hide()
	move_hand()
	cursor.has_summoned = true
	is_resetting = true
	for i in range (1, 6):
		if fusion_queue.has(i):
			current_hand[i-1] = null
	while current_hand.find(null) != -1:
		current_hand.erase(null)
	for i in get_children():
		if i.name != "Hand_Cursor":
			i.queue_free()
	board.clear_move_tiles()
	confirm_step = false
	
	first_is_board = false
	confirm_step = false
	queue_empty = false
	mid_animation = false
	ready_to_split = false
	cancelling = false
	processing_final = false
	final_nodes = []
	valid_fusion = false
	valid_power_up = false
	valid_checked = false
	card_anim_active = false
	card_anim_current = 6
	card_anim_done = false
	card_num = 0
	hand_pos = 1
	hand_active = false
	fusion_queue = []
	fusion_queue_confirm = []
	
	board.get_node(board.get_card(cursor.grid_x, cursor.grid_y)).data_paste(final_card)
	final_card = null
	
	cursor.has_summoned = true

func setup_hand():
	var hand
	var fusion_counter
	for i in range(1, 6):
		hand = load("res://Scenes/Card_Hand.tscn").instance()
		hand.name = str("Hand"+str(i))
		hand.position = Vector2(180 + 230 * (i-1), 480)
		hand.default_position = hand.position
		hand.scale = Vector2(2, 2)
		hand.hide()
		add_child(hand, false)
		fusion_counter = load("res://Scenes/Fusion_Counter.tscn").instance()
		fusion_counter.visible = false
		fusion_counter.name = str("Fusion_Counter"+str(i))
		add_child(fusion_counter, false)
	show()
	board_card = null
	draw_post_summon()
	for i in range (1, 6):
		get_node("Hand"+str(i)).show()
	$"Hand_Cursor".show()
	cursor.last_summoning = false
	show()
	cursor.summoning = false
	for i in range (1, 6):
		get_node("Hand"+str(i)).position = get_node("Hand"+str(i)).default_position
	
	hand_pos = 1
	move_cursor()

func check_ready_to_split():
	if fusion_queue.back() == 3:
		for i in range (1, 6, 4):
			if get_node("Hand" + str(i)).position.y == 1480 or get_node("Hand" + str(i)).is_in_center():
				return true
	return false

func get_hand_card_id(number):
	return get_node("Hand"+str(number)).card_id

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if cursor.team == color.RED:
		current_stars = board.stars_red
	else:
		current_stars = board.stars_white
	if is_moving:
		move(delta)
		return
	if processing_final and mid_animation:
		process_final()
		return
	elif reset_start:
		reset_start = false
		reset_hand()
	elif is_resetting:
		processing_final = false
		hand_active = false
		cursor.in_menu = false
		is_resetting = false
		setup_hand()
		return
	if !mid_animation:
		if can_move and hand_active:
			process_button_input()
		elif hand_active and card_anim_active and !cursor.has_summoned:
			animate_draw_cards()
	if fusion_queue.size() != 0:
		if !cancelling and ready_to_split and mid_animation and ((fusion_queue.back() == 3 and check_ready_to_split()) or (fusion_queue.back() != 3 and get_node("Hand"+str(fusion_queue.back())).is_in_center())):
			prepare_confirm_screen()
			ready_to_split = false
		if cancelling and ready_to_split and mid_animation and get_node_or_null("Fusion_Card"+str(fusion_queue.size())) != null:
			if get_node("Fusion_Card"+str(fusion_queue.size())).is_in_center():
				return_to_hand()
				ready_to_split = false
	if confirm_timer < 0.4: # Approximate time for confirm animation to finish, with some margin for error.
		confirm_timer += delta
