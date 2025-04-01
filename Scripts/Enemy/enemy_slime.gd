class_name EnemySlime extends CharacterBody2D

@export var speed: int = 150
var target: Player
@onready var nav_agent:= $NavigationAgent2D as NavigationAgent2D

var starting_position


@onready var sprite = $SlimeSprite

func _ready():
	starting_position = global_position

func _process(_delta: float) -> void:
	update_animations()

func _physics_process(_delta: float) -> void:
	update_velocity()
	move_and_slide()

func update_animations() -> void:
	sprite.play("idle")
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true

func update_velocity():
	var overlapping = $Vision.get_overlapping_bodies()
	var filtered = overlapping.filter(func(b): return b is Player)
	if !filtered.is_empty():
		print("found player")
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


func _on_timer_timeout() -> void:
	make_path()
	# Replace with function body.
