extends Area2D

var velocity: Vector2 = Vector2.ZERO

func _ready():
	# connect the signal to the function
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		queue_free()
