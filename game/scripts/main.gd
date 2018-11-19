extends Node2D
var cell_size = 32
var tile_cell_size = 64
var world_size = 128
var world = []
var offset = Vector2(32,32)
var empty_cell_obj = load("res://objects/empty_cell.tscn")
var global
var tilemap = null
var dCount = 0
var on_pause = false
var players = []
var level = null
var top_left = Vector2()
var bottom_right = Vector2()
var map_size = Vector2()
var gold_on_level = 0
var gold_found = 0
var fin_map = null
var set_num = 1


func add_player(player):
	players.append(weakref(player))
	if player.bot_class == 0:
		$main_camera.set_target(player)

func update_gold_count(value):
	gold_found += value
	if gold_found == gold_on_level:
		final()
	$ui/goldCount.text = str(gold_on_level) + "/" + str(gold_found)


func _ready():
	level = $level

	global = get_node("/root/global")
	if global.level != -1:
		$level.queue_free()
		var level_file = load("res://levels/" + global.levels[global.level] + ".tscn")
		var new_level = level_file.instance()
		add_child(new_level)
		new_level.name = "level"
		level = new_level
	offset = Vector2(0,0)
	tilemap = level.get_node("level")
	fin_map = level.get_node("fin")
	calculate_map_bounds(level.get_node("level"))
	update_gold_count(0)
	for x in range(world_size):
		world.append([])
		for y in range(world_size):
			world[x].append(null)
	if level.has_method("_rebuild"):
		level._rebuild(1)
	for mob in level.get_node("bots").get_children():
		mob.goal = level.get_node("player").position
		mob.nav = level.get_node("nav")
		mob.nav_from_above = level.get_node("nav_fa")
		mob.goal_obj = level.get_node("player")
		mob.update_path()
	if level.has_node("fin"):
		level.get_node("fin").visible = false
	
	var set_name = level.get_node("level").tile_set.resource_path.split("/")[3].split(".")[0]
	if set_name == "tiles":
		set_num = 1
	if set_name == "tiles2":
		set_num = 2
	
func _input(event):
	if Input.is_action_just_pressed("pause"):
		on_pause = !on_pause
		get_tree().paused = on_pause

func map_to_world(cell):
	var pos = Vector2(cell.x * cell_size + offset.x, cell.y * cell_size + offset.y)
	return pos

func final():
	play_sound("v0")
	for c in fin_map.get_used_cells():
		tilemap.set_cell(c.x, c.y, fin_map.get_cell(c.x, c.y))
		
	pass

func world_to_map(pos):
	pos = pos + Vector2(cell_size/4, cell_size/4)
	var cell = Vector2(int(pos.x / cell_size), int(pos.y / cell_size))
	return cell

func world_to_tile(pos):
	var cell_pos = world_to_tile_pos(pos)
	var tile = tilemap.get_cell(cell_pos.x, cell_pos.y)
	return tile

func world_to_tile_pos(pos):
	pos = pos + Vector2(tile_cell_size/4, tile_cell_size/4)
	var cell_pos = Vector2(int(pos.x / tile_cell_size), int(pos.y / tile_cell_size))
	return cell_pos

func tile_to_world_pos(cell_pos):
	return tilemap.map_to_world(cell_pos)

func add_empty_cell(cell_pos):
	var empty_cell = empty_cell_obj.instance()
	level.add_child(empty_cell)
	empty_cell.set_cell(tilemap.get_cell(cell_pos.x, cell_pos.y))
	empty_cell.cell_pos = cell_pos
	empty_cell.position = tilemap.map_to_world(cell_pos) + Vector2(32,32)
	replace_cell(cell_pos, -1)
	return empty_cell

func kill_in_cell(cell_pos):
	for p in players:
		if p.get_ref() != null:
			var p_cell_pos32 = world_to_tile_pos(p.get_ref().position - Vector2(32,0))
			if p_cell_pos32 == cell_pos or p.get_ref().current_tile_pos == cell_pos:
				p.get_ref().die()

func get_cell(cell_pos):
	return tilemap.get_cell(cell_pos.x, cell_pos.y)

