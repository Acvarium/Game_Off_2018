extends KinematicBody2D

var target_pos = Vector2()
var target_direction = Vector2()
var is_moving = false
var on_the_ladder = false
var main_node
var speed = 0
var max_speed = 300
var velocity = Vector2()
enum ENTITY_TYPES {UP, DOWN, LEFT, RIGHT}
var cooldown = true
var current_hole_L = null
var current_hole_R = null
const BOMB_MAX_SPEED = 250

var gold = 0
var nav = null
var nav_from_above = null
var goal = Vector2()
var goal_obj = null
var path = []
var gold_slot = 0
var to_drop_gold = false
var in_the_trap = false
var allowed_to_pickup = true
var follow_player = true
var last_pos = Vector2()
var ghost_mode = false
export var player_side = 0

export var bot_class = 0
export var main_player = true
var canvas = null

var on_the_floor = false

var allowe_to_crawl_up = false
var direction = Vector2()
var currentDir = Vector2(0,-1)
var b_press = false
var a_press = false

var bb_press = false
var aa_press = false

var spawn_pos = Vector2()
export var last_trap_tile = Vector2()
var to_remove_last_trap_tile = false
var last_trap_cell = 999
var current_tile_pos = Vector2()
var bot_random_dir = UP
var bot_go_random = true
var stand_time = 0
var allowe_to_move = true
var frozen = false
var bombs = 0
var left_key = false
var right_key = false
var up_key = false
var down_key = false
var was_in_trap
var bot2_dir = Vector2(1, 0)
var invinc = false
var to_explode = false
var explosion_started = false
var direct_ray_length = 320
#					 left   right   up     down
var bot_neighbors = [false, false, false, false]

func pickup_bonus(value):
	bombs += 1
	main_node.play_sound("bom")
	main_node.replace_cell(main_node.world_to_tile_pos(position),-1)
	main_node.set_bomb_count(bombs, player_side)

func _ready():
	main_node = get_node("/root/main")
	canvas = main_node.get_node("canvas")
	if main_node.is_in_group("view"):
		set_physics_process(false)
		visible = false
		return
	randomize()
	# Налаштування променів ігнорувати власника
	for r in $rays.get_children():
		r.add_exception(self)
	# Визначення позиції появи в місці, де персонаж розташований на початку гри
	spawn_pos = global_position
	if bot_class > 0:
		if bot_class == 1:
			$colSwitch.play("bot")
		elif bot_class == 2:
			$colSwitch.play("bot1")
			if randf() < 0.5:
				bot2_dir = Vector2(-1, 0)
	else:
		$colSwitch.play("player")
	# Додати даного персонажа до списку персонажів на рівні
	if bot_class == 1:
		$Sprite.texture = preload("res://textures/hero_bot.png")
	if bot_class == 2:
		$Sprite.texture = preload("res://textures/bomb_anim.png")
		max_speed = BOMB_MAX_SPEED
		$anim.playback_speed = 0.6
		$timers/explosion_timer.wait_time = randf() * 6 + 2
		$timers/explosion_timer.start()
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	main_node.add_player(self)
#--------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------

func add_debug_lines(shift, col):
	if path.size() > 0 and bot_class == 1:
		var shift_vec = Vector2(shift, shift)
		var cp = position
		for p in path:
			canvas.lines.append([cp + shift_vec, p + shift_vec, col])
			cp = p

func set_keys(l,r,u,d):
	left_key = l
	right_key = r
	up_key = u
	down_key = d

func _physics_process(delta):
	if frozen:
		if $anim.is_playing():
			if $anim.current_animation == "explode" and !obstacle(DOWN):
				$anim.stop()
				$Sprite.modulate = Color(1,1,1)
				frozen = false
				$sounds/pss.play()
				
			pass
		return
