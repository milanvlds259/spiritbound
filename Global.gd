extends Node
# this is an autoload script DO NOT ATTACH THIS TO ANY NODE
# Define a global signal.
signal spirit_picked_up
signal spirit_inventory_updated
signal player_hp_changed
signal setup_hpbar
signal player_died
signal score_updated(enemies_killed, floors_cleared)

var enemies_killed: int = 0
var floors_cleared: int = 0

func add_enemy_kill() -> void:
	enemies_killed += 1
	score_updated.emit(enemies_killed, floors_cleared)

func add_floor_cleared() -> void:
	floors_cleared += 1
	score_updated.emit(enemies_killed, floors_cleared)

func reset_score() -> void:
	enemies_killed = 0
	floors_cleared = 0
	score_updated.emit(enemies_killed, floors_cleared)