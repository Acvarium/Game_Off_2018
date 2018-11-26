extends Position2D
var main_node
var half_blast_size = Vector2(112,32)
var is_explothing = false

func _ready():
	set_physics_process(false)
	main_node = get_node("/root/main")

func _physics_process(delta):
	if is_explothing:
		kill()

func kill():
	var cell_pos = main_node.world_to_tile_pos(position)
	var AA = position - half_blast_size
	var BB = position + half_blast_size
	var to_die = main_node.players_in_rect(AA, BB)
	for p in to_die:
		p.get_ref().die()
	
func _on_exp_timer_timeout():
	$anim.play("explosion")
	$kill_timer.start()

func _on_anim_animation_finished(anim_name):
	if anim_name == "explosion":
		queue_free()

func _on_kill_timer_timeout():
	is_explothing = true
	set_physics_process(true)
