extends KinematicBody2D
var main_node
var half_blast_size = Vector2(112,32)
export var is_explothing = false
var velocity = 0
var is_moving = false
var target_y = 0
var max_speed = 300
var destroy = false

func _ready():
	set_physics_process(false)
	main_node = get_node("/root/main")
	if has_node("rays"):
		set_physics_process(true)

func _physics_process(delta):
	if is_explothing:
		if !destroy:
			destroy = true
			var cell_pos = main_node.world_to_tile_pos(position)
			main_node.replace_cell(cell_pos, -1)
			main_node.replace_cell(cell_pos + Vector2(1,0), -1)
			main_node.replace_cell(cell_pos + Vector2(-1,0), -1)
			
			
		kill()
	if has_node("rays"):
		$rays/down.force_raycast_update()
		$rays/down2.force_raycast_update()
		if !$rays/down.is_colliding() and !$rays/down2.is_colliding() and !is_moving:
			var current_cell = main_node.world_to_map(position)
			target_y = main_node.map_to_world(current_cell + Vector2(0,1)).y
			is_moving = true
		if is_moving:
			var speed = max_speed
			velocity = speed * delta
			var distance_to_target = abs(target_y - position.y)
			if abs(velocity) > distance_to_target:
				velocity = distance_to_target
				is_moving = false
			move_and_collide(Vector2(0, velocity))
		
func kill():
	var cell_pos = main_node.world_to_tile_pos(position)
	var AA = position - half_blast_size
	var BB = position + half_blast_size
	var to_die = main_node.players_in_rect(AA, BB)
	for p in to_die:
		p.get_ref()._die("exp", 5)
	
func _on_exp_timer_timeout():
	$anim.play("explosion")
	$kill_timer.start()

func _on_anim_animation_finished(anim_name):
	if anim_name == "explosion":
		queue_free()

func _on_kill_timer_timeout():
	is_explothing = true
	set_physics_process(true)
