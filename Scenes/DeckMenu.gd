extends Node2D


var json_validator_script = load("res://Scripts/JSON_Validator.cs")
var json_validator = json_validator_script.new()
var valid_addons = []
var addons_file = File.new()
var addons_id = []
var current_set
var current_set_data
var current_deck
var deck1 = []
var deck1_names = []
var deck2 = []
var deck2_names = []
var set_list_last = 0
var deck_list_last = null
var dc_totals = Vector2.ZERO
onready var set_list = $SetCardList
onready var deck_list = $DeckCardList
onready var card_display = $Card_Display
onready var set_list_name = $SetListName
onready var deck_list_name = $DeckListName


# Functions ported from Board.gd

func get_card_data(card_id):
	var mod_id = card_id.split(".")
	if addons_id.find(str(mod_id[0] + "." + mod_id[1])) != -1:
		for card in valid_addons[addons_id.find(str(mod_id[0] + "." + mod_id[1]))].cards:
			if card["number"] == str(mod_id[2]):
				return card

func get_addons():
	var files = []
	var dir = Directory.new()
	dir.open("user://addons")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and file.ends_with(".json"):
			files.append(file)
	dir.list_dir_end()
	if files == []:
		var _scene_change = get_tree().change_scene("res://Scenes/No_Sets_Error.tscn")
	return files

func validate_addons(addons):
	for i in addons:
		if json_validator.ValidateJson("user://addons/" + i): # If addon is valid
			addons_file.open("user://addons/" + i, File.READ)
			var addons_text = addons_file.get_as_text()
			addons_file.close()
			valid_addons.append(JSON.parse(addons_text).result)
			addons_id.append(str(valid_addons[addons_id.size()].mod_creator + "." + valid_addons[addons_id.size()].mod_name))
			

func load_set_list(number):
	current_set = number
	current_set_data = []
	set_list.clear()
	for card in valid_addons[number].cards:
		current_set_data.append(str(addons_id[number] + "." + card.number))
		set_list.add_item(card.name)

func _on_SetCardList_item_activated(index):
	if current_deck == 1:
		if deck1.count(current_set_data[index]) < 3 \
		and deck1.size() < 40: # A deck can have up to 40 cards, and up to 3 copies of each card
			deck1.append(current_set_data[index])
			deck1_names.append(set_list.get_item_text(index))
			deck_list.add_item(set_list.get_item_text(index))
			card_display.card_id = current_set_data[index]
			deck_list_name.text = "Current Deck:\nDeck " + str(current_deck) + "\nSize: " + str(deck1.size()) + "/40"
	else:
		if deck2.count(current_set_data[index]) < 3 \
		and deck2.size() < 40: # A deck can have up to 40 cards, and up to 3 copies of each card
			deck2.append(current_set_data[index])
			deck2_names.append(set_list.get_item_text(index))
			deck_list.add_item(set_list.get_item_text(index))
			card_display.card_id = current_set_data[index]
			deck_list_name.text = "Current Deck:\nDeck " + str(current_deck) + "\nSize: " + str(deck2.size()) + "/40"
	calculate_dc_total()

func _on_SetCardList_item_selected(index):
	card_display.show()
	card_display.card_id = current_set_data[index]
	set_list_last = index


# Called when the node enters the scene tree for the first time.
func _ready():
	current_deck = 1
	deck_list_name.text = "Current Deck:\nDeck " + str(current_deck) + "\nSize: " + str(deck1.size()) + "/40"
	validate_addons(get_addons())
	if addons_id.size() > 0:
		load_set_list(0)
		set_list.grab_focus()
		set_list.select(0, true)
		card_display.show()
		card_display.card_id = current_set_data[0]
		set_list_name.text = "Current Set:\n" + addons_id[current_set]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("ui_right"):
		deck_list.grab_focus()
		if deck_list.get_item_count() != 0:
			if deck_list_last == null:
				deck_list_last = 0
			deck_list.select(deck_list_last, true)
			_on_DeckCardList_item_selected(deck_list_last)
	elif Input.is_action_just_pressed("ui_left"):
		set_list.grab_focus()
		if set_list.get_item_count() != 0:
			if set_list_last == null:
				set_list_last = 0
			set_list.select(set_list_last, true)
			_on_SetCardList_item_selected(set_list_last)
	elif Input.is_action_just_pressed("ui_l1"):
		_on_PrevSet_pressed()
	elif Input.is_action_just_pressed("ui_r1"):
		_on_NextSet_pressed()
	elif Input.is_action_just_pressed("ui_l2"):
		_on_PrevDeck_pressed()
	elif Input.is_action_just_pressed("ui_r2"):
		_on_NextDeck_pressed()
	elif Input.is_action_just_pressed("ui_start") and deck1.size() == 40 and deck2.size() == 40:
		DeckData.deck_red = deck1
		DeckData.deck_white = deck2
		DeckData.addons_id = addons_id
		DeckData.valid_addons = valid_addons
		var _scene_change = get_tree().change_scene("res://Scenes/Board.tscn")
	
	
	
	if deck1.size() == 40 and deck2.size() == 40:
		$PressStartText.show()
	else:
		$PressStartText.hide()





func _on_DeckCardList_item_activated(index):
	if current_deck == 1:
		deck1.pop_at(index)
		deck1_names.pop_at(index)
		deck_list.remove_item(index)
		deck_list_name.text = "Current Deck:\nDeck " + str(current_deck) + "\nSize: " + str(deck1.size()) + "/40"
	else:
		deck2.pop_at(index)
		deck2_names.pop_at(index)
		deck_list.remove_item(index)
		deck_list_name.text = "Current Deck:\nDeck " + str(current_deck) + "\nSize: " + str(deck2.size()) + "/40"
	if deck_list.get_item_count() > 0:
		if index == 0:
			deck_list.select(0)
			_on_DeckCardList_item_selected(0)
		else:
			deck_list.select(index - 1)
			_on_DeckCardList_item_selected(index - 1)
	else:
		card_display.hide()
	calculate_dc_total()


func _on_DeckCardList_item_selected(index):
	card_display.show()
	if current_deck == 1:
		card_display.card_id = deck1[index]
	else:
		card_display.card_id = deck2[index]
	deck_list_last = index


func _on_PrevSet_pressed():
	if current_set - 1 >= 0:
		load_set_list(current_set - 1)
		set_list.select(0, true)


func _on_NextSet_pressed():
	if current_set + 1 < addons_id.size():
		load_set_list(current_set + 1)
		set_list.select(0, true)

func calculate_dc_total():
	dc_totals = Vector2.ZERO
	for card in deck1:
		dc_totals.x += get_card_data(card)["dc"]
	for card in deck2:
		dc_totals.y += get_card_data(card)["dc"]
	$DCTotals.text = "Player 1's DC: " + str(dc_totals.x) + "\nPlayer 2's DC: " + str(dc_totals.y)
	return


func _on_PrevDeck_pressed():
	if current_deck == 2:
		current_deck = 1
		deck_list.clear()
		for card in deck1_names:
			deck_list.add_item(card)
		set_list.select(0, true)
		deck_list_name.text = "Current Deck:\nDeck " + str(current_deck) + "\nSize: " + str(deck1.size()) + "/40"


func _on_NextDeck_pressed():
	if current_deck == 1:
		current_deck = 2
		deck_list.clear()
		for card in deck2_names:
			deck_list.add_item(card)
		set_list.select(0, true)
		deck_list_name.text = "Current Deck:\nDeck " + str(current_deck) + "\nSize: " + str(deck2.size()) + "/40"
