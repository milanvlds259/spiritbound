extends Node2D

const SPIRIT_FOLDER := "res://Scenes/spirits/"  # Ensure this matches your folder exactly
const MEDKIT_SCENE := "res://Scenes/medkit.tscn"

var spirit_scenes: Array = []
var medkit_scene: PackedScene

func _ready():
	load_spirit_scenes()
	medkit_scene = load(MEDKIT_SCENE)
	if not medkit_scene:
		print("[Spirits] ERROR: Could not load medkit scene.")

func spawn_spirits():
	print("[Spirits] Spawning spirits...")

	if spirit_scenes.is_empty():
		print("[Spirits] No spirit scenes loaded.")
		return

	if not medkit_scene:
		print("[Spirits] ERROR: Medkit scene not loaded.")
		return

	var room = get_parent()
	var spawn_points = get_children().filter(func(n): return n is Node2D)

	if spawn_points.size() < 3:
		print("[Spirits] Not enough spawn points. Need at least 3.")
		return

	# Shuffle spirit scenes and take 3 unique ones (or fewer if limited)
	var shuffled_spirits = spirit_scenes.duplicate()
	shuffled_spirits.shuffle()

	for i in range(spawn_points.size()):
		var spawn_point = spawn_points[i]
		var instance
        
        # First and third points spawn medkits
		if i == 0 or i == 2:
			if i >= spawn_points.size():  # Skip if not enough spawn points
				continue
			instance = medkit_scene.instantiate()
			print("[Spawner] Spawning medkit at point %d" % i)
		else:
            # Other points spawn spirits
			var spirit_scene = shuffled_spirits[i % shuffled_spirits.size()]
			instance = spirit_scene.instantiate()
			instance.scale = Vector2(0.25, 0.25)
			print("[Spirits] Spawned %s at point %d" % [spirit_scene.resource_path, i])
        
        # Place relative to room
		instance.position = room.to_local(spawn_point.global_position)
		instance.z_index = 999
        
		room.add_child(instance)

func load_spirit_scenes():
	if not spirit_scenes.is_empty():
		return

	var dir = DirAccess.open(SPIRIT_FOLDER)
	if not dir:
		print("[Spirits] ERROR: Could not open folder: %s" % SPIRIT_FOLDER)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			var scene_path = SPIRIT_FOLDER + file_name
			var scene = load(scene_path)
			if scene:
				spirit_scenes.append(scene)
		file_name = dir.get_next()
	dir.list_dir_end()

	print("[Spirits] Loaded %d spirit scenes." % spirit_scenes.size())
