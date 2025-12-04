extends Area2D
class_name Hurtbox

@export var owner_stats: Stats

signal hit_received(damage: int, from: Area2D)

func _ready() -> void:
	# This area is *detected* by hitboxes, but doesn't detect anything itself
	monitoring = false
	monitorable = true

	# Put all hurtboxes on layer 1 (same as before)
	collision_layer = 1
	# It doesn't need to detect anything, so mask = 0
	collision_mask = 0

func receive_hit(damage: int, from: Area2D) -> void:
	# Let the owner (tree, NPC, etc.) hook in custom logic
	hit_received.emit(damage, from)

	# Default behaviour: if we have Stats, forward the damage there
	if owner_stats:
		owner_stats.take_damage(damage)
