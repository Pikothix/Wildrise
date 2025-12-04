class_name DamageComponent
extends Area2D

@export var max_damage: float = 1.0
var current_damage: float = 0.0

signal max_damage_reached

func apply_damage(damage: float) -> void:
	current_damage = clampf(current_damage + damage, 0.0, max_damage)

	if is_equal_approx(current_damage, max_damage):
		max_damage_reached.emit()
