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
var current_hole = null
var gold = 0
var nav = null
var goal = Vector2()
var goal_obj = null
var path = []

export var bot_class = 0
export var main_player = true

var direction = Vector2()
var currentDir = Vector2(0,-1)
var b_press = false
var a_press = false
var spawn_pos = Vector2()


func _ready():
	main_node = get_node("/root/main")
	print(main_node.name)
	for r in $rays.get_children():
		r.add_exception(self)
	spawn_pos = global_position
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
	direction = Vector2()
	
	var tile_pos = main_node.to_64(position)
	var l_tile_pos = main_node.to_64($points/left.global_position)
	
	var c_cell = main_node.world_to_tile(position)
	var l_cell = main_node.world_to_tile($points/left.global_position)
	var ld_cell = main_node.world_to_tile($points/l_down.global_position)
	var d_cell = main_node.world_to_tile(pointUnder)
	
	var c_cell_t = t_type(c_cell)
	var l_cell_t = t_type(l_cell)
	var ld_cell_t = t_type(ld_cell)
	var d_cell_t = t_type(d_cell)
	
	var b_key = false
	var a_key = false
	var left_key = false
	var right_key = false
	var up_key = false
	var down_key = false
	
	if bot_class == 0:
		b_key = Input.is_action_pressed("B")
		a_key = Input.is_action_pressed("A")
		left_key = Input.is_action_pressed("ui_left")
		right_key = Input.is_action_pressed("ui_right")
		up_key = Input.is_action_pressed("ui_up")
		down_key = Input.is_action_pressed("ui_down")
		
	elif bot_class > 0 and nav != null:
		if path.size() > 0:
			var d = position.distance_to(path[0])
			var d_vec = position - path[0]
			if d > 32:
				var ss = ""
				if d_vec.x > 0:
					left_key = true
					ss += "left  "
				elif d_vec.x < 0:
					right_key = true
					ss += "right "
				elif d_vec.y < 0:
					down_key = true
					ss += "down  "
				if d_vec.y > 0:
					up_key = true
					ss += "up    "
				
				print(str(goal) + " " + str(path.size()) + " " + ss)
				
			else:
				path.remove(0)
	
	var debug_type = 2
	$points/center/x.visible = c_cell_t ==  debug_type
	$points/left/x.visible = l_cell_t ==  debug_type
	$points/down/x.visible = d_cell_t ==  debug_type
	$points/l_down/x.visible = ld_cell_t ==  debug_type
	
	if tile_pos.x <= position.x and tile_pos.y <= position.y and c_cell_t == 3:
		main_node.play_sound("coin")
		gold += 1
		main_node.replace_cell(main_node.world_to_tile_pos(position),-1)
	
	var on_ladder = (c_cell == 1 or d_cell == 1 or l_cell == 1 or ld_cell == 1)
	var on_pipe = (c_cell_t == 2 or l_cell_t == 2) and tile_pos.y <= position.y
	on_the_ladder = on_ladder or on_pipe
	if Input.is_action_just_released("B") and main_player:
		b_press = false
		if current_hole != null:
			current_hole.play_back()
		current_hole = null
	if Input.is_action_just_released("A")  and main_player:
		a_press = false
		if current_hole != null:
			current_hole.play_back()
		current_hole = null

	if abs(direction.y) == 0:
		if Input.is_action_pressed("B") and main_player:
			var cell_to_empty = main_node.world_to_tile_pos(position)
			cell_to_empty.x -= 1
			cell_to_empty.y += 1
			if tile_pos.x > position.x:
				direction.x = 1
				if !is_moving:
					currentDir = Vector2(1,0)
			elif can_be_holed(cell_to_empty) and !b_press:
				b_press = true
				$sounds/blaster.play()
				current_hole = main_node.add_empty_cell(cell_to_empty)
				$Sprite.frame = 17
		
		elif Input.is_action_pressed("A")  and main_player:
			var cell_to_empty = main_node.world_to_tile_pos(position)
			cell_to_empty.x += 1
			cell_to_empty.y += 1
			if tile_pos.x > position.x:
				direction.x = -1
				if !is_moving:
					currentDir = Vector2(-1,0)
			elif can_be_holed(cell_to_empty) and !a_press:
				a_press = true
				$sounds/blaster.play()
				main_node.add_empty_cell(cell_to_empty)
				$Sprite.frame = 19
	

	var can_move_up = (up_key and (c_cell_t == 1 or l_cell_t == 1))
	var can_move_down = down_key
	
	if can_move_up or can_move_down:
		if tile_pos.x > position.x:
			var go_right = (c_cell == 1 or d_cell == 1)
			if (up_key and c_cell == 1 and d_cell != 1):
				go_right = true
			elif up_key and l_cell == 1 and c_cell != 1:
				go_right = false
			elif up_key and ld_cell == 1 and d_cell != 1:
				go_right = false
				
			if go_right:
				direction.x = 1
				if !is_moving:
					currentDir = Vector2(1,0)
			else:
				direction.x = -1
				if !is_moving:
					currentDir = Vector2(-1,0)
		if up_key and c_cell == 1:
			if !obstacle(UP):
				direction.y = -1
				if !is_moving:
					currentDir = Vector2(0,-1)
		if down_key:
			if !obstacle(DOWN):
				direction.y = 1
			if !is_moving:
				currentDir = Vector2(0,1)
		
	elif left_key and (obstacle(DOWN) or on_the_ladder):
		if !obstacle(LEFT):
			direction.x = -1
		if !is_moving:
			currentDir = Vector2(-1,0)
	elif right_key and (obstacle(DOWN) or on_the_ladder):
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
		if c_cell_t == 2:
			if $anim.current_animation != "up":
				$anim.play("up")
		else:
			if $anim.current_animation != "left":
				$anim.play("left")
	elif direction.x == 1:
		if c_cell_t == 2 or l_cell_t == 2:
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
			if abs(velocity.x) < 3 and !(t_type(c_cell) == 2 or t_type(l_cell) == 2):
				$Sprite.frame = 6

