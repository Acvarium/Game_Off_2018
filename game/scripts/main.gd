extends Node2D
var cell_size = 32
var tile_cell_size = 64
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
var mouse_move_check = 4
var mouse_last_pos = Vector2()
var start_pause = true
var default_zoom = Vector2(0.8,0.8)
var freezer = Vector2(-640, -640)
var cells_for_bonuses = []
var multiplayer_count = 0
var exited = 0
var under_control = []
var players_in_exit = 0
var zoom_out = false

func add_player(player):
	for p in players:
		if player == p.get_ref():
			return
	players.append(weakref(player))
	if player.bot_class == 0:
		multiplayer_count += 1
		print("------" + player.name)
		under_control.append(weakref(player))
		$main_camera.set_target(player)

func update_gold_count(value):
	gold_found += value
	if gold_found == gold_on_level:
		final()
	$ui/goldCount.text = str(gold_found) + "/" + str(gold_on_level)

func get_freezer_pos(player):
	var _pos = freezer
	for i in players.size():
		if players[i].get_ref() == player:
			_pos.x -= i * 128
	return _pos

func init_bonus_cells():
	if level.has_node("nav/navMap"):
		var nav = level.get_node("nav/navMap")
		var _tile_map = level.get_node("level")
		for nc in nav.get_used_cells():
			if _tile_map.get_cell(nc.x, nc.y) == -1:
				cells_for_bonuses.append(nc)

func get_random_bonus_cell():
	if cells_for_bonuses.size() > 0:
		var r = randi()%cells_for_bonuses.size()
		return cells_for_bonuses[r]
	return null
	
func put_obj(obj_name, _pos):
	if level.has_node("objects"):
		var cell_pos = world_to_map(_pos)
		var w_pos = map_to_world(cell_pos)
		var obj = load("res://objects/" + obj_name + ".tscn")
		var obj_inst = obj.instance()
		level.get_node("objects").add_child(obj_inst)
		obj_inst.global_position = w_pos

func multi_exit(value):
	players_in_exit += value
	print(str(players_in_exit) + " / " + str(under_control.size()))
	if players_in_exit == under_control.size() and gold_found == gold_on_level:
		exit()

func window_resized():
	print("Resizing: ", get_viewport_rect().size)
	var to_fit = true
	if level.get("fit_cam_x") != null:
		if level.fit_cam_x:
			fit_cam_to_width()
			

func fit_cam_to_width():
	var zzz = ((bottom_right - top_left )) / get_viewport_rect().size
	$main_camera.zoom = Vector2(zzz.x, zzz.x)
	$main_camera.position = (((bottom_right - top_left) * 64) * 0.5 + top_left)

func _ready():
	randomize()
	get_tree().get_root().connect("size_changed", self, "window_resized")
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
	
	if global.levels_states[str(global.level + 1)] < -7:
		$ui/skip_button.visible = true
		
	$ui/level_name.text = "Level " + str(global.level + 1)
	default_zoom = $main_camera.zoom
	
	var zzz = ((bottom_right - top_left )) / get_viewport_rect().size
	$main_camera.zoom = Vector2(zzz.x, zzz.x)
	$main_camera.position = ((bottom_right - top_left) * 64) * 0.5 + top_left
	if global.options["glow"]:
		var bloom_env_obj = load("res://objects/bloom_env.tscn")
		var bloom_env = bloom_env_obj.instance()
		add_child(bloom_env)
	init_bonus_cells()

func set_bomb_count(bombs, player_side):
	var slot = $ui/slots1
	if player_side == 1:
		slot = $ui/slots2
	slot.visible = bombs > 0
	slot.get_node("Label").visible = bombs > 1
	slot.get_node("ex0").visible = bombs > 0
	slot.get_node("Label").text = "x" + str(bombs)

func _input(event):
	if Input.is_action_just_pressed("zoom_out") and !zoom_out:
		fit_cam_to_width()
		zoom_out = true
	if Input.is_action_just_released("zoom_out") and zoom_out:
		zoom_out = false
		var to_fit = false
		if level.get("fit_cam_x") != null:
			to_fit = level.fit_cam_x
		if !to_fit:
			$main_camera.zoom = default_zoom
	if Input.is_action_just_pressed("ui_page_up") and global.debug:
		exit()
	if Input.is_action_just_pressed("debug"):
		$canvas.lines = []
		$canvas.update()
		global.debug = !global.debug 
	if Input.is_action_just_pressed("ui_cancel"):
		global.goto_scene("res://scenes/menu.tscn")
	if  event is InputEventMouseMotion:
		mouse_move_check = 4
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
		$mouse_move_timer.start()
	elif start_pause:
		var to_fit = false
		if level.get("fit_cam_x") != null:
			to_fit = level.fit_cam_x
		if !to_fit:
			$main_camera.zoom = default_zoom
		start_pause = false
		get_tree().paused = false
		$ui/ready.visible = false
		$ui/title.visible = false
		$ui/help_info.visible = false
		$ui/help_dark.visible = false
		if level.has_node("canvas"):
			level.get_node("canvas").free()
		
		$ui/level_name.visible = false
		$ui/help.visible = false
		$ui/goldCount.visible = true
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
		
