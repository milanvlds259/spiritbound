class_name GuardMovementC extends Node

@export var speed = 100
@export var health_component: HealthComponent
@export var limit: int = 10

# Follow for a certain amount of time
@export var follow_duration: int = 10

# Follow while there is a certain distance from starting position
@export var follow_distance: int = 160
@export var consider_distance: int = 130

@onready var parent: CharacterBody2D = get_parent()

@onready var follow_area = $"../FollowArea"

enum State{IDLE, FOLLOW, CONSIDER, BACK}
var current_state: State = State.IDLE

var start_position
var target : Player

func _ready() -> void:
	health_component.died.connect(disable) # Replace with function body.
	start_position = parent.position

func update_velocity():
	match current_state:
		State.IDLE:
			parent.velocity = Vector2.ZERO
			var overlap = follow_area.get_overlapping_bodies()
			var filtered = overlap.filter(func(b): return b is Player)
			if !filtered.is_empty():
				follow_body(filtered[0])

		State.FOLLOW:
			# Follows Player until Enemy gets too far away
			var dist_to_start = (start_position - parent.global_position).length()
			if dist_to_start > follow_distance:
				target = null
				current_state = State.BACK
				return
	
			#Finds the target player's position and computes the directoin to follow
			var direction = target.global_position - parent.global_position
			var new_velocity = direction.normalized() * speed
			parent.velocity = new_velocity
		
		State.CONSIDER:
			var dir_to_start = start_position - parent.global_position
			var overlap = follow_area.get_overlapping_bodies()
			var filtered = overlap.filter(func(b): return b is Player)
			if !filtered.is_empty():
				follow_body(filtered[0])
			if dir_to_start.length() < limit:
				parent.global_position = start_position
				current_state = State.IDLE
		
		State.BACK:
			var dir_to_start = start_position - parent.global_position
			if dir_to_start.length() < consider_distance:
				current_state = State.CONSIDER
		
			parent.velocity = dir_to_start.normalized() * speed


func _physics_process(_delta) -> void:
	update_velocity()
	parent.move_and_slide()

func follow_body(body) -> void:
	target = body
	current_state = State.FOLLOW
	await get_tree().create_timer(follow_duration).timeout
	stop_follow()

func stop_follow() -> void:
	if current_state == State.FOLLOW:
		target = null
		current_state = State.BACK




func disable() -> void:
	process_mode = ProcessMode.PROCESS_MODE_DISABLED



func _on_follow_area_body_exited(body) -> void: pass
	#Follows Player while Player is within the detection area 
	#if body == target:
	 #	target = null
