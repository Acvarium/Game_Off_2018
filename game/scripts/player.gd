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
var gold_slot = 0
var to_drop_gold = false
var in_the_trap = false
var allowed_to_pickup = true

export var bot_class = 0
export var main_player = true

var allowe_to_crawl_up = false
var direction = Vector2()
var currentDir = Vector2(0,-1)
var b_press = false
var a_press = false
var spawn_pos = Vector2()
export var last_trap_tile = Vector2()
var to_remove_last_trap_tile = false
var last_trap_cell = 999
var current_tile_pos = Vector2()
var bot_random_dir = UP
var bot_go_random = true

func _ready():
	main_node = get_node("/root/main")
	randomize()
	# Налаштування променів ігнорувати власника
	for r in $rays.get_children():
		r.add_exception(self)
	# Визначення позиції появи в місці, де персонаж розташований на початку гри
	spawn_pos = global_position
	if bot_class > 0:
		$colSwitch.play("bot")
	else:
		$colSwitch.play("player")
	# Додати даного персонажа до списку персонажів на рівні
	main_node.add_player(self)

func _physics_process(delta):
	# Визначення поточної позиції в системі координат тайлів
	$jump_ray.force_raycast_update()

	direction = Vector2()
	var tile_pos = main_node.to_64(position)
	var l_tile_pos = main_node.to_64($points/left.global_position)
	
	# Встановлення значень тайлів по 4 ключовим точкам
	var c_cell = main_node.world_to_tile(position)
	var l_cell = main_node.world_to_tile($points/left.global_position)
	var ld_cell = main_node.world_to_tile($points/l_down.global_position)
	var d_cell = main_node.world_to_tile(position + Vector2(0, 32))
	# Встановлення значень типів тайлів по 4 ключовим точкам,
	# що дозволяє визначати реакцію персонажа на управління
	var c_cell_t = t_type(c_cell)
	var l_cell_t = t_type(l_cell)
	var ld_cell_t = t_type(ld_cell)
	var d_cell_t = t_type(d_cell)
	# створення змінних зля бреженнення команд управління
	var left_key = false
	var right_key = false
	var up_key = false
	var down_key = false
	
	var can_move_up = !obstacle(UP) and (c_cell_t == 1 or l_cell_t == 1)
	var can_move_down = !obstacle(DOWN)
	on_the_ladder = (c_cell == 1 or d_cell == 1 or l_cell == 1 or ld_cell == 1)
	var on_pipe = (c_cell_t == 2 or l_cell_t == 2) and tile_pos.y <= position.y
	
	current_tile_pos = main_node.world_to_tile_pos(position)
	# Визначення поточної позиції в тайловій системі зі зміщенням вправо на пів тайла
	var current_tile_pos_minus32 = main_node.world_to_tile_pos(position - Vector2(32,0))

	# Якщо персонаж знаходиться в пастці, і йому дозволено вибратись з неї, та очистити позицію поточної пастки з пам'яті
	# ця ситуація передбачає на короткий час можливість рухатись понад відкритою пасткою
	if to_remove_last_trap_tile:
		# значення тайла в комінці з пасткою
		var ltp = main_node.get_cell(last_trap_tile + Vector2(0,1))
		# Якщо пастку відкрито в тім самім місці вдруге, а персонаж не зміщувався з неї, він повинен провалитись повторно
		var new_hole = last_trap_cell == -1 and ltp != -1
		# Якщо персонаж вийшов за межі дозволеного простору, після того, як вибрався з пастки, особливий статус анулюється
		if new_hole or !(current_tile_pos == last_trap_tile or (current_tile_pos + Vector2(0,-1)) == last_trap_tile or current_tile_pos_minus32 == last_trap_tile):
			to_remove_last_trap_tile = false
			last_trap_tile = Vector2()
		# збереження стану комірки з пасткою, для перевірки, чи не було створено нову пастку в тому ж місці
		last_trap_cell = ltp
	# Примусове оновлення стану променів
	for r in $rays.get_children():
		r.force_raycast_update()
	
	# Якщо це не бот, записати в змінні управління стан натиснення клавіш
	if bot_class == 0:
		left_key = Input.is_action_pressed("ui_left")
		right_key = Input.is_action_pressed("ui_right")
		up_key = Input.is_action_pressed("ui_up")
		down_key = Input.is_action_pressed("ui_down")
	
	# А от якщо це бот...
	elif bot_class > 0 and nav != null:
		if path.size() > 0:
			var d = position.distance_to(path[0])
			var d_vec = position - path[0]
			if d > 32:
				var ss = ""
				if d_vec.y < 0 and !obstacle(DOWN) and on_the_ladder:
					down_key = true
					ss += "down  "
				elif d_vec.x > 0 and !obstacle(LEFT):
					left_key = true
					ss += "left  "
				elif d_vec.x < 0 and !obstacle(RIGHT):
					right_key = true
					ss += "right "
				elif d_vec.y < 0 and !obstacle(DOWN):
					down_key = true
					ss += "down  "
				if d_vec.y > 0 and can_move_up:
					up_key = true
					ss += "up    "
				
			else:
				path.remove(0)

		var fall_distance = position.distance_to($jump_ray.get_collision_point())
		var y_diff = position.y - goal.y
		var dd = Vector2(0, 1).dot((goal - position).normalized())
		var fallDif = fall_distance - (abs(y_diff) + 32)
		if on_pipe and fallDif < 32 and dd > 0.15 and !obstacle(DOWN):
			down_key = true
			left_key = false
			right_key = false
			up_key = false
			$nav_update.wait_time = 0.01
			$nav_update.start()
			
		# відображення стрілок, що допомагають дізнатись про напрямок, куди намагається рухатись бот
		$arrows/up.visible = up_key
		$arrows/down.visible = down_key
		$arrows/left.visible = left_key
		$arrows/right.visible = right_key
		
		# Якщо не в пастці, заборонити повзти вгору
		if !in_the_trap or last_trap_tile.y != (current_tile_pos.y-1):
			allowe_to_crawl_up = false
		# Якщо в пастці та дозволено повзти вгору, тоді повзи
		if in_the_trap and allowe_to_crawl_up:
			left_key = false
			right_key = false
			down_key = false
			up_key = true

	
