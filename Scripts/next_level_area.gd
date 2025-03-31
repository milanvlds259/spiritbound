extends Area2D

signal player_can_transition(can_transition: bool)

@export_file("*.tscn") var next_level: String = ""

var player_in_area: bool = false

func _ready():
	# Make sure this node is in the "next_level" group
	if not is_in_group("next_level"):
		add_to_group("next_level")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	player_in_area = true
	player_can_transition.emit(true)
	body.continue_prompt_visible = true
	body.continue_prompt.visible = true
	print("Player entered next level area")

func _on_body_exited(body: Node2D):
	player_in_area = false
	player_can_transition.emit(false)
	body.continue_prompt_visible = false
	body.continue_prompt.visible = false
	print("Player exited next level area")

func _process(_delta):
	if player_in_area and Input.is_action_just_pressed("interact"):
		print("Transitioning to: ", next_level)
		# Simple fade transition
		if next_level and next_level != "":
			get_tree().change_scene_to_file(next_level)
		else:
			print("ERROR: No next level path specified!")
