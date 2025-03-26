class_name FireSpirit extends Area2D

signal spirit_picked_up

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	#play idle anim
	$AnimatedSprite2D.play("idle")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# Emit signal; HUD will handle making the sprite visible.
		body.add_spirit("fire")
		Global.emit_signal("spirit_picked_up")
		queue_free()
