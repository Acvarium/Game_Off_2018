extends KinematicBody2D

const GRAVITY = 500.0

const FLOOR_ANGLE_TOLERANCE = 40
const WALK_FORCE = 600
const WALK_MIN_SPEED = 10
const WALK_MAX_SPEED = 200
const STOP_FORCE = 1300
const JUMP_SPEED = 200
const JUMP_MAX_AIRBORNE_TIME = 0.2

const SLIDE_STOP_VELOCITY = 1.0 # one pixel/second
const SLIDE_STOP_MIN_TRAVEL = 1.0 # one pixel

var on_the_ladder = false
var velocity = Vector2()
var on_air_time = 100
var jumping = false
var dir = Vector2()
var last_dir = Vector2()
var prev_jump_pressed = false

func _physics_process(delta):
	var force = Vector2(0, GRAVITY)
	if on_the_ladder:
		force = Vector2(0, 0)
	var walk_left = Input.is_action_pressed("ui_left")
	var walk_right = Input.is_action_pressed("ui_right")
	var jump = Input.is_action_pressed("jump")
	var up = Input.is_action_pressed("ui_up")
	var down = Input.is_action_pressed("ui_down")
	
	var stop = true
	if walk_left:
		dir.x = -1
		if velocity.x <= WALK_MIN_SPEED and velocity.x > -WALK_MAX_SPEED:
			force.x -= WALK_FORCE
			stop = false
		if last_dir.x != -1:
			$anim.play("walk_left")
	elif walk_right:
		dir.x = 1
		if velocity.x >= -WALK_MIN_SPEED and velocity.x < WALK_MAX_SPEED:
			force.x += WALK_FORCE
			stop = false
			
		if last_dir.x != 1:
			$anim.play("walk_right")
	else:
		dir.x = 0
		if $anim.is_playing():
			$anim.stop()
	if on_the_ladder:
		if up:
			velocity.y = -WALK_MAX_SPEED
		elif down:
			velocity.y = WALK_MAX_SPEED
		else:
			velocity.y = 0
			
	if stop:

		var vsign = sign(velocity.x)
		var vlen = abs(velocity.x)
		
		vlen -= STOP_FORCE * delta
		if vlen < 0:
			vlen = 0
		
		velocity.x = vlen * vsign

	# Integrate forces to velocity
	velocity += force * delta	
	# Integrate velocity into motion and move
	velocity = move_and_slide(velocity, Vector2(0, -1))
	
	if is_on_floor():
		on_air_time = 0
		
	if jumping and velocity.y > 0:
		# If falling, no longer jumping
		jumping = false
	
	if on_air_time < JUMP_MAX_AIRBORNE_TIME and jump and not prev_jump_pressed and not jumping:
		# Jump must also be allowed to happen if the character left the floor a little bit ago.
		# Makes controls more snappy.
		velocity.y = -JUMP_SPEED
		jumping = true
	
	on_air_time += delta
	prev_jump_pressed = jump
	
	
	last_dir = dir
	
func _on_Area2D_area_entered(area):
	print("in")

func _on_Area2D_area_exited(area):
	print("out")

func _on_Area2D_body_entered(body):
	print("in")
	on_the_ladder = true
	
func _on_Area2D_body_exited(body):
	print("out")
	on_the_ladder = false
