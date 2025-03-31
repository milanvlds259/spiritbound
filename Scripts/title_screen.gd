extends Node

# Path to the main game scene - change this to your main scene path
@export var scene_path : String = "res://Scenes/main.tscn"

# Transition properties
var transition_duration = 0.75  # Time in seconds for the fade
var is_transitioning = false

# Reference to the transition overlay
var transition_overlay: ColorRect

func _ready():
	# Connect the play button signal
	$PlayButton.pressed.connect(_on_play_button_pressed)
	
	# Create a transition overlay
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)  # Start fully transparent
	transition_overlay.size = Vector2(1920, 1080)  # Make it cover the screen
	transition_overlay.z_index = 100  # Ensure it shows on top
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Prevent catching mouse events
	add_child(transition_overlay)

func _on_play_button_pressed():
	if is_transitioning:
		return
		
	is_transitioning = true
	
	# Create a tween for smooth fade transition
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1), transition_duration)
	tween.tween_callback(change_scene)

func change_scene():
	# Change to the main scene
	get_tree().change_scene_to_file(scene_path)
