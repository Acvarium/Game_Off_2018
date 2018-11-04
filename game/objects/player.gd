extends KinematicBody2D

var target_pos = Vector2()
var target_direction = Vector2()
var is_moving = false
var on_the_ladder = false
var main_node
var speed = 0
var max_speed = 150
var velocity = Vector2()
enum ENTITY_TYPES {UP, DOWN, LEFT, RIGHT}

var direction = Vector2()
var currentDir = Vector2(0,-1)

func _ready():
	main_node = get_node("/root/main")
	$rays/up.add_exception(self)
	$rays/down.add_exception(self)
	$rays/left.add_exception(self)
	$rays/right.add_exception(self)

func _physics_process(delta):
	var t = main_node.get_node("ui/dir")
	var tt = "UP " + str(obstacle(UP)) + " DOWN " + str(obstacle(DOWN))
	t.text = tt
	direction = Vector2()
	if Input.is_action_pressed("ui_up"):
		if !obstacle(UP):
			direction.y = -1
		if !is_moving:
			currentDir = Vector2(0,-1)
	elif Input.is_action_pressed("ui_down"):
		if !obstacle(DOWN):
			direction.y = 1
		if !is_moving:
			currentDir = Vector2(0,1)
	elif Input.is_action_pressed("ui_left"):
		if !obstacle(LEFT):
			direction.x = -1
		if !is_moving:
			currentDir = Vector2(-1,0)
	elif Input.is_action_pressed("ui_right"):
		if !obstacle(RIGHT):
			direction.x = 1
		if !is_moving:
			currentDir = Vector2(1,0)

	if !is_moving and direction != Vector2():
		print(main_node.is_cell_vacant(self))
		target_direction = direction
		if main_node.is_cell_vacant(self):
			target_pos = main_node.update_tank_pos(self)
			is_moving = true
	elif is_moving:
		speed = max_speed
		velocity = speed * target_direction * delta
		var distance_to_target = Vector2(abs(target_pos.x - position.x), abs(target_pos.y - position.y))
		if abs(velocity.x) > distance_to_target.x:
			velocity.x = distance_to_target.x * target_direction.x
			is_moving = false
			
		if abs(velocity.y) > distance_to_target.y:
			velocity.y = distance_to_target.y * target_direction.y
			is_moving = false
		move_and_collide(velocity)


func obstacle(dir):
	if dir == UP:
		return $rays/up.is_colliding()
	elif dir == DOWN:
		return $rays/down.is_colliding() 
	elif dir == LEFT:
		return $rays/left.is_colliding()
	elif dir == RIGHT:
		return $rays/right.is_colliding()

func _on_Area2D_body_entered(body):
	print("in")
	on_the_ladder = true
	
func _on_Area2D_body_exited(body):
	print("out")
	on_the_ladder = false
