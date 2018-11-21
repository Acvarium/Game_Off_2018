extends Node
var current_scene = null
var level = -1
var players_lifes = [4,4,4,4]
var levels = ["level0", "level1","level2","level3","level4","level5","level6"]

const MAX_STAGE = 200
var stage = 1
var stages_lock = []
var screen_size = Vector2(1280, 720)

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child( root.get_child_count() -1 )

func next_level():
	level += 1
	if level > levels.size() - 1:
		level = 0
#	goto_scene("res://scenes/main.tscn")

func set_level(value):
	level = value
	if level > levels.size() - 1:
		level = 0

func goto_scene(path):
	call_deferred("_deferred_goto_scene",path)

func _deferred_goto_scene(path):
	current_scene.free()
	var s = ResourceLoader.load(path)
	current_scene = s.instance()
	get_tree().get_root().add_child(current_scene)
	get_tree().set_current_scene( current_scene )


func _input(event):
	if Input.is_action_just_pressed("full_scr"):
		OS.window_fullscreen = !OS.window_fullscreen

func save_game():
	var savegame = File.new()
	savegame.open("user://__savegame.save", File.WRITE)
	for i in range(stages_lock.size()):
		savegame.store_line({str(i):stages_lock[i]}.to_json())
	savegame.close()

# Завантаження гри
func load_game():
	var savegame = File.new()
	if !savegame.file_exists("user://__savegame.save"):
		for i in range(MAX_STAGE):
			stages_lock.append(1)
		stages_lock[0] = 0
		return #Error!  We don't have a save to load
	var currentline = {} 
	savegame.open("user://__savegame.save", File.READ)
	stages_lock.clear()
	var n = 0
	while (!savegame.eof_reached()):
		n += 1
		currentline.parse_json(savegame.get_line())
	for i in range(MAX_STAGE):
		stages_lock.append(currentline[str(i)])
	savegame.close()
	print(currentline["72"])