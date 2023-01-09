extends Node2D

var spawning = true
var despawning = false
var summon_tile = false
var clone_cursor = false
var was_clone = false
var spawned = false


# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Sprite").modulate.a8 = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if summon_tile:
		$Sprite.texture = load("res://Assets/Tile/tile_summon_indicator.png")
	elif clone_cursor:
		clone_cursor = false
		was_clone = true
		z_index = 6
		spawned = true
		despawning = true
		spawning = false
		if get_node("../Cursor").team == 0:
			$Sprite.texture = load("res://Assets/Cursor/Cursor_Red.png")
		else:
			$Sprite.texture = load("res://Assets/Cursor/Cursor_White.png")
			
	if spawned:
		get_node("Sprite").modulate.a8 = 255
		spawned = false
	
	if spawning:
		if get_node("Sprite").modulate.a8 <= 100:
			get_node("Sprite").modulate.a8 += 200 * delta
			if get_node("Sprite").modulate.a8 >= 100:
				 spawning = false
	
	
	
	if despawning and !spawning:
		if get_node("Sprite").modulate.a8 >= 0:
			get_node("Sprite").modulate.a8 -= (200 + int(was_clone) * 100) * delta
			if get_node("Sprite").modulate.a8 <= 0:
				queue_free()
