class_name HurtBoxC extends Node

@export var area2D: Area2D

signal damage_taken

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area2D.body_entered.connect(collision)

func collision(body) -> void:
	damage_taken.emit(1)
	print(body)
