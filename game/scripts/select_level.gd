tool
extends Control
export var level = 0 setget set_level
var global

func set_level(value):
	level = value
#	if has_node("level_button"):
#		$level_button.text = "level " + str(level)

func _ready():
	global = get_node("/root/global")
	if has_node("prev"):
		var has_prev = false
		if level >= 0 and level < global.levels.size() :
			var file2Check = File.new()
			if file2Check.file_exists("res://prev/" + global.levels[level] + ".png"):
				has_prev = true
		if has_prev:
			$prev.texture = load("res://prev/" + global.levels[level] + ".png")
		else:
			$prev.visible = false
			

func _on_level_button_pressed():
	global.set_level(level)
	global.goto_scene("res://scenes/main.tscn")