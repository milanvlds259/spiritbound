class_name Minotaur extends CharacterBody2D

# Speed, Health, Damage#
@export var speed: float = 100
var charge_speed: float
@export var max_health: int = 1
var current_health: int
@export var base_damage: float = 1

# Animation #
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Damage Taken and Death #
@export var damage_label: PackedScene
var hurt_color = Color(1,0,0)
var hurt_duration = 0.1
@onready var hit_box: Area2D = $HitBox         # The Area2D used for taking damage

# Attacking #
@onready var attacking = false
@export var impulse_str: float = 500

# AI #
enum State{IDLE, FOLLOW, BACK, ATTACK, CHARGE}
enum Mind{CALM, ANNOYED, ANGERED}
@export var ai_type: String = "FOLLOW";
@onready var vision: Area2D = $Vision              #Used for dialogue and vision
@onready var follow_area: Area2D = $FollowArea     #Used for following
var current_state: State = State.IDLE
var mind_state: Mind = Mind.CALM
var start_position: Vector2       # Sets where we will guard if the player runs
var end_position: Vector2         # Sets where we will go depending on different factors
var limit: float = 1              # Sets how close we need to be to a location

# Target: Player #
var target : Player # Target our player

func _ready() -> void:
	# Speed and Health # Set Charge Speed
	charge_speed = 5 * speed
	current_health = max_health

	if hit_box:
		# Connect enemy hitbox when area entered
		hit_box.area_entered.connect(_on_hitbox_area_entered)
		# Connect enemy hitbox to hit player
		hit_box.body_entered.connect(_on_hitbox_body_entered)
	
	# Initialize base guarding spot.
	start_position = position


func _process(_delta: float) -> void:
	updateAnimations()

func _physics_process(_delta: float) -> void:
	update_velocity()
	move_and_slide()

func updateAnimations() -> void:
	match current_state:
		# Match animations to possible states
		###########################CHANGE ANIMATIONS WHEN COMPLETE
		State.IDLE:
			$AnimatedSprite2D.play("walk") # play idle animation
		State.FOLLOW:
			$AnimatedSprite2D.play("walk") # play walking animation
		State.BACK:
			$AnimatedSprite2D.play("walk") # play walking animation (walking back to spot)
		State.ATTACK:
			$AnimatedSprite2D.play("walk") # play attacking animation
		State.CHARGE:
			$AnimatedSprite2D.play("walk") # play charging animation

	# Orients the sprite based on the direction of movement
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func update_velocity() -> void:
	match current_state:
		State.IDLE:
			match mind_state:
				Mind.CALM:
					var overlap = follow_area.get_overlapping_bodies()
					var filtered = overlap.filter(func(b): return b is Player)
					if !filtered.is_empty():
						follow_body(filtered[0])

				Mind.ANNOYED:
					var overlap = vision.get_overlapping_bodies()
					var filtered = overlap.filter(func(b): return b is Player)
					if !filtered.is_empty():
						follow_body(filtered[0])

				Mind.ANGERED:
					var overlap = vision.get_overlapping_bodies()
					var filtered = overlap.filter(func(b): return b is Player)
					if !filtered.is_empty():
						follow_body(filtered[0])

		State.FOLLOW:
			var overlap = follow_area.get_overlapping_bodies()
			var filtered = overlap.filter(func(b): return b is Player)
			if filtered.is_empty():
				match mind_state:
					Mind.CALM:
						current_state = State.BACK
				current_state = State.CHARGE
				return
			#Finds the target player's position and computes the directoin to follow
			var direction = target.global_position - global_position
			var new_velocity = direction.normalized() * speed
			velocity = new_velocity
		
		State.BACK:
			var dir_to_start = start_position - global_position
			if dir_to_start.length() < limit:
				position = start_position
				velocity = Vector2.ZERO
				current_state = State.IDLE
				return
			var overlap = vision.get_overlapping_bodies()
			var filtered = overlap.filter(func(b): return b is Player)

			if !filtered.is_empty():
				follow_body(filtered[0])

			velocity = dir_to_start.normalized() * speed

		State.ATTACK:
			current_state = State.BACK
			return

		State.CHARGE:
			var overlap = vision.get_overlapping_bodies()
			var filtered = overlap.filter(func(b): return b is Player)
			if filtered.is_empty():
				match mind_state:
					Mind.ANGERED:
						speed = 1000
			#Finds the target player's position and computes the directoin to follow
			var direction = target.global_position - global_position
			var new_velocity = direction.normalized() * charge_speed
			velocity = new_velocity
			return


func follow_body(body) -> void:
	target = body
	match mind_state:
		Mind.CALM:
			current_state = State.FOLLOW
		Mind.ANNOYED:
			current_state = State.FOLLOW
		Mind.ANGERED:
			current_state = State.CHARGE
	print("chasing")


#func stop_follow() -> void:
#	if current_state != State.BACK:
#		target = null
#		print("timeout")
#		current_state = State.BACK

func _change_marker_direction() -> void:
	# Swap start and end positions.
	var temp: Vector2 = end_position
	end_position = start_position
	start_position = temp

func _on_hitbox_area_entered(area: Area2D) -> void:
	# Check if the area is the player's attack hitbox (temporary)
	if area.is_in_group("player_attack"):
		damage_taken(5)
	elif area.is_in_group("arrows"):
		damage_taken(2)
		area.queue_free()

func _on_hitbox_body_entered(body: Node) -> void:
	if attacking:
		var push_dir = (body.global_position - global_position).normalized()
		if body.has_method("apply_knockback"):
				body.apply_knockback(push_dir * impulse_str)
				await get_tree().create_timer(0.5).timeout
	else:
		attacking = true
		if body.is_in_group("player"):
			if body.has_method("stun"):
				body.stun(0.75)
			var push_dir = (body.global_position - global_position).normalized()
			var angle = push_dir.angle();
		
			if body.has_method("apply_knockback"):
				body.apply_knockback(push_dir * impulse_str * 0.5)
				await get_tree().create_timer(0.5).timeout
				body.apply_knockback(push_dir * impulse_str)
				body.take_damage(base_damage)

			if $AttackEffect:
				$AttackEffect.rotation = angle
				$AttackEffect.position = push_dir * 5
				$AttackEffect/AttackSprite.play("attack")

		
			await get_tree().create_timer(0.5).timeout
			attacking = false

func change_mind_state() -> void:
	match mind_state:
		Mind.CALM:
			if current_health < max_health:
				mind_state = Mind.ANNOYED
				print("annoyed")
		Mind.ANNOYED:
			if current_health < (10):
				mind_state = Mind.ANGERED
				print("angered!!")

func damage_taken(damage: int) -> void:
	modulate = hurt_color
	current_health -= damage
	var damage_label_instance = damage_label.instantiate()
	damage_label_instance.text = str(damage)

	add_child(damage_label_instance)

	if current_health <= 0:
		died()
	await get_tree().create_timer(hurt_duration).timeout
	modulate = Color(1, 1, 1, 1)
	change_mind_state()

func died() -> void:
	disable()
	modulate = hurt_color
	await get_tree().create_timer(hurt_duration).timeout
	queue_free()

func disable() -> void:
	# Disable further physics processing (could also play a death animation, etc.).
	set_physics_process(false)
