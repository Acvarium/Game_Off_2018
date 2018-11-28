tool
extends Node2D
export var to_retuild = false
export var build = 0 setget _rebuild
var main_node
var cleared_cells = []
var cleared_cells_td = []


func _rebuild(new_value):
	if !to_retuild:
		return
	if !has_node("nav"):
		return
	$nav/navMap.clear()
	$nav_fa/navMap.clear()
	var r = $level.get_used_rect()

	var tilemap = $level.tile_set
	for c in $level.get_used_cells():
		var c_type = cell_type(c.x, c.y)
		var c_up_type = cell_type(c.x, c.y - 1)
		
		if c_type == 5:
			if c_up_type == -1 or c_up_type < 0:
				if c.y > r.position.y:
					set_nav_cell(c.x,  c.y - 1, true)
			if c.x > r.position.x and c.x < (r.size.x + r.position.x - 1) and c.y > r.position.y:
				fall(c.x + 1, c.y - 1)
				fall(c.x - 1, c.y - 1)
		
		elif c_type == 2 or c_type == 1:
			set_nav_cell(c.x,  c.y, true)
			if c_type == 1 and c_up_type == -1:
				set_nav_cell(c.x,  c.y - 1, true)
			if c_type == 2:
				fall(c.x, c.y)
			if c_type == 1 and cell_type(c.x, c.y + 1) != 5 and cell_type(c.x, c.y + 1) != 1:
				$nav/navMap.set_cell(c.x, c.y, -1)
				
func get_cell_name(pos):
	var cell = $level.get_cell(pos.x, pos.y)
	var cell_name = $level.tile_set.tile_get_name(cell)
	return cell_name

func fall(x,y):
	var n = 0
	var a = true
	while n < 80 and a:
		var c_type = cell_type(x, y)
		a = c_type == -1 or c_type == 2 or c_type == 1
		if a:
			if c_type != 1: 
				set_nav_cell(x, y, false)
			y += 1
			
		n += 1
		

func set_nav_cell(x, y, b):
	if b:
		$nav/navMap.set_cell(x, y, 1)
	$nav_fa/navMap.set_cell(x, y, 1)
				
	
func cell_type(x,y):
	var cell_name = get_cell_name(Vector2(x,y))
	var fl = cell_name.left(2) 
	if cell_name == 'ladder':
		return 1
	elif fl == 'pi':
		return 2
	elif cell_name == "exit":
		return 4
	elif fl == 'gr' or fl == "st":
		return 5
	return -1
	
func _ready():
	main_node = get_node("/root/main")
	print($level.get_used_rect())

func _physics_process(delta):
	for c in cleared_cells:
		$nav/navMap.set_cell(c.x, c.y, 1)
	for c in cleared_cells_td:
		$nav_fa/navMap.set_cell(c.x, c.y, 1)
	cleared_cells.clear()
	if main_node != null:
		if main_node.players.size() > 0:
			for p in main_node.players:
				if p.get_ref() != null:
					if p.get_ref().bot_class == 2:
						var cell_pos = main_node.world_to_tile_pos(p.get_ref().position)
						if $nav/navMap.get_cell(cell_pos.x, cell_pos.y) != -1:
							cleared_cells.append(cell_pos)
						$nav/navMap.set_cell(cell_pos.x, cell_pos.y, -1)
						if $nav_fa/navMap.get_cell(cell_pos.x, cell_pos.y) != -1:
							cleared_cells_td.append(cell_pos)
						$nav_fa/navMap.set_cell(cell_pos.x, cell_pos.y, -1)

