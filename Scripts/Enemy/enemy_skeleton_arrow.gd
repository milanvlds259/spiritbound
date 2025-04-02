extends Area2D

var damage: int = 10
var velocity: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
	queue_free()