# Додадковий інформаційний вивід, що дозволяє відлагоджувати гру
	var debug_type = 2
	$gold.visible = gold_slot > 0
	$points/center/x.visible = allowed_to_pickup
	$points/left/x.visible = to_drop_gold
	
	$points/center/x.visible =  allowe_to_crawl_up
#	$points/left/x.visible = l_cell_t ==  debug_type
	$points/down/x.visible = d_cell_t ==  debug_type
	$points/l_down/x.visible = bot_go_random
	
	if tile_pos.x <= position.x and tile_pos.y <= position.y:
		if c_cell_t == 3:
			if bot_class == 0:
				main_node.play_sound("coin")
				gold += 1
				main_node.replace_cell(main_node.world_to_tile_pos(position),-1)
			elif gold_slot == 0 and allowed_to_pickup:
				to_drop_gold = false
				gold_slot = 1
				$timers/bot_drop_timer.wait_time = randf() * 20 + 8
				$timers/bot_drop_timer.start()
				main_node.replace_cell(main_node.world_to_tile_pos(position),-1)
		if bot_class > 0:
			pass
#			print(in_the_trap)
		if bot_class > 0 and gold_slot > 0 and in_the_trap:
			gold_slot = 0
			var drop_pos = main_node.world_to_tile_pos(position)
			main_node.replace_cell(drop_pos, 13)
			
		if bot_class > 0 and gold_slot > 0 and to_drop_gold and c_cell == -1 and !in_the_trap:
			allowed_to_pickup = false
			gold_slot = 0
			$timers/bot_pickup_timer.wait_time = randf() * 15 + 8
			$timers/bot_pickup_timer.start()
			main_node.replace_cell(main_node.world_to_tile_pos(position),13)
	# визначення, чи знаходиться персонаж на драбині
	# А чи може на трубі
	
	on_the_ladder = on_the_ladder or on_pipe
	# Якщо в пастці та дозволено повзти вгору, вести себе наче на драбині
	
	if allowe_to_crawl_up and in_the_trap:
		on_the_ladder = true
	
	# Якщо відпущено ліву клавішу буріння
	if Input.is_action_just_released("B") and main_player:
		b_press = false
		if current_hole != null:
			current_hole.play_back()
		current_hole = null
	# Якщо відпущено праву клавішу буріння
	if Input.is_action_just_released("A") and main_player:
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
				current_hole = main_node.add_empty_cell(cell_to_empty)
				$Sprite.frame = 19

	can_move_up = (up_key and (c_cell_t == 1 or l_cell_t == 1))
	can_move_down = down_key
	
	if in_the_trap and allowe_to_crawl_up:
		can_move_up = true
	
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
		if up_key and (c_cell == 1 or allowe_to_crawl_up):
			if !obstacle(UP):
				direction.y = -1
				if !is_moving:
					currentDir = Vector2(0,-1)
		if down_key:
			if !obstacle(DOWN):
				direction.y = 1
			if !is_moving:
				currentDir = Vector2(0,1)
		
	elif left_key and (obstacle(DOWN) or on_the_ladder) and (bot_class == 0 or !in_the_trap):
		if !obstacle(LEFT):
			direction.x = -1
		if !is_moving:
			currentDir = Vector2(-1,0)
	elif right_key and (obstacle(DOWN) or on_the_ladder) and (bot_class == 0 or !in_the_trap):
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
		if up_cell == -1 or up_cell_name == "ladder_top":
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

