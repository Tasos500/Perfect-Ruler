extends Node


var example_deck = ["Tasos500.TestMod.015",\
					"Tasos500.TestMod.015",\
					"Tasos500.TestMod.015",\
					"Tasos500.TestMod.008",\
					"Tasos500.TestMod.008",\
					"Tasos500.TestMod.008",\
					"Tasos500.TestMod.036",\
					"Tasos500.TestMod.036",\
					"Tasos500.TestMod.036",\
					"Tasos500.TestMod.417",\
					"Tasos500.TestMod.417",\
					"Tasos500.TestMod.417",\
					"Tasos500.TestMod.326",\
					"Tasos500.TestMod.326",\
					"Tasos500.TestMod.326",\
					"Tasos500.TestMod.780",\
					"Tasos500.TestMod.780",\
					"Tasos500.TestMod.780",\
					]


var example_deck_names =   ["Tyhone #2",\
							"Tyhone #2",\
							"Tyhone #2",\
							"Darkfire Dragon",\
							"Darkfire Dragon",\
							"Darkfire Dragon",\
							"Time Wizard",\
							"Time Wizard",\
							"Time Wizard",\
							"Man-Eater Bug",\
							"Man-Eater Bug",\
							"Man-Eater Bug",\
							"Candle of Fate",\
							"Candle of Fate",\
							"Candle of Fate",\
							"Megamorph",\
							"Megamorph",\
							"Megamorph",\
							]
var deck_red = []
var deck_white = []
var addons_id = []
var valid_addons = []
var first_run = false
var deck_red_names = []
var deck_white_names = []
var debug = false

# Called when the node enters the scene tree for the first time.
func _ready():
	debug_set_example_deck()
	pass # Replace with function body.

func debug_set_example_deck():
	deck_red = example_deck.duplicate()
	deck_white = example_deck.duplicate()
	deck_red_names = example_deck_names.duplicate()
	deck_white_names = example_deck_names.duplicate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
