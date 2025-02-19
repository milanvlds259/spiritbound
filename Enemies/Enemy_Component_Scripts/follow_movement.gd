class_name FollowMovementC extends Node

@export var speed = 20
#@export var healthComponent: HealthComponent

@onready var parent: CharacterBody2D = get_parent()

var start_position
#var target : Player

func _ready() -> void:
	#healthComponent.died.connect(disable) # Replace with function body.
	start_position = parent.position

func update_velocity(dir):
	#if !target: return
	
	#var direction = target.global_position - parent.global_position
	#var new_velocity = direction.normalized() * speed
	var new_velocity = Vector2(dir, dir).normalized() * speed
	parent.velocity = new_velocity

func _physics_process(_delta) -> void:
	update_velocity(1)
	parent.move_and_slide()

func disable() -> void:
	process_mode = ProcessMode.PROCESS_MODE_DISABLED

func _on_follow_area_body_entered(body: Node2D) -> void:
	update_velocity(-1)
	#if body is Player:
	#	target = body
