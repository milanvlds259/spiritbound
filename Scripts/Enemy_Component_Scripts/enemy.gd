extends CharacterBody2D

var startPosition
var endPosition

@onready var animations = $Sprite2D
@export var speed = 100;



func _process(_delta) -> void:
	updateAnimations()

func updateAnimations():
	if velocity.x > 0:
		animations.flip_h = false
	if velocity.x < 0 :
		animations.flip_h = true

func disable() -> void:
	pass