func world_to_map(pos):
	pos = pos + Vector2(cell_size/4, cell_size/4)
	var cell = Vector2(int(pos.x / cell_size), int(pos.y / cell_size))
	return cell

func world_to_tile(pos):
	var cell_pos = world_to_tile_pos(pos)
	var tile = tilemap.get_cell(cell_pos.x, cell_pos.y)
	return tile

func spawn_around(cell_pos, obj_type):
	var _cell = -1
	if obj_type == "gold":
		_cell = 29
	else:
		return
		
	if (tilemap.get_cell(cell_pos.x, cell_pos.y)) == -1:
		replace_cell(cell_pos, _cell)
		return
	elif cells_for_bonuses.size() > 0:
		var dist = INF
		var closest = Vector2()
		for c in cells_for_bonuses:
			if cell_pos.distance_to(c) < dist and tilemap.get_cell(c.x, c.y) == -1:
				dist = cell_pos.distance_to(c)
				closest = c
		replace_cell(closest, _cell)

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
	replace_cell(cell_pos, 37)
	return empty_cell

func kill_in_cell(cell_pos):
	for p in players:
		if p.get_ref() != null:
			var p_cell_pos32 = world_to_tile_pos(p.get_ref().position - Vector2(32,0))
			if p_cell_pos32 == cell_pos or p.get_ref().current_tile_pos == cell_pos:
				p.get_ref()._die("exp", 0.1)

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

func players_in_rect(AA, BB):
	var _players = []
	for p in players:
		if p.get_ref() != null:
			var p_pos = p.get_ref().position
			if p_pos.x > AA.x and p_pos.x < BB.x and p_pos.y > AA.y and p_pos.y < BB.y:
				_players.append(p)
			
	return _players

func play_sound(_name):
	if $sounds.has_node(_name):
		$sounds.get_node(_name).play()

func is_cell_vacant(player):
	var is_vacant = true
	if player.bot_class == 0:
		return true
	var direction = player.direction
	var grid_pos = world_to_map(player.position) + direction
	for p in players:
		if p == null or !p.get_ref():
			continue
		if p.get_ref() == player or p.get_ref().bot_class == 0 or p.get_ref().frozen:
			continue
		var p_grid_pos = world_to_map(p.get_ref().target_pos) 
		if abs(p_grid_pos.x - grid_pos.x) < 2 and abs(p_grid_pos.y - grid_pos.y) < 2:
			is_vacant = false
	return is_vacant

			
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

func busted(_pos):
	$main_camera.zoom_in(0.5)
	$main_camera.fallow = false
	$main_camera.position = _pos
	play_sound("busted")
	get_tree().paused = true


func _process(delta):
	if !on_pause and global.debug:
		var colors = [
		Color(1,0,0),
		Color(1,1,0),
		Color(0,1,0),
		Color(0,1,1),
		Color(0,0,1)]
		
		$canvas.lines = []
		var a = 0	
		var i = 0
		for p in players:
			p.get_ref().add_debug_lines(a,colors[i])
			a += 2
			i += 1
			if i >= colors.size():
				i = 0
		$canvas.update()
	if $ui/grid.visible and !on_pause:
		print_world()

func _on_busted_finished():
	global.change_level_state(-1)
	global.reload_current()

func _on_v1_finished():
	global.change_level_state(1)
	global.next_level()

func _on_mouse_move_timer_timeout():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) 

func _on_start_pause_timer_timeout():
	if start_pause:
		if !level.has_node("start_music"):
			play_sound("start")
		$ui/ready.visible = false
		if level.get("title") != null:
			$ui/title.visible = level.title != ""
			$ui/title.text = level.title
		else:
			$ui/title.visible = false
			
		if level.get("help_info") != null:
			$ui/help_info.visible = level.help_info != ""
			$ui/help_dark.visible = level.help_info != ""
			
			$ui/help_info.text = level.help_info
		else:
			$ui/help_info.visible = false
			$ui/help_dark.visible = false
			
		
		$ui/level_name.visible = !$ui/title.visible
		get_tree().paused = true

func _on_skip_button_pressed():
	global.next_level()
