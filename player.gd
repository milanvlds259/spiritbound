extends CharacterBody2D

@export var speed: float = 250.0  # Movement speed in pixels per second

var direction: Vector2 = Vector2.ZERO
var current_direction: String = "down"
var is_sprinting: bool = false
var is_attacking : bool = false

func _ready():
	$AnimatedSprite2D.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)

func _physics_process(delta):
	handle_input()
	move_and_slide()
	update_animation()


func handle_input():
	var input_direction = Vector2.ZERO
    
    # Always process movement to update velocity 
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
		if not is_attacking:
			current_direction = "left"
			$AnimatedSprite2D.flip_h = true
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
		if not is_attacking:
			current_direction = "right"
			$AnimatedSprite2D.flip_h = false
	if Input.is_action_pressed("move_up"):
		input_direction.y -= 1
		if not is_attacking:
			current_direction = "up"
	if Input.is_action_pressed("move_down"):
		input_direction.y += 1
		if not is_attacking:
			current_direction = "down"

	input_direction = input_direction.normalized()
	direction = input_direction
	velocity = direction * speed

    # Attack input check (only triggers if not already attacking)
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		$AnimatedSprite2D.play("attack")

func update_animation():
	if is_attacking:
		return

	if direction != Vector2.ZERO:
		$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("idle")

func _on_AnimatedSprite2D_animation_finished():
	print("Animation finished")
	if $AnimatedSprite2D.animation == "attack":
		print("Attack animation finished")
		is_attacking = false
		$AnimatedSprite2D.play("idle")