extends Area2D

@onready var anim = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
@onready var regen_timer = $RegenTimer

var broken = false

func _ready():
	anim.play("ShieldSpawn")
	await anim.animation_finished
	anim.play("ShieldIdle")

func _on_body_entered(body):
	if broken:
		return

	# Ignore ranged damage
	if body.is_in_group("ranged"):
		return

	# Accept melee hit
	if body.is_in_group("melee"):
		shatter()

func shatter():
	broken = true
	collision.disabled = true
	anim.play("ShieldShatter")
	await anim.animation_finished

	# Hide instead of queue_free to allow regeneration
	visible = false
	regen_timer.start()

func _on_RegenTimer_timeout():
	# Reactivate the shield
	broken = false
	visible = true
	collision.disabled = false
	anim.play("ShieldSpawn")
	await anim.animation_finished
	anim.play("ShieldIdle")


func _on_timer_timeout() -> void:
	pass # Replace with function body.
