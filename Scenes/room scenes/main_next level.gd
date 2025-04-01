class_name main_next_level
extends Area2D

signal player_can_transition(can_transition: bool)

var player_in_area: bool = false

func _ready():
	if not is_in_group("next_level"):
		add_to_group("next_level")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	player_in_area = true
	player_can_transition.emit(true)

	if body.has_node("ContinuePrompt"):
		body.get_node("ContinuePrompt").visible = true

	print("Player entered next level area")

func _on_body_exited(body: Node2D):
	player_in_area = false
	player_can_transition.emit(false)

	if body.has_node("ContinuePrompt"):
		body.get_node("ContinuePrompt").visible = false

	print("Player exited next level area")

func _process(_delta):
	if player_in_area and Input.is_action_just_pressed("interact"):
		print("Interacted with NextLevelArea")
		var room_loader = find_room_loader()
		if room_loader:
			room_loader.load_next_room()
		else:
			print("ERROR: RoomLoader not found in scene!")

func find_room_loader() -> Node:
	# Walk up the scene tree until we find the node named "room_loader"
	var current = get_parent()
	while current:
		if current.name == "room_loader":
			return current
		current = current.get_parent()
	return null
