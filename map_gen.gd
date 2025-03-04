extends Node2D

const MAP_SCENE_PATHS := {
	"top_left": "res://Map scenes/top left/",
	"top_center": "res://Map scenes/top center/",
	"top_right": "res://Map scenes/top right/",
	"center_left": "res://Map scenes/center left/",
	"center_center": "res://Map scenes/center center/",
	"center_right": "res://Map scenes/center right/",
	"bottom_left": "res://Map scenes/bottom left/",
	"bottom_center": "res://Map scenes/bottom center/",
	"bottom_right": "res://Map scenes/bottom right/"
}

func _ready():
	for key in MAP_SCENE_PATHS.keys():
		var scene_path = pick_random_scene(MAP_SCENE_PATHS[key])
		if scene_path:
			load_and_add_scene(scene_path)

func pick_random_scene(folder_path: String) -> String:
	var files = []
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				files.append(folder_path + file_name)
			file_name = dir.get_next()
	
	if files.size() > 0:
		return files[randi() % files.size()]
	return ""

func load_and_add_scene(scene_path: String):
	var scene = load(scene_path).instantiate()
	if scene:
		for child in scene.get_children():
			if "TileMapLayer" in child.get_class():
				add_child(child.duplicate())
