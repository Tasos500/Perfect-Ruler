extends CanvasLayer

enum color {RED, WHITE}
var card_num = 0
var hand_pos = 1
var hand_active = false
var current_hand
var current_deck
var fusion_queue = []

var movement_percentage = 0.0
var move_speed = 1000
var initial_position = offset
var input_direction = Vector2(0,-1)
var is_moving = false
var can_move = false
var going_down = false

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
	if Input.is_action_just_pressed("ui_cancel"):
		move_hand()
	elif Input.is_action_just_pressed("ui_right"):
		if hand_pos != 5:
			hand_pos += 1
		move_cursor()
	elif Input.is_action_just_pressed("ui_left"):
		if hand_pos != 1:
			hand_pos -= 1
		move_cursor()
	elif Input.is_action_just_pressed("ui_up"):
		if fusion_queue.size() != 5 and !fusion_queue.has(hand_pos):
			fusion_queue.push_back(hand_pos)
			process_fusion_counters()
	elif Input.is_action_just_pressed("ui_down"):
		if fusion_queue.size() != 0:
			fusion_queue.erase(hand_pos)
			process_fusion_counters()

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_moving:
		move(delta)
		return
	if can_move and hand_active:
		process_button_input()
	elif hand_active and card_anim_active:
		animate_draw_cards()
