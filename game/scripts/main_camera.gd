extends Camera2D
var target = null
var main_node
var view_field = Vector2()
var global

func _ready():
	main_node = get_node("/root/main")
	global = get_node("/root/global")
	view_field = global.screen_size * zoom
	print(view_field)

func zoom_in(value):
	zoom = Vector2(value,value)
	if target != null:
		position = target.position
	

func _physics_process(delta):
	if target != null:
		position = target.position
#		var c_AA = main_node.top_left + (view_field * 0.5)
#		var c_BB = main_node.bottom_right - (view_field * 0.5)
#		position.x = clamp(position.x, c_AA.x, c_BB.x)
#		position.y = clamp(position.y, c_AA.y, c_BB.y)
#
func set_target(_target):
	target = _target