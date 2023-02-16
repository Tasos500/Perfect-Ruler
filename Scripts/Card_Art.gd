extends Sprite

var default_texture = preload("res://Assets/Card/CardArtTemplate.png")


# Called when the node enters the scene tree for the first time.
func _ready():
	texture = default_texture
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	scale.x = float(319.0/texture.get_height())
	scale.y = float(319.0/texture.get_width())
