extends Node2D
var cell_pos = Vector2()
var cell = -1
var main_node
var unfinished = true
var close_back = false
var player_inside = null

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
	var cell_name = main_node.get_tile_name(cell)
	var cell_frame = get_frame_for_cell(cell_name)
	if cell_frame != 1:
		$Sprite.frame = cell_frame
		$anim.play("open")

func play_back():
	if !unfinished:
		return
	print("unfinished")
	var t = $anim.current_animation_position
	$anim.play_backwards("open")
	$anim.seek(t)
	close_back = true

func get_frame_for_cell(cell_name):
	for i in range(cells.size()):
		if cells[i] == cell_name:
			return frames[i]
	return -1

func _on_Timer_timeout():
	$anim.play("close")
	$Sprite.modulate  = Color(1,1,1,1)

func close_out():
	if player_inside != null:
		player_inside.die()
		$prop_player_timeout.start()
		return
	main_node.replace_cell(cell_pos, cell)
	queue_free()

func _on_anim_animation_finished(anim_name):
	if anim_name == "open":
		if close_back:
			close_out()
		$Sprite.modulate  = Color(0,0,0,0)
		unfinished = false
		
	elif anim_name == "close":
		close_out()

func _on_Area2D_area_entered(area):
	if area.is_in_group("player"):
		player_inside = area.get_parent()
		print(area.get_parent().name)
		player_inside.in_the_trap = true

func _on_Area2D_area_exited(area):
	if player_inside != null:
		player_inside.in_the_trap = false
		player_inside = null
	

func _on_prop_player_timeout_timeout():
	main_node.replace_cell(cell_pos, cell)
	queue_free()
