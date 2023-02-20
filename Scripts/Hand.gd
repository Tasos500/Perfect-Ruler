extends CanvasLayer

enum color {RED, WHITE}
var card_num = 0
var hand_pos = 1
var hand_active = false
var current_hand
var current_deck
var fusion_queue = []
var fusion_queue_confirm = []

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

var card_anim_active = false
var card_anim_current = 6
var card_anim_done = false

onready var board  = $"../.."
onready var cursor = $"../../Cursor"

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()

func move_hand():
	initial_position = offset
	if going_down:
		input_direction = Vector2(0,1)
	else:
		input_direction = Vector2(0,-1)
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
			card_anim_active = true
		else:
			cursor.in_menu = false
			cursor.has_summoned = false
			hand_pos = 1
			move_cursor()
		going_down = !going_down
	else:
		offset = initial_position + (1000 * input_direction * movement_percentage)

func process_button_input():
	if Input.is_action_just_pressed("ui_cancel") and !mid_animation:
		if !confirm_step:
			move_hand()
		elif confirm_step and !mid_animation:
			reverse_fusion_queue()
	elif Input.is_action_just_pressed("ui_right") and !confirm_step and !mid_animation:
		if hand_pos != 5:
			hand_pos += 1
		move_cursor()
	elif Input.is_action_just_pressed("ui_left") and !confirm_step and !mid_animation:
		if hand_pos != 1:
			hand_pos -= 1
		move_cursor()
	elif Input.is_action_just_pressed("ui_up") and !confirm_step and !mid_animation:
		if fusion_queue.size() != 5 and !fusion_queue.has(hand_pos):
			fusion_queue.push_back(hand_pos)
			process_fusion_counters()
	elif Input.is_action_just_pressed("ui_down") and !confirm_step and !mid_animation:
		if fusion_queue.size() != 0:
			fusion_queue.erase(hand_pos)
			process_fusion_counters()
	elif Input.is_action_just_pressed("ui_accept") and !mid_animation:
		if !confirm_step:
			process_fusion_queue()
		elif confirm_step and !mid_animation:
			process_final()

# Draws cards into the Cursor's hand, until it reaches 5.
func draw():
	if cursor.team == color.RED:
		current_hand = board.hand_red
		current_deck = board.deck_red
	else:
		current_hand = board.hand_white
		current_deck = board.deck_white
	card_num = current_hand.size()
	while current_hand.size() != 5:
		if current_deck.size() == 0:
			break
		current_hand.push_back(str(current_deck.pop_front()))
		get_node("Hand"+str(current_hand.size())).card_id = current_hand[current_hand.size() - 1]

func process_fusion_counters():
	if fusion_queue.size() > 0:
		for i in range (0, fusion_queue.size()):
			get_node("Fusion_Counter"+str(i+1)).position = Vector2(180 + 230*(fusion_queue[i]-1), 180)
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
	for i in range (1, 6):
		if current_hand.size() != 0:
			get_node("Hand"+str(i)).card_id = current_hand[i - 1]

func process_fusion_queue():
	mid_animation = true
	fusion_queue_confirm = []
	if fusion_queue.size() == 0:
		fusion_queue.push_back(hand_pos)
		fusion_queue_confirm.push_back(get_hand_card_id(hand_pos))
		queue_empty = true
	else:
		for i in fusion_queue:
			fusion_queue_confirm.push_back(get_hand_card_id(i))
	if !board.is_empty(cursor.grid_x, cursor.grid_y):
		if !board.get_node(board.get_card(cursor.grid_x, cursor.grid_y)).is_leader:
			first_is_board = true
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
	var fusion_card
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
	for i in range (1, 6):
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
	confirm_step = true
	var fusion_card
	for i in range (1, fusion_queue_confirm.size()+1):
		fusion_card = load("res://Scenes/Card_Hand.tscn").instance()
		fusion_card.name = "Fusion_Card"+str(i)
		fusion_card.card_id = fusion_queue_confirm[i-1]
		fusion_card.scale = Vector2(2, 2)
		add_child(fusion_card, false)
		fusion_card.position = fusion_card.center_position
		if first_is_board:
			first_is_board = false
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

func process_final():
	pass

func check_ready_to_split():
	if fusion_queue.back() == 3:
		for i in range (1, 6):
			if i == 3:
				continue
			if get_node("Hand" + str(i)).position.y == 1480 or get_node("Hand" + str(i)).is_in_center():
				return true
	return false

func get_hand_card_id(number):
	return get_node("Hand"+str(number)).card_id

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_moving:
		move(delta)
		return
	if can_move and hand_active:
		process_button_input()
	elif hand_active and card_anim_active:
		animate_draw_cards()
	if fusion_queue.size() != 0:
		if !cancelling and ready_to_split and mid_animation and ((fusion_queue.back() == 3 and check_ready_to_split()) or (fusion_queue.back() != 3 and get_node("Hand"+str(fusion_queue.back())).is_in_center())):
			prepare_confirm_screen()
			ready_to_split = false
		if cancelling and ready_to_split and mid_animation and get_node_or_null("Fusion_Card"+str(fusion_queue.size())) != null:
			if get_node("Fusion_Card"+str(fusion_queue.size())).is_in_center():
				return_to_hand()
				ready_to_split = false
