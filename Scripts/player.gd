class_name Player extends CharacterBody2D

@export var speed: float = 950.0  # Movement speed in pixels per second
@export var arrow: PackedScene
@export var elec_arrow: PackedScene
@export var regular_arrow_speed: float = 250
@export var thunder_arrow_speed: float = 1000
var arrow_speed: float = 250

enum Controltype{KEYBOARD, CONTROLLER}
# 0 is Keyboard, # 1 is Controller
@export var control_type: int = 0
var control = Controltype.KEYBOARD
var joystick_vector: Vector2 = Vector2.ZERO

@export var max_hp: int = 20
var hp: int
var is_invincible: bool = false

var stunned:bool = false

var direction: Vector2 = Vector2.ZERO
var current_direction: String = "down"
var is_sprinting: bool = false
var is_attacking : bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knockback_decay: float = 200.0

var attack_mode: String = ""
var arrow_fired: bool = false

var spirit_inventory: Array = []
@export var powerup_label: PackedScene

var continue_prompt_visible: bool = false
@onready var continue_prompt = $ContinuePrompt

func _ready():
	$PlayerSprite.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)
	$PlayerSprite.frame_changed.connect(_on_PlayerSprite_frame_changed)
	$AttackEffect01/AttackEffectSprite.frame_changed.connect(_on_attack_effect_frame_changed)
	$AttackEffect01/AttackHitbox.disabled = true
	$ContinuePrompt.visible = false

	# Set up hp bar
	call_deferred("emit_setup_hpbar")
	if (control_type == 0):
		control = Controltype.KEYBOARD
	else:
		control = Controltype.CONTROLLER


func _on_can_transition(can_transition: bool):
	$ContinuePrompt.visible = can_transition

func emit_setup_hpbar():
	hp = max_hp
	Global.emit_signal("setup_hpbar", hp, max_hp)


func _physics_process(_delta):
	handle_input()
	velocity += knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * _delta)
	update_animation()

func apply_knockback(impulse: Vector2) -> void:
    # Normalize the impulse vector first to ensure consistent direction
	var normalized_impulse = impulse.normalized()
    
    # Get the current scene scale to compensate
	var current_scene = get_tree().current_scene
	var scene_scale_factor = 1.0
    
    # If the scene has a scale property, use it to compensate
	if current_scene and current_scene.scale != Vector2.ONE:
		scene_scale_factor = (current_scene.scale.x + current_scene.scale.y) / 2
    
    # Apply a consistent force with scene scale compensation
	var adjusted_impulse = normalized_impulse * (knockback_decay / 2) / scene_scale_factor
    
    # Apply the final impulse
	knockback_velocity = adjusted_impulse

func handle_input():
	var input_direction = Vector2.ZERO

	# Flip sprtite depending on mouse position
	match control:
		Controltype.KEYBOARD:
			if get_viewport():
				# Get mouse position in world coordinates
				var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
				# Compare mouse position with player position
				if mouse_pos.x < global_position.x:
					if not $PlayerSprite.flip_h:
						$PlayerSprite.flip_h = true
				else:
					if $PlayerSprite.flip_h:
						$PlayerSprite.flip_h = false
	
		Controltype.CONTROLLER:
			var look_dir = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
			if look_dir < 0:
				if not $PlayerSprite.flip_h:
					$PlayerSprite.flip_h = true
			else:
				if $PlayerSprite.flip_h:
					$PlayerSprite.flip_h = false
	
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

	var speed_mult = 1.0
	if "air" in spirit_inventory:
		speed_mult = 1.5

	velocity = direction * speed * speed_mult
	if stunned:
		velocity = Vector2.ZERO

	# Attack input check (only triggers if not already attacking)
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		_attack_melee()

	if Input.is_action_just_pressed("ranged_attack"):
		is_attacking = true
		_attack_ranged()

func add_spirit(type: String) -> void:
	spirit_inventory.append(type)
	Global.emit_signal("spirit_inventory_updated", spirit_inventory)
	print("Spirit added to inventory: ", type)

	var powerup_text: String = ""

	if type == "earth":
		powerup_text = "+25 Max HP!"
		max_hp += 25        # Increase max health by x
		hp += 25            # Heal by x so that the new max is accounted for
		Global.emit_signal("player_hp_changed", hp)
		Global.emit_signal("setup_hpbar", hp, max_hp)
	elif type == "fire":
		powerup_text = "Larger Melee Range!"
	elif type == "air":
		powerup_text = "+50% Move Speed!"
	elif type == "thunder":
		powerup_text = "Faster Arrows"
	else:
		powerup_text = "Unknown Effect!"

	if powerup_label:
		var label_instance = powerup_label.instantiate()
		label_instance.text = powerup_text
		add_child(label_instance)

