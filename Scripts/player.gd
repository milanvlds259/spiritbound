class_name Player extends CharacterBody2D

@export var speed: float = 250.0  # Movement speed in pixels per second
@export var arrow: PackedScene
@export var elec_arrow: PackedScene
@export var arrow_speed: float = 750

var hp: int = 20
var max_hp: int = 20
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

func _on_can_transition(can_transition: bool):
	$ContinuePrompt.visible = can_transition

func emit_setup_hpbar():
	Global.emit_signal("setup_hpbar", hp, max_hp)


func _physics_process(_delta):
	handle_input()
	velocity += knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * _delta)
	update_animation()

func apply_knockback(impulse: Vector2) -> void:
	knockback_velocity += impulse

func handle_input():
	var input_direction = Vector2.ZERO

	if Input.is_action_just_pressed("interact"):
		if $ContinuePrompt.visible:
			get_tree().change_scene_to_file("res://Scenes/main.tscn")

	# Flip sprtite depending on mouse position
	if get_viewport():
		if get_viewport().get_mouse_position().x < get_viewport().size.x / 2:
			if not $PlayerSprite.flip_h:
				$PlayerSprite.flip_h = true
				#if not is_attacking:
					#$AttackEffect01/AttackEffectSprite.flip_h = true
		else:
			if $PlayerSprite.flip_h:
				$PlayerSprite.flip_h = false
				#if not is_attacking:
					#$AttackEffect01/AttackEffectSprite.flip_h = false
	
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
		powerup_text = "+20 Max HP!"
		max_hp += 20        # Increase max health by 20
		hp += 20            # Heal by 20 so that the new max is accounted for
		Global.emit_signal("player_hp_changed", hp)
		Global.emit_signal("setup_hpbar", hp, max_hp)
	elif type == "fire":
		powerup_text = "Larger Melee Range!"
	elif type == "air":
		powerup_text = "+50% Move Speed!"
	elif type == "thunder":
		powerup_text = "Faster Arrows"
	else:
		powerup_text = "Unknown Spirit!"

	if powerup_label:
		var label_instance = powerup_label.instantiate()
		label_instance.text = powerup_text
		add_child(label_instance)

func _attack_melee():
	# get attack dir from mouse pos relative to center of screen
	var center = Vector2(get_viewport().size / 2)
	var attack_dir = (get_viewport().get_mouse_position() - center).normalized()
	var angle = attack_dir.angle()

	if get_viewport().get_mouse_position().x < get_viewport().size.x / 2:
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
		arrow_speed = 2500
	else:
		used_arrow = arrow
		arrow_speed = 750

	if not arrow:
		push_error("Arrow scene not set")
		return

	# calculate initial position of arrow
	var arrow_instance = used_arrow.instantiate()
	arrow_instance.position = global_position

	# calculate direction of arrow
	var center = Vector2(get_viewport().size / 2)
	var dir = (get_viewport().get_mouse_position() - center).normalized()

	# set arrow direction
	arrow_instance.rotation = dir.angle()
	arrow_instance.velocity = dir * arrow_speed

	get_tree().current_scene.add_child(arrow_instance)

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
	if current_frame == 3 or current_frame == 4:
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
		is_attacking = false
		attack_mode = ""
		$PlayerSprite.play("idle")

func stun(secs: float):
	stunned = true
	await get_tree().create_timer(secs).timeout
	stunned = false
	
