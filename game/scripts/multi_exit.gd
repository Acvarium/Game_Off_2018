extends Area2D
var main_node = null

func _ready():
	main_node = get_node("/root/main")

func _on_multi_exit_body_entered(body):
	print(body.name)
	if body.get("bot_class") != null:
		if body.bot_class == 0:
			$ex0.modulate = Color(0,0,1)
			main_node.multi_exit(1)

func _on_multi_exit_body_exited(body):
	if body.get("bot_class") != null:
		if body.bot_class == 0:
			$ex0.modulate = Color(1,1,1)
			main_node.multi_exit(-1)
