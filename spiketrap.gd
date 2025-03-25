extends AnimatedSprite2D  # Now this script runs directly on the AnimatedSprite2D

@export var damage: int = 2  # Damage dealt to the player
@export var damage_frames: Array = [3, 4, 5]  # The frames that deal damage

@onready var hitbox: Area2D = $Area2D  # Reference to the Area2D

var player_in_trap = null  # Stores reference to player

func _ready():
	animation = "default"  # Ensure the correct animation is played
	play()  # Start playing the animation
	frame_changed.connect(_on_frame_changed)  # Detect when the frame changes

	hitbox.body_entered.connect(_on_body_entered)
	hitbox.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_trap = body  # Store player reference

func _on_body_exited(body):
	if body == player_in_trap:
		player_in_trap = null  # Remove player reference when they leave

func _on_frame_changed():
	if frame in damage_frames and player_in_trap:
		if player_in_trap.has_method("take_damage"):
			player_in_trap.take_damage(damage)
			print("Spike trap hit player! Frame:", frame)
