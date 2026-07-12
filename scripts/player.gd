extends CharacterBody2D

var current_speed = 400.0 
const JUMP_VELOCITY = -700.0 
const GRAVITY = 1600.0

@onready var animated_sprite = $AnimatedSprite2D
const MAX_JUMPS = 2 
var jumps_left = MAX_JUMPS
var is_jumping = false

const COYOTE_TIME = 0.15
var coyote_timer = 0.0

var is_dead = false

func _physics_process(delta):
	
	if is_dead:
		velocity.x = 0
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	if is_on_floor():
		coyote_timer = COYOTE_TIME
		jumps_left = MAX_JUMPS
		is_jumping = false
	else:
		coyote_timer -= delta 
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("jump"):
		if coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1
			coyote_timer = 0.0 
			is_jumping = true
		elif jumps_left > 0:
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1
			is_jumping = true
			

	if Input.is_action_just_released("jump") and velocity.y < 0 and is_jumping:
		velocity.y *= 0.5 

	velocity.x = current_speed
	
	if is_on_floor():
		animated_sprite.play("default")
	else:
		animated_sprite.play("jump")

	move_and_slide()

func die():
	is_dead = true
