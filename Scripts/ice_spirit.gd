extends Area2D
class_name IceSpirit

signal spirit_picked_up

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$AnimatedSprite2D.play("idle")

func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.add_spirit("ice")
		Global.emit_signal("spirit_picked_up")
		queue_free()
