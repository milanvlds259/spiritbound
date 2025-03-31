class_name Enemy extends CharacterBody2D

@export var speed: float = 100
@export var health: int = 1

@export var damage_label: PackedScene

# Marker movement parameters
@export var marker_end_point: Marker2D = null   # Drag a Marker2D node here if available.
@export var marker_limit: float = 1.5           # When to change movement direction

@export var follow_duration: float = 10.0
@export var follow_distance: int = 900
@export var consider_distance: int = 700

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_area: Area2D = $HitBox         # The Area2D used for taking damage

@onready var attacking = false


@export var impulse_str: float = 200

@export var ai_type: String = "FOLLOW";

@onready var follow_area: Area2D = $FollowArea      # Area2D used for vision
enum State{IDLE, FOLLOW, CONSIDER, BACK, RUN}
enum GameAi{CHASER, RUNNER, GUARDER}

var hurt_color = Color(255,0,0)
var hurt_duration = 0.1

var current_state: State = State.IDLE

var start_position: Vector2
var end_position: Vector2

var target : Player

func _ready() -> void:
	# Connect the hurt area's signal for collision detection.
	if hurt_area:
		hurt_area.area_entered.connect(_on_hurt_area_entered)
	# Initialize marker movement positions.
	start_position = position
	if marker_end_point:
		end_position = marker_end_point.global_position
	else:
		end_position = start_position + Vector2(0, 10)

	# Connect enemy hitbox to hit player
	$HitBox.body_entered.connect(_on_hitbox_body_entered)

func _process(_delta: float) -> void:
	updateAnimations()

func _physics_process(_delta: float) -> void:
	update_velocity()
	move_and_slide()

func updateAnimations() -> void:
	if !attacking:
		$AnimatedSpriwte2D.play("walk")
	else:
		$AnimatedSprite2D.play("attack")
		await get_tree().create_timer(1).timeout
		attacking = false

	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func update_marker_velocity() -> void:
	pass
	# Marker-based movement: enemy moves between start_position and end_position.
	var move_direction: Vector2 = (end_position - global_position)

	if move_direction.length() < marker_limit:
		_change_marker_direction()
	# Set velocity in the direction toward the active target position.
	velocity = move_direction.normalized() * speed

func update_velocity() -> void:
	match current_state:
		State.IDLE:
			update_marker_velocity()
			var overlap = follow_area.get_overlapping_bodies()
			var filtered = overlap.filter(func(b): return b is Player)
			if !filtered.is_empty():
				follow_body(filtered[0])

		State.FOLLOW:
			# Follows Player until Enemy gets too far away
			var dist_to_start = (start_position - global_position).length()
			
			var overlap = follow_area.get_overlapping_bodies()
			var filtered = overlap.filter(func(b): return b is Player)
			if filtered.is_empty():
				current_state = State.BACK
				return
			
			#Finds the target player's position and computes the directoin to follow
			var direction = target.global_position - global_position
			var new_velocity = direction.normalized() * speed
			
			if dist_to_start > follow_distance:
				current_state = State.RUN
				
			velocity = new_velocity
		
		#State.CONSIDER:
		#	var dir_to_start = end_position - global_position
		#	var overlap = follow_area.get_overlapping_bodies()
		#	var filtered = overlap.filter(func(b): return b is Player)
		#	
		#	if !filtered.is_empty():
		#		follow_body(filtered[0])
		#		print("considering")
		#	if dir_to_start.length() < marker_limit:
		#		global_position = end_position
		#		current_state = State.IDLE
		
		State.BACK:
			var dir_to_start = start_position - global_position
			if dir_to_start.length() < marker_limit:
				position = start_position
				print("back")
				print(dir_to_start.length())
				velocity = Vector2.ZERO
				current_state = State.IDLE
				return
			var overlap = follow_area.get_overlapping_bodies()
			var filtered = overlap.filter(func(b): return b is Player)
			if !filtered.is_empty():
				follow_body(filtered[0])
			velocity = dir_to_start.normalized() * speed
			
		State.RUN:
			var dir_to_start = start_position - global_position
			if dir_to_start.length() < consider_distance:
				current_state = State.BACK
				return
			
			velocity = dir_to_start.normalized() * speed * 2


func follow_body(body) -> void:
	target = body
	current_state = State.FOLLOW
	print("chasing")
	#await get_tree().create_timer(follow_duration).timeout
	#stop_follow()

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

func _on_hurt_area_entered(area: Area2D) -> void:
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
			var push_dir = (body.global_position - global_position).normalized()
			var angle = push_dir.angle();
		
			if body.has_method("apply_knockback"):
				body.apply_knockback(push_dir * impulse_str)
				await get_tree().create_timer(0.5).timeout
				body.apply_knockback(push_dir * impulse_str)
				body.take_damage(2)
		
			if $AttackEffect:
				$AttackEffect.rotation = angle
				$AttackEffect.position = push_dir * 5
				$AttackEffect/AttackEffectSprite.play("attack")

		
			await get_tree().create_timer(0.5).timeout
			attacking = false


func damage_taken(damage: int) -> void:
	modulate = hurt_color
	health -= damage

	var damage_label_instance = damage_label.instantiate()
	damage_label_instance.text = str(damage)

	add_child(damage_label_instance)

	if health <= 0:
		died()
	await get_tree().create_timer(hurt_duration).timeout
	modulate = Color(1, 1, 1, 1)

func died() -> void:
	disable()
	modulate = hurt_color
	await get_tree().create_timer(hurt_duration).timeout
	queue_free()

func disable() -> void:
	# Disable further physics processing (could also play a death animation, etc.).
	set_physics_process(false)
