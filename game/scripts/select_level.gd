tool
extends Control
export var level = 0 setget set_level
var global

func set_level(value):
	level = value
	if has_node("level_button"):
		$level_button.text = "level " + str(level)

func _ready():
	global = get_node("/root/global")
	pass


func _on_level_button_pressed():
	global.set_level(level)
	global.goto_scene("res://scenes/main.tscn")
