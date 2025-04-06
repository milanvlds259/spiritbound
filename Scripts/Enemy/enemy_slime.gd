class_name EnemySlime extends CharacterBody2D

@export var health: int = 10
@export var speed: int = 150
var target: Player
@onready var nav_agent:= $NavigationAgent2D as NavigationAgent2D


var idle: bool = true
var starting_position

@onready var hurt_area: Area2D = $HitBox         # The Area2D used for taking damage
var hurt_color = Color(1, 0.3, 0.3)
var invincible: bool = false
@export var damage_label: PackedScene

@onready var sprite = $SlimeSprite

func _ready():
	starting_position = global_position
	hurt_area.area_entered.connect(_on_hurt_area_entered)
	sprite.animation_finished.connect(_on_animation_finished)

func _process(_delta: float) -> void:
	update_animations()

func _physics_process(_delta: float) -> void:
	update_velocity()
	move_and_slide()

func update_animations() -> void:
	if idle:
		sprite.play("idle")
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func update_velocity():
	var overlapping = $Vision.get_overlapping_bodies()
	var filtered = overlapping.filter(func(b): return b is Player)
	if !filtered.is_empty():
		target = filtered[0]
	else:
		target = null
	var dir = to_local(nav_agent.get_next_path_position()).normalized()
	velocity = dir * speed

func make_path() -> void:
	if target:
		nav_agent.target_position = target.global_position
	else:
		nav_agent.target_position = starting_position

func _on_hurt_area_entered(area: Area2D) -> void:
	# Check if the area is the player's attack hitbox (temporary)
	if !invincible:
		if area.is_in_group("player_attack"):
			damage_taken(3)
		elif area.is_in_group("arrows"):
			damage_taken(3)
			area.queue_free()

func damage_taken(damage: int) -> void:
	modulate = hurt_color
	idle = false
	sprite.play("hurt")
	var damage_label_instance = damage_label.instantiate()
	damage_label_instance.text = str(damage)
	add_child(damage_label_instance)
	health -= damage
	if health <= 0:
		died()

func died() -> void:
	disable()
	sprite.play("death")

func disable() -> void:
	# Disable further physics processing (could also play a death animation, etc.).
	set_physics_process(false)

func _on_animation_finished() -> void:
	modulate = Color(1,1,1,1)
	if sprite.animation == "hurt":
		idle = true
	elif sprite.animation == "death":
		queue_free()


func _on_timer_timeout() -> void:
	make_path()
	# Replace with function body.
