extends CanvasLayer

func _ready() -> void:

	Global.spirit_inventory_updated.connect(_on_spirit_inventory_updated)

func _on_spirit_inventory_updated(new_inventory: Array) -> void:
	var inventory = $SpiritInventory
	print(inventory)
	# Optionally, reset all panels first.
	for panel in inventory.get_children():
		print(panel)
		if panel.has_node("Sprite"):
			print("Panel has sprite")
			panel.get_node("Sprite").visible = false
	# Show sprites based on the player's inventory
	for index in range(new_inventory.size()):
		# Assume panel order corresponds to inventory order.
		var panel = inventory.get_child(index)
		if panel.has_node("Sprite"):
			var spirit_sprite = panel.get_node("Sprite")
			spirit_sprite.visible = true