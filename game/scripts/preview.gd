extends Node2D
var global

func _ready():
	global = get_node("/root/global")
	for l in global.levels:
		var level_obj = load("res://levels/" + l + ".tscn")
		
		var level = level_obj.instance()
		add_child(level)
		level.get_node("level").tile_set = load("res://tiles/tiles_simp.tres")
		level.get_node("fin").visible = false
		
		if level.has_node("ParallaxBackground/ParallaxLayer/TextureRect"):
			level.get_node("ParallaxBackground/ParallaxLayer/TextureRect").texture = load("res://textures/b.png")
		yield(get_tree(),"idle_frame")
		yield(get_tree(),"idle_frame")
		var data = get_viewport().get_texture().get_data()
	#	get_viewport().get_texture().get_data()
		data.flip_y()
		data.save_png("res://prev/" + l + ".png")
		level.queue_free()