func set_in_trap(value):
	in_the_trap = value
	if value:
		last_trap_tile = main_node.world_to_tile_pos(position) 
		if bot_class > 0:
			$timers/bot_get_out_timer.start()
			$colSwitch.play("in_trap")
	else:
		if bot_class > 0:
			$colSwitch.play("bot")

func die():
	if bot_class > 0:
		$colSwitch.play("bot")
	in_the_trap = false
	last_trap_tile = Vector2()
	$timers/bot_get_out_timer.stop()
	to_remove_last_trap_tile = false
	allowe_to_crawl_up = false
	main_node.remove_player(self)
	target_pos = Vector2()
	target_direction = Vector2()
	direction = Vector2()
	is_moving = false
	global_position = spawn_pos
	if bot_class > 0:
		update_path()

func obstacle(dir):
	if dir == UP:
		return $rays/up.is_colliding() or $rays/up2.is_colliding() 
	elif dir == DOWN:
		if last_trap_tile != Vector2():
			var current_tile_pos_minus32 = main_node.world_to_tile_pos(position - Vector2(32,0))
			if main_node.world_to_tile_pos(position) == last_trap_tile or current_tile_pos_minus32 == last_trap_tile:
				to_remove_last_trap_tile = true
				return true
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
	if path.size() > 0:
		if bot_go_random and randi()%path.size() > 12:
			goal = Vector2(randf() * 2000, randf() * 1000)
	path = nav.get_simple_path(position, goal, false)
	if path.size() == 0:
		pass
#		print(path.size())

func _on_cooldown_timeout():
	cooldown = true

func _on_nav_update_timeout():
	if nav != null and bot_class > 0:
		update_path()
		$nav_update.wait_time = randf() * 0.5 + 0.5
		$nav_update.start()
		
func _on_Area_body_entered(body):
	print("name " + name + " body " + body.name)
	if body.is_in_group("level"):
		die()

func _on_bot_pickup_timer_timeout():
	allowed_to_pickup = true

func _on_bot_drop_timer_timeout():
	to_drop_gold = true

func _on_bot_get_out_timer_timeout():
	allowe_to_crawl_up = true

func _on_Area_area_entered(area):
	if bot_class == 0:
		if area.is_in_group("player"):
			if area.get_parent().bot_class > 0:
				die()

func _on_Area_area_exited(area):
	pass # replace with function body

func _on_random_dir_timer_timeout():
	bot_go_random = true
	pass
