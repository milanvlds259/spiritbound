extends CharacterBody2D

enum Phase { PHASE_ONE, PHASE_TWO, PHASE_THREE }

@export var max_health: int = 30
@export var speed: float = 200.0
@export var avoid_range: float = 200.0
@export var sword_scene: PackedScene
@export var shield_scene: PackedScene

var current_health: int = 0
var current_phase: int = Phase.PHASE_ONE
var shield_instance: Node = null
var player_node: Node = null
var is_dead: bool = false

@onready var anim = $AnimatedSprite2D
@onready var attack_timer = $AttackTimer
@onready var channel_timer = $SwordSpawnTimer

func _ready():
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_node = players[0]
		print("Banshee found player at:", player_node.global_position)
	else:
		print("No player found in group.")

	current_health = max_health
	enter_phase(current_phase)
	attack_timer.start()
	anim.play("BansheeIdle")

func _physics_process(delta):
	if is_dead:
		return
	update_phase()
	handle_movement()

func update_phase():
	var health_percent = float(current_health) / max_health
	var new_phase = current_phase

	if health_percent <= 0.33:
		new_phase = Phase.PHASE_THREE
	elif health_percent <= 0.66:
		new_phase = Phase.PHASE_TWO
	else:
		new_phase = Phase.PHASE_ONE

	if new_phase != current_phase:
		current_phase = new_phase
		enter_phase(current_phase)

func enter_phase(phase):
	match phase:
		Phase.PHASE_ONE:
			remove_shield()
			channel_timer.stop()
		Phase.PHASE_TWO:
			spawn_shield()
			channel_timer.stop()
		Phase.PHASE_THREE:
			spawn_shield()
			channel_timer.start()

func spawn_shield():
	if shield_scene and not shield_instance:
		print("Spawning shield...")
		shield_instance = shield_scene.instantiate()
		if not shield_instance:
			print("Shield instantiation failed.")
		else:
			add_child(shield_instance)
			shield_instance.global_position = global_position
			shield_instance.scale *= 3
	else:
		print("Shield not spawned. Either already exists or scene not assigned.")

func remove_shield():
	if shield_instance:
		shield_instance.queue_free()
		shield_instance = null

func handle_movement():
	if not player_node:
		return

	var to_player = player_node.global_position - global_position
	if to_player.length() < avoid_range:
		velocity = -to_player.normalized() * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func _on_attack_timer_timeout() -> void:
	if is_dead or not player_node:
		return

	anim.play("BansheeAttack")
	throw_sword()

func throw_sword():
	if sword_scene and player_node:
		var sword = sword_scene.instantiate()
		get_tree().current_scene.add_child(sword)
		sword.global_position = global_position + Vector2(0, -100)
		print("Sword spawned at:", sword.global_position)
		sword.call_deferred("set_target", player_node.global_position)

func _on_SwordSpawnTimer_timeout():
	if is_dead or not player_node:
		return

	anim.play("BansheeChannel")
	spawn_swords_around_player(player_node.global_position)

func spawn_swords_around_player(center: Vector2):
	var num_swords = 8
	var radius = 200.0

	for i in num_swords:
		var angle = (TAU / num_swords) * i
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		var sword = sword_scene.instantiate()
		get_tree().current_scene.add_child(sword)
		sword.global_position = pos
		sword.look_at(center)
		sword.start_after_delay(center, 1.0)

func take_damage(amount: int) -> void:
	if shield_instance and not shield_instance.broken:
		print("Shield is active! Damage blocked.")
		return
	
	current_health -= amount
	print("Banshee took damage! Current HP:", current_health)
	$AnimatedSprite2D.modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	$AnimatedSprite2D.modulate = Color(1, 1, 1)

	if current_health <= 0:
		die()

func on_shield_shattered():
	shield_instance = null

func die():
	if is_dead:
		return

	is_dead = true
	print("Banshee has been defeated!")
	anim.play("BansheeDeath")
	attack_timer.stop()
	channel_timer.stop()
	set_physics_process(false)
	await anim.animation_finished
	queue_free()

func _on_HitBox_area_entered(area: Area2D) -> void:
	print("HitBox collided with:", area.name)

	if area.is_in_group("player_attack"):
		print("Melee hit detected!")
		take_damage(4)

	elif area.is_in_group("arrows"):
		print("Arrow hit detected!")
		take_damage(2)
		area.queue_free()

	else:
		print("Not a valid attack group.")
