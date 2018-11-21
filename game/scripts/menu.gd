extends Control
var global

func _ready():
	global = get_node("/root/global")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
