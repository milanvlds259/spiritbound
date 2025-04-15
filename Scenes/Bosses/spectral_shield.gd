extends Area2D

@onready var anim = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
@onready var regen_timer = get_parent().get_node("ShieldRegenTimer")

var broken = false
var can_be_hit = false

func _ready():
	anim.play("ShieldSpawn")
	await anim.animation_finished
	anim.play("ShieldIdle")
	can_be_hit = true

func _on_area_entered(area: Area2D) -> void:
	if broken or not can_be_hit:
		return

	print("Shield collided with:", area.name, "Groups:", area.get_groups())

	if area.is_in_group("arrows"):
		print("Arrow hit – shield blocks it.")
		return

	if area.is_in_group("player_attack"):
		print("Melee hit detected – shattering shield.")
		shatter()

func shatter():
	broken = true
	can_be_hit = false
	collision.disabled = true
	anim.play("ShieldShatter")
	await anim.animation_finished

	call_deferred("deactivate_shield")

func deactivate_shield():
	visible = false
	regen_timer.start()

func _on_RegenTimer_timeout():
	broken = false
	can_be_hit = false
	visible = true
	collision.disabled = false
	anim.play("ShieldSpawn")
	await anim.animation_finished
	anim.play("ShieldIdle")

	await get_tree().create_timer(0.2).timeout  # Small invulnerability buffer
	can_be_hit = true
