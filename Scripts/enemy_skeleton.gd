class_name EnemySkeleton extends CharacterBody2D

# Speed, Health, Damage
@export var speed: float = 200
@export var health: int = 5
@export var base_damage: int = 5

# Animation
@onready var sprite: AnimatedSprite2D = $SkellySprite

#Taking Damage
@export var damage_label: PackedScene
@onready var hurt_area: Area2D = $HitBox         # The Area2D used for taking damage
var hurt_color = Color(1,0.10,0.10)
var hurt_duration = 0.1

# Attacking
@onready var is_attacking = false
@onready var attack_range: Area2D = $AttackRange   # The Area2D for checking if player is in range
var attack_type = "attackdown"
@export var impulse_str: float = 200

# Movement/AI 
var target : Player
@onready var follow_area: Area2D = $Vision      # Area2D used for vision
enum State{IDLE, FOLLOW, HURT, ATTACK, DEATH, BLOCK}
var current_state: State = State.IDLE

# Start/End Position
var start_position: Vector2
var end_position: Vector2

func _ready() -> void:
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	$AttackArea/AttackHitbox.disabled = true
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
		State.FOLLOW:
			sprite.play("walk")

	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func update_velocity() -> void:
	match current_state:
		State.IDLE:
			var overlap = follow_area.get_overlapping_bodies()
			var filtered = overlap.filter(func(b): return b is Player)
			if !filtered.is_empty():
				follow_body(filtered[0])
			velocity = Vector2.ZERO

		State.FOLLOW:
			check_attack()
			# Follows Player until Enemy gets too far away			
			var overlap = follow_area.get_overlapping_bodies()
			var filtered = overlap.filter(func(b): return b is Player)
			if filtered.is_empty():
				current_state = State.IDLE
				return
			
			#Finds the target player's position and computes the directoin to follow
			var direction = target.global_position - global_position
			var new_velocity = direction.normalized() * speed
			velocity = new_velocity
		State.HURT:
			velocity = Vector2.ZERO
		State.ATTACK:
			velocity = Vector2.ZERO
		
		State.BLOCK:
			#Finds the target player's position and computes the directoin to follow
			if target:
				var direction = target.global_position - global_position
				var new_velocity = direction.normalized() * speed


func follow_body(body) -> void:
	target = body
	current_state = State.FOLLOW

func _on_hurt_area_entered(area: Area2D) -> void:
	# Check if the area is the player's attack hitbox (temporary)
	if area.is_in_group("player_attack"):
		damage_taken(3)
	elif area.is_in_group("arrows"):
		block_damage(0)
		area.queue_free()

func _on_hitbox_body_entered(body: Node) -> void:
	
	if body.is_in_group("player"):
		var push_dir = (body.global_position - global_position).normalized()
		body.apply_knockback(push_dir * impulse_str)

func block_damage(damage: int) -> void:
	current_state = State.BLOCK
	sprite.play("block")
	var damage_label_instance = damage_label.instantiate()
	damage_label_instance.text = str("blocked")
	add_child(damage_label_instance)
	
	

func damage_taken(damage: int) -> void:
	modulate = hurt_color
	current_state = State.HURT
	sprite.play("hurt")
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
	var attack_space = attack_range.get_overlapping_bodies()
	var attack_target = attack_space.filter(func(b): return b is Player)
	if !attack_target.is_empty():
		if !is_attacking:
			is_attacking = true
			attack(attack_target[0])
			current_state = State.ATTACK
			return

func attack(body) -> void:
	if body.is_in_group("player"):
		var push_dir = (body.global_position - global_position).normalized()
		var angle = push_dir.angle();
		$AttackArea.rotation = angle
		$AttackArea.position = push_dir * 5
		current_state = State.ATTACK
		if angle > 0:
			attack_type = "attackdown"
		else: 
			attack_type = "attackup"

func _on_frame_changed() -> void:
	var current_frame = sprite.frame
	var animation = sprite.animation
	if animation == "attackdown" or animation == "attackup":
		if current_frame > 2 and current_frame < 5:
			$AttackArea/AttackHitbox.disabled = false
		else:
			$AttackArea/AttackHitbox.disabled = true

func _on_sprite_animation_finished() -> void:
	if sprite.animation == "hurt":
		current_state = State.IDLE
		modulate = Color(1, 1, 1, 1)
		is_attacking = false

	elif sprite.animation == "death":
		queue_free()
		modulate = Color(1, 1, 1, 1)
		is_attacking = false

	elif sprite.animation == "attackdown" or sprite.animation == "attackup":
		current_state = State.IDLE
		is_attacking = false
	
	elif sprite.animation == "raiseshield" or sprite.animation == "block":
		current_state = State.IDLE
		is_attacking = false
		

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.stun(0.25)
		body.apply_knockback(body.position-global_position)
		body.take_damage(base_damage)
