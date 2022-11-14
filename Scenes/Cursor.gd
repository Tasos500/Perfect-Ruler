extends Node2D

enum color {RED, WHITE}
const cursor_red = preload("res://Assets/Cursor/Cursor_Red.png")
const cursor_white = preload("res://Assets/Cursor/Cursor_White.png") 

export var team = color.RED
const move_speed = 8
var tile_size = 150

var initial_position = Vector2(0,0)
var input_direction = Vector2(0,0)
var is_moving = false
var movement_percentage = 0.0
var can_move = true

var grid_x = 4
var grid_y = 7

var grid_x_red = 4
var grid_y_red = 7

var grid_x_white = 4
var grid_y_white = 1

var grid_x_move
var grid_y_move
var holding_card = false
var card_held

var button_is_pressed = false

# Called when the node enters the scene tree for the first time.
func _ready():
	initial_position = position

func _process(delta):
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
		card_movement()

func process_cursor_input():
	if !can_move:
		return
	if input_direction.y == 0:
		input_direction.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
		if (input_direction.x == -1 and grid_x == 1) or (input_direction.x == 1 and grid_x == 7):
			input_direction.x = 0
		else:
			grid_x += input_direction.x
			if team == color.RED:
				grid_x_red = grid_x
			elif team == color.WHITE:
				grid_x_white = grid_x
	if input_direction.x == 0:
		input_direction.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
		if (input_direction.y == -1 and grid_y == 1) or (input_direction.y == 1 and grid_y == 7):
			input_direction.y = 0
		else:
			grid_y += input_direction.y
			if team == color.RED:
				grid_y_red = grid_y
			elif team == color.WHITE:
				grid_y_white = grid_y
	
	if input_direction != Vector2.ZERO:
		initial_position = position
		is_moving = true

func card_movement():
	if !get_parent().is_empty(grid_x, grid_y) and !holding_card:
		grid_x_move = grid_x
		grid_y_move = grid_y
		holding_card = true
		card_held = get_parent().matrix[grid_x-1][grid_y-1]
	elif get_parent().is_empty(grid_x, grid_y) and holding_card:
		if get_parent().get_node(card_held).tile_speed >= (abs(grid_x_move-grid_x)+abs(grid_y_move-grid_y)):
			get_parent().move_card_to_empty(grid_x_move, grid_y_move, grid_x, grid_y)
			holding_card = false
			card_held = null

func move(delta):
	movement_percentage += move_speed * delta
	if movement_percentage >= 1.0:
		position = initial_position + (tile_size * input_direction)
		movement_percentage = 0.0
		is_moving = false
	else:
		position = initial_position + (tile_size * input_direction * movement_percentage)
