extends Node2D
var cell_pos = Vector2()
var cell = -1
var main_node
var unfinished = true
var close_back = false
var player_inside = null
var mode = 0
var sprite
var cells

var cells1 = [
"ground",
"ground2",
"ground3",
"ground4",
]

var cells2 = [
"ground",
"ground2",
"ground3",
"ground4",
"ground5",
"ground6",
"ground7",
"ground8",
"ground9",
"ground10",
"ground11",
"ground12",
"ground13",
"ground14",
]

var frames1 = [4, 3, 5, 6]
var frames2 = [5, 6, 7, 8, 9, 21, 22, 23, 24, 25, 37, 38, 40, 41]

var frames

func _process(delta):
	if $Label.visible:
		if player_inside != null:
			$Label.text	 = player_inside.name
		else:
			$Label.text = ""

func _ready():

	main_node = get_node("/root/main")
	sprite = $Sprite
	frames = frames1
	cells = cells1
	mode = main_node.set_num
	if mode == 2:
		sprite = $Sprite2
		frames = frames2
		cells = cells2
		$Sprite.visible = false
		$Sprite2.visible = true
	var t = OS.get_ticks_msec()/1000.0
	var m = $water_anim.get_animation("water").length
	$water_anim.seek(fmod(t,m))
		

func set_cell(_cell):
	cell = _cell
	var cell_name = main_node.get_tile_name(cell)
	var cell_frame = get_frame_for_cell(cell_name)
	if cell_frame != 1:
		sprite.frame = cell_frame
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
	sprite.modulate  = Color(1,1,1,1)

func close_out():
	main_node.kill_in_cell(cell_pos)
	main_node.replace_cell(cell_pos, cell)

	queue_free()

func _on_anim_animation_finished(anim_name):
	if anim_name == "open":
		if close_back:
			close_out()
		sprite.modulate  = Color(0,0,0,0)
		unfinished = false
	elif anim_name == "close":
		close_out()

func _on_Area2D_area_entered(area):
	if area.is_in_group("player"):
		player_inside = area.get_parent()
#		print("in trap " + area.get_parent().name)
		player_inside.set_in_trap(true)

func _on_Area2D_area_exited(area):
	if player_inside != null:
		player_inside.set_in_trap(false)
		player_inside = null
	

func _on_prop_player_timeout_timeout():
	main_node.replace_cell(cell_pos, cell)
	queue_free()
