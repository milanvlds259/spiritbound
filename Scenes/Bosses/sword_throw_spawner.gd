extends CharacterBody2D

@export var speed: float = 600.0
#@onready var sprite := $AnimatedSprite2D

var direction: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var started := false

func start_homing(target: Vector2):
	target_position = target
	direction = (target_position - global_position).normalized()
	await get_tree().create_timer(1.0).timeout
	started = true
	sprite.play("fly")

func _physics_process(delta):
	if started:
		velocity = direction * speed
		move_and_slide()

func _on_body_entered(body):
	if body.name == "Player":
		sprite.play("impact")
		queue_free()
