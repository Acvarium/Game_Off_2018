extends Control
var global

func _ready():
	global = get_node("/root/global")

func _on_Button_pressed():
	global.level = -1
	global.goto_scene("res://scenes/main.tscn")

func _on_Level1_pressed():
	global.level = 0
	global.goto_scene("res://scenes/main.tscn")
