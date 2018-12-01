extends Node2D
var global

func _ready():
	global = get_node("/root/global")

	for l in global.levels:
		var level_obj = load("res://levels/" + l + ".tscn")
		
		var level = level_obj.instance()
		add_child(level)
		if level.has_node("canvas"):
			level.get_node("canvas").free()
		var used_cells = level.get_node("level").get_used_cells()
		var top_left = Vector2(INF, INF)
		var bottom_right = Vector2(-INF, -INF)
		for pos in used_cells:
			if pos.x < top_left.x:
				top_left.x = pos.x
			elif pos.x > bottom_right.x:
				bottom_right.x = pos.x
			if pos.y < top_left.y:
				top_left.y = pos.y
			elif pos.y > bottom_right.y:
				bottom_right.y = pos.y
		$vCam.position = top_left * 64
		var zzz = ((bottom_right - top_left + Vector2(1,1)) * 64) / global.screen_size
		print(zzz)
		if (zzz.y - zzz.x) > 2:
			zzz.y = zzz.x + 2
		$vCam.zoom = Vector2(zzz.x, zzz.y)
		
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