#	for i in range(4):
#		bot_neighbors[i] = false
	
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
#	$coo.text = str(c_cell_t) + " " + str(l_cell_t) + " " + str(ld_cell_t) + " " + str(d_cell_t)
	
	if c_cell_t == 999 or l_cell_t == 999:
		_die("exp", 0.1)
	# створення змінних зля бреженнення команд управління
	set_keys(false,false,false,false)
	for r in $rays.get_children():
		r.force_raycast_update()
		
	if bot_class > 0:
		find_bot_neighbors()
		
	if bot_class == 1:
		find_bot_neighbors()
	var can_move_up = !obstacle(UP) and (c_cell_t == 1 or l_cell_t == 1)
	on_the_ladder = (c_cell_t == 1 or d_cell_t == 1 or l_cell_t == 1 or ld_cell_t == 1)
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

	
	# Якщо це не бот, записати в змінні управління стан натиснення клавіш
	if bot_class == 0:
		set_keys(Input.is_action_pressed("ui_left"), Input.is_action_pressed("ui_right"), Input.is_action_pressed("ui_up"), Input.is_action_pressed("ui_down"))
	
	# А от якщо це бот...
#**************************************************************************************************
#**************************************************************************************************
	elif bot_class > 0:
		if bot_class == 1 and nav != null:
			if path.size() > 0:
				var d = position.distance_to(path[0])
				var d_vec = position - path[0]
				if d > 32:
					if d_vec.y < 0 and !obstacle(DOWN) and on_the_ladder:
						down_key = true
					elif d_vec.x > 0 and !obstacle(LEFT):
						left_key = true
					elif d_vec.x < 0 and !obstacle(RIGHT):
						right_key = true
					elif d_vec.y < 0 and !obstacle(DOWN):
						down_key = true
					if d_vec.y > 0 and can_move_up:
						up_key = true
				else:
					path.remove(0)
			
		
	#**************************************************************************************************
		elif bot_class == 2 and !in_the_trap:
			var cell_on_right = main_node.world_to_tile_pos(position) + Vector2(1,1)
			var cr = t_type(main_node.get_cell(cell_on_right))
			var cell_on_left = main_node.world_to_tile_pos(position) + Vector2(-1,1)
			var cl = t_type(main_node.get_cell(cell_on_left))
			
			if bot2_dir.x == 1:
				if obstacle(RIGHT) or cr == -1:
					bot2_dir.x = -1
				else:
					set_keys(false,true,false,false)
			else:
				if obstacle(LEFT) or cl == -1:
					bot2_dir.x = 1
				else:
					set_keys(true,false,false,false)
	# Якщо не в пастці, заборонити повзти вгору
		if !in_the_trap or last_trap_tile.y != (current_tile_pos.y-1):
			allowe_to_crawl_up = false
		# Якщо в пастці та дозволено повзти вгору, тоді повзи
		if in_the_trap and allowe_to_crawl_up:
			set_keys(false, false, true, false)	
# Додадковий інформаційний вивід, що дозволяє відлагоджувати гру
	var debug_type = 2
	$gold.visible = gold_slot > 0
	
	
	if tile_pos.x <= position.x and tile_pos.y <= position.y:
		if c_cell_t == 3:
			if bot_class == 0:
				main_node.play_sound("coin")
				gold += 1
				main_node.update_gold_count(1)
				main_node.replace_cell(main_node.world_to_tile_pos(position),-1)
			elif gold_slot == 0 and allowed_to_pickup:
				to_drop_gold = false
				gold_slot = 1
				$timers/bot_drop_timer.wait_time = randf() * 20 + 8
				$timers/bot_drop_timer.start()
				main_node.replace_cell(main_node.world_to_tile_pos(position),-1)
		elif c_cell_t == 4:
			main_node.exit()
		elif c_cell_t == 5:
			if bot_class == 0:
				pickup_bonus("bomb")
				
		if bot_class > 0 and gold_slot > 0 and in_the_trap:
			gold_slot = 0
			var drop_pos = main_node.world_to_tile_pos(position)
			var gold_id = 13
			if main_node.set_num == 2:
				gold_id = 29
			main_node.replace_cell(drop_pos, gold_id)
			
# Викинути бомбу якщо в пастці бот 2 класу
		elif bot_class == 2 and gold_slot == 0 and in_the_trap and !was_in_trap and randf() < 0.3:
			var drop_pos = main_node.world_to_tile_pos(position)
			var bomb_id = 36
			main_node.replace_cell(drop_pos, bomb_id)

		if bot_class > 0 and gold_slot > 0 and to_drop_gold and c_cell == -1 and !in_the_trap and obstacle(DOWN):
			allowed_to_pickup = false
			gold_slot = 0
			$timers/bot_pickup_timer.wait_time = randf() * 15 + 8
			$timers/bot_pickup_timer.start()
			var gold_id = 13
			if main_node.set_num == 2:
				gold_id = 29
			main_node.replace_cell(main_node.world_to_tile_pos(position), gold_id)
	# визначення, чи знаходиться персонаж на драбині
	# А чи може на трубі
	
	on_the_ladder = on_the_ladder or on_pipe
	# Якщо в пастці та дозволено повзти вгору, вести себе наче на драбині
	
	if allowe_to_crawl_up and in_the_trap:
		on_the_ladder = true
	

