extends KinematicBody2D

var  gravity = 1000.0 # Pixels/second

const FLOOR_ANGLE_TOLERANCE = 1
const WALK_FORCE = 600
const WALK_MIN_SPEED = 300
const WALK_MAX_SPEED = 300
const STOP_FORCE = 5000
const JUMP_SPEED = 400

var velocity = Vector2()
var on_air_time = 100
var jumping = false
var onSteps = false
var prev_jump_pressed = false


func _fixed_process(delta):
	# Create forces
	
	var force = Vector2(0, gravity)

	var left = Input.is_action_pressed("left")
	var right = Input.is_action_pressed("right")
	var jump = Input.is_action_pressed("jump")
	var up = Input.is_action_pressed("up")
	var down = Input.is_action_pressed("down")
	
	#var rLeft = Input.action_release("left")
	
	var stop = true
	
	
	if (left):
		velocity.x = -WALK_MAX_SPEED

	elif (right):
		velocity.x = WALK_MAX_SPEED

	if (up) and onSteps:
		velocity.y = -WALK_MAX_SPEED 

	elif (down) and onSteps:
		velocity.y = WALK_MAX_SPEED 

	if jump and not onSteps and is_colliding():
		velocity.y = -JUMP_SPEED

	if (stop):
		var vsign = sign(velocity.x)
		var vlen = abs(velocity.x)

		vlen -= STOP_FORCE*delta
		if (vlen < 0):
			vlen = 0
		
		velocity.x = vlen*vsign

		if onSteps:
			var vSignY = sign(velocity.y)
			var vLenY = abs(velocity.y)
	
			vLenY -= STOP_FORCE*delta
			if (vLenY < 0):
				vLenY = 0
			velocity.y = vLenY*vSignY

	velocity.y += gravity*delta

	# Integrate velocity into motion and move
	var motion = velocity*delta
	motion = move(motion)

	if (is_colliding()) and not jump:
		var n = get_collision_normal()
		motion = n.slide(motion)
		velocity = n.slide(velocity)
		move(motion)

	if get_pos().x < 0:
		var a = get_pos()
		a.x += 1024
		set_pos(a)
	if get_pos().x > 1024:
		var a = get_pos()
		a.x -= 1024
		set_pos(a)
	if velocity.x > 0:
		get_node("Sprite").set_flip_h(true)
	elif velocity.x < 0:
		get_node("Sprite").set_flip_h(false)

func _ready():
	set_fixed_process(true)

#func _on_steps_body_enter( body ):
#	onSteps = true
#	gravity = 0.0
#	velocity.y = 0.0
#	velocity.x = 0.0
#
#func _on_steps_body_exit( body ):
#	gravity = 900.0
#	velocity.y = 0.0
#	velocity.x = 0.0
#	onSteps = false
#	pass # replace with function body


func _on_jumper_body_enter( body ):
	velocity.y = -abs(velocity.y)*1.1
	pass # replace with function body
