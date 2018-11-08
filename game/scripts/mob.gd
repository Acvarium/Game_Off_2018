extends Sprite

var speed = 150
var nav = null setget set_nav
var path = []
var goal = Vector2()
var goal_obj = null

func _ready():
	pass
	
func set_nav(new_nav):
	nav = new_nav
	update_path()

func set_goal(new_goal):
	goal = new_goal
	update_path()

func update_path():
	if nav == null:
		return
	if goal_obj != null:
		goal = goal_obj.position
	path = nav.get_simple_path(position, goal, false)
	if path.size() == 0:
		pass

func _physics_process(delta):
	if path.size() > 0:
		print(path.size())
		var d = position.distance_to(path[0])
		if d > 2:
			position = position.linear_interpolate(path[0], (speed * delta)/d)
		else:
			path.remove(0)
	else:
		pass

func _on_Timer_timeout():
	update_path()