#--------------------------------------------------------------------------------------------------------------------
	# Якщо відпущено ліву клавішу буріння
	if Input.is_action_just_released("B") and main_player:
		b_press = false
		bb_press = false
		
		if current_hole_L != null:
			if current_hole_L.get_ref():
				current_hole_L.get_ref().play_back()
		current_hole_L = null
	# Якщо відпущено праву клавішу буріння
	if Input.is_action_just_released("A") and main_player:
		a_press = false
		aa_press = false
		if current_hole_R != null:
			if current_hole_R.get_ref():
				
				
				current_hole_R.get_ref().play_back()
		current_hole_R = null

#--------------------------------------------------------------------------------------------------------------------
# Обробка натискання клавіш свирління
#--------------------------------------------------------------------------------------------------------------------
	var fully_on_floor = $rays/down.is_colliding() and $rays/down2.is_colliding() 
	if abs(direction.y) == 0:
		if Input.is_action_pressed("B") and main_player and (fully_on_floor or on_the_ladder or on_pipe) and !current_hole_R:
			var cell_to_empty = main_node.world_to_tile_pos(position)
			cell_to_empty.x -= 1
			cell_to_empty.y += 1
			if can_be_holed(cell_to_empty) and !b_press:
				b_press = true
				$sounds/blaster_L.play()
				current_hole_L = weakref(main_node.add_empty_cell(cell_to_empty))
				$Sprite.frame = 17
			elif !bb_press:
				$sounds/miss.play()
				bb_press = true
			
		if Input.is_action_pressed("A")  and main_player and (fully_on_floor or on_the_ladder or on_pipe) and !current_hole_L:
			var cell_to_empty = main_node.world_to_tile_pos(position)
			cell_to_empty.x += 1
			cell_to_empty.y += 1
			if tile_pos.x > position.x:
				cell_to_empty.x -= 1
			if can_be_holed(cell_to_empty) and !a_press:
				a_press = true
				$sounds/blaster_R.play()
				current_hole_R = weakref(main_node.add_empty_cell(cell_to_empty))
				$Sprite.frame = 19
			elif !aa_press:
				$sounds/miss.play()
				aa_press = true
#--------------------------------------------------------------------------------------------------------------------

	if bot_neighbors[0]:
		set_keys(false,true,false,false)
	if bot_neighbors[3]:
		set_keys(false,true,true,false)
		
	can_move_up = (up_key and (c_cell_t == 1 or l_cell_t == 1))
	if current_hole_L != null or current_hole_R != null:
		set_keys(false, false, false, false)
		
	if in_the_trap and allowe_to_crawl_up:
		can_move_up = true
	
	if can_move_up or down_key:
		if tile_pos.x > position.x:
			var go_right = (c_cell_t == 1 or d_cell_t == 1)
			if (up_key and c_cell_t == 1 and d_cell_t != 1):
				go_right = true
			elif up_key and l_cell_t == 1 and c_cell_t != 1:
				go_right = false
			elif up_key and ld_cell_t == 1 and d_cell_t != 1:
				go_right = false
				
			if go_right:
				direction.x = 1
				if !is_moving:
					currentDir = Vector2(1,0)
			else:
				direction.x = -1
				if !is_moving:
					currentDir = Vector2(-1,0)
		if up_key and (c_cell_t == 1 or allowe_to_crawl_up):
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


	if tile_pos.x > position.x and (current_hole_R != null or current_hole_L != null):
		if current_hole_R:
			target_pos = current_hole_R.get_ref().position + Vector2(-64,-64)
			if position.x > target_pos.x:
				target_direction = Vector2(-1,0)
			else:
				target_direction = Vector2(1,0)
			is_moving = true
		if current_hole_L:
			target_pos = current_hole_L.get_ref().position + Vector2(64,-64)
			if position.x > target_pos.x:
				target_direction = Vector2(-1,0)
			else:
				target_direction = Vector2(1,0)
			is_moving = true
	
	if !is_moving and direction != Vector2():
		target_direction = direction
		if main_node.is_cell_vacant(self):
			target_pos = main_node.map_to_world(main_node.world_to_map(position) + direction)
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

		
		
