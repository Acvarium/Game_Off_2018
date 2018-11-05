extends Node2D
var cell_pos = Vector2()
var cell = -1
var main_node

func _ready():
	main_node = get_node("/root/main")

func _on_Timer_timeout():
	main_node.replace_cell(cell_pos, cell)
	queue_free()
