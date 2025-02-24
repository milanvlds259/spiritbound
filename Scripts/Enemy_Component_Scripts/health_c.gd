class_name HealthComponent extends Node

signal died
# Health value
@export var health: int = 1
@export var hurt_comp: HurtBoxC


func _ready() -> void:
	# This connects the damage_taken function in this node to the damage signal
	hurt_comp.damage_taken.connect(damage_taken) 


func damage_taken(damage) -> void:
	# Function for taking a certain @damage and tracking the health of the mob
	health -= damage
	if health <= 0:
		# Checking for death
		died.emit()

# Called when the node enters the scene tree for the first time.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
