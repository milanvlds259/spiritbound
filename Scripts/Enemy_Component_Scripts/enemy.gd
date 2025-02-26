class_name Enemy extends CharacterBody2D

signal died

@export var speed: float = 100
@export var health: int = 1

# Marker movement parameters
@export var marker_end_point: Marker2D = null  # Drag a Marker2D node here if available.
@export var marker_limit: float = 0.5           # When to change movement direction

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurt_area: Area2D = $HitBox         # The Area2D used for taking damage

var start_position: Vector2
var end_position: Vector2

func _ready() -> void:
	# Connect the hurt area's signal for collision detection.
	if hurt_area:
		hurt_area.area_entered.connect(_on_hurt_area_entered)
		hurt_area.body_entered.connect(_on_hurt_body_entered)
	# Initialize marker movement positions.
	start_position = position
	if marker_end_point:
		end_position = marker_end_point.global_position
	else:
		end_position = start_position + Vector2(0, 32)

func _process(_delta: float) -> void:
	updateAnimations()

func _physics_process(_delta: float) -> void:
	update_marker_velocity()
	move_and_slide()

func updateAnimations() -> void:
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func update_marker_velocity() -> void:
	# Marker-based movement: enemy moves between start_position and end_position.
	var move_direction: Vector2 = (end_position - position)
	if move_direction.length() < marker_limit:
		_change_marker_direction()
	# Set velocity in the direction toward the active target position.
	velocity = move_direction.normalized() * speed

func _change_marker_direction() -> void:
	# Swap start and end positions.
	var temp: Vector2 = end_position
	end_position = start_position
	start_position = temp

func _on_hurt_area_entered(area: Area2D) -> void:
	# Check if the area is the player's attack hitbox (temporary)
	if area.is_in_group("player_attack"):
		print("Enemy hit by player's attack!")
		queue_free()

func _on_hurt_body_entered(body: RigidBody2D) -> void:
	# Check if the area is the player's attack hitbox (temporary)
	if body.is_in_group("player_attack"):
		print("Enemy hit by player's attack!")
		queue_free()


func _on_damage_taken(damage: int) -> void:
	health -= damage
	if health <= 0:
		emit_signal("died")
		disable()

func disable() -> void:
	# Disable further physics processing (could also play a death animation, etc.).
	set_physics_process(false)
