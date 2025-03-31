extends TileMapLayer

const ENEMY_FOLDER := "res://Scenes/Enemies/"
@export var base_enemies := 2
@export var enemy_scale_factor := 0.5

var enemy_scenes: Array = []
var spawned_enemies: Array = []

func spawn_enemies():
	print("[Spawner] Starting enemy spawn process...")

	var room_count = 1
	var room_loader = get_tree().get_first_node_in_group("room_loader")
	if room_loader:
		room_count = room_loader.room_count
		print("[Spawner] Room count: %d" % room_count)
	else:
		print("[Spawner] Room loader not found — defaulting room_count to 1")

	if room_count % 5 == 0:
		print("[Spawner] Boss room detected — skipping enemy spawn.")
		return

	load_enemy_scenes()

	var spawn_cells = get_used_cells()
	print("[Spawner] Total spawn cells in enemy_spawner layer: %d" % spawn_cells.size())

	var valid_positions: Array[Vector2] = []
	var tile_size = tile_set.tile_size

	for cell in spawn_cells:
		var world_pos = map_to_local(cell) + Vector2(tile_size) / 2.0
		valid_positions.append(world_pos)

	if valid_positions.is_empty():
		print("[Spawner] No valid positions found! Nothing to spawn.")
		return

	var total_enemies = base_enemies + int(room_count * enemy_scale_factor)
	total_enemies = min(total_enemies, valid_positions.size())
	print("[Spawner] Total enemies to spawn: %d" % total_enemies)

	for i in range(total_enemies):
		var pos = valid_positions.pick_random()
		valid_positions.erase(pos)
		spawn_random_enemy(pos)

func load_enemy_scenes():
	if not enemy_scenes.is_empty():
		print("[Spawner] Enemy scenes already loaded.")
		return

	var dir = DirAccess.open(ENEMY_FOLDER)
	if not dir:
		print("[Spawner] ERROR: Could not open enemy folder: %s" % ENEMY_FOLDER)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			var full_path = ENEMY_FOLDER + file_name
			var enemy_scene = load(full_path)
			if enemy_scene:
				enemy_scenes.append(enemy_scene)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("[Spawner] Total enemy scenes loaded: %d" % enemy_scenes.size())

func spawn_random_enemy(pos: Vector2):
	if enemy_scenes.is_empty():
		print("[Spawner] ERROR: No enemy scenes available to spawn.")
		return

	var enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	enemy.scale = Vector2(0.25, 0.25)

	get_parent().add_child(enemy)
	spawned_enemies.append(enemy)

	enemy.connect("tree_exited", Callable(self, "_on_enemy_died"))
	print("[Spawner] Spawned enemy at position: %s with scale: %s" % [str(pos), str(enemy.scale)])

func _on_enemy_died():
	await get_tree().process_frame

	spawned_enemies = spawned_enemies.filter(func(e):
		return e != null and e.is_inside_tree()
	)

	if spawned_enemies.is_empty():
		print("[Spawner] All enemies defeated. Spawning spirits...")
		var spirit_spawner = get_parent().get_node_or_null("spirit_spawner")
		if spirit_spawner and spirit_spawner.has_method("spawn_spirits"):
			spirit_spawner.spawn_spirits()
		else:
			print("[Spawner] spirit_spawner not found or missing spawn_spirits()")
