class_name Minotaur extends CharacterBody2D

# Speed, Health, Damage #
@export var speed: float = 100
var charge_speed: float
@export var max_health: int = 1
var current_health: int
@export var base_damage: float = 1

# Animation #
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Damage Taken/Healing Death #
@export var damage_label: PackedScene
var hurt_color = Color(255,0,0)
var heal_color = Color(0,0,255)
var hurt_duration = 0.1
@onready var hit_box: Area2D = $HitBox         # The Area2D used for taking damage

# Attacking #
@onready var is_attacking = false
@onready var charging = false
@export var impulse_str: float = 500
@onready var attack_range: Area2D = $AttackRange   # The Area2D for checking if player is in range
var charging_position: Vector2

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
	charge_speed = 3 * speed
	current_health = max_health
	charging_position = Vector2.ZERO


	$AttackEffect/AttackSprite.frame_changed.connect(_on_attack_effect_frame_changed)
	$AttackEffect/AttackHitbox.disabled = true
	
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
			modulate = Color(1, 1, 1, 1)
		State.FOLLOW:
			$AnimatedSprite2D.play("walk") # play walking animation
			modulate = Color(1, 1, 1, 1)
		State.BACK:
			$AnimatedSprite2D.play("walk") # play walking animation (walking back to spot)
			modulate = Color(1, 1, 1, 1)
		State.ATTACK:
			$AnimatedSprite2D.play("walk") # play attacking animation
			modulate = Color(1, 1, 0, 1)
		State.CHARGE:
			$AnimatedSprite2D.play("walk") # play charging animation
			modulate = Color(1, 0, 1, 1)

	# Orients the sprite based on the direction of movement
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func update_velocity() -> void:
	match mind_state:
		Mind.CALM:
			match current_state:
				State.IDLE:
					var overlap = follow_area.get_overlapping_bodies()
					var filtered = overlap.filter(func(b): return b is Player)
					if !filtered.is_empty():
						follow_body(filtered[0])

				State.FOLLOW:
					check_attack()
					var overlap = follow_area.get_overlapping_bodies()
					var filtered = overlap.filter(func(b): return b is Player)
					if filtered.is_empty():
						current_state = State.BACK
						return
					var direction = target.global_position - global_position
					var new_velocity = direction.normalized() * speed
					velocity = new_velocity
				
				State.ATTACK:
					print("attacking")
					velocity = Vector2.ZERO
				
				State.BACK:
					print("going back")
					var dir_to_start = start_position - global_position
					print(dir_to_start)
					if dir_to_start.length() < limit:
						print("reset")
						position = start_position
						velocity = Vector2.ZERO
						current_state = State.IDLE
						return
					var overlap = follow_area.get_overlapping_bodies()
					var filtered = overlap.filter(func(b): return b is Player)
					if !filtered.is_empty():
						follow_body(filtered[0])
					velocity = dir_to_start.normalized() * speed

		Mind.ANNOYED:
			match current_state:
				State.IDLE:
					print("idle")
					var overlap = follow_area.get_overlapping_bodies()
					var filtered = overlap.filter(func(b): return b is Player)
					if !filtered.is_empty():
						follow_body(filtered[0])
				State.FOLLOW:
					print("follow")
					check_attack();
					var overlap = follow_area.get_overlapping_bodies()
					var filtered = overlap.filter(func(b): return b is Player)
					if filtered.is_empty():
						current_state = State.BACK
						return
					var direction = target.global_position - global_position
					var new_velocity = direction.normalized() * speed * 1.5
					velocity = new_velocity
				State.ATTACK:
					print("attack")
					velocity = Vector2.ZERO
				State.BACK:
					print("back")
					var dir_to_start = start_position - global_position
					if dir_to_start.length() < limit:
						position = start_position
						velocity = Vector2.ZERO
						current_state = State.IDLE
						return
					var overlap = follow_area.get_overlapping_bodies()
					var filtered = overlap.filter(func(b): return b is Player)
					if !filtered.is_empty():
						follow_body(filtered[0])
					velocity = dir_to_start.normalized() * speed
				

		Mind.ANGERED:
			match current_state:
				State.IDLE:
					print("idle")
					var overlap = vision.get_overlapping_bodies()
					var filtered = overlap.filter(func(b): return b is Player)
					if !filtered.is_empty():
						follow_body(filtered[0])
				State.FOLLOW:
					print("follow")
					check_attack();
					var over_vis = vision.get_overlapping_bodies()
					var filt_vis = over_vis.filter(func(b): return b is Player)
					if filt_vis.is_empty():
						current_state = State.BACK
						return
					var over_foll = follow_area.get_overlapping_bodies()
					var filt_foll = over_foll.filter(func(b):return b is Player)
					if filt_foll.is_empty():
						charge(filt_vis[0])
						return
					var direction = target.global_position - global_position
					var new_velocity = direction.normalized() * speed * 2
					velocity = new_velocity
				State.ATTACK:
					print("attack")
					velocity = Vector2.ZERO
				State.CHARGE:
					print("charge")
					if !charging:
						return
					var dir_to_charge = charging_position - global_position
					if dir_to_charge.length() < limit*3:
						position = charging_position
						velocity = Vector2.ZERO
						current_state = State.IDLE
						charging = false
						charging_position = global_position
						await get_tree().create_timer(1).timeout
						return
					velocity = dir_to_charge.normalized() * charge_speed
				State.BACK:
					print("back")
					var dir_to_start = start_position - global_position
					if dir_to_start.length() < limit:
						position = start_position
						velocity = Vector2.ZERO
						current_state = State.IDLE
						return
					var overlap = follow_area.get_overlapping_bodies()
					var filtered = overlap.filter(func(b): return b is Player)
					if !filtered.is_empty():
						follow_body(filtered[0])
					velocity = dir_to_start.normalized() * speed

