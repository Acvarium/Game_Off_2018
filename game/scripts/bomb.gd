extends Position2D

func _ready():

	pass

func _on_exp_timer_timeout():
	$anim.play("explosion")
