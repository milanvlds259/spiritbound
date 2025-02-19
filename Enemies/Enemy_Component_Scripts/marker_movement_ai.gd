class_name MarkerMovementAIC extends Node

@export var speed = 100
@export var end_point: Marker2D = null
@export var limit = 0.5

@export var health_comp: HealthComponent
@export var hurt_comp: HurtBoxC


@onready var parent = get_parent()
var start_position
var end_position

# Called when the node enters the scene tree for the first time.
func _ready():
	health_comp.died.connect(disable)
	
	end_point = parent.get_node_or_null("Marker2D")
	start_position = parent.position
	if !end_point:
		end_position = start_position + Vector2(0, 32)
		return
	
	end_position = end_point.global_position
	
func change_direction():
	var temp_end = end_position
	end_position = start_position
	start_position = temp_end

func update_velocity():
	var move_direction = (end_position - parent.position)
	if move_direction.length() < limit:
		change_direction()
	
	parent.velocity = move_direction.normalized()*speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	update_velocity()
	parent.move_and_slide()

func disable() -> void:
	process_mode = ProcessMode.PROCESS_MODE_DISABLED
