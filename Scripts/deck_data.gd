extends Node


var example_deck = ["Tasos500.TestMod.000",\
					"Tasos500.TestMod.000",\
					"Tasos500.TestMod.000",\
					"Tasos500.TestMod.015",\
					"Tasos500.TestMod.015",\
					"Tasos500.TestMod.015",\
					"Tasos500.TestMod.008",\
					"Tasos500.TestMod.008",\
					"Tasos500.TestMod.008",\
					"Tasos500.TestMod.007",\
					"Tasos500.TestMod.007",\
					"Tasos500.TestMod.007",\
					"Tasos500.TestMod.294",\
					"Tasos500.TestMod.294",\
					"Tasos500.TestMod.294",\
					"Tasos500.TestMod.801",\
					"Tasos500.TestMod.801",\
					"Tasos500.TestMod.801",\
					"Tasos500.TestMod.036",\
					"Tasos500.TestMod.036",\
					"Tasos500.TestMod.036",\
					]

var deck_red = []
var deck_white = []

# Called when the node enters the scene tree for the first time.
func _ready():
	debug_set_example_deck()
	pass # Replace with function body.

func debug_set_example_deck():
	deck_red = example_deck
	deck_white = deck_red


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass