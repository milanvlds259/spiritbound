extends Area2D

@export var heal_amount: int = 20

func _ready() -> void:
    # Connect the body_entered signal to our function
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    # Check if the body that entered is the player
	if body is Player:
        # Heal the player
		if body.hp < body.max_hp:
            # Cap the healing to max_hp
			var actual_heal = min(heal_amount, body.max_hp - body.hp)
			body.hp += actual_heal
            
            # Update the UI
			Global.emit_signal("player_hp_changed", body.hp)
            
            # Create visual feedback (optional)
			if body.has_method("show_healing_effect"):
				body.show_healing_effect(actual_heal)
            
            # Remove the medkit
			queue_free()