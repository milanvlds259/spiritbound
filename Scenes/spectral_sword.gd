extends Area2D

@export var damage: int = 4
@export var speed: float = 325.0

var velocity: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var tracking := true
var movement_active := false

func _ready():
	$AnimatedSprite2D.play("SwordSpawn")
	await $AnimatedSprite2D.animation_finished

	tracking = false
	$AnimatedSprite2D.play("SwordRotate")

	var direction = (target_pos - global_position).normalized()
	velocity = direction * speed
	look_at(target_pos)
	rotation += deg_to_rad(90)
	movement_active = true

func set_target(pos: Vector2):
	target_pos = pos

func start_after_delay(pos: Vector2, delay: float):
	await get_tree().create_timer(delay).timeout
	set_target(pos)

func _process(delta: float) -> void:
	if tracking and target_pos != Vector2.ZERO:
		look_at(target_pos)
		rotation += deg_to_rad(90)

	if movement_active:
		position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
		print("Sword hit player!")
	queue_free()
	
