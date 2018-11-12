extends Node
var current_scene = null
var level = -1
var players_lifes = [4,4,4,4]
var levels = ["level1"]
var screen_size = Vector2(1280, 720)

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child( root.get_child_count() -1 )

func next_level():
	level += 1
	if level > levels.size() - 1:
		level = -1
#	goto_scene("res://scenes/main.tscn")

func goto_scene(path):
	call_deferred("_deferred_goto_scene",path)

func _deferred_goto_scene(path):
	current_scene.free()
	var s = ResourceLoader.load(path)
	current_scene = s.instance()
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene( current_scene )
