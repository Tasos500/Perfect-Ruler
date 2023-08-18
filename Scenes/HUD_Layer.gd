extends CanvasLayer

var movement_percentage = 0.0
var move_speed = 1000
var initial_position = offset
var input_direction = Vector2(0,-1)
var is_moving = true
var can_move = false
var going_down = true
var hud_active = true
onready var board = get_node("../..")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func move(delta):
	movement_percentage += 3 * delta
	if movement_percentage >= 1.0:
		offset = initial_position + (175 * input_direction)
		movement_percentage = 0.0
		is_moving = false
		going_down = !going_down
		initial_position = offset
		update_turn_count()
	else:
		offset = initial_position + (175 * input_direction * movement_percentage)

func update_turn_count():
	if board.turn_counter >= 0:
		get_node("%Turn_Counter").text = "%02d" % [board.turn_counter]
	else:
		get_node("%Turn_Counter").text = "00"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_moving:
		input_direction.y = int(-1 + 2 * int(going_down))
		move(delta)
		
