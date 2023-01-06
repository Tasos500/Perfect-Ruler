extends Node2D

var spawning = true
var despawning = false


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Sprite").modulate.a8 = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if spawning:
		if get_node("Sprite").modulate.a8 <= 100:
			get_node("Sprite").modulate.a8 += 200 * delta
			if get_node("Sprite").modulate.a8 >= 100:
				 spawning = false
	
	if despawning and !spawning:
		if get_node("Sprite").modulate.a8 >= 0:
			get_node("Sprite").modulate.a8 -= 200 * delta
			if get_node("Sprite").modulate.a8 <= 0:
				queue_free()
