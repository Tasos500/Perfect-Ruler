extends Camera2D

onready var node_to_follow = get_node("Cursor")

func _process(delta):
	position = node_to_follow.position