func check_attack() -> void:
	var attack_space = attack_range.get_overlapping_bodies()
	var attack_target = attack_space.filter(func(b): return b is Player)
	if !attack_target.is_empty():
		if !is_attacking:
			is_attacking = true
			attack_melee(attack_target[0])
			current_state = State.ATTACK
			return

func follow_body(body) -> void:
	target = body
	current_state = State.FOLLOW

func charge(body) -> void:
	target = body
	current_state = State.CHARGE
	charging_position = body.global_position
	charging = true

func _on_hitbox_area_entered(area: Area2D) -> void:
	# Check if the area is the player's attack hitbox (temporary)
	if area.is_in_group("player_attack"):
		damage_taken(5)
	elif area.is_in_group("arrows"):
		damage_taken(2)
		area.queue_free()

func _on_hitbox_body_entered(body: Node) -> void:

	var push_dir = (body.global_position - global_position).normalized()
	if body.has_method("apply_knockback"):
		body.apply_knockback(push_dir * 2* impulse_str)

func attack_melee(body) -> void:
	if body.is_in_group("player"):
		var push_dir = (body.global_position - global_position).normalized()
		var angle = push_dir.angle();
		await get_tree().create_timer(0.5).timeout


		if $AttackEffect:
			$AttackEffect.rotation = angle
			$AttackEffect.position = push_dir * 5
			match mind_state:
				Mind.CALM:
					$AttackEffect/AttackSprite.play("attack")

				Mind.ANNOYED:
					$AttackEffect/AttackSprite.play("attack")

				Mind.ANGERED:
					$AttackEffect/AttackSprite.play("attack_fire")

func _on_attack_effect_frame_changed():
	var current_frame = $AttackEffect/AttackSprite.frame
	# If the current frame is where the attack should be active.
	# Adjust the frame numbers (e.g. 3 and 4) as needed depending on your animation indexing.
	if mind_state == Mind.ANGERED and current_frame == 5:
		$AttackEffect/AttackHitbox.disabled = false
	elif current_frame == 3 or current_frame == 4:
		$AttackEffect/AttackHitbox.disabled = false
	else:
		$AttackEffect/AttackHitbox.disabled = true



func change_mind_state() -> void:
	match mind_state:
		Mind.CALM:
			if current_health < (0.90 * max_health):
				mind_state = Mind.ANNOYED
				print("annoyed")
		Mind.ANNOYED:
			if current_health == max_health:
				mind_state = Mind.CALM
				print("calmed")
			if current_health < (0.40 * max_health):
				mind_state = Mind.ANGERED
				print("angered!!")
		Mind.ANGERED:
			if current_health > (0.60 * max_health):
				mind_state = Mind.ANNOYED

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

func damage_heal(heal: int) -> void:
	modulate = heal_color
	if current_health < max_health:
		current_health += min(max_health-current_health, heal)
	
	var damage_label_instance = damage_label.instantiate()
	damage_label_instance.text = str(heal)

	add_child(damage_label_instance)

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

func _on_attack_effect_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		match mind_state:
			Mind.CALM:
				body.stun(0.25)
				body.apply_knockback(body.position-global_position)
				body.take_damage(base_damage)

			Mind.ANNOYED:
				body.stun(0.5)
				body.apply_knockback(body.position-global_position)
				body.take_damage(2*base_damage)

			Mind.ANGERED:
				body.stun(0.75)
				body.apply_knockback(body.position-global_position)
				body.take_damage(3*base_damage)
		
	 # Replace with function body.


func _on_attack_sprite_animation_finished() -> void:
	is_attacking = false
	current_state = State.FOLLOW
	 # Replace with function body.