func get_tile_name(cell):
	var cell_name = ""
	var ids = tilemap.tile_set.get_tiles_ids()
	if ids.find(cell, 0) != -1:
		cell_name = tilemap.tile_set.tile_get_name(cell)
	return cell_name

func replace_cell(cell_pos, cell):
	tilemap.set_cell(cell_pos.x, cell_pos.y, cell)

# Перерахунок позиції в цілочисленні значення з кроком в 64
func to_64(pos):
	pos = pos + Vector2(tile_cell_size/4, tile_cell_size/4)
	var cell_pos = Vector2(int(pos.x / tile_cell_size), int(pos.y / tile_cell_size))
	pos = tilemap.map_to_world(cell_pos) + Vector2(32,32)
	return pos

func play_sound(_name):
	if $sounds.has_node(_name):
		$sounds.get_node(_name).play()

func is_cell_vacant(player):
	var is_vacant = true
	if player.bot_class == 0:
		return true
	var direction = player.direction
	var grid_pos = world_to_map(player.position) + direction
	for x in range(2):
		for y in range(2):
			if (grid_pos.x + x - 1) < 0 or (grid_pos.x + x - 1) >= world.size():
				is_vacant = false
			if (grid_pos.y + y - 1) < 0 or (grid_pos.y + y - 1) >= world[0].size():
				is_vacant = false
			var cell = world[grid_pos.x + x - 1][grid_pos.y + y - 1]
			if cell != null:
				if cell.get_ref() != player:
					is_vacant = false
	if !is_vacant:
#		print(player.name)
#		var rand_pos = Vector2()
#		rand_pos.x = randf() * map_size.x + top_left.x
#		rand_pos.y = randf() * map_size.y + bottom_right.y
#		player.goal = rand_pos
#		player.follow_player = false
		return false
	return true

func remove_player(player):
	var grid_pos = world_to_map(player.position)
	for x in range(world_size):
		for y in range(world_size):
			if world[x][y]:
				if world[x][y].get_ref() == player:
					world[x][y] = null

func update_player_pos(player):
	remove_player(player)
	var grid_pos = world_to_map(player.position)
	var new_grid_pos = grid_pos + player.direction
	var target_pos = map_to_world(new_grid_pos) 
	if player.bot_class == 0:
		return target_pos
	for x in range(2):
		for y in range(2):
			world[new_grid_pos.x + x - 1][new_grid_pos.y + y - 1] = weakref(player)
	return target_pos
	
func print_world():
	var ss = ""
	for x in range(world_size):
		var l = ""
		for y in range(world_size):
			if world[y][x] != null:
				l += "[color=green][[/color]+[color=green]][/color]"
			else:
				l += " . "
		ss += l + "\n"
	$ui/grid.bbcode_text = ss
			
func calculate_map_bounds(_tilemap):
	var used_cells = _tilemap.get_used_cells()
	top_left.x = INF
	top_left.y = INF
	
	for pos in used_cells:
		var tn = get_tile_name(_tilemap.get_cell(pos.x, pos.y))
		if tn == "gold":
			gold_on_level += 1
		if pos.x < top_left.x:
			top_left.x = pos.x
		elif pos.x > bottom_right.x:
			bottom_right.x = pos.x
		if pos.y < top_left.y:
			top_left.y = pos.y
		elif pos.y > bottom_right.y:
			bottom_right.y = pos.y
	bottom_right = (bottom_right + Vector2(1,1)) * 64
	top_left *= 64
	map_size = bottom_right - top_left 
	$main_camera.limit_left = top_left.x 
	$main_camera.limit_right = bottom_right.x 
	$main_camera.limit_top = top_left.y
	$main_camera.limit_bottom = bottom_right.y 

func exit():
	get_tree().paused = true
	play_sound("v1")

func busted():
	$main_camera.zoom_in(0.6)
	play_sound("busted")
	get_tree().paused = true


func _process(delta):
	if $ui/grid.visible and !on_pause:
		print_world()

func _on_busted_finished():
	get_tree().reload_current_scene()
	get_tree().paused = false

func _on_v1_finished():
	global.next_level()
	get_tree().reload_current_scene()
	get_tree().paused = false