#--------------------------------------------------------------------------------------------------------------------
# Анімація
#--------------------------------------------------------------------------------------------------------------------
	if current_hole_L or current_hole_R:
		if $anim.is_playing():
			$anim.stop()
		if b_press and a_press:
			$Sprite.frame = 14
		elif b_press:
			$Sprite.frame = 17
		elif a_press:
			$Sprite.frame = 19
		
	elif direction.y == 1:
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
	elif direction == Vector2():
		if $anim.is_playing():
			if $anim.current_animation != "stand" and !b_press and !a_press:
				$anim.stop()
		if on_the_ladder and velocity.y != 0:
			$Sprite.frame = 20
		else:
			if abs(velocity.x) < 3 and !(t_type(c_cell) == 2 or t_type(l_cell) == 2)  and !b_press and !a_press:
				if $anim.current_animation != "stand":
					$anim.play("stand")
	was_in_trap = in_the_trap
	if bot_class == 2 and !is_moving and to_explode and tile_pos.x <= position.x and tile_pos.y <= position.y:
		start_explosion()

#--------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------

#	if last_pos == position and bot_class > 0:
#		if (OS.get_ticks_msec() - stand_time) > 100:
#			random_goal()
#	else:
#		stand_time = OS.get_ticks_msec()
#	last_pos = position


func can_be_holed(cell_pos):
	var _cell = main_node.get_cell(cell_pos) 
	var cell_name = main_node.get_tile_name(_cell)
	if cell_name.left(8) == "ground_h":
		return false
	if cell_name.left(1) == 'g':
		var up_cell_pos = cell_pos
		up_cell_pos.y -= 1
		var up_cell = main_node.get_cell(up_cell_pos)
		var up_cell_name = main_node.get_tile_name(up_cell)
		if up_cell == -1 or up_cell_name == "ladder_top" or up_cell_name == "empty":
			return true
	return false

func t_type(cell):
	var cell_name = main_node.get_tile_name(cell)
	if cell_name == 'ladder':
		return 1
	elif cell_name.left(1) == 'l':
		return 998
	elif cell_name.left(1) == 'p':
		return 2
	elif cell_name == "gold":
		return 3
	elif cell_name == "exit":
		return 4
	elif cell_name == "bomb":
		return 5
	elif cell_name == "empty":
		if bot_class == 0:
			return -1
		else:
			return 6
	elif cell_name.left(8) == "ground_h":
		return 7
	elif cell != -1:
		return 999
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
	if invinc:
		return
	if bot_class > 0:
		respawn()
	else:
		if !ghost_mode:
			main_node.busted(position)

func respawn():
	print("resp " + name)
	if bot_class > 0:
		
		frozen = false
		$colSwitch.play("bot")
		in_the_trap = false
		last_trap_tile = Vector2()
		$timers/bot_get_out_timer.stop()
		to_remove_last_trap_tile = false
		allowe_to_crawl_up = false
		target_pos = Vector2()
		target_direction = Vector2()
		direction = Vector2()
		is_moving = false
		global_position = spawn_pos
		update_path()
		if bot_class == 2:
			$timers/explosion_timer.start()
		$sounds/teleport.play()
		if bot_class == 2:
			$timers/explosion_timer.start()

func _die(die_type, _time_out):
	if invinc:
		return
	if bot_class == 0:
		die()
	else:
		if die_type == "exp":
			if gold_slot > 0:
				main_node.spawn_around(current_tile_pos, "gold")
				gold_slot = 0
			frozen = true
			position = main_node.get_freezer_pos(self)
			$timers/respawn_timer.wait_time = _time_out
			$timers/respawn_timer.start()

func start_explosion():
	to_explode = false
	$timers/explosion_timer.wait_time = 6
	if in_the_trap or !obstacle(DOWN):
		$timers/explosion_timer.start()
	else:
		frozen = true
		$anim.play("explode")

func toggle_ghost():
	ghost_mode = !ghost_mode
	if ghost_mode:
		modulate = Color(1,1,1,0.5)
	else:
		modulate = Color(1,1,1,1)
		

