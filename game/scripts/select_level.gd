tool
extends Control
export var level = 0 setget set_level
var lock = true

func set_level(value):
	if global == null:
		return
	level = value
	if has_node("level_num"):
		$level_num.text = str(level)
	if has_node("level_num"):
		if !Engine.editor_hint:
			$level_num.visible = false
	if has_node("prev"):
		var has_prev = false
		if level >= 0 and level < global.levels.size():
			var file2Check = File.new()
			if file2Check.file_exists("res://prev/" + global.levels[level] + ".png"):
				has_prev = true
		$prev.visible = has_prev
		
		if has_prev:
			$prev/lock.visible = global.check_lock(level) < 0
			$prev.texture = load("res://prev/" + global.levels[level] + ".png")
				
func _ready():
	global = get_node("/root/global")
	set_level(level)
	
func _on_level_button_pressed():
	if level >= 0 and level < global.levels.size() and $prev/lock.visible == false:
		global.set_level(level)
		global.goto_scene("res://scenes/main.tscn")