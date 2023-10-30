extends ItemList


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var json_validator_script = load("res://Scripts/JSON_Validator.cs")
var json_validator = json_validator_script.new()
var valid_addons = []
var addons_file = File.new()
var addons_id = []
var current_set
var current_set_data
var current_deck
var set_list



# Functions ported from Board.gd

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
	return files

func validate_addons(addons):
	for i in addons:
		if json_validator.ValidateJson("user://addons/" + i): # If addon is valid
			addons_file.open("user://addons/" + i, File.READ)
			var addons_text = addons_file.get_as_text()
			addons_file.close()
			valid_addons.append(JSON.parse(addons_text).result)
			addons_id.append(str(valid_addons[addons_id.size()].mod_creator + "." + valid_addons[addons_id.size()].mod_name))
			
	print(addons_id[0])

func load_set_list(number):
	current_set = number
	current_set_data = []
	clear()
	for card in valid_addons[number].cards:
		current_set_data.append(str(addons_id[number] + "." + card.number))
		add_item(card.name)

# Called when the node enters the scene tree for the first time.
func _ready():
	validate_addons(get_addons())
	load_set_list(0)
	grab_focus()
	select(0, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
