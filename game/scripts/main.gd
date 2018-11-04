extends Node2D
const cell_size = 32
const world_size = 128
var world = []

func _ready():
	for x in range(world_size):
		world.append([])
		for y in range(world_size):
			world[x].append(null)
	
func map_to_world(cell):
	var pos = Vector2(cell.x * cell_size, cell.y * cell_size)
	return pos
	
func world_to_map(pos):
	pos = pos + Vector2(cell_size/4, cell_size/4)
	var cell = Vector2(int(pos.x / cell_size), int(pos.y / cell_size))
	return cell

func is_cell_vacant(tank):
	var direction = tank.direction
	var grid_pos = world_to_map(tank.position) + direction
	for x in range(2):
		for y in range(2):
			if (grid_pos.x + x - 1) < 0 or (grid_pos.x + x - 1) >= world.size():
				return false
			if (grid_pos.y + y - 1) < 0 or (grid_pos.y + y - 1) >= world[0].size():
				return false
			var cell = world[grid_pos.x + x - 1][grid_pos.y + y - 1]
			if cell != null:
				if cell.get_ref() != tank:
					return false
	return true

func remove_tank(tank):
	var grid_pos = world_to_map(tank.position)
	for x in range(world_size):
		for y in range(world_size):
			if world[x][y]:
				if world[x][y].get_ref() == tank:
					world[x][y] = null

func update_tank_pos(tank):
	remove_tank(tank)
	var grid_pos = world_to_map(tank.position)
	var new_grid_pos = grid_pos + tank.direction
	for x in range(2):
		for y in range(2):
			world[new_grid_pos.x + x - 1][new_grid_pos.y + y - 1] = weakref(tank)
	
	var target_pos = map_to_world(new_grid_pos) 

	return target_pos


	return true