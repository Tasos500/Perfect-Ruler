extends Node2D

enum color {RED, WHITE}
const cursor_red = preload("res://Assets/Cursor/Cursor_Red.png")
const cursor_white = preload("res://Assets/Cursor/Cursor_White.png") 

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

onready var board = $".."
onready var tilemap = $"../TileMap"

# Movement stack, in order to hold moves to be done by a card once confirmed.
var movement_stack = []
var last_move = "none"
var next_move = "none"

# Called when the node enters the scene tree for the first time.
func _ready():
	initial_position = position

func _process(delta):
	if card_is_moving:
		card_movement()
	else:
		if !is_moving and can_move:
			process_cursor_input()
		elif input_direction != Vector2.ZERO:
			move(delta)
		else:
			is_moving = false
		if !is_moving:
			process_button_input()
		if team == color.RED:
			get_node("Sprite").texture = cursor_red
		elif team == color.WHITE:
			get_node("Sprite").texture = cursor_white

func process_button_input():
	if Input.is_action_just_pressed("ui_accept"):
		get_parent().create_card(grid_x, grid_y)
	elif Input.is_action_just_pressed("ui_cancel"):
		if !holding_card:
			grab_card()
		else:
			release_card()

func process_cursor_input():
	if !can_move and is_moving:
		return
	if input_direction.y == 0:
		input_direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
		grid_x_next = grid_x + input_direction.x
		grid_y_next = grid_y
		if (input_direction.x == -1 and grid_x == 1) or (input_direction.x == 1 and grid_x == 7):
			input_direction.x = 0
	if input_direction.x == 0:
		input_direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
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
	if !get_parent().is_empty(grid_x, grid_y) and !holding_card:
		grid_x_move = grid_x
		grid_y_move = grid_y
		holding_card = true
		card_held = get_parent().get_card(grid_x, grid_y)
		get_parent().show_move_tiles(get_parent().get_node(card_held).tile_speed, grid_x, grid_y)

func release_card():
	if holding_card:
		if board.get_node(card_held).tile_speed >= (abs(grid_x_move-grid_x)+abs(grid_y_move-grid_y)): # Speed check
			card_is_moving = true
			get_parent().clear_move_tiles()


func card_movement():
	if movement_stack.size() != 0 and !board.get_node(card_held).is_moving:
		card_direction = stack_to_vector()
		board.get_node(card_held).input_direction = card_direction
		board.move_card(grid_x_move, grid_y_move, grid_x_move+card_direction.x, grid_y_move+card_direction.y)
		if board.get_card(grid_x_move, grid_y_move) != card_held:
			board.get_node(card_held).is_moving = true
			grid_x_move += card_direction.x
			grid_y_move += card_direction.y
	elif movement_stack.size() == 0 and !board.get_node(card_held).is_moving:
		card_is_moving = false
		holding_card = false
		card_held = null
		movement_stack = []

func process_movement_stack():
	movement_stack.append(tile_to_move_next())
	
	simplify_stack()
	
	print(movement_stack)
	print("Stack size: ", movement_stack.size())
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
	else:
		position = initial_position + (tile_size * input_direction * movement_percentage)
