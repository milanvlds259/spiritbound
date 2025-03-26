extends CharacterBody2D

@export var health: int = 1
@export var mask_node: NodePath  # Assign the mask node in the inspector

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $HitBox

var mask_reference: Node = null  # Store the mask instance

func _ready():
	print("box Ready! Children:")
	for child in get_children():
		print("-", child.name)
	
	hitbox.area_entered.connect(_on_hitbox_area_entered)

	# Get reference to the mask node
	if mask_node:
		mask_reference = get_node(mask_node)

func _on_hitbox_area_entered(area: Area2D):
	print("HitBox detected collision with:", area.name)
	if area.is_in_group("player_attack"):
		damage_taken(1)

func damage_taken(damage: int) -> void:
	health -= damage
	print("Bookshelf took damage! Health:", health)
	if health <= 0:
		died()

func died() -> void:
	if mask_reference and mask_reference.has_method("reduce_opacity"):
		mask_reference.reduce_opacity()
	queue_free()
