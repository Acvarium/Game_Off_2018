extends Sprite
var player = null

func _ready():
	pass

func set_player(_player):
	player = weakref(_player)

func _on_anim_animation_finished(anim_name):
	if player != null:
		if player.get_ref() != null:
			player.get_ref().respawn()
	queue_free()
