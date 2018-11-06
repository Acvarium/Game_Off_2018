extends Node2D
var cell_size = 32
var tile_cell_size = 64
var world_size = 128
var world = []
var offset = Vector2(32,32)
var empty_cell_obj = load("res://objects/empty_cell.tscn")
var tilemap = null

func _ready():
	offset = Vector2(0,0)
	tilemap = $level/level
	for x in range(world_size):
		world.append([])
		for y in range(world_size):
			world[x].append(null)

func map_to_world(cell):
	var pos = Vector2(cell.x * cell_size + offset.x, cell.y * cell_size + offset.y)
	return pos

func world_to_map(pos):
	pos = pos + Vector2(cell_size/4, cell_size/4)
	var cell = Vector2(int(pos.x / cell_size), int(pos.y / cell_size))
	return cell

func world_to_tile(pos):
	var cell_pos = world_to_tile_pos(pos)
	var tile = tilemap.get_cell(cell_pos.x, cell_pos.y)
	$ui/last_dir.text = str(tile) + " " + str(cell_pos) 
	return tile

func world_to_tile_pos(pos):
	pos = pos + Vector2(tile_cell_size/4, tile_cell_size/4)
	var cell_pos = Vector2(int(pos.x / tile_cell_size), int(pos.y / tile_cell_size))
	return cell_pos

func add_empty_cell(cell_pos):
	var empty_cell = empty_cell_obj.instance()
	$level.add_child(empty_cell)
	empty_cell.set_cell(tilemap.get_cell(cell_pos.x, cell_pos.y))
	empty_cell.cell_pos = cell_pos
	empty_cell.position = tilemap.map_to_world(cell_pos) + Vector2(32,32)
	replace_cell(cell_pos, -1)

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

func to_64(pos):
	$ui/dtext3.text = str(world_to_map(pos)) + " " + str(pos)
	pos = pos + Vector2(tile_cell_size/4, tile_cell_size/4)
	var cell_pos = Vector2(int(pos.x / tile_cell_size), int(pos.y / tile_cell_size))
	pos = tilemap.map_to_world(cell_pos)
	pos.x += 32
	pos.y += 32
	var grid_pos = world_to_map(pos)
	$ui/dtext4.text = str(grid_pos) + " " + str(pos)
	return pos

func is_cell_vacant(player):
	var direction = player.direction
	var grid_pos = world_to_map(player.position) + direction
	for x in range(2):
		for y in range(2):
			if (grid_pos.x + x - 1) < 0 or (grid_pos.x + x - 1) >= world.size():
				return false
			if (grid_pos.y + y - 1) < 0 or (grid_pos.y + y - 1) >= world[0].size():
				return false
			var cell = world[grid_pos.x + x - 1][grid_pos.y + y - 1]
			if cell != null:
				if cell.get_ref() != player:
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
	for x in range(2):
		for y in range(2):
			world[new_grid_pos.x + x - 1][new_grid_pos.y + y - 1] = weakref(player)
	var target_pos = map_to_world(new_grid_pos) 
	return target_pos
	return true