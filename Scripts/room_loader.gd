extends Node2D

const ROOM_SCENE_FOLDER := "res://scenes/room scenes/"
const BOSS_ROOM_SCENE_FOLDER := "res://scenes/boss room scenes/"

var room_count := 0
var current_room: Node = null

var used_rooms: Array = []
var used_boss_rooms: Array = []

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	load_next_room()

func load_next_room():
	room_count += 1

	var folder_path: String
	var used_list: Array
	var scene_path: String

	if room_count % 5 == 0:
		folder_path = BOSS_ROOM_SCENE_FOLDER
		scene_path = get_boss_room_by_index(used_boss_rooms.size())
	else:
		folder_path = ROOM_SCENE_FOLDER
		scene_path = pick_unique_scene(folder_path, used_rooms)

	print("Loading room #%d from folder: %s" % [room_count, folder_path])
	print("Selected scene path: ", scene_path)

	if scene_path == "":
		print("No unused scenes found!")
		return

	if current_room:
		current_room.queue_free()

	var room_scene = load(scene_path)
	if room_scene:
		current_room = room_scene.instantiate()
		add_child(current_room)
		print("Room added to scene tree.")
		print("Room structure:")
		current_room.print_tree_pretty()
		call_deferred("_place_player_and_spawn_enemies")
	else:
		print("Failed to load scene: ", scene_path)

func _place_player_and_spawn_enemies():
	player = get_tree().get_first_node_in_group("player")
	if player and current_room:
		var spawn = current_room.get_node_or_null("PlayerSpawn")
		if spawn:
			player.global_position = spawn.global_position
			print("Player placed at: ", player.global_position)
		else:
			print("PlayerSpawn node not found in current room!")

		print("Looking for enemy_spawner in room children...")
		for node in current_room.get_children():
			if node.name == "enemy_spawner":
				if node.has_method("spawn_enemies"):
					print("Calling enemy_spawner.spawn_enemies()...")
					node.call_deferred("spawn_enemies")
				else:
					print("enemy_spawner node found but has no 'spawn_enemies' method")
	else:
		print("Player or current_room is null")

func pick_unique_scene(folder_path: String, used_list: Array) -> String:
	var files = []
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			print("Checking file:", file_name)
			if not dir.current_is_dir() and (file_name.ends_with(".tscn") or file_name.ends_with(".tscn.remap")):
				var full_path = folder_path + file_name
				print("Found candidate:", full_path)
				if not used_list.has(full_path.replace(".remap", "")):
					files.append(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("ERROR: Could not open directory: ", folder_path)

	print("DEBUG FILES FOUND IN DIR:")
	for f in files:
		print(" →", f)

	if files.is_empty():
		print("All scenes used in folder: ", folder_path)
		return ""

	var selected = files[randi() % files.size()]
	if selected.ends_with(".remap"):
		selected = selected.replace(".remap", "")
	used_list.append(selected)
	return selected

func get_boss_room_by_index(index: int) -> String:
	var boss_files = [
		"tc_1.tscn",
		"tc_2.tscn",
		"tc_3.tscn",
		"tc_4.tscn"
	]

	if index >= boss_files.size():
		index = boss_files.size() - 1  # clamp to last if somehow over

	var file = boss_files[index]
	var full_path = BOSS_ROOM_SCENE_FOLDER + file
	var remap_path = full_path + ".remap"

	if FileAccess.file_exists(remap_path):
		full_path = remap_path

	used_boss_rooms.append(full_path.replace(".remap", ""))
	return full_path.replace(".remap", "")
