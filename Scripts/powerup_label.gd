extends Label

var velocity = Vector2(0, -40)  # Upward movement speed
var fade_speed = 1.25          # How quickly it fades out

func _ready():
	# Random horizontal offset for variation
	position.x += randf_range(-5, 5)
    
func _process(delta):
	# Move the label upward
	position += velocity * delta
		
    # Fade out the label
	modulate.a -= fade_speed * delta
		
	# Remove the label when it's fully transparent
	if modulate.a <= 0:
		queue_free()