extends CanvasLayer


enum color {RED, WHITE}
var movement_percentage = 0.0
var move_speed = 1000
var initial_position = offset
var input_direction = Vector2(0,-1)
var is_moving = false
var can_move = false
var going_down = false
onready var board = get_node("../..")
onready var cursor = get_node("../../Cursor")

func move(delta):
	movement_percentage += 3 * delta
	if movement_percentage >= 1.0:
		offset = initial_position + (1000 * input_direction)
		movement_percentage = 0.0
		is_moving = false
		going_down = !going_down
		initial_position = offset
	else:
		offset = initial_position + (1000 * input_direction * movement_percentage)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func declare_winner(winner):
	if winner == color.RED:
		$Winner_Text.text = "Player 1 Wins!\nPress [X] to play again.\nPress [Z] to go back to the deck editor."
	elif winner == color.WHITE:
		$Winner_Text.text = "Player 2 Wins!\nPress [X] to play again.\nPress [Z] to go back to the deck editor."
	else:
		$Winner_Text.text = "It's a draw!\nPress [X] to play again.\nPress [Z] to go back to the deck editor."
	is_moving = true

func process_button_input():
	if Input.is_action_just_pressed("ui_accept"):
		var _scene_change = get_tree().change_scene("res://Scenes/Board.tscn")
	elif Input.is_action_just_pressed("ui_cancel"):
		var _scene_change = get_tree().change_scene("res://Scenes/DeckEditor.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_moving:
		input_direction.y = int(-1 + 2 * int(going_down))
		move(delta)
	if !is_moving and going_down and board.winner_declared: #If visible on screen, AKA a winner has been declared
		process_button_input()
