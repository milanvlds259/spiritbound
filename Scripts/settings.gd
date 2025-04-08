extends Node


# Path to the main game scene - change this to your main scene path
@export var title_screen_path : String = "res://Scenes/title_screen.tscn"

var scene_path: String = ""

# Transition properties
var transition_duration = 0.75  # Time in seconds for the fade
var is_transitioning = false

# Reference to the transition overlay
var transition_overlay: ColorRect

func _ready():
	# Connect the play button signal
	$CloseButton.pressed.connect(_on_close_button_pressed)
	$ChangeModeButton.pressed.connect(_on_change_mode_button_pressed)
	$ChangeControlButton.pressed.connect(_on_change_control_button_pressed)

	$DifficultyText.text = SettingsManager.get_difficulty_name()
	$ControlTypeText.text = SettingsManager.get_control_name()

	# Create a transition overlay
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)  # Start fully transparent
	transition_overlay.size = Vector2(1920, 1080)  # Make it cover the screen
	transition_overlay.z_index = 100  # Ensure it shows on top
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Prevent catching mouse events
	add_child(transition_overlay)

func _on_close_button_pressed() -> void:
	if is_transitioning:
		return
	
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1), transition_duration)
	scene_path = title_screen_path
	tween.tween_callback(change_scene)


func _on_change_mode_button_pressed() -> void:
	$DifficultyText.text = SettingsManager.next_difficulty()

func _on_change_control_button_pressed() -> void:
	$ControlTypeText.text = SettingsManager.next_control()
	

func change_scene():
	# Change to the main scene
	get_tree().change_scene_to_file(scene_path)
