extends CanvasLayer

@export var spirit_textures: Dictionary
@export var menu_scene: PackedScene

func _ready() -> void:

	Global.spirit_inventory_updated.connect(_on_spirit_inventory_updated)
	Global.player_hp_changed.connect(_on_player_hp_changed)
	Global.setup_hpbar.connect(_on_setup_hpbar)
	Global.player_died.connect(_on_player_died)
	Global.score_updated.connect(_on_score_updated)
	$RestartButton.pressed.connect(_on_restart_button_pressed)
	$MenuBackButton.pressed.connect(_on_menu_back_button_pressed)

func _on_spirit_inventory_updated(new_inventory: Array) -> void:
	var inventory = $SpiritInventory
	# reset all panels first.
	for panel in inventory.get_children():
		print(panel)
		if panel.has_node("Sprite"):
			print("Panel has sprite")
			panel.get_node("Sprite").visible = false

	# Show sprites based on the player's inventory
	for index in range(new_inventory.size()):
		# Get spirit type
		var spirit_type = new_inventory[index]
		# Get the panel for the spirit
		var panel = inventory.get_child(index)
		if panel.has_node("Sprite"):
			# Get the sprite node
			var sprite = panel.get_node("Sprite")
			if spirit_textures.has(spirit_type):
				# Set the sprite texture
				sprite.texture = spirit_textures[spirit_type]
				# Make the sprite visible
				sprite.visible = true
			else:
				print("No texture found for spirit type: " + spirit_type)

func _on_player_hp_changed(new_hp: int) -> void:

	$HPBar.value = new_hp
	$HPBar/HPValueLabel.text = str(new_hp) + " / " + str(int($HPBar.max_value))

func _on_setup_hpbar(hp: int, max_hp: int) -> void:
	print("Setting up hp bar")
	$HPBar.max_value = max_hp
	$HPBar.value = hp
	$HPBar/HPValueLabel.text = str(hp) + " / " + str(max_hp)

func _on_player_died() -> void:
	# Tint the screen darker by showing a semi-transparent ColorRect
	$DeathTint.visible = true
	$RestartButton.visible = true
	$GameOverText.visible = true
	$MenuBackButton.visible = true
	$GameOverText/Score.visible = true
	$DeathSound.play()


	_on_score_updated(Global.enemies_killed, Global.floors_cleared)

func _on_restart_button_pressed() -> void:
	Global.reset_score()
	get_tree().reload_current_scene()

func _on_menu_back_button_pressed() -> void:
	#transition to the menu scene (not instantiated)
	get_tree().change_scene_to_packed(menu_scene)

func _on_score_updated(enemies_killed: int, floors_cleared: int) -> void:
	$GameOverText/Score.text = "Floors Cleared: " + str(floors_cleared) + "\nEnemies Killed: " + str(enemies_killed)