func _attack_melee():
	
	var attack_dir = Vector2.ZERO
	var angle = 0
	match control:
		# Sets attack direction and attack angle for the rotation and direction later
		Controltype.KEYBOARD:
			var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()

			attack_dir = (mouse_pos - global_position).normalized()
			angle = attack_dir.angle()
		
		Controltype.CONTROLLER:
			# takes the current value of the right joystick to figure out the attack direction and angle
			attack_dir = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
			angle = atan2(attack_dir.y, attack_dir.x)
			
	# Orients the attack effect sprite so that it looks correct
	if $PlayerSprite.flip_h:
		$AttackEffect01/AttackEffectSprite.flip_h = true
	else:
		$AttackEffect01/AttackEffectSprite.flip_h = false

	if $AttackEffect01/AttackEffectSprite.flip_h:
		angle += PI
	
	
	$AttackEffect01/AttackEffectSprite.rotation = angle
	$AttackEffect01/AttackEffectSprite.position = attack_dir * 5

	# Update attack hitbox collider
	$AttackEffect01/AttackHitbox.position = attack_dir * 12
	$AttackEffect01/AttackHitbox.rotation = angle + PI/2

	$PlayerSprite.play("attack")
	if "fire" in spirit_inventory:
		$AttackEffect01/AttackHitbox.scale = Vector2(2, 2)
		$AttackEffect01/AttackEffectSprite.scale = Vector2(2, 2)
		$AttackEffect01/AttackHitbox.position = attack_dir * 16
		$AttackEffect01/AttackEffectSprite.position = attack_dir * 5
		$AttackEffect01/AttackEffectSprite.play("attack01fire")
	else:
		$AttackEffect01/AttackHitbox.scale = Vector2(1, 1)
		$AttackEffect01/AttackEffectSprite.scale = Vector2(1, 1)
		$AttackEffect01/AttackEffectSprite.play("attack01")




func _attack_ranged():
	attack_mode = "ranged"
	arrow_fired = false
	$PlayerSprite.play("attack_ranged")

func fire_arrow():
	var used_arrow: PackedScene
	if "thunder" in spirit_inventory:
		used_arrow = elec_arrow
		arrow_speed = thunder_arrow_speed
	else:
		used_arrow = arrow
		arrow_speed = regular_arrow_speed

	if not arrow:
		push_error("Arrow scene not set")
		return

	# calculate initial position of arrow
	var arrow_instance = used_arrow.instantiate()

    # Calculate the correct position and scale for the arrow
	var current_scene = get_tree().current_scene
	var scene_scale = current_scene.scale
	var scale_factor = 1.0


	if current_scene.name == "tutorial_level":
		scale_factor = 4.0
	elif scene_scale != Vector2.ONE:
		scale_factor = (scene_scale.x + scene_scale.y) / 2
	else:
		scale_factor = 1.0
	print(scale_factor)

	get_tree().current_scene.add_child(arrow_instance)

	arrow_instance.global_position = global_position

	arrow_instance.scale = Vector2(1, 1) / scene_scale
	
	# Different method of firing arrow based on input type
	var dir = Vector2.ZERO
	
	match control:
		# Sets attack direction and attack angle for the rotation and direction later
		Controltype.KEYBOARD:
			# Get the player's position in viewport coordinates
			var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	  
			# Get attack direction relative to the player
			dir = (mouse_pos - global_position).normalized()
			arrow_instance.rotation = dir.angle()
			
		
		Controltype.CONTROLLER:
			# takes the current value of the right joystick to figure out the attack direction and angle
			dir = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
			if dir == Vector2.ZERO:
				dir = Vector2(1,0)
			var angle = atan2(dir.y, dir.x)
			dir = dir.normalized()
			arrow_instance.rotation = angle
	# calculate direction of arrow

	var adjusted_speed = arrow_speed * scale_factor
	if current_scene.name != "tutorial_level":
		adjusted_speed = adjusted_speed / 4.0
	arrow_instance.velocity = dir * adjusted_speed

func take_damage(damage: int):
	if is_invincible:
		return
	is_invincible = true
	hp -= damage
	if hp <= 0:
		hp = 0
		die()
	Global.emit_signal("player_hp_changed", hp)
	$PlayerSprite.play("hurt")


func die():
	# Emit signal to global script
	Global.emit_signal("player_died")
	#disable player
	queue_free()

func _on_PlayerSprite_frame_changed():
	# When performing a ranged attack, fire the arrow at frame 6.
	if attack_mode == "ranged" and not arrow_fired:
		if $PlayerSprite.frame == 6:
			arrow_fired = true
			fire_arrow()

func _on_attack_effect_frame_changed():
	var current_frame = $AttackEffect01/AttackEffectSprite.frame
	# If the current frame is where the attack should be active.
	# Adjust the frame numbers (e.g. 3 and 4) as needed depending on your animation indexing.
	if current_frame == 2 or current_frame == 3:
		$AttackEffect01/AttackHitbox.disabled = false
	else:
		$AttackEffect01/AttackHitbox.disabled = true

func update_animation():
	if is_attacking or $PlayerSprite.animation == "hurt":
		return

	if direction != Vector2.ZERO:
		$PlayerSprite.play("run")
	else:
		$PlayerSprite.play("idle")

func _on_AnimatedSprite2D_animation_finished():
	if $PlayerSprite.animation == "hurt":
		is_invincible = false
		is_attacking = false
		$PlayerSprite.play("idle")
	if $PlayerSprite.animation == "attack" or $PlayerSprite.animation == "attack_ranged":
		is_invincible = false ## If you initiate an attack while the hurt animation is occuring, then player stays invincible
		is_attacking = false
		attack_mode = ""
		$PlayerSprite.play("idle")

func stun(secs: float):
	stunned = true
	await get_tree().create_timer(secs).timeout
	stunned = false
	
