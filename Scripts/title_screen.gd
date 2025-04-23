extends Node

# Path to the main game scene - change this to your main scene path
@export var main_scene_path : String = "res://room_loader.tscn"
@export var tutorial_scene_path_keyboard: String = "res://scenes/levels/tutorial_level.tscn"
@export var tutorial_scene_path_controller: String = "res://scenes/levels/tutorial_level2.tscn"
@export var settings_scene_path: String = "res://scenes/settings.tscn"

var scene_path: String = ""

# Transition properties
var transition_duration = 0.75  # Time in seconds for the fade
var is_transitioning = false

# Reference to the transition overlay
var transition_overlay: ColorRect

func _ready():
	# Connect the play button signal
	$PlayButton.pressed.connect(_on_play_button_pressed)
	$TutorialButton.pressed.connect(_on_tutorial_button_pressed)
	$SettingsButton.pressed.connect(_on_settings_button_pressed)
	# Create a transition overlay
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)  # Start fully transparent
	transition_overlay.size = Vector2(1920, 1080)  # Make it cover the screen
	transition_overlay.z_index = 100  # Ensure it shows on top
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Prevent catching mouse events
	add_child(transition_overlay)

func _on_play_button_pressed() -> void:
	if is_transitioning:
		return
		
	is_transitioning = true
	
	# Create a tween for smooth fade transition
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1), transition_duration)
	scene_path = main_scene_path
	tween.tween_callback(change_scene)

func _on_settings_button_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	# Create a tween for smooth fade transition
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1), transition_duration)
	scene_path = settings_scene_path
	tween.tween_callback(change_scene)
	
func _on_tutorial_button_pressed() -> void:
	if is_transitioning:
		return
	
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1), transition_duration)
	if SettingsManager.get_control_name() == "Controller":
		scene_path = tutorial_scene_path_controller
	elif SettingsManager.get_control_name() == "Keyboard":
		scene_path = tutorial_scene_path_keyboard
	tween.tween_callback(change_scene)


func change_scene():
	# Change to the main scene
	get_tree().change_scene_to_file(scene_path)
