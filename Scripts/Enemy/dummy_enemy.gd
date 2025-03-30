class_name DummyEnemy extends CharacterBody2D

@export var health: int = 1

@export var damage_label: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurt_area: Area2D = $HitBox         # The Area2D used for taking damage

@export var impulse_str: float = 200

var hurt_color = Color(255,0,0)
var hurt_duration = 0.1

func _ready() -> void:
	# Connect the hurt area's signal for collision detection.
	if hurt_area:
		hurt_area.area_entered.connect(_on_hurt_area_entered)

	# Connect enemy hitbox to hit player
	$HitBox.body_entered.connect(_on_hitbox_body_entered)

func _on_hurt_area_entered(area: Area2D) -> void:
	# Check if the area is the player's attack hitbox (temporary)
	if area.is_in_group("player_attack"):
		damage_taken(5)
	elif area.is_in_group("arrows"):
		damage_taken(2)
		area.queue_free()

func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		var push_dir = (body.global_position - global_position).normalized()
		
		
		if body.has_method("apply_knockback"):
			body.apply_knockback(push_dir * impulse_str)


func damage_taken(damage: int) -> void:
	modulate = hurt_color
	health -= damage

	var damage_label_instance = damage_label.instantiate()
	damage_label_instance.text = str(damage)

	add_child(damage_label_instance)

	if health <= 0:
		died()
	await get_tree().create_timer(hurt_duration).timeout
	modulate = Color(1, 1, 1, 1)

func died() -> void:
	disable()
	modulate = hurt_color
	await get_tree().create_timer(hurt_duration).timeout
	queue_free()

func disable() -> void:
	# Disable further physics processing (could also play a death animation, etc.).
	set_physics_process(false)
