extends Area2D

@onready var anim = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
@onready var regen_timer = $Timer

var broken = false

func _ready():
	anim.play("ShieldSpawn")
	await anim.animation_finished
	anim.play("ShieldIdle")

func _on_body_entered(body: Node2D) -> void:
	if broken:
		return

	print("Shield collided with:", body.name)

	if body.is_in_group("arrows"):
		print("Arrow hit – shield blocks it.")
		return

	if body.is_in_group("player_attack"):
		print("Melee hit detected – shield will shatter!")
		shatter()

func shatter():
	broken = true
	collision.disabled = true
	anim.play("ShieldShatter")
	await anim.animation_finished

	visible = false
	regen_timer.start()

	# Notify parent (e.g. Banshee) if needed
	if get_parent().has_method("on_shield_shattered"):
		get_parent().on_shield_shattered()

func _on_Timer_timeout():
	broken = false
	visible = true
	collision.disabled = false
	anim.play("ShieldSpawn")
	await anim.animation_finished
	anim.play("ShieldIdle")
