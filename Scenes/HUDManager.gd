extends CanvasLayer

func _ready() -> void:

	Global.spirit_inventory_updated.connect(_on_spirit_inventory_updated)
	Global.player_hp_changed.connect(_on_player_hp_changed)
	Global.setup_hpbar.connect(_on_setup_hpbar)

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

func _on_player_hp_changed(new_hp: int) -> void:

	$HPBar.value = new_hp
	$HPBar/HPValueLabel.text = str(new_hp) + " / " + str($HPBar.max_value)

func _on_setup_hpbar(hp: int, max_hp: int) -> void:
	print("Setting up hp bar")
	$HPBar.max_value = max_hp
	$HPBar.value = hp
	$HPBar/HPValueLabel.text = str(hp) + " / " + str(max_hp)
