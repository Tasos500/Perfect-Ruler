extends Sprite

onready var tween = get_node("Tween")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	tween.interpolate_property($Sprite, "modulate",
		Color(1,1,1,1), Color(1,1,1,0.5), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	tween.interpolate_property($Sprite, "modulate",
		Color(1,1,1,0.5), Color(1,1,1,1), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
