extends Node2D
var cell_pos = Vector2()
var cell = -1
var main_node

var cells = [
"ground",
"ground2",
"ground3",
"ground4",
]

var frames = [4, 3, 5, 6]

func _ready():
	main_node = get_node("/root/main")

func set_cell(_cell):
	cell = _cell
	print(cell)
	var cell_name = main_node.get_tile_name(cell)
	var cell_frame = get_frame_for_cell(cell_name)
	if cell_frame != 1:
		$Sprite.frame = cell_frame
		$anim.play("open")
		
func get_frame_for_cell(cell_name):
	for i in range(cells.size()):
		if cells[i] == cell_name:
			return frames[i]
	return -1

func _on_Timer_timeout():
	$anim.play("close")
	$Sprite.modulate  = Color(1,1,1,1)

func _on_anim_animation_finished(anim_name):
	if anim_name == "open":
		$Sprite.modulate  = Color(0,0,0,0)
	elif anim_name == "close":
		main_node.replace_cell(cell_pos, cell)
		queue_free()