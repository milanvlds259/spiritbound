extends Node

# Game difficulty settings
var curr_difficulty: int = 0
var difficulty_names: Array = ["Easy", "Normal", "Hardcore", "Milansanity"]

# Control settings
var curr_control: int = 0
var control_names: Array = ["Keyboard", "Controller"]

# Return enemy spawn count based on difficulty
func get_enemy_spawncount() -> int:
    match curr_difficulty:
        0: return 3  # Easy
        1: return 5  # Normal
        2: return 8  # Hardcore
        3: return 14 # Milansanity
    return 4  # Default

func next_difficulty() -> String:
    curr_difficulty = (curr_difficulty + 1) % difficulty_names.size()
    return get_difficulty_name()
    
func get_difficulty_name() -> String:
    return difficulty_names[curr_difficulty]

func next_control() -> String:
    curr_control = (curr_control + 1) % control_names.size()
    return get_control_name()
    
func get_control_name() -> String:
    return control_names[curr_control]