func can_be_holed(cell_pos):
	var _cell = main_node.get_cell(cell_pos) 
	var cell_name = main_node.get_tile_name(_cell)
	if cell_name.left(1) == 'g':
		var up_cell_pos = cell_pos
		up_cell_pos.y -= 1
		var up_cell = main_node.get_cell(up_cell_pos)
		var up_cell_name = main_node.get_tile_name(up_cell)
		if up_cell == -1 or up_cell_name == "ladder_top" or  up_cell_name == "gold":
			return true
	return false

func t_type(cell):
	var cell_name = main_node.get_tile_name(cell)
	if cell_name == 'ladder':
		return 1
	if cell_name.left(1) == 'p':
		return 2
	if cell_name == "gold":
		return 3
	return -1

func die():
	global_position = spawn_pos

func obstacle(dir):
	if dir == UP:
		return $rays/up.is_colliding() or $rays/up2.is_colliding() 
	elif dir == DOWN:
		return $rays/down.is_colliding() or $rays/down2.is_colliding() 
	elif dir == LEFT:
		return $rays/left.is_colliding() or $rays/left2.is_colliding()
	elif dir == RIGHT:
		return $rays/right.is_colliding() or $rays/right2.is_colliding()

func set_nav(new_nav):
	nav = new_nav
	update_path()

func set_goal(new_goal):
	goal = new_goal
	update_path()

func update_path():
	if goal_obj != null:
		goal = goal_obj.position
		
	path = nav.get_simple_path(position, goal, false)
	if path.size() == 0:
		print(path.size())

func _on_cooldown_timeout():
	cooldown = true

func _on_nav_update_timeout():
	if nav != null and bot_class > 0:
		update_path()
