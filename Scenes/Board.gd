extends Node2D

var matrix

# Ensures effects that trigger at start of turn occur by the oldest card first, and can be used as a general array for checking every card. Cards are popped when destroyed.
var card_age = []

#Decks have exactly 40 cards. These will contain pointers to the databases.
var deck_red
var deck_white

# Cards popped from card_age end up here, and are public to both players.
var graveyard_red
var graveyard_white

var load_card = load("res://Scenes/Card_Placeholder.tscn")

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
		print(matrix)

func move_card_to_empty(x1, y1, x2, y2):
	print(matrix[x1-1][y1-1])
	get_node(matrix[x1-1][y1-1]).position = get_node("Cursor").position
	matrix[x2-1][y2-1] = matrix[x1-1][y1-1]
	matrix[x1-1][y1-1] = null
	
	print(matrix)

func create_card(w, h):
	var new_card = load_card.instance()
	add_child(new_card, true)
	add_to_matrix(new_card, w, h)

# Called when the node enters the scene tree for the first time.
func _ready():
	matrix = create_map(7,7)
	print(matrix)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
