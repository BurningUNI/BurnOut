extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
const SPEED = 70

var last_direction = "down"

func _physics_process(delta):
	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	elif Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	elif Input.is_action_pressed("ui_up"):
		direction.y -= 1

	velocity = direction.normalized() * SPEED
	move_and_slide()

	# ANIMAZIONE
	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				sprite.play("walk_right")
				last_direction = "right"
			else:
				sprite.play("walk_left")
				last_direction = "left"
		else:
			if direction.y > 0:
				sprite.play("walk_down")
				last_direction = "down"
			else:
				sprite.play("walk_up")
				last_direction = "up"
	else:
		sprite.play("idle_" + last_direction)
