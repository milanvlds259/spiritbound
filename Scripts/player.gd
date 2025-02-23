class_name Player extends CharacterBody2D

@export var speed: float = 250.0  # Movement speed in pixels per second

var direction: Vector2 = Vector2.ZERO
var current_direction: String = "down"
var is_sprinting: bool = false
var is_attacking : bool = false
var push_force = 80.0

func _ready():
	$PlayerSprite.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)
	$AttackEffect01/AttackEffectSprite.frame_changed.connect(_on_attack_effect_frame_changed)
	$AttackEffect01/AttackHitbox.disabled = true

func _physics_process(_delta):
	handle_input()
	move_and_slide()
	handle_collision()
	update_animation()

func handle_collision():
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * push_force)


func handle_input():
	var input_direction = Vector2.ZERO

	# Flip sprtite depending on mouse position
	if get_viewport().get_mouse_position().x < get_viewport().size.x / 2:
		if not $PlayerSprite.flip_h:
			$PlayerSprite.flip_h = true
			$AttackEffect01/AttackEffectSprite.flip_h = true
	else:
		if $PlayerSprite.flip_h:
			$PlayerSprite.flip_h = false
			$AttackEffect01/AttackEffectSprite.flip_h = false
	
	# Always process movement to update velocity 
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
		if not is_attacking:
			current_direction = "left"
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
		if not is_attacking:
			current_direction = "right"
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

		# get attack dir from mouse pos relative to center of screen
		var center = Vector2(get_viewport().size / 2)
		var attack_dir = (get_viewport().get_mouse_position() - center).normalized()
		var angle = attack_dir.angle()

		if $AttackEffect01/AttackEffectSprite.flip_h:
			angle += PI

		print(attack_dir.angle())
		$AttackEffect01/AttackEffectSprite.rotation = angle
		$AttackEffect01/AttackEffectSprite.position = attack_dir * 5

		# Update attack hitbox collider
		$AttackEffect01/AttackHitbox.position = attack_dir * 12
		$AttackEffect01/AttackHitbox.rotation = angle + PI/2

		$PlayerSprite.play("attack")
		$AttackEffect01/AttackEffectSprite.play("attack01")

func _on_attack_effect_frame_changed():
	var current_frame = $AttackEffect01/AttackEffectSprite.frame
	# If the current frame is where the attack should be active.
	# Adjust the frame numbers (e.g. 3 and 4) as needed depending on your animation indexing.
	if current_frame == 3 or current_frame == 4:
		$AttackEffect01/AttackHitbox.disabled = false
	else:
		$AttackEffect01/AttackHitbox.disabled = true

func update_animation():
	if is_attacking:
		return

	if direction != Vector2.ZERO:
		$PlayerSprite.play("run")
	else:
		$PlayerSprite.play("idle")

func _on_AnimatedSprite2D_animation_finished():
	print("Animation finished")
	if $PlayerSprite.animation == "attack":
		print("Attack animation finished")
		is_attacking = false
		$PlayerSprite.play("idle")
