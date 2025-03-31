class_name EnemySkelArcher extends CharacterBody2D

# Speed, Health, Damage
@export var speed: float = 250
@export var health: int = 5
@export var base_damage: int = 3
@export var skel_arrow: PackedScene

# Animation
@onready var sprite: AnimatedSprite2D = $SkelArcherSprite

#Taking Damage
@export var damage_label: PackedScene
@onready var hurt_area: Area2D = $HitBox         # The Area2D used for taking damage
var hurt_color = Color(1,0.50,0.50)
var hurt_duration = 0.1
var is_invincible: bool = false

# Attacking
@onready var is_attacking = false
@onready var attack_range: Area2D = $AttackRange   # The Area2D for checking if player is in range
var attack_type = "attack"
@export var impulse_str: float = 200
@export var arrow_speed: int = 1000

# Movement/AI 
var target : Player
@onready var follow_area: Area2D = $Vision      # Area2D used for vision
enum State{IDLE, FOLLOW, HURT, ATTACK, DEATH, RUN}
var current_state: State = State.IDLE

# Start/End Position
var start_position: Vector2
var end_position: Vector2

func _ready() -> void:
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	# Connect the hurt area's signal for collision detection.
	if hurt_area:
		hurt_area.area_entered.connect(_on_hurt_area_entered)
	# Initialize marker movement positions.
	start_position = position

	# Connect enemy hitbox to hit player
	$HitBox.body_entered.connect(_on_hitbox_body_entered)

func _process(_delta: float) -> void:
	updateAnimations()

func _physics_process(_delta: float) -> void:
	update_velocity()
	move_and_slide()

func updateAnimations() -> void:
	match current_state:
		State.IDLE:
			sprite.play("idle")
		State.ATTACK:
			sprite.play(attack_type)
			$AttackEffect.play("attackeffect")
		State.FOLLOW:
			sprite.play("walk")
		State.RUN:
			sprite.play("walk")

	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func update_velocity() -> void:
	var bugs = $BugCollider.get_overlapping_bodies()
	var filt_bugs = bugs.filter(func(b): return b is Player)
	if filt_bugs.is_empty():
		return
	else:
		target = filt_bugs[0]

	match current_state:
		State.IDLE:
			var overlap = follow_area.get_overlapping_bodies()
			var filtered = overlap.filter(func(b): return b is Player)
			if !filtered.is_empty():
				follow_body(filtered[0])
			velocity = Vector2.ZERO

		State.FOLLOW:
			var attackable_area = follow_area.get_overlapping_bodies()
			var filtered = attackable_area.filter(func(b): return b is Player)
			if filtered.is_empty():
				print("following")
				# Finds the target player's position and computes direction to follow
				if target:
					var direction = target.global_position - global_position
					var new_velocity = direction.normalized() * speed
					velocity = new_velocity
					return
			else:
				check_attack()
			# Follows Player until Enemy gets too far away


		State.HURT:
			velocity = Vector2.ZERO
		State.ATTACK:
			velocity = Vector2.ZERO

		State.RUN:
			# If the skeleton is already following player, it will continue, otherwise it will not change velocity
			var run_space = attack_range.get_overlapping_bodies()
			var filtered = run_space.filter(func(b): return b is Player)
			if !filtered.is_empty():
				# Finds the target player's position and computes direction to follow
				var scared_range = $ScaredRange.get_overlapping_bodies()
				var filt_scared = scared_range.filter(func(b): return b is Player)
				if !filt_scared.is_empty():
					check_attack()
					return
					var direction = -target.global_position + global_position
					var new_velocity = direction.normalized() * speed
					velocity = new_velocity
					return
			else:
				current_state = State.FOLLOW

func check_exists() -> bool:
	var check = get_tree().get_nodes_in_group("player")
	if check.size() > 0:
		return true
	return false

func follow_body(body) -> void:
	target = body
	current_state = State.FOLLOW

func _on_hurt_area_entered(area: Area2D) -> void:
	# Check if the area is the player's attack hitbox (temporary)
	if !is_invincible:
		if area.is_in_group("player_attack"):
			damage_taken(3)
		elif area.is_in_group("arrows"):
			damage_taken(1)
			area.queue_free()

func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var push_dir = (body.global_position - global_position).normalized()
		body.apply_knockback(push_dir * impulse_str)

func damage_taken(damage: int) -> void:
	is_invincible = true
	modulate = hurt_color
	current_state = State.HURT
	sprite.play("hurt")
	$AttackEffect.stop()
	var damage_label_instance = damage_label.instantiate()
	damage_label_instance.text = str(damage)
	add_child(damage_label_instance)
	health -= damage
	if health <= 0:
		died()

func died() -> void:
	current_state = State.DEATH
	disable()
	sprite.play("death")

func disable() -> void:
	# Disable further physics processing (could also play a death animation, etc.).
	set_physics_process(false)

func check_attack() -> void:
	var attack_space = follow_area.get_overlapping_bodies()
	var attack_target = attack_space.filter(func(b): return b is Player)
	if !attack_target.is_empty():
		if !is_attacking:
			is_attacking = true
			current_state = State.ATTACK
			return

func attack(body) -> void:
	if body.is_in_group("player"):
		var dir = (body.global_position - global_position).normalized()
		var arrow_instance = skel_arrow.instantiate()
		arrow_instance.position = global_position
		arrow_instance.rotation = dir.angle()
		arrow_instance.velocity = dir*arrow_speed
		arrow_instance.damage = base_damage
		get_tree().current_scene.add_child(arrow_instance)
		current_state = State.ATTACK
		if dir[0] < 0:
			sprite.flip_h = true
			$AttackEffect.flip_h = true
		else:
			sprite.flip_h = false
			$AttackEffect.flip_h = false
		$AttackEffect.play("attackeffect")
		

func _on_frame_changed() -> void:
	var current_frame = sprite.frame
	var animation = sprite.animation
	if animation == "attack":
		if current_frame > 6 and current_frame < 8:
			var attack_space = follow_area.get_overlapping_bodies()
			var attack_target = attack_space.filter(func(b): return b is Player)
			if !attack_target.is_empty():
				attack(attack_target[0])

func _on_sprite_animation_finished() -> void:
	is_invincible = false
	is_attacking = false
	if sprite.animation == "hurt":
		current_state = State.RUN
		modulate = Color(1, 1, 1, 1)

	elif sprite.animation == "death":
		queue_free()
		modulate = Color(1, 1, 1, 1)


	elif sprite.animation == "attack":
		current_state = State.RUN

	

		

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.apply_knockback(body.position-global_position)
		body.take_damage(base_damage)
