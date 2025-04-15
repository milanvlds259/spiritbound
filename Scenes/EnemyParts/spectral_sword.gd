extends Area2D

@export var damage: int = 15
@export var speed: float = 325.0

var velocity: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var movement_active := false

@onready var anim = $AnimatedSprite2D

func _ready():
	anim.play("SwordSpawn")
	await anim.animation_finished
	
	# Set final look direction once after spawn
	look_at(target_pos)
	rotation += deg_to_rad(90)  # Adjust based on sprite design
	
	# Lock in movement direction
	var direction = (target_pos - global_position).normalized()
	velocity = direction * speed
	anim.play("SwordRotate")
	movement_active = true

func set_target(pos: Vector2):
	target_pos = pos

func _process(delta: float) -> void:
	if movement_active:
		position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Sword hit player!")
		body.take_damage(damage)
		shatter()
	elif body.is_in_group("wall"):
		shatter()

func shatter():
	anim.play("SwordShatter")
	await anim.animation_finished
	queue_free()
