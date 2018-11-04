extends KinematicBody2D

var target_pos = Vector2()
var target_direction = Vector2()
var is_moving = false
var on_the_ladder = false
var main_node
var speed = 0
var max_speed = 350
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
	$rays/up.force_raycast_update()
	$rays/down.force_raycast_update()
	$rays/left.force_raycast_update()
	$rays/right.force_raycast_update()
	var currentCell = main_node.current_cell(position)
	var pointUnder = position
	pointUnder.y += 32
	var cellUnder = main_node.current_cell(pointUnder)
	
	var t = main_node.get_node("ui/dir")
	var tt = "UP " + str(obstacle(UP)) + " DOWN " + str(obstacle(DOWN))
	t.text = tt
	direction = Vector2()
	on_the_ladder = (currentCell == 1 or cellUnder == 1)
	if Input.is_action_pressed("ui_up") and currentCell == 1:
		if !obstacle(UP):
			if $anim.current_animation != "up":
				$anim.play("up")
			direction.y = -1
		if !is_moving:
			currentDir = Vector2(0,-1)
	elif Input.is_action_pressed("ui_down") and on_the_ladder:
		if !obstacle(DOWN):
			direction.y = 1
		if !is_moving:
			currentDir = Vector2(0,1)
	elif Input.is_action_pressed("ui_left") and (obstacle(DOWN) or on_the_ladder):
		if !obstacle(LEFT):
			direction.x = -1
		if !is_moving:
			currentDir = Vector2(-1,0)
	elif Input.is_action_pressed("ui_right") and (obstacle(DOWN) or on_the_ladder):
		if !obstacle(RIGHT):
			direction.x = 1
		if !is_moving:
			currentDir = Vector2(1,0)
	elif !on_the_ladder and !obstacle(DOWN) :

		direction.y = 1
		if !is_moving:
			currentDir = Vector2(0,1)
	else:
		if $anim.is_playing():
			$anim.stop()
	if !is_moving and direction != Vector2():
		print(main_node.is_cell_vacant(self))
		target_direction = direction
		if main_node.is_cell_vacant(self):
			target_pos = main_node.update_player_pos(self)
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
	if direction.y == 1:
		if $anim.current_animation != "fall":
			$anim.play("fall")
	elif direction.y == -1:
		if $anim.current_animation != "up":
			$anim.play("up")
	elif direction.x == -1:
		if $anim.current_animation != "left":
			$anim.play("left")
	elif direction.x == 1:
		if $anim.current_animation != "right":
			$anim.play("right")

	if direction == Vector2():
		if $anim.is_playing():
			$anim.stop()
		$Sprite.frame = 6
		
func obstacle(dir):
	if dir == UP:
		return $rays/up.is_colliding() or $rays/up2.is_colliding() 
	elif dir == DOWN:
		return $rays/down.is_colliding() or $rays/down2.is_colliding() 
	elif dir == LEFT:
		return $rays/left.is_colliding() or $rays/left2.is_colliding()
	elif dir == RIGHT:
		return $rays/right.is_colliding() or $rays/right2.is_colliding()

func _on_Area2D_body_entered(body):
	print("in")
	on_the_ladder = true
	
func _on_Area2D_body_exited(body):
	print("out")
	on_the_ladder = false
