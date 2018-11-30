extends Camera2D
var target = null
var main_node
var view_field = Vector2()
var global
var fallow = true

func _ready():
	main_node = get_node("/root/main")
	global = get_node("/root/global")
	view_field = global.screen_size * zoom

func zoom_in(value):
	zoom = Vector2(value,value)
	if target != null:
		position = target.get_ref().position
	

func _physics_process(delta):
	if !fallow:
		return
	var multi_target = main_node.under_control.size() > 1
	var current_target = target
	if multi_target:
		var pos_y = INF
		for uc in main_node.under_control:
			if uc.get_ref() != null:
				if uc.get_ref().position.y < pos_y:
					pos_y = uc.get_ref().position.y
					current_target = uc
	if current_target != null:
		position = current_target.get_ref().position


func set_target(_target):
	target = weakref(_target)