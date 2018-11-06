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
var cooldown = true

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
	
	var pointUnder = position
	pointUnder.y += 28
	main_node.to_64(position)
	var t = main_node.get_node("ui/dir")
	var tt = "UP " + str(obstacle(UP)) + " DOWN " + str(obstacle(DOWN))
	t.text = tt
	direction = Vector2()
	
	var tile_pos = main_node.to_64(position)
	var l_tile_pos = main_node.to_64($points/left.global_position)
	
	var c_cell = main_node.world_to_tile(position)
	var l_cell = main_node.world_to_tile($points/left.global_position)
	var ld_cell = main_node.world_to_tile($points/l_down.global_position)
	var d_cell = main_node.world_to_tile(pointUnder)
	
	$points/center/x.visible = c_cell == 1
	$points/left/x.visible = l_cell == 1
	$points/down/x.visible = d_cell == 1
	$points/l_down/x.visible = ld_cell == 1
	var on_ladder = (c_cell == 1 or d_cell == 1 or l_cell == 1 or ld_cell == 1)
	var on_pipe = (t_type(c_cell) == 2  or t_type(l_cell) == 2) and tile_pos.y <= position.y
	on_the_ladder = on_ladder or on_pipe
	if cooldown and abs(direction.y) == 0:
		if Input.is_action_pressed("B"):
			var cell_to_empty = main_node.world_to_tile_pos(position)
			cell_to_empty.x -= 1
			cell_to_empty.y += 1
			var _cell = main_node.get_cell(cell_to_empty) 
			if can_be_holed(_cell):
				if tile_pos.x > position.x:
					direction.x = 1
					if !is_moving:
						currentDir = Vector2(1,0)
				else:
					main_node.add_empty_cell(cell_to_empty)
					cooldown = false
					$cooldown.start()
					$Sprite.frame = 17
		
		elif Input.is_action_pressed("A"):
			var cell_to_empty = main_node.world_to_tile_pos(position)
			cell_to_empty.x += 1
			cell_to_empty.y += 1
			var _cell = main_node.get_cell(cell_to_empty) 
			if can_be_holed(_cell):
				if tile_pos.x > position.x:
					direction.x = -1
					if !is_moving:
						currentDir = Vector2(-1,0)
				else:
					main_node.add_empty_cell(cell_to_empty)
					cooldown = false
					$cooldown.start()
					$Sprite.frame = 19
	
	var c_cell_t = t_type(c_cell)
	var l_cell_t = t_type(l_cell)
	var ld_cell_t = t_type(ld_cell)
	var d_cell_t = t_type(d_cell)
	var can_move_up = (Input.is_action_pressed("ui_up") and (c_cell_t == 1 or l_cell_t == 1))
	var can_move_down = Input.is_action_pressed("ui_down") 
	
	if can_move_up or can_move_down:
		if tile_pos.x > position.x and t_type(c_cell) != 2:
			var go_right = (c_cell == 1 or d_cell == 1)
			if (Input.is_action_pressed("ui_up") and c_cell == 1 and d_cell != 1):
				go_right = true
			elif Input.is_action_pressed("ui_up") and l_cell == 1 and c_cell != 1:
				go_right = false
			elif Input.is_action_pressed("ui_down") and ld_cell == 1 and d_cell != 1:
				go_right = false
				
			if go_right:
				direction.x = 1
				if !is_moving:
					currentDir = Vector2(1,0)
			else:
				direction.x = -1
				if !is_moving:
					currentDir = Vector2(-1,0)
		if Input.is_action_pressed("ui_up") and c_cell == 1:
			if !obstacle(UP):
				direction.y = -1
				if !is_moving:
					currentDir = Vector2(0,-1)
		if Input.is_action_pressed("ui_down"):
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
#	else:
#		if $anim.is_playing():
#			$anim.stop()
	if !is_moving and direction != Vector2():
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
		if on_the_ladder:
			if $anim.current_animation != "up":
				$anim.play("up")
		elif $anim.current_animation != "fall":
			$anim.play("fall")
	elif direction.y == -1:
		if $anim.current_animation != "up":
			$anim.play("up")
	elif direction.x == -1:
		if t_type(c_cell) == 2:
			if $anim.current_animation != "up":
				$anim.play("up")
		else:
			if $anim.current_animation != "left":
				$anim.play("left")
	elif direction.x == 1:
		if t_type(c_cell) == 2:
			if $anim.current_animation != "up":
				$anim.play("up")
		else:
			if $anim.current_animation != "right":
				$anim.play("right")
	if direction == Vector2():
		if $anim.is_playing():
			$anim.stop()
		if on_the_ladder and velocity.y != 0:
			$Sprite.frame = 20
		else:
			if abs(velocity.x) < 3 and t_type(c_cell) != 2:
				$Sprite.frame = 6

func can_be_holed(cell):
	var cell_name = main_node.get_tile_name(cell)
	return cell_name.left(1) == 'g'

func t_type(cell):
	var cell_name = main_node.get_tile_name(cell)
	if cell_name == 'ladder':
		return 1
	if cell_name.left(1) == 'p':
		return 2
	return -1

func obstacle(dir):
	if dir == UP:
		return $rays/up.is_colliding() or $rays/up2.is_colliding() 
	elif dir == DOWN:
		return $rays/down.is_colliding() or $rays/down2.is_colliding() 
	elif dir == LEFT:
		return $rays/left.is_colliding() or $rays/left2.is_colliding()
	elif dir == RIGHT:
		return $rays/right.is_colliding() or $rays/right2.is_colliding()

func _on_cooldown_timeout():
	cooldown = true