func is_bot_around(ray):
	if ray.is_colliding():
		var col_obj = ray.get_collider()
		if col_obj.is_in_group("character"):
			if col_obj.bot_class > 0:
				if direction != col_obj.direction:
					return true
#		if ray.get_collider() != null:
#			if ray.get_collider().get("bot_class") != null:
#				if ray.get_collider().bot_class > 0:
#					return true
	return false

func find_bot_neighbors():
	var hn = false
	for r in $rays.get_children():
		if r.is_in_group("a"):
			if is_bot_around(r):
				hn = true
	if hn and randf() < 0.2:
		random_goal()



#	for i in range(4):
#		bot_neighbors[i] = false
#	var sides = ["left", "right", "up", "down"]
#	for i in range(4):
#		for j in range(2):
#			var n = ""
#			if j == 1:
#				n == "2"
#			if is_bot_around(get_node("rays/" + sides[i] + n)):
#				bot_neighbors[i] = true
#	var sss = ""
#	for i in range(4):
#		sss += str(int(bot_neighbors[i])) + " "
#	$coo.text = sss

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

func _input(event):
	pass
	if bot_class == 0:
		if Input.is_action_just_released("put"):
			if bombs > 0:
				bombs -= 1
				main_node.set_bomb_count(bombs, player_side)
				main_node.put_obj("bomb", $points/center.global_position)
			else:
				$sounds/miss.play()
		if Input.is_action_just_pressed("ghost"):
			toggle_ghost()

func set_nav(new_nav):
	nav = new_nav
	update_path()

func set_goal(new_goal):
	goal = new_goal
	update_path()

func update_path():
	var c_nav = nav
	if follow_player and goal_obj != null:
		goal = goal_obj.position
	if (position.y - goal.y) < -32 and nav_from_above != null:
		c_nav = nav_from_above
	if c_nav != null:
		path = c_nav.get_simple_path(position, goal, false)
	if path.size() == 0:
		random_goal()
	$coo.text = str(path.size())

func _on_cooldown_timeout():
	cooldown = true

func random_goal():
	var to_random = true
	if !follow_player and randf() < 0.5:
		 to_random = false
	if !follow_player and path.size() < 1:
		to_random = true
	if to_random:
		follow_player = false
	#	if randf() < 0.15 or path.size() < 1:
		var rand_b_pos = main_node.get_random_bonus_cell()
		if rand_b_pos != null:
			var rand_pos = main_node.tile_to_world_pos(rand_b_pos)
			goal = rand_pos
			if nav != null and bot_class > 0:
				update_path()
	
func _on_nav_update_timeout():
	follow_player = true
#	if path.size() > 0:
#		if randi()%path.size() > 5:
#			random_goal()
	if nav != null and bot_class > 0:
		update_path()
		$nav_update.wait_time = randf() * 0.5 + 0.5
		$nav_update.start()
		
func _on_Area_body_entered(body):
	if body.is_in_group("level"):
		_die("exp", 0.1)

func _on_bot_pickup_timer_timeout():
	allowed_to_pickup = true

func _on_bot_drop_timer_timeout():
	to_drop_gold = true

func _on_bot_get_out_timer_timeout():
	allowe_to_crawl_up = true
	if bot_class == 2:
		print("Allowe")

func _on_Area_area_entered(area):
	if area.is_in_group("level"):
		_die("exp", 0.1)
	if bot_class == 0:
		if area.is_in_group("player"):
			if area.get_parent().bot_class > 0:
				_die("exp", 0.1)

func _on_Area_area_exited(area):
	pass # replace with function body

func _on_random_dir_timer_timeout():
	bot_go_random = true
	pass

func _on_respwn_timer_timeout():
	var spawner_obj = load("res://objects/spawner.tscn")
	var spawner = spawner_obj.instance()
	get_parent().add_child(spawner)
	spawner.set_player(self)
	spawner.position = spawn_pos
	
#	respawn()

func _on_anim_animation_finished(anim_name):
	
	if anim_name == "explode":
		invinc = true
		main_node.put_obj("explosion", $points/center.global_position)
		$anim.play("cooldown")
	elif anim_name == "cooldown":
		invinc = false
		frozen = false
		$timers/explosion_timer.start()

func _on_explosion_timer_timeout():
	to_explode